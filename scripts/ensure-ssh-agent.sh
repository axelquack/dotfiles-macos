#!/usr/bin/env bash
# Ensure ssh-agent has identities via pass-cli (Proton Pass SoT).
# Idempotent: no-op when the agent already has keys.
#
# Prefer this over hand-running load every time. Does NOT auto-login and does
# NOT install a LaunchAgent — one GUI unlock after reboot/logout is still
# required (least privilege / Keychain policy).
#
# Usage:
#   ./scripts/ensure-ssh-agent.sh
#   ./scripts/ensure-ssh-agent.sh --vault-name Personal
#
# Over SSH (macOS -25308): cannot unlock Pass/Keychain. Run in a GUI Terminal
# on the Mac, or use agent forwarding from a machine that already loaded keys.
set -euo pipefail

VAULT="${PASS_SSH_VAULT:-Personal}"

usage() {
  cat <<'EOF'
Usage: ensure-ssh-agent.sh [--vault-name NAME]

Idempotent SSH agent load via pass-cli.
  --vault-name NAME   Pass vault (default: Personal, or $PASS_SSH_VAULT)
  -h, --help          Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault-name)
      [[ $# -ge 2 ]] || { echo "ERROR: --vault-name needs a value" >&2; exit 2; }
      VAULT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ok() { echo "OK: $*"; }
warn() { echo "WARN: $*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }

agent_has_ids() {
  ssh-add -l >/dev/null 2>&1
}

# SSH into a logged-in Mac often has no SSH_AUTH_SOCK even though the GUI
# session's launchd agent already holds keys. Reuse that socket when present.
attach_macos_gui_ssh_agent() {
  local sock
  if agent_has_ids; then
    return 0
  fi
  # shellcheck disable=SC2231
  for sock in /private/tmp/com.apple.launchd.*/Listeners; do
    [[ -S "${sock}" ]] || continue
    if SSH_AUTH_SOCK="${sock}" ssh-add -l >/dev/null 2>&1; then
      export SSH_AUTH_SOCK="${sock}"
      ok "attached to macOS GUI SSH agent"
      return 0
    fi
  done
  return 1
}

print_gui_howto() {
  cat >&2 <<EOF
In a GUI Terminal on this Mac, run:

  pass-cli login
  pass-cli ssh-agent load --vault-name ${VAULT}

Or re-run:

  $(cd "$(dirname "$0")" && pwd)/ensure-ssh-agent.sh --vault-name ${VAULT}

Over SSH, use agent forwarding from a host that already has keys loaded
(ssh -A), or load on the Mac's GUI first so login shells can attach.
EOF
}

if ! command -v ssh-add >/dev/null 2>&1; then
  die "ssh-add not found"
fi

if agent_has_ids || attach_macos_gui_ssh_agent; then
  ok "SSH agent already has identities"
  ssh-add -l 2>/dev/null | sed 's/^/  /' || true
  exit 0
fi

if ! command -v pass-cli >/dev/null 2>&1; then
  die "pass-cli not found. Install with: brew install pass-cli"
fi

pass_err="$(mktemp)"
trap 'rm -f "$pass_err"' EXIT

pass_ok=0
if pass-cli vault list >/dev/null 2>"$pass_err"; then
  pass_ok=1
fi

if [[ "${pass_ok}" -eq 1 ]]; then
  ok "pass-cli session"
  echo "==> pass-cli ssh-agent load --vault-name ${VAULT}"
  if pass-cli ssh-agent load --vault-name "${VAULT}"; then
    if agent_has_ids; then
      ok "SSH agent loaded from Pass (${VAULT})"
      ssh-add -l 2>/dev/null | sed 's/^/  /' || true
      exit 0
    fi
    warn "pass-cli ssh-agent load finished but agent still has no identities"
  else
    warn "pass-cli ssh-agent load failed"
  fi
elif grep -qE '25308|User interaction is not allowed|Could not get local key from keyring' "$pass_err" 2>/dev/null; then
  warn "pass-cli cannot access Keychain in this session (macOS -25308)."
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    warn "Detected SSH session — unlock is GUI-only on this Mac."
  fi
  print_gui_howto
  exit 1
else
  echo "pass-cli error:" >&2
  sed 's/^/  /' "$pass_err" >&2 || true
  warn "pass-cli is not logged in (or failed)."
  print_gui_howto
  exit 1
fi

# Last resort: on-disk keys already materialized from Pass (cache, not SoT).
CANDIDATES=(
  "${HOME}/.ssh/id_ed25519_github"
  "${HOME}/.ssh/id_ed25519"
)
for key in "${CANDIDATES[@]}"; do
  if [[ -f "${key}" ]]; then
    if ssh-add --apple-use-keychain "${key}" >/dev/null 2>&1; then
      ok "loaded on-disk key from Keychain (Pass cache): ${key}"
      ssh-add -l 2>/dev/null | sed 's/^/  /' || true
      exit 0
    fi
  fi
done

warn "SSH agent still has no identities."
print_gui_howto
exit 1
