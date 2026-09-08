#!/usr/bin/env bash
# Stream Deck: Proton Pass GUI login (Keychain). Required after reboot.
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
sd_need pass-cli
echo "== pass-cli login =="
pass-cli login
echo
pass-cli test || true
echo "OK"
sd_pause
