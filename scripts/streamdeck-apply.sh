#!/usr/bin/env bash
# Apply the chezmoi-managed Stream Deck layout to the live Elgato app.
#
# The Stream Deck app keeps profiles in memory and rewrites them on quit.
# This script: deploy action scripts → quit app → write ProfilesV3 → relaunch.
#
# Usage (from the clone, GUI session on the Mac with the deck plugged in):
#   ./scripts/streamdeck-apply.sh
#   ./scripts/streamdeck-apply.sh --dry-run
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${HOME}/.config/streamdeck/bin"
APP="/Applications/Elgato Stream Deck.app"

usage() {
  cat <<'EOF'
Usage: streamdeck-apply.sh [--dry-run]

Quit Elgato Stream Deck, write the dotfiles 15-key + MCP profiles, relaunch.
Requires the cask app and chezmoi-deployed ~/.config/streamdeck/bin scripts.
EOF
}

DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

if [[ ! -d "$APP" ]]; then
  die "Elgato Stream Deck.app missing. Install: brew install --cask elgato-stream-deck"
fi

# Deploy action scripts (chezmoi source → ~/.config/streamdeck).
if command -v chezmoi >/dev/null 2>&1; then
  chezmoi apply --source "$ROOT" --force "${HOME}/.config/streamdeck" \
    || chezmoi apply --source "$ROOT" --force
fi

[[ -f "$BIN/lib.sh" ]] || die "missing $BIN/lib.sh after chezmoi apply"

chmod a+x "$BIN"/*.command "$BIN"/*.sh "$BIN/lib.sh" "$ROOT/scripts/streamdeck_profile.py" \
  "$ROOT/scripts/hue_scene.py" "$ROOT/scripts/streamdeck-apply.sh" 2>/dev/null || true

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ "$DRY" -eq 1 ]]; then
  python3 "$ROOT/scripts/streamdeck_profile.py" --dry-run
  exit 0
fi

if [[ -f "$ROOT/scripts/hue_scene.py" ]]; then
  echo "== hue login (We Love Lights → ~/.config/streamdeck/hue.local) =="
  python3 "$ROOT/scripts/hue_scene.py" --bootstrap \
    || echo "WARN: hue bootstrap failed — Studio scene keys will no-op until it succeeds"
fi

ICON_SRC="$ROOT/scripts/streamdeck_icon.swift"
ICON_BIN="$BIN/streamdeck-icon"
if [[ -f "$ICON_SRC" ]] && command -v swiftc >/dev/null 2>&1; then
  if [[ ! -x "$ICON_BIN" || "$ICON_SRC" -nt "$ICON_BIN" ]]; then
    echo "== compiling streamdeck-icon =="
    mkdir -p "$BIN"
    swiftc -O -framework AppKit -o "$ICON_BIN" "$ICON_SRC"
  fi
fi

echo "== quitting Stream Deck (profiles are in-memory until quit) =="
osascript -e 'tell application "Stream Deck" to quit' >/dev/null 2>&1 || true
# Bundle name is "Stream Deck"; also try the full app name.
osascript -e 'tell application "Elgato Stream Deck" to quit' >/dev/null 2>&1 || true
for _ in {1..20}; do
  pgrep -x "Stream Deck" >/dev/null 2>&1 || break
  sleep 0.25
done
if pgrep -x "Stream Deck" >/dev/null 2>&1; then
  killall "Stream Deck" 2>/dev/null || true
  sleep 1
fi
pgrep -x "Stream Deck" >/dev/null 2>&1 && die "Stream Deck still running; quit it and retry"

echo "== writing ProfilesV3 =="
python3 "$ROOT/scripts/streamdeck_profile.py"

echo "== launching Stream Deck =="
open -a "Elgato Stream Deck"
echo "OK — hardware profile 'dotfiles' (page 1 workspaces, page 2 MCP extras)"
echo "    MCP Deck profile 'MCP Actions' (8×4, for Grok via Elgato MCP)"
echo
echo "If the app still warns about Hotkeys / Bedienungshilfen, enable Stream Deck under:"
echo "  System Settings → Privacy & Security → Accessibility"
open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility" 2>/dev/null || \
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
