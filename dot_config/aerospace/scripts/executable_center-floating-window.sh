#!/bin/bash
# Center a floating window on the display it currently occupies.
# Invoked from on-window-detected via exec-and-forget; uses AEROSPACE_WINDOW_ID.
#
# AeroSpace 0.21 has no native "center floating window" command.
# Qt apps (Stream Deck) ignore JXA `position =`; classic AppleScript works
# only after `set frontmost to true`.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

app_name="${1:-}"
wid="${AEROSPACE_WINDOW_ID:-}"

if [[ -z "$app_name" && -n "$wid" ]] && command -v aerospace >/dev/null 2>&1; then
  app_name="$(aerospace echo --window-id "$wid" -- '%{app-name}' 2>/dev/null || true)"
fi
app_name="${app_name:-Stream Deck}"

window_geom() {
  osascript - "$app_name" <<'APPLESCRIPT'
on run argv
  set appName to item 1 of argv
  tell application "System Events"
    if not (exists process appName) then return "missing"
    tell process appName
      if (count of windows) is 0 then return "missing"
      set {wx, wy} to position of window 1
      set {ww, wh} to size of window 1
      return (wx as integer as text) & " " & (wy as integer as text) & " " & (ww as integer as text) & " " & (wh as integer as text)
    end tell
  end tell
end run
APPLESCRIPT
}

target_xy() {
  local wx="$1" wy="$2" ww="$3" wh="$4"
  /usr/bin/osascript -l JavaScript - "$wx" "$wy" "$ww" "$wh" <<'JXA'
ObjC.import("AppKit")
function axFrame(nsScreen, primaryH) {
  const vf = nsScreen.visibleFrame
  return {
    x: vf.origin.x,
    y: primaryH - vf.origin.y - vf.size.height,
    w: vf.size.width,
    h: vf.size.height,
  }
}
function run(argv) {
  const wx = Number(argv[0]), wy = Number(argv[1])
  const ww = Number(argv[2]), wh = Number(argv[3])
  const cx = wx + ww / 2, cy = wy + wh / 2
  const screens = $.NSScreen.screens
  const primaryH = screens.objectAtIndex(0).frame.size.height
  let frame = axFrame(screens.objectAtIndex(0), primaryH)
  for (let i = 0; i < screens.count; i++) {
    const f = axFrame(screens.objectAtIndex(i), primaryH)
    if (cx >= f.x && cx <= f.x + f.w && cy >= f.y && cy <= f.y + f.h) {
      frame = f
      break
    }
  }
  const x = Math.round(frame.x + (frame.w - ww) / 2)
  const y = Math.round(frame.y + (frame.h - wh) / 2)
  return x + " " + y
}
JXA
}

move_window() {
  local nx="$1" ny="$2"
  osascript - "$app_name" "$nx" "$ny" <<'APPLESCRIPT'
on run argv
  set appName to item 1 of argv
  set nx to (item 2 of argv) as integer
  set ny to (item 3 of argv) as integer
  tell application "System Events"
    tell process appName
      set frontmost to true
      delay 0.05
      set position of window 1 to {nx, ny}
    end tell
  end tell
  return "ok"
end run
APPLESCRIPT
}

# Window may not be mapped/sized on first detect.
for _ in 1 2 3 4 5 6 7 8; do
  geom="$(window_geom 2>/dev/null || true)"
  if [[ "$geom" == "missing" || -z "$geom" ]]; then
    sleep 0.25
    continue
  fi
  read -r wx wy ww wh _ <<< "$geom"
  if [[ -z "${ww:-}" || -z "${wh:-}" || "$ww" -lt 50 || "$wh" -lt 50 ]]; then
    sleep 0.25
    continue
  fi
  xy="$(target_xy "$wx" "$wy" "$ww" "$wh" 2>/dev/null || true)"
  [[ -z "$xy" ]] && { sleep 0.25; continue; }
  read -r nx ny _ <<< "$xy"
  if move_window "$nx" "$ny" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.25
done
exit 0
