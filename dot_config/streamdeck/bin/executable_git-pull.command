#!/usr/bin/env bash
# Stream Deck: git pull --rebase (dotfiles clone)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
cd "$(sd_root)"
echo "== git pull --rebase =="
pwd
git status -sb
git pull --rebase
echo "OK"
sd_pause
