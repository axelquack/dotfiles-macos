#!/usr/bin/env bash
# Stream Deck: chezmoi diff
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
sd_need chezmoi
cd "$(sd_root)"
echo "== chezmoi diff =="
pwd
chezmoi diff || true
echo "OK"
sd_pause
