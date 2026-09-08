#!/usr/bin/env bash
# Stream Deck: Himalaya TUI (one account per session; default from local config)
set -euo pipefail
# shellcheck disable=SC1091
source "${HOME}/.config/streamdeck/bin/lib.sh"
sd_bootstrap
if command -v himalaya-tui >/dev/null 2>&1; then
  echo "== himalaya-tui =="
  exec himalaya-tui
fi
sd_need himalaya
echo "== himalaya (CLI; no TUI on PATH) =="
himalaya --help | head -20 || true
himalaya envelope list 2>/dev/null | head -30 || himalaya list 2>/dev/null | head -30 || true
sd_pause
