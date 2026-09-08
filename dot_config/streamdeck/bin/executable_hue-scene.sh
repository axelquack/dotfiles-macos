#!/usr/bin/env bash
# Recall a Hue scene (or --off / --list). Silent — no Terminal pause.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:${HOME}/.grok/bin:${HOME}/.local/bin:${PATH}"
CANDIDATES=()
if command -v chezmoi >/dev/null 2>&1; then
  src="$(chezmoi source-path 2>/dev/null || true)"
  [[ -n "${src}" ]] && CANDIDATES+=("${src}/scripts/hue_scene.py")
fi
CANDIDATES+=("${HOME}/Developer/Projects/dotfiles-macos/scripts/hue_scene.py")
for py in "${CANDIDATES[@]}"; do
  if [[ -f "$py" ]]; then
    exec python3 "$py" "$@"
  fi
done
echo "ERROR: hue_scene.py not found" >&2
exit 1
