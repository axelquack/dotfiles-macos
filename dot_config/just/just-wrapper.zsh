# zsh function: fall back to the global justfile for recipes that exist
# only there. Sourced from ~/.zshrc (interactive) and ~/.zshenv (every zsh,
# including `zsh -c`). See docs/himalaya.md.
# Idempotent: re-sourcing only redefines the function.

just() {
  local _jgf="${HOME}/.config/just/just-global-fallback.sh"
  if [[ -x "$_jgf" ]]; then
    "$_jgf" "$@"
  else
    command just "$@"
  fi
}
