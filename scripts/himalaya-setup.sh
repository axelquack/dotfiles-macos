#!/usr/bin/env bash
# Install Himalaya CLI (Homebrew) companion bits: himalaya-tui, config.toml,
# optional unsigned Mail.app IMAP profile.
#
# Public repo: account inventory lives in gitignored himalaya-accounts.local.
# Config uses pass-cli titles only (never password.raw). Mail.app profiles
# embed passwords at generate time and must not be committed.
#
# Usage:
#   ./scripts/himalaya-setup.sh
#   ./scripts/himalaya-setup.sh --dry-run
#   ./scripts/himalaya-setup.sh --tui
#   ./scripts/himalaya-setup.sh --force-tui
#   ./scripts/himalaya-setup.sh --mailapp          # GUI pass-cli session
#   ./scripts/himalaya-setup.sh --mailapp --no-open
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MAP_FILE="${HIMALAYA_ACCOUNTS_MAP:-$SCRIPT_DIR/himalaya-accounts.local}"
EXAMPLE="$SCRIPT_DIR/himalaya-accounts.example"
CONFIG_OUT="${HIMALAYA_CONFIG:-$HOME/.config/himalaya/config.toml}"
APPLY_PY="$SCRIPT_DIR/himalaya-apply.py"

TUI_GIT="https://github.com/pimalaya/himalaya-tui.git"
TUI_REV="1303e56"
TUI_FEATURES="imap,smtp,rustls-ring"

DRY_RUN=0
DO_TUI=0
FORCE_TUI=0
DO_CONFIG=1
DO_MAILAPP=0
OPEN_MAILAPP=1
SKIP_CONFIG=0

usage() {
  sed -n '2,20p' "$0"
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --tui) DO_TUI=1 ;;
    --force-tui) DO_TUI=1; FORCE_TUI=1 ;;
    --mailapp) DO_MAILAPP=1 ;;
    --no-open) OPEN_MAILAPP=0 ;;
    --skip-config) SKIP_CONFIG=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

ensure_cargo_path() {
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  fi
  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:${PATH:-/usr/bin}"
}

install_tui() {
  ensure_cargo_path
  if ! command -v cargo >/dev/null 2>&1; then
    if command -v rustup >/dev/null 2>&1; then
      rustup default stable
      ensure_cargo_path
    else
      die "cargo/rustup missing — brew install rustup && rustup default stable"
    fi
  fi
  if [[ "$FORCE_TUI" -eq 0 ]] && command -v himalaya-tui >/dev/null 2>&1; then
    echo "tui: already installed $(command -v himalaya-tui)"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "tui: dry-run cargo install --locked --git $TUI_GIT --rev $TUI_REV"
    return 0
  fi
  if [[ "$FORCE_TUI" -eq 1 ]]; then
    cargo install --locked --git "$TUI_GIT" --rev "$TUI_REV" \
      --no-default-features --features "$TUI_FEATURES" --force
  else
    cargo install --locked --git "$TUI_GIT" --rev "$TUI_REV" \
      --no-default-features --features "$TUI_FEATURES"
  fi
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$HOME/.cargo/bin/himalaya-tui" "$HOME/.local/bin/himalaya-tui"
  echo "tui: installed $HOME/.local/bin/himalaya-tui"
}

apply_config() {
  if [[ ! -f "$MAP_FILE" ]]; then
    echo "config: skipped (no map $MAP_FILE)"
    echo "  cp $EXAMPLE $MAP_FILE   # gitignored; fill real accounts"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    python3 "$APPLY_PY" --map "$MAP_FILE" --config "$CONFIG_OUT" --dry-run
    return 0
  fi
  python3 "$APPLY_PY" --map "$MAP_FILE" --config "$CONFIG_OUT"
}

apply_mailapp() {
  if [[ ! -f "$MAP_FILE" ]]; then
    die "missing map $MAP_FILE — copy $EXAMPLE and edit (gitignored)"
  fi
  if ! command -v pass-cli >/dev/null 2>&1; then
    die "pass-cli not found"
  fi
  if [[ "$DRY_RUN" -eq 0 ]] && ! pass-cli vault list >/dev/null 2>&1; then
    die "pass-cli not logged in — run in a GUI Terminal: pass-cli login"
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    python3 "$APPLY_PY" --map "$MAP_FILE" --mailapp --dry-run
  elif [[ "$OPEN_MAILAPP" -eq 1 ]]; then
    python3 "$APPLY_PY" --map "$MAP_FILE" --mailapp --open
  else
    python3 "$APPLY_PY" --map "$MAP_FILE" --mailapp
  fi
}

[[ -x "$APPLY_PY" || -f "$APPLY_PY" ]] || die "missing $APPLY_PY"
command -v python3 >/dev/null 2>&1 || die "python3 not found"

if [[ "$SKIP_CONFIG" -eq 1 ]]; then
  DO_CONFIG=0
fi

if [[ "$DO_TUI" -eq 1 ]]; then
  install_tui
fi
if [[ "$DO_CONFIG" -eq 1 ]]; then
  apply_config
fi
if [[ "$DO_MAILAPP" -eq 1 ]]; then
  apply_mailapp
fi
