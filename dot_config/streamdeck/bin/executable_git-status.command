#!/usr/bin/env bash
# Stream Deck: git status in the dotfiles clone
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
cd "$(sd_root)"
echo "== git status =="
pwd
git status -sb
echo
git diff --stat || true
echo "OK"
sd_pause
