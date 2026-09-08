#!/usr/bin/env bash
# Stream Deck: chezmoi status
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
sd_need chezmoi
cd "$(sd_root)"
echo "== chezmoi status =="
pwd
chezmoi status || true
echo "OK"
sd_pause
