#!/usr/bin/env bash
# Stream Deck: chezmoi apply (dotfiles source → $HOME)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
sd_need chezmoi
cd "$(sd_root)"
echo "== chezmoi apply =="
pwd
chezmoi apply
echo "OK"
sd_pause
