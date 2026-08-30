#!/usr/bin/env bash
# Fail fast before topgrade: Proton Pass session + SSH agent identities.
# Wired from ~/.config/topgrade.toml [pre_commands] via:
#   "$(chezmoi source-path)/scripts/topgrade-precheck.sh"
#
# Usage (also fine standalone):
#   ./scripts/topgrade-precheck.sh
set -euo pipefail

die() {
  echo "ERROR: $*" >&2
  exit 1
}

ok() {
  echo "OK: $*"
}

# --- pass-cli (chezmoi templates / Proton Pass) ---
if ! command -v pass-cli >/dev/null 2>&1; then
  die "pass-cli not found. Install with: brew install pass-cli"
fi

# pass-cli 2.2.4+ removed `test`; vault list requires an active session.
if ! pass-cli vault list >/dev/null 2>&1; then
  die "pass-cli is not logged in. In a GUI Terminal run: pass-cli login"
fi
ok "pass-cli session"

# --- SSH agent (chezmoi update / git fetch over GitHub) ---
if ! command -v ssh-add >/dev/null 2>&1; then
  die "ssh-add not found"
fi

# Prefer the GitHub deploy key used on these Macs; fall back to default id.
CANDIDATES=(
  "${HOME}/.ssh/id_ed25519_github"
  "${HOME}/.ssh/id_ed25519"
)

loaded_any=0
if ssh-add -l >/dev/null 2>&1; then
  loaded_any=1
fi

if [[ "${loaded_any}" -eq 0 ]]; then
  for key in "${CANDIDATES[@]}"; do
    if [[ -f "${key}" ]]; then
      # macOS: unlock from Keychain when possible (GUI session).
      if ssh-add --apple-use-keychain "${key}" >/dev/null 2>&1; then
        ok "loaded SSH key: ${key}"
        loaded_any=1
        break
      fi
    fi
  done
fi

if ! ssh-add -l >/dev/null 2>&1; then
  cat >&2 <<'EOF'
ERROR: SSH agent has no identities.
chezmoi update / git fetch will hang or break-pipe on a passphrase prompt.

Load your GitHub key in this Terminal, then re-run topgrade:
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github
  # or: ssh-add --apple-use-keychain ~/.ssh/id_ed25519
EOF
  exit 1
fi

ok "SSH agent has identities"
echo "topgrade-precheck: ready"
