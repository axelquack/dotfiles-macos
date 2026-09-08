#!/usr/bin/env bash
# Stream Deck: reload AeroSpace config
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
sd_need aerospace
echo "== aerospace reload-config =="
aerospace reload-config
echo "OK"
sd_pause
