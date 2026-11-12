#!/usr/bin/env bash
# Fail when a secret-shaped file name is in scope, or when gitleaks finds a leak.
#
#   scripts/check-secrets.sh            working tree (tracked + untracked, not ignored)
#   scripts/check-secrets.sh --staged   the index (what pre-commit runs)
#   scripts/check-secrets.sh --history  every commit
#
# Bash 3.2 is enough. This script does not use associative arrays.

set -euo pipefail

mode="worktree"
case "${1:-}" in
  "")
    mode="worktree"
    ;;
  --staged)
    mode="staged"
    ;;
  --history)
    mode="history"
    ;;
  -h|--help)
    echo "usage: scripts/check-secrets.sh [--staged|--history]" >&2
    exit 0
    ;;
  *)
    echo "check-secrets: unknown argument: $1" >&2
    exit 2
    ;;
esac

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "check-secrets: gitleaks is not installed or not on PATH. Install gitleaks, then run this script again." >&2
  exit 127
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "check-secrets: not inside a git repository." >&2
  exit 2
fi

root="$(git rev-parse --show-toplevel)"
cd "$root"

# .env.example is the only allowed env file. Every other pattern here is rejected.
name_forbidden() {
  local base="$1"
  if [[ "$base" == ".env.example" ]]; then
    return 1
  fi
  case "$base" in
    .env|.env.*)
      return 0
      ;;
    *.bak*)
      return 0
      ;;
    *.pem|*.key)
      return 0
      ;;
    id_rsa*|id_ed25519*)
      return 0
      ;;
    auth.json|auth*.json)
      return 0
      ;;
    *credentials*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

collect_paths() {
  case "$mode" in
    worktree)
      git ls-files -z -c -o --exclude-standard
      ;;
    staged)
      git diff --cached --name-only -z --diff-filter=ACMR
      ;;
    history)
      if git rev-parse --verify HEAD >/dev/null 2>&1; then
        git log --all --pretty=tformat: --name-only -z
      fi
      ;;
  esac
}

tmp=""
seen_file="$(mktemp)"
bad_file="$(mktemp)"
scan_file="$(mktemp)"
cleanup() {
  if [[ -n "$tmp" ]]; then
    rm -rf "$tmp"
  fi
  rm -f "$seen_file" "$bad_file" "$scan_file"
}
trap cleanup EXIT

while IFS= read -r -d '' path; do
  if [[ -z "$path" ]]; then
    continue
  fi
  if grep -Fxq -- "$path" "$seen_file"; then
    continue
  fi
  printf '%s\n' "$path" >> "$seen_file"
  base="${path##*/}"
  if name_forbidden "$base"; then
    printf '%s\n' "$path" >> "$bad_file"
  fi
  printf '%s\n' "$path" >> "$scan_file"
done < <(collect_paths)

name_rc=0
if [[ -s "$bad_file" ]]; then
  name_rc=1
  echo "check-secrets: forbidden file name (unstage it and add it to .gitignore):" >&2
  while IFS= read -r path; do
    echo "  $path" >&2
  done < "$bad_file"
fi

gl_rc=0
run_gitleaks() {
  if [[ -f "$root/.gitleaks.toml" ]]; then
    gitleaks "$@" --config "$root/.gitleaks.toml"
  else
    gitleaks "$@"
  fi
}

case "$mode" in
  staged)
    set +e
    run_gitleaks protect --staged --no-banner --redact
    gl_rc=$?
    set -e
    ;;
  history)
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
      echo "check-secrets: no commits to scan." >&2
      gl_rc=0
    else
      set +e
      run_gitleaks detect --no-banner --redact
      gl_rc=$?
      set -e
    fi
    ;;
  worktree)
    if [[ ! -s "$scan_file" ]]; then
      echo "check-secrets: working tree has no files to scan." >&2
    else
      tmp="$(mktemp -d)"
      while IFS= read -r path; do
        if [[ -f "$path" && ! -L "$path" ]]; then
          mkdir -p "$tmp/$(dirname "$path")"
          cp -P "$path" "$tmp/$path"
        fi
      done < "$scan_file"
      set +e
      run_gitleaks detect --no-git --source "$tmp" --no-banner --redact 2>&1 | sed "s#${tmp}/##g"
      gl_rc=${PIPESTATUS[0]}
      set -e
    fi
    ;;
esac

if [[ "$gl_rc" -ne 0 ]]; then
  echo "check-secrets: gitleaks found a leak." >&2
fi

# Repo-specific checks kept from the previous public-repo scanner.
# They look for key material, tracked private maps, and LAN addresses.
repo_extra() {
  local extra_rc=0
  local exclude=(
    ':!scripts/check-secrets.sh'
    ':!.gitleaks.toml'
    ':!SECURITY.md'
    ':!CHANGELOG.md'
    ':!docs/secrets-pass.md'
    ':!docs/himalaya.md'
    ':!AGENTS.md'
    ':!*.example'
    ':!scripts/pass-*-map.local'
    ':!machine-*.md'
  )

  echo "-- credential heuristics --"
  # Tracked files only. Gitignored notes are not part of the public tree.
  # git grep pathspecs exclude the files that name these patterns.
  # Print filenames only. Never print a matching line.
  pubkey_files="$(git grep -l -E -e 'ssh-ed25519[[:space:]]+AAAA[A-Za-z0-9+/]{20,}' -- "${exclude[@]}" || true)"
  if [[ -n "$pubkey_files" ]]; then
    echo "FAIL: full ssh-ed25519 public key line" >&2
    printf '%s\n' "$pubkey_files" | sed 's/^/  /' >&2
    extra_rc=1
  else
    echo "OK: no full ssh-ed25519 public key lines"
  fi

  key_files="$(
    git grep -l -F -e '-----BEGIN OPENSSH PRIVATE KEY-----' -e '-----BEGIN RSA PRIVATE KEY-----' -- "${exclude[@]}" || true
  )"
  if [[ -n "$key_files" ]]; then
    echo "FAIL: private key block" >&2
    printf '%s\n' "$key_files" | sed 's/^/  /' >&2
    extra_rc=1
  else
    echo "OK: no private key blocks"
  fi

  if git ls-files --error-unmatch scripts/pass-ssh-key-map.local >/dev/null 2>&1 \
    || git ls-files --error-unmatch scripts/pass-env-map.local >/dev/null 2>&1 \
    || git ls-files --error-unmatch scripts/himalaya-accounts.local >/dev/null 2>&1 \
    || git ls-files --error-unmatch scripts/hue.local >/dev/null 2>&1 \
    || git ls-files --error-unmatch scripts/smb-hosts.local >/dev/null 2>&1; then
    echo "FAIL: gitignored map file is tracked" >&2
    extra_rc=1
  else
    echo "OK: local map files not tracked"
  fi

  if git ls-files '*.mobileconfig' | grep -q .; then
    echo "FAIL: .mobileconfig is tracked (IMAP passwords)" >&2
    extra_rc=1
  else
    echo "OK: no .mobileconfig in git"
  fi

  echo "-- himalaya / Mail.app password material --"
  # Filenames only on failure. The line filter drops docs that forbid the field.
  pass_hits="$(git grep -n -I -e 'password\.raw' -e 'IncomingPassword' -- "${exclude[@]}" || true)"
  pass_left=""
  if [[ -n "$pass_hits" ]]; then
    pass_left="$(printf '%s\n' "$pass_hits" | rg -v 'check-secrets|SECURITY|himalaya-apply|never |not |do not' || true)"
  fi
  if [[ -n "$pass_left" ]]; then
    echo "FAIL: password.raw or IncomingPassword in tracked files" >&2
    printf '%s\n' "$pass_left" | cut -d: -f1 | sort -u | sed 's/^/  /' >&2
    extra_rc=1
  else
    echo "OK: no IMAP password fields in tracked files"
  fi

  echo "-- public inventory heuristics (LAN addresses in tracked files) --"
  lan_hits="$(git grep -n -I -E -e '192\.168\.[0-9]+\.[0-9]+' -e '10\.[0-9]+\.[0-9]+\.[0-9]+' || true)"
  lan_left=""
  if [[ -n "$lan_hits" ]]; then
    lan_left="$(printf '%s\n' "$lan_hits" | rg -v 'YOUR_|example|placeholder|no LAN|without.*IP|not.*192' || true)"
  fi
  if [[ -n "$lan_left" ]]; then
    echo "FAIL: RFC1918 address in tracked files (public repo)" >&2
    printf '%s\n' "$lan_left" | cut -d: -f1 | sort -u | sed 's/^/  /' >&2
    extra_rc=1
  else
    echo "OK: no LAN addresses in tracked files"
  fi

  if [[ "$mode" == "history" ]]; then
    echo "-- git history (real ed25519 pubkey blob) --"
    if git log -p --all -G 'ssh-ed25519[[:space:]]+AAAA[A-Za-z0-9+/]{40,}' 2>/dev/null \
      | rg -n 'ssh-ed25519[[:space:]]+AAAA[A-Za-z0-9+/]{40,}' \
      | rg -v 'check-secrets|gitleaks|SECURITY|AAAA…' \
      | head -5 | grep -q .; then
      echo "FAIL: pubkey material in history" >&2
      extra_rc=1
    else
      echo "OK: no pubkey blobs in history"
    fi

    echo "-- git history (LAN addresses in unpushed commits) --"
    if git log -p '@{u}..HEAD' 2>/dev/null | rg -n '192\.168\.[0-9]+\.[0-9]+' \
      | rg -v 'YOUR_|example|no LAN' | head -10 | grep -q .; then
      echo "FAIL: LAN addresses in unpushed commits" >&2
      extra_rc=1
    else
      echo "OK: no LAN addresses in unpushed commits (or no upstream)"
    fi
  fi

  return "$extra_rc"
}

extra_rc=0
repo_extra || extra_rc=$?

if [[ "$name_rc" -ne 0 || "$extra_rc" -ne 0 ]]; then
  cleanup
  exit 1
fi
if [[ "$gl_rc" -ne 0 ]]; then
  cleanup
  exit "$gl_rc"
fi

echo "check-secrets: no findings ($mode)."
cleanup
exit 0
