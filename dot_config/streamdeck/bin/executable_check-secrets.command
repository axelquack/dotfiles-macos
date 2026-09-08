#!/usr/bin/env bash
# Stream Deck: public-repo secret scan (pre-push)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
ROOT="$(sd_root)"
cd "$ROOT"
echo "== check-secrets =="
pwd
[[ -x "$ROOT/scripts/check-secrets.sh" ]] || sd_die "missing scripts/check-secrets.sh"
"$ROOT/scripts/check-secrets.sh"
echo "OK"
sd_pause
