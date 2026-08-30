#!/usr/bin/env bash
# Fail fast before topgrade: Proton Pass session + SSH agent identities.
# Wired from ~/.config/topgrade.toml [pre_commands] via:
#   "$(chezmoi source-path)/scripts/topgrade-precheck.sh"
#
# Usage (also fine standalone):
#   ./scripts/topgrade-precheck.sh
#
# Pass / Keychain over SSH: macOS returns -25308 ("User interaction is not
# allowed"). That is NOT "logged out" — the GUI session may be fine. Per
# docs/moon.md we warn and continue so topgrade can still upgrade brew/MAS.
# Chezmoi template steps that need Pass may still fail later in that case.
set -euo pipefail

die() {
  echo "ERROR: $*" >&2
  exit 1
}

ok() {
  echo "OK: $*"
}

warn() {
  echo "WARN: $*" >&2
}

# --- pass-cli (chezmoi templates / Proton Pass) ---
if ! command -v pass-cli >/dev/null 2>&1; then
  die "pass-cli not found. Install with: brew install pass-cli"
fi

# pass-cli 2.2.4+ removed `test`; vault list requires an active session + keyring.
pass_err="$(mktemp)"
pass_ok=0
if pass-cli vault list >/dev/null 2>"$pass_err"; then
  pass_ok=1
fi

if [[ "${pass_ok}" -eq 1 ]]; then
  ok "pass-cli session"
elif grep -qE '25308|User interaction is not allowed|Could not get local key from keyring' "$pass_err" 2>/dev/null; then
  warn "pass-cli cannot access Keychain in this session (macOS -25308)."
  warn "You may already be logged in in a GUI Terminal — SSH/non-interactive cannot unlock the keyring."
  warn "Continuing topgrade; skip or expect failures on chezmoi steps that need Pass."
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    warn "Detected SSH session. Prefer: GUI Terminal on this Mac → pass-cli login → topgrade"
  fi
else
  # Truly no session / other failure
  echo "pass-cli error:" >&2
  sed 's/^/  /' "$pass_err" >&2 || true
  rm -f "$pass_err"
  die "pass-cli is not logged in (or failed). In a GUI Terminal run: pass-cli login"
fi
rm -f "$pass_err"

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

Over SSH, --apple-use-keychain often fails (-25308). From the machine that
already has the key loaded, use agent forwarding, or run topgrade in a GUI
Terminal on the target Mac.
EOF
  exit 1
fi

ok "SSH agent has identities"
echo "topgrade-precheck: ready"
