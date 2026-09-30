#!/usr/bin/env bash
# Wrapper around Homebrew topgrade.
# Over SSH, skip Mac App Store (`mas`): Apple ID password cannot be supplied
# from an env file (`mas signin` was removed) and Keychain is locked (-25308).
# GUI Terminal still runs `mas` unless ~/.config/topgrade.env sets SKIP.
#
# Usage: same argv as topgrade. Wired as a zsh function named `topgrade`.
set -euo pipefail

ENV_FILE="${HOME}/.config/topgrade.env"

ensure_env_file() {
  [[ -f "${ENV_FILE}" ]] && return 0
  mkdir -p "${HOME}/.config"
  cat > "${ENV_FILE}" <<'EOF'
# Local topgrade flags — not secrets. Mode 600.
# Do NOT put an Apple ID password here. `mas` cannot sign in from the CLI;
# App Store updates need a GUI session (Touch ID / password in App Store.app).
#
# Over SSH this wrapper skips `mas` automatically.
# TOPGRADE_SKIP_MAS=1    # skip MAS even in a GUI Terminal
# TOPGRADE_SKIP_MAS=0    # do not auto-skip on SSH (you will get a password prompt)
EOF
  chmod 600 "${ENV_FILE}"
}

load_env_file() {
  [[ -f "${ENV_FILE}" ]] || return 0
  local line key val
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    [[ "${line}" == *"="* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    val="${val#\"}"
    val="${val%\"}"
    val="${val#\'}"
    val="${val%\'}"
    case "${key}" in
      TOPGRADE_SKIP_MAS | SKIP_MAS)
        TOPGRADE_SKIP_MAS="${val}"
        ;;
    esac
  done < "${ENV_FILE}"
}

resolve_topgrade() {
  local cand
  for cand in /opt/homebrew/bin/topgrade /usr/local/bin/topgrade; do
    if [[ -x "${cand}" ]]; then
      printf '%s\n' "${cand}"
      return 0
    fi
  done
  command -v topgrade || true
}

ensure_env_file
load_env_file

extra=()
skip="${TOPGRADE_SKIP_MAS:-}"
if [[ -n "${SSH_CONNECTION:-}" ]]; then
  case "${skip}" in
    0 | false | no | NO | False) ;;
    *) extra+=(--disable mas) ;;
  esac
else
  case "${skip}" in
    1 | true | yes | TRUE | Yes) extra+=(--disable mas) ;;
  esac
fi

bin="$(resolve_topgrade)"
if [[ -z "${bin}" ]]; then
  echo "ERROR: topgrade not found" >&2
  exit 127
fi

if [[ "$(realpath "${bin}" 2>/dev/null || echo "${bin}")" == "$(realpath "$0")" ]]; then
  echo "ERROR: topgrade-wrap would recurse; put the brew binary on PATH" >&2
  exit 1
fi

if [[ "${#extra[@]}" -gt 0 ]]; then
  echo "topgrade-wrap: ${extra[*]} (App Store password cannot be automated over SSH)" >&2
  exec "${bin}" "${extra[@]}" "$@"
fi

# Bash 3.2 (macOS) + set -u: empty extra[@] is unbound.
exec "${bin}" "$@"
