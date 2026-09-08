#!/usr/bin/env bash
# Stream Deck: topgrade (Pass session + SSH agent precheck runs first)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
sd_need topgrade
ROOT="$(sd_root)"
cd "$ROOT"
echo "== topgrade =="
if [[ -x "$ROOT/scripts/topgrade-precheck.sh" ]]; then
  "$ROOT/scripts/topgrade-precheck.sh" || echo "WARN: precheck reported issues (continuing)"
fi
topgrade
echo "OK"
sd_pause
