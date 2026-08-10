#!/usr/bin/env bash
# Secret + public-repo inventory scan for dotfiles-macos.
# Usage:
#   ./scripts/check-secrets.sh
#   ./scripts/check-secrets.sh --history
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
HISTORY=0
[[ "${1:-}" == "--history" ]] && HISTORY=1

fail=0

EXCLUDE_GLOBS=(
  --glob '!**/.git/**'
  --glob '!scripts/check-secrets.sh'
  --glob '!.gitleaks.toml'
  --glob '!SECURITY.md'
  --glob '!CHANGELOG.md'
  --glob '!docs/secrets-pass.md'
  --glob '!AGENTS.md'
  --glob '!**/*.example'
  --glob '!scripts/pass-*-map.local'
  --glob '!machine-*.md'
)

echo "== dotfiles-macos secret check (PUBLIC REPO) =="

if command -v gitleaks >/dev/null 2>&1; then
  echo "-- gitleaks (working tree) --"
  if ! gitleaks detect --source "$ROOT" --no-git --config "$ROOT/.gitleaks.toml" --verbose; then
    fail=1
  fi
  if [[ "$HISTORY" -eq 1 ]]; then
    echo "-- gitleaks (git history) --"
    if ! gitleaks detect --source "$ROOT" --config "$ROOT/.gitleaks.toml" --verbose; then
      fail=1
    fi
  fi
else
  echo "-- gitleaks not installed; using ripgrep fallback --"
  echo "   install: brew install gitleaks   # also in brewfile.home.machines"
fi

echo "-- credential heuristics --"
if rg -n "${EXCLUDE_GLOBS[@]}" -e 'ssh-ed25519[[:space:]]+AAAA[A-Za-z0-9+/]{20,}' . 2>/dev/null; then
  echo "FAIL: full ssh-ed25519 public key line"
  fail=1
else
  echo "OK: no full ssh-ed25519 public key lines"
fi

if rg -n "${EXCLUDE_GLOBS[@]}" -F -- '-----BEGIN OPENSSH PRIVATE KEY-----' . 2>/dev/null \
  || rg -n "${EXCLUDE_GLOBS[@]}" -F -- '-----BEGIN RSA PRIVATE KEY-----' . 2>/dev/null; then
  echo "FAIL: private key block"
  fail=1
else
  echo "OK: no private key blocks"
fi

# Private map files must not be tracked
if git ls-files --error-unmatch scripts/pass-ssh-key-map.local 2>/dev/null \
  || git ls-files --error-unmatch scripts/pass-env-map.local 2>/dev/null; then
  echo "FAIL: gitignored map file is tracked"
  fail=1
else
  echo "OK: local map files not tracked"
fi

echo "-- public inventory heuristics (LAN IPs in tracked files) --"
# Flag private-use RFC1918 in tracked sources (allow docs that only say 'no LAN IPs')
if git ls-files -z | xargs -0 rg -n -e '192\.168\.[0-9]+\.[0-9]+' -e '10\.[0-9]+\.[0-9]+\.[0-9]+' 2>/dev/null \
  | rg -v 'YOUR_|example|placeholder|no LAN|without.*IP|not.*192' \
  | head -20 | grep -q .; then
  echo "FAIL: RFC1918 IP-like address in tracked files (public repo)"
  git ls-files -z | xargs -0 rg -n -e '192\.168\.[0-9]+\.[0-9]+' 2>/dev/null | head -15 || true
  fail=1
else
  echo "OK: no LAN IPs in tracked files"
fi

if [[ "$HISTORY" -eq 1 ]]; then
  echo "-- git history (real ed25519 pubkey blob) --"
  if git log -p --all -G 'ssh-ed25519[[:space:]]+AAAA[A-Za-z0-9+/]{40,}' 2>/dev/null \
    | rg -n 'ssh-ed25519[[:space:]]+AAAA[A-Za-z0-9+/]{40,}' \
    | rg -v 'check-secrets|gitleaks|SECURITY|AAAA…' \
    | head -5 | grep -q .; then
    echo "FAIL: pubkey material in history"
    fail=1
  else
    echo "OK: no pubkey blobs in history"
  fi

  echo "-- git history (LAN IPs in pushed-range risk) --"
  if git log -p origin/master..HEAD 2>/dev/null | rg -n '192\.168\.[0-9]+\.[0-9]+' \
    | rg -v 'YOUR_|example|no LAN' | head -10 | grep -q .; then
    echo "FAIL: LAN IPs in unpushed commit history — squash/rewrite before push"
    fail=1
  else
    echo "OK: no LAN IPs in unpushed history (or no upstream)"
  fi
fi

if [[ "$fail" -ne 0 ]]; then
  echo "== RESULT: FAIL =="
  exit 1
fi
echo "== RESULT: PASS =="
