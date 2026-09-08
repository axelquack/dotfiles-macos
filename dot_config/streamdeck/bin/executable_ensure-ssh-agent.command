#!/usr/bin/env bash
# Stream Deck: load SSH identities from Pass when the agent is empty
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
ROOT="$(sd_root)"
cd "$ROOT"
echo "== ensure-ssh-agent =="
[[ -x "$ROOT/scripts/ensure-ssh-agent.sh" ]] || sd_die "missing scripts/ensure-ssh-agent.sh"
"$ROOT/scripts/ensure-ssh-agent.sh"
echo
ssh-add -l || true
echo "OK"
sd_pause
