# ~/.zshrc - Zsh configuration file for the Z Shell

# --- Zsh Environment Setup ---

# Load Zsh Profiling Module (Optional: Uncomment for startup time debugging)
# zmodload zsh/zprof

# Add Homebrew Zsh completions to the function path
# This ensures completions installed by Homebrew are found before system ones.
fpath=(/usr/local/share/zsh-completions $fpath)

# Initialize the Zsh completion system (with caching)
# - autoload: Loads the compinit function only when needed.
# - Uz: Prevents errors if compinit is already loaded and skips security checks.
# - compinit: Initializes completions based on fpath.
# - -C: Enables caching via ~/.zcompdump file for faster startups.
#       If completions seem broken after installing new software, try removing ~/.zcompdump
autoload -Uz compinit && compinit -C

# --- PATH Configuration ---
# Sets the command search path using Zsh's special 'path' array.
# - typeset -U path: Ensures the 'path' array contains only unique elements (no duplicates).
# - Directories are searched in the order they appear in the array.
# Note: Version managers (pyenv, rbenv, fnm) below will modify the PATH further via their init scripts.
typeset -U path # Ensure path elements are unique
path=(
    # User-specific binary directory
    ~/bin
    # Homebrew binaries (preferred over system binaries)
    /usr/local/bin
    /usr/local/sbin
    # Standard system binaries
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    # Add other custom paths here if needed
)
# Export the configured 'path' array to the standard PATH environment variable.
export PATH

# --- Tool Initialization ---
# Load configuration and environment settings for various command-line tools.
# Order can sometimes matter; version managers usually come before prompt setup.

# pyenv + uv (Python versioning and environments)
# Initialize pyenv first to manage Python interpreters. uv is used within projects.
# Requires pyenv to be installed (e.g., `brew install pyenv`). uv (`brew install uv`) is used separately.
# The `eval` command sets up pyenv's shell integration (shims).
eval "$(pyenv init - zsh)"

# rbenv (Ruby Version Manager)
# Initialize rbenv for managing Ruby versions.
# Requires rbenv and ruby-build to be installed (e.g., `brew install rbenv ruby-build`).
# The `eval` command sets up rbenv's shell integration (shims).
eval "$(rbenv init - zsh)"

# fnm (Fast Node Manager)
# Initializes fnm for managing Node.js versions.
# Requires fnm to be installed (e.g., `brew install fnm`).
# The `--use-on-cd` flag enables automatic Node version switching.
# The `eval` command sets up fnm's shell integration.
eval "$(fnm env --use-on-cd)"

# Starship Prompt (starship.rs)
# Initializes the Starship prompt after other tools are set up.
# Requires Starship to be installed (e.g., `brew install starship`).
# This command sets up the necessary shell functions and variables for Starship.
eval "$(starship init zsh)"

# Atuin Shell History Integration
# Hooks into Zsh to record history and overrides Ctrl+R binding.
# Requires Atuin to be installed (`brew install atuin`).
eval "$(atuin init zsh)"

# Docker usage
# Use Homebrew to install Colima itself, the Docker command-line client, and Docker Compose (which is often needed for multi-container applications).
# 'brew install colima docker docker-compose'
#   colima: Installs the Colima VM management tool.
#   docker: Installs only the docker CLI client.
#   docker-compose: Installs the Docker Compose CLI (v2).
# Start the VM & Docker: colima start (Use this whenever you want to use Docker)
# Stop the VM & Docker: colima stop (Frees up the resources used by the VM)
# Check Status: colima status
# Delete the VM: colima delete

# --- Aliases ---
# Custom shortcuts for frequently used commands.

# Section for general utility aliases.

# Listing files with 'eza' (modern 'ls' replacement, successor to 'exa')
# Assumes 'eza' is installed (`brew install eza`). Flags explained:
# -b: Basic listing, minimal detail
# -g: Show group column
# -h: Human-readable file sizes
# -H: Show header row
# -l: Long listing format
# --git: Show Git status for files
# -a: Show hidden files (starting with .)
# --tree: Display as a tree
# --level=N: Limit tree depth
alias ls='eza'                  # Basic listing (replaces system 'ls')
alias l='eza -bghHl --git'      # Detailed list with Git status
alias ll='eza -bghHl --git -a'  # Detailed list including hidden files, with Git status
alias la='eza -a'               # List all files (including hidden), basic format
alias lt='eza --tree --level=2' # List files in a tree structure, 2 levels deep

# Alias for rmtrash (safer alternative to 'rm')
# Assumes 'rmtrash' is installed (`brew install rmtrash`)
alias trash='rmtrash'

# Process listing (Top command with specific sorting/display options)
# I am currently using btop instead: 'brew install btop'
# alias 'ttop=top -ocpu -R -F -s 2 -n30' # Sort by CPU, show registers/frame ptr, update every 2s, 30 iterations

# Network utilities
alias ip="dig +short myip.opendns.com @resolver1.opendns.com" # Get public IP address
alias localip="ipconfig getifaddr en0 || ipconfig getifaddr en1" # Get local Wi-Fi/Ethernet IP (tries en0 then en1)
alias ips="ifconfig -a | grep -o 'inet6\? \(\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\|[a-fA-F0-9:]\+\)' | sed -e 's/inet6* //'" # List all assigned IP addresses

# Network traffic inspection (Requires root/sudo)
alias sniff="sudo ngrep -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'" # Sniff HTTP GET/POST traffic on interface en0
alias httpdump="sudo tcpdump -i en0 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\"" # Dump HTTP headers on interface en0

# Open network ports listing
alias listen="sudo lsof -i -P | grep -i \"listen\"" # Show processes listening on network ports

# Hashing fallbacks (macOS uses `shasum` and `md5` instead of `sha1sum`/`md5sum`)
command -v md5sum > /dev/null || alias md5sum="md5"
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# macOS specific utilities
alias showhidden="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"  # Show hidden files in Finder
alias hidehidden="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder" # Hide hidden files in Finder
alias rebuildopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user' # Rebuild the "Open With..." context menu database
alias defhist='history 1 | grep "defaults"'                                                        # Show recent 'defaults write' commands from Zsh history

# Directory navigation shortcuts
alias downloads='cd ~/Downloads'
alias desktop='cd ~/Desktop'

# Application shortcuts
alias markdown='open -a /Applications/Obsidian.app/'        # Open Obsidian application
alias code='open -a /Applications/Visual\ Studio\ Code.app' # Open Visual Studio Code application

# --- Aliases: Git ---
# Common Git command shortcuts to speed up workflow.
alias ga='git add'                          # Stage changes
alias gap='git add -p'                      # Stage changes interactively (patch mode)
alias gp='git push'                         # Push commits to remote
alias gl='git log --oneline --graph --decorate' # Compact, graphical commit history
alias gs='git status -sb'                   # Short branch/status output
alias gd='git diff'                         # Show unstaged changes
alias gdc='git diff --cached'               # Show staged changes (changes added to index)
alias gm='git commit -m'                    # Commit with message
alias gma='git commit -am'                  # Add all tracked files and commit
alias gb='git branch'                       # List branches
alias gc='git checkout'                     # Switch branches or restore files
alias gcb='git checkout -b'                 # Create a new branch and switch to it
alias gra='git remote add'                  # Add a remote repository
alias grr='git remote rm'                   # Remove a remote repository
alias gpu='git pull --rebase'               # Fetch and rebase changes from remote
alias gcl='git clone'                       # Clone a repository
alias gsta='git stash push'                 # Stash current changes
alias gstp='git stash pop'                  # Apply and remove the latest stash
alias gstd='git stash drop'                 # Discard the latest stash
alias gf='git reflog'                       # Show the reflog (history of HEAD changes)

# --- Aliases & Functions: Docker (using Colima) ---
# Shortcuts and helper functions for Docker commands.
# Assumes a CLI-based Docker environment using Colima (or similar).
# Installation: `brew install colima docker docker-compose`
# Usage: Run `colima start` before using Docker commands, `colima stop` when done.
# These aliases will use the standard `docker` CLI, which connects to the Docker daemon provided by Colima.
alias dcstart='colima start'       # Start the Colima VM/Docker
alias dcstop='colima stop'         # Stop the Colima VM/Docker daemon
alias dcstatus='colima status'     # Check Colima VM status
alias dl="docker ps -l -q"         # Show the ID of the last exited container
alias dps="docker ps"              # List currently running containers
alias dpa="docker ps -a"           # List all containers (running and stopped)
alias di="docker images"           # List Docker images
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'" # Get the IP address of a container (pass container ID/name)
alias dkd="docker run -d -P"       # Run a container in detached mode, publishing all exposed ports
alias dki="docker run -i -t -P"    # Run a container interactively, publishing all exposed ports
alias dex="docker exec -i -t"      # Execute a command inside a running container interactively

# Docker Functions (provide more complex logic than simple aliases)
# Stop all running containers
dstop() { docker stop $(docker ps -aq); } # Use -aq to get IDs of all containers
# Remove all stopped containers
drm() { docker rm $(docker ps -aq -f status=exited); } # Use filter for stopped
# Stop and remove all containers (use with caution!)
alias drmf='dstop && drm' # Chain the stop and remove functions
# Remove all dangling images (unused image layers, saves disk space)
alias drimd='docker image prune -f' # Use the modern prune command
# Remove all images (use with extreme caution! Left commented out by default)
# dri() { docker rmi $(docker images -q); }
# Build a Docker image with a specified tag (e.g., dbu my-image)
dbu() { docker build -t=$1 .; }
# List Docker aliases and functions defined in this file
dalias() { alias | grep 'docker'; functions | grep '^d[a-z]* ()'; } # Show aliases and functions starting with 'd' related to docker
# Get an interactive bash shell inside a running container (pass container name/ID, e.g., dbash my-container)
dbash() { docker exec --interactive --tty $(docker ps -aqf "name=$1") bash; }

# --- Final Setup ---

# Zsh Profiling Output (Optional: Uncomment for startup time debugging)
# Make sure this is the *very last* command executed in .zshrc
# zprof
