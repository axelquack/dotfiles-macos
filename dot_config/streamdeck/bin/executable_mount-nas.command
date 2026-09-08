#!/usr/bin/env bash
# Stream Deck: mount UniFi NAS SMB shares (gitignored host map)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
ROOT="$(sd_root)"
echo "== mount UniFi SMB =="
[[ -x "$ROOT/scripts/mount-unifi-smb.sh" ]] || sd_die "missing scripts/mount-unifi-smb.sh"
"$ROOT/scripts/mount-unifi-smb.sh"
echo "OK"
sd_pause
