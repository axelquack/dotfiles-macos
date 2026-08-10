#!/usr/bin/env bash
# Import local ~/.ssh private keys into Proton Pass as native ssh_key items.
#
# Key basename → Pass title mapping lives in a **gitignored** map file so this
# public repo never lists private host inventory or LAN IPs.
#
#   cp scripts/pass-ssh-key-map.example scripts/pass-ssh-key-map.local
#
# Requires: pass-cli logged in (interactive Terminal for Keychain).
# Usage:
#   ./scripts/pass-import-ssh-keys.sh
#   ./scripts/pass-import-ssh-keys.sh --dry-run
#   PASS_SSH_MAP=~/.config/dotfiles-macos/pass-ssh-key-map ./scripts/pass-import-ssh-keys.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pass-map-lib.sh
source "$SCRIPT_DIR/pass-map-lib.sh"

VAULT="${PASS_VAULT:-Personal}"
MAP_FILE="${PASS_SSH_MAP:-$SCRIPT_DIR/pass-ssh-key-map.local}"
EXAMPLE="$SCRIPT_DIR/pass-ssh-key-map.example"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

if ! command -v pass-cli >/dev/null 2>&1; then
  echo "ERROR: pass-cli not found. brew install pass-cli && pass-cli login"
  exit 1
fi

if ! pass-cli vault list >/dev/null 2>&1; then
  echo "ERROR: pass-cli not logged in. Run: pass-cli login"
  exit 1
fi

pass_map_require "$MAP_FILE" "$EXAMPLE" || exit 1

KEY_MAP=()
while IFS= read -r line; do
  KEY_MAP+=("$line")
done < <(pass_map_load_lines "$MAP_FILE")
if [[ ${#KEY_MAP[@]} -eq 0 ]]; then
  echo "ERROR: map file is empty: $MAP_FILE"
  exit 1
fi

EXISTING=$(pass-cli item list "$VAULT" --output json 2>/dev/null | python3 -c '
import json,sys
raw=sys.stdin.read()
try:
  data=json.loads(raw)
except Exception:
  sys.exit(0)
items=data if isinstance(data,list) else data.get("items") or []
for it in items:
  t=it.get("title") or ""
  if t:
    print(t)
')

title_exists() {
  local want="$1"
  printf '%s\n' "$EXISTING" | grep -Fxq "$want"
}

imported=0
skipped=0
missing_file=0

for entry in "${KEY_MAP[@]}"; do
  local_name="${entry%%|*}"
  title="${entry#*|}"
  path="$HOME/.ssh/$local_name"

  if [[ ! -f "$path" ]]; then
    echo "SKIP (no local file): $local_name"
    missing_file=$((missing_file + 1))
    continue
  fi

  if title_exists "$title"; then
    echo "OK (already in Pass): $title"
    skipped=$((skipped + 1))
    continue
  fi

  echo "IMPORT → Pass [$VAULT]: $title  ←  $path"
  if [[ "$DRY" -eq 1 ]]; then
    continue
  fi

  pass-cli item create ssh-key import \
    --vault-name "$VAULT" \
    --title "$title" \
    --from-private-key "$path"
  imported=$((imported + 1))
  EXISTING+=$'\n'"$title"
done

echo
echo "Done. imported=$imported already_in_pass=$skipped no_local_file=$missing_file dry_run=$DRY"
echo "Next: ./scripts/bootstrap-secrets-from-pass.sh"
