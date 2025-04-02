#!/usr/bin/env bash

# execute straight from Github (though the brewfile will not be found) 'curl https://raw.github.com/guttertec/projects/dotfiles/master/bootstraph.sh | sh -'

# This line sets the -e option, which causes the script to exit immediately if any command exits with a non-zero status.
set -e

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
  echo "Sorry, this script is only available on macOS."
  exit
fi

# Check if zsh is installed
if ! which zsh >/dev/null 2>&1; then
  echo "[Error] zsh is not installed"
  exit
fi

# Switch to zsh if not already using it
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "[Info] Switching to zsh..."
  chsh -s "$(which zsh)"
  echo "[Info] Please restart your terminal session to start using zsh."
fi

# Check if Xcode is installed
if ! xcode-select -p >/dev/null 2>&1; then
  echo "[Info] Xcode is not installed. Installing..."
  yes | xcode-select --install
  echo "[Info] Please install Xcode from the App Store or from https://developer.apple.com/xcode/downloads/."
  exit
else
  xcodebuild_version=$(xcodebuild -version | grep "Xcode" | sed 's/Xcode //')
  echo "[Info] Xcode $xcodebuild_version is already installed."
fi

# Check if Homebrew is already installed and if not, install it
if ! which brew >/dev/null 2>&1; then
  echo "[Info] Homebrew is not installed. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew_ver=$(brew --version)
  echo "[Info] Homebrew installed. Version: ${brew_ver}"
else
  echo "[Info] Homebrew is already installed."
fi

# Check if Java is installed, if not or outdated install via homebrew
if ! which java >/dev/null 2>&1; then
  echo "[Info] Java is not installed. Installing the latest version..."
  brew install temurin
  echo "[Info] Java installed."
else
  echo "[Info] Java is already installed."
fi

# Check if Ruby is installed
if ! which ruby >/dev/null 2>&1; then
  echo "[Error] Ruby is not installed"
  exit
fi

# Check if Ruby is installed, if not or outdated install via homebrew
if ! which ruby >/dev/null 2>&1; then
  echo "[Info] Ruby is not installed. Installing..."
  brew install ruby
  ruby_version=$(ruby -v | cut -d ' ' -f 2)
  echo "[Info] Ruby $ruby_version installed."
else
  ruby_version=$(ruby -v | cut -d ' ' -f 2)
  echo "[Info] Ruby $ruby_version is already installed."
fi

# Check if Rubygems is installed and up-to-date
if ! which gem >/dev/null 2>&1; then
  echo "[Error] Rubygems is not installed"
  exit
else
  gem_version=$(gem -v)
  latest_gem_version=$(gem list rubygems-update --remote | grep "rubygems-update" | sed 's/rubygems-update (\(.*\))/\1/')
  if [ "$gem_version" != "$latest_gem_version" ]; then
    echo "[Info] Rubygems is not up-to-date. Updating..."
    sudo gem update --system
    echo "[Info] Rubygems updated to version $latest_gem_version."
  else
    echo "[Info] Rubygems is up-to-date."
  fi
fi

# Use Homebrew to install everything by using a Brewfile
if [ -f "brewfile.private" ]; then
  echo "[Info] Installing brewfile.client"
  echo "[Info] Please make sure you are signed in to the Mac App Store to install apps via mas."
  brew bundle --file=brewfile.private
else
  echo "[Info] brewfile.private not found. Skipping installation with brew bundle."
fi

# Print a summary of what was installed
echo "[Info] Installation completed. The following packages should now work:"
echo " - zsh"
echo " - Xcode"
echo " - Homebrew"
echo " - Java"
echo " - Ruby"
echo " - Rubygems"
