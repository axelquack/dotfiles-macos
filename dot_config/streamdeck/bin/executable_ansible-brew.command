#!/usr/bin/env bash
# Stream Deck: Ansible brew bundle for this Mac (haumea or moon)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
sd_need ansible-playbook
ROOT="$(sd_root)"
HOST="$(hostname -s)"
cd "$ROOT/ansible"
echo "== ansible-playbook brew ($HOST) =="
pwd
ansible-playbook setup-macos.yml --limit "$HOST" --tags brew
echo "OK"
sd_pause
