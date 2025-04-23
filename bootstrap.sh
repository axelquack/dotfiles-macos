#!/usr/bin/env bash

# Bootstrap script for macOS setup

# Exit immediately if a command exits with a non-zero status.
# Exit if unset variables are used.
# Cause pipelines to return the exit status of the last command that failed.
set -euo pipefail

# --- Configuration ---
# Define the expected location of the Brewfile relative to the user's home directory
# Adjust this path if your Brewfile is stored elsewhere (e.g., ~/.Brewfile)
BREWFILE_PATH="$HOME/dotfiles/brewfile.private" # Example assuming cloned to ~/dotfiles

# --- Helper Functions ---
info() { echo "[Info] $1"; }
error() { echo "[Error] $1" >&2; }
warning() { echo "[Warning] $1"; }

# --- Sanity Checks ---
info "Starting macOS bootstrap process..."

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
  error "This script is only for macOS."
  exit 1
fi

# --- Zsh Setup ---
# Check if zsh is installed (standard on modern macOS)
if ! command -v zsh >/dev/null 2>&1; then
  error "zsh is not installed. This script requires zsh."
  exit 1
fi

# Switch default shell to zsh if not already set
if [ "$SHELL" != "$(command -v zsh)" ]; then
  info "Switching default shell to zsh..."
  if chsh -s "$(command -v zsh)"; then
    info "Default shell changed to zsh. Please restart your terminal session for the change to take full effect."
  else
    error "Failed to change shell. Manual intervention required."
    exit 1
  fi
fi

# --- Developer Tools Setup ---
# Check if Xcode Command Line Tools are installed
if ! xcode-select -p >/dev/null 2>&1; then
  info "Xcode Command Line Tools not found. Installing..."
  # Trigger the graphical installer - requires user interaction
  xcode-select --install
  info "Please follow the on-screen prompts to install the Command Line Tools."
  info "Re-run this script after the installation is complete."
  exit 0 # Exit gracefully, user needs to complete installation
else
  xcodebuild_version=$(xcodebuild -version 2>/dev/null | grep "Xcode" | sed 's/Xcode //' || echo "Unknown")
  info "Xcode Command Line Tools detected (Xcode version: $xcodebuild_version)."
fi

# --- Homebrew Setup ---
# Check if Homebrew is installed and install it if missing
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew not found. Installing..."
  # Non-interactive install
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to PATH for the current script session (especially important on Apple Silicon)
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  info "Homebrew installed successfully."
else
  info "Homebrew is already installed."
  # Ensure Homebrew is in the PATH for subsequent commands
  if [[ "$(uname -m)" == "arm64" ]] && [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ "$(uname -m)" != "arm64" ]] && [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
     eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Optional: Update Homebrew formulae list here if desired (can take time)
# info "Updating Homebrew..."
# brew update

# --- Optional Java Setup ---
# Install a recent JDK if Java is not detected
if ! command -v java >/dev/null 2>&1; then
  info "Java command not found. Installing Adoptium Temurin JDK via Homebrew..."
  brew install temurin
  info "Java (Temurin) installed."
else
  java_ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
  info "Java already installed (Version: $java_ver)."
fi

# --- Install Packages via Brewfile ---
info "Attempting to install packages from Brewfile..."
if [ -f "$BREWFILE_PATH" ]; then
  info "Found Brewfile at $BREWFILE_PATH."
  info "Installing packages via 'brew bundle'. This may take a while..."
  info "Note: You may be prompted for your password for some installations (e.g., casks, system updates)."
  info "Please make sure you are signed in to the Mac App Store if installing MAS apps."
  if brew bundle --file="$BREWFILE_PATH"; then
    info "Brew bundle completed successfully."
  else
    error "Brew bundle command failed. Check the output above for specific errors."
    # Decide if you want to exit or continue
    # exit 1
  fi
else
  warning "Brewfile not found at $BREWFILE_PATH. Skipping installation via brew bundle."
  warning "Please ensure your dotfiles repository is cloned to the correct location ($HOME/dotfiles) or adjust BREWFILE_PATH."
fi

# --- Final Summary ---
info "Bootstrap script finished."
info "Installed or verified:"
info " - zsh (as default shell)"
info " - Xcode Command Line Tools"
info " - Homebrew"
info " - Java (Temurin, if wasn't present)"
info " - Packages listed in $BREWFILE_PATH (if found)"
info "Please restart your terminal or open a new tab/window for all changes (especially shell and PATH) to take effect."
