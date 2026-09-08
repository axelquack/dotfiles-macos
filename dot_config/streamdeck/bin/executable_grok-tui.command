#!/usr/bin/env bash
# Stream Deck: Grok Build TUI in the dotfiles clone
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
ROOT="$(sd_root)"
cd "$ROOT"
echo "== grok (dotfiles-macos) =="
pwd
if command -v grok >/dev/null 2>&1; then
  exec grok
fi
if [[ -x "${HOME}/.grok/bin/grok" ]]; then
  exec "${HOME}/.grok/bin/grok"
fi
sd_die "grok not on PATH (expected ~/.grok/bin/grok)"
