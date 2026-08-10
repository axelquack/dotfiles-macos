#!/usr/bin/env bash
# Bootstrap machine secrets from Proton Pass (pass-cli) + chezmoi.
#
# Public-repo safe: host/key inventory is **not** in git. Provide a local map:
#   cp scripts/pass-ssh-key-map.example scripts/pass-ssh-key-map.local
#
#   1) SSH private keys: Pass ssh_key items → ~/.ssh/ (mode 600)
#   2) SSH host config + git identity: chezmoi apply (Pass-backed templates)
#   3) Optional: pass-cli ssh-agent load
#   4) Optional: ~/.zshrc.local from pass-env-map.local
#
# Prerequisites: pass-cli login; ~/.config/chezmoi/chezmoi.toml (local, never commit)
#
# Usage:
#   ./scripts/bootstrap-secrets-from-pass.sh
#   ./scripts/bootstrap-secrets-from-pass.sh --keys-only
#   ./scripts/bootstrap-secrets-from-pass.sh --no-chezmoi
#   ./scripts/bootstrap-secrets-from-pass.sh --with-zshrc-local
#   ./scripts/bootstrap-secrets-from-pass.sh --agent-load
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=pass-map-lib.sh
source "$SCRIPT_DIR/pass-map-lib.sh"

VAULT="${PASS_VAULT:-Personal}"
MAP_FILE="${PASS_SSH_MAP:-$SCRIPT_DIR/pass-ssh-key-map.local}"
EXAMPLE="$SCRIPT_DIR/pass-ssh-key-map.example"
KEYS_ONLY=0
NO_CHEZMOI=0
WITH_ZSHRC=0
AGENT_LOAD=0

for arg in "$@"; do
  case "$arg" in
    --keys-only) KEYS_ONLY=1 ;;
    --no-chezmoi) NO_CHEZMOI=1 ;;
    --with-zshrc-local) WITH_ZSHRC=1 ;;
    --agent-load) AGENT_LOAD=1 ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

if ! command -v pass-cli >/dev/null 2>&1; then
  die "pass-cli not found (brew install pass-cli)"
fi
if ! pass-cli vault list >/dev/null 2>&1; then
  die "pass-cli not logged in — run: pass-cli login"
fi

pass_map_require "$MAP_FILE" "$EXAMPLE" || exit 1
KEY_MAP=()
while IFS= read -r line; do
  KEY_MAP+=("$line")
done < <(pass_map_load_lines "$MAP_FILE")
[[ ${#KEY_MAP[@]} -gt 0 ]] || die "empty map: $MAP_FILE"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

write_key_from_pass() {
  local basename="$1"
  local title="$2"
  local priv="$HOME/.ssh/$basename"
  local pub="$HOME/.ssh/${basename}.pub"

  local material
  if ! material=$(pass-cli item view --vault-name "$VAULT" --item-title "$title" --output json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
item=d.get("item") or d
content=item.get("content") or {}
inner=content.get("content") or content
ssh=inner.get("SshKey") or inner.get("ssh_key") or {}
priv=ssh.get("private_key") or ""
pub=ssh.get("public_key") or ""
if not priv:
  sys.exit(2)
sys.stdout.write(priv)
if not priv.endswith("\n"):
  sys.stdout.write("\n")
sys.stdout.write("---PUB---\n")
sys.stdout.write(pub)
if pub and not pub.endswith("\n"):
  sys.stdout.write("\n")
'); then
    echo "SKIP (not in Pass or unreadable): $title"
    return 1
  fi

  local priv_body pub_body
  priv_body=$(printf '%s' "$material" | python3 -c '
import sys
t=sys.stdin.read().split("---PUB---\n",1)
sys.stdout.write(t[0])
')
  pub_body=$(printf '%s' "$material" | python3 -c '
import sys
t=sys.stdin.read().split("---PUB---\n",1)
sys.stdout.write(t[1] if len(t)>1 else "")
')

  if [[ ! "$priv_body" =~ BEGIN ]]; then
    echo "SKIP (no PEM in Pass item): $title"
    return 1
  fi

  umask 077
  printf '%s' "$priv_body" >"$priv"
  chmod 600 "$priv"
  if [[ -n "$pub_body" ]]; then
    printf '%s' "$pub_body" >"$pub"
    chmod 644 "$pub"
  elif command -v ssh-keygen >/dev/null 2>&1; then
    ssh-keygen -y -f "$priv" >"$pub" 2>/dev/null || true
    chmod 644 "$pub" 2>/dev/null || true
  fi
  echo "OK key: $basename"
  return 0
}

echo "== 1) SSH keys from Proton Pass =="
ok=0
miss=0
for entry in "${KEY_MAP[@]}"; do
  local_name="${entry%%|*}"
  title="${entry#*|}"
  if write_key_from_pass "$local_name" "$title"; then
    ok=$((ok + 1))
  else
    miss=$((miss + 1))
  fi
done
echo "keys written=$ok missing_in_pass=$miss"

if [[ "$AGENT_LOAD" -eq 1 ]]; then
  echo "== 1b) pass-cli ssh-agent load =="
  pass-cli ssh-agent load --vault-name "$VAULT" || echo "WARN: ssh-agent load failed (optional)"
  if command -v ssh-add >/dev/null 2>&1; then
    for entry in "${KEY_MAP[@]}"; do
      f="$HOME/.ssh/${entry%%|*}"
      [[ -f "$f" ]] && ssh-add --apple-use-keychain "$f" 2>/dev/null || true
    done
  fi
fi

if [[ "$KEYS_ONLY" -eq 1 ]]; then
  echo "Done (--keys-only)."
  exit 0
fi

if [[ "$NO_CHEZMOI" -eq 0 ]]; then
  echo "== 2) chezmoi apply =="
  if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]]; then
    die "missing ~/.config/chezmoi/chezmoi.toml — see README Step 4"
  fi
  if ! command -v chezmoi >/dev/null 2>&1; then
    die "chezmoi not found"
  fi
  if [[ -d "$REPO_ROOT/private_dot_ssh" ]]; then
    chezmoi apply --source "$REPO_ROOT" || chezmoi apply
  else
    chezmoi apply
  fi
  echo "OK chezmoi apply"
else
  echo "== 2) chezmoi skipped (--no-chezmoi) =="
fi

if [[ "$WITH_ZSHRC" -eq 1 ]]; then
  echo "== 3) ~/.zshrc.local =="
  "$SCRIPT_DIR/pass-write-zshrc-local.sh" || true
fi

echo
echo "Bootstrap finished. See docs/secrets-pass.md"
