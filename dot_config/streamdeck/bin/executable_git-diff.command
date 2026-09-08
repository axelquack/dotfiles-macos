#!/usr/bin/env bash
# Stream Deck: git diff (dotfiles clone)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
cd "$(sd_root)"
echo "== git diff =="
pwd
git diff
echo "OK"
sd_pause
