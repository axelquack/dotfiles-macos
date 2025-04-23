# ~/.zshenv
# Sourced FIRST for ALL zsh instances (interactive, non-interactive, scripts).
# Primarily used for setting universally needed ENVIRONMENT VARIABLES.

# Set the default text editor for command-line tools (e.g., git commit, crontab -e).
# Choose ONE of the following lines based on your preference:
export EDITOR="vim"
# export EDITOR="nvim" # If you use Neovim
# export EDITOR="nano"
# export EDITOR="code -w" # For Visual Studio Code (requires 'code' command in PATH, '-w' waits for close)

# Set the default pager for displaying long output (e.g., man pages, git log).
# 'less' is the standard, powerful pager.
export PAGER="less"
# export PAGER="bat" # Optional: If you install 'bat' (`brew install bat`) for syntax highlighting.

# Optional: Set ZDOTDIR here if you want to move your Zsh config files
# (like .zshrc, .zshenv, etc.) to a different directory (e.g., ~/.config/zsh).
# export ZDOTDIR="$HOME/.config/zsh"
