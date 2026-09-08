#!/usr/bin/env bash
# Stream Deck: git push (dotfiles clone) — confirms before pushing
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
cd "$(sd_root)"
echo "== git push (confirm) =="
pwd
git status -sb
echo
read -r -p "git push? [y/N] " ans
if [[ "${ans}" != [yY] ]]; then
  echo "aborted"
  sd_pause
  exit 0
fi
git push
echo "OK"
sd_pause
