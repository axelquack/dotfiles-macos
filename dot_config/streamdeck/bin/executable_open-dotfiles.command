#!/usr/bin/env bash
# Stream Deck: open the dotfiles clone in Finder + preferred editor
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
ROOT="$(sd_root)"
[[ -d "$ROOT" ]] || sd_die "dotfiles clone not found: $ROOT"
echo "== open dotfiles =="
echo "$ROOT"
open "$ROOT"
if [[ -d "/Applications/Cursor.app" ]]; then
  open -a Cursor "$ROOT"
elif [[ -d "/Applications/Zed.app" ]]; then
  open -a Zed "$ROOT"
fi
echo "OK"
sd_pause
