#!/usr/bin/env bash
# Open one Himalaya account. Called by the generated mail.just recipes.
#   himalaya-open.sh <account>            -> himalaya-tui -a <account> (CLI inbox list if no TUI)
#   himalaya-open.sh <account> <args...>  -> himalaya <args...> -a <account>
set -euo pipefail
account=${1:?account}
shift
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:$PATH"
if [[ $# -eq 0 ]]; then
  if command -v himalaya-tui >/dev/null 2>&1; then
    exec himalaya-tui -a "$account"
  fi
  exec himalaya envelope list -a "$account"
fi
exec himalaya "$@" -a "$account"
