#!/usr/bin/env bash
# Stream Deck: compact git log (dotfiles clone)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
cd "$(sd_root)"
echo "== git log =="
pwd
git log --oneline --graph --decorate -20
echo "OK"
sd_pause
