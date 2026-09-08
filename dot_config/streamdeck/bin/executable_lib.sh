#!/usr/bin/env bash
# Shared helpers for Stream Deck .command actions (sourced, not executed).
# Public repo: no host inventories, vault IDs, or secrets.

sd_bootstrap() {
  export PATH="/opt/homebrew/bin:/usr/local/bin:${HOME}/.grok/bin:${HOME}/.local/bin:${PATH}"
  # Terminal.app .command windows are often non-login; load brew + fnm lightly.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || true
  fi
  if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash 2>/dev/null)" || true
  fi
}

sd_root() {
  local root=""
  if command -v chezmoi >/dev/null 2>&1; then
    root="$(chezmoi source-path 2>/dev/null || true)"
  fi
  if [[ -z "${root}" || ! -d "${root}" ]]; then
    root="${HOME}/Developer/Projects/dotfiles-macos"
  fi
  printf '%s\n' "${root}"
}

sd_pause() {
  echo
  echo "[Stream Deck] Press Return to close."
  read -r _ || true
}

sd_die() {
  echo "ERROR: $*" >&2
  sd_pause
  exit 1
}

sd_need() {
  command -v "$1" >/dev/null 2>&1 || sd_die "missing command: $1"
}
