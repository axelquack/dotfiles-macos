# .zshrc is for interactive shell configuration. You set options for the interactive shell there with the setopt and unsetopt commands. You can also load shell modules, set your history options, change your prompt, set up zle and completion, et cetera. You also set any variables that are only used in the interactive shell (e.g. $LS_COLORS).

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
ZSH_THEME="ys"

#############################################################
# ZSH
#############################################################

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

#############################################################
# PLUGINS
#############################################################

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(brew docker gem git github npm nvm osx pip python rsync ruby rvm screen ssh-agent)

source $ZSH/oh-my-zsh.sh

##############################################################
# PATH
##############################################################

# Customize to your needs...
export PATH=$PATH:/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# NVM
export NVM_DIR="$HOME/.nvm"
. "$(brew --prefix nvm)/nvm.sh"

#############################################################
# ALIAS
#############################################################

alias 'ttop=top -ocpu -R -F -s 2 -n30'

# Get OS X Software Updates, and update installed Ruby gems, Homebrew and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; sudo gem update'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | grep -o 'inet6\? \(\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\|[a-fA-F0-9:]\+\)' | sed -e 's/inet6* //'"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Open network ports (for all users)
alias listen="sudo lsof -i -P | grep -i "listen""

# OS X has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# OS X has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# Empty the Trash on all mounted volumes and the main HDD
# Also, clear Apple’s System Logs to improve shell startup speed
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# Hide/show all desktop icons (useful when presenting)
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# rebuild Launch Services to remove duplicate entries on Open With menu
alias rebuildopenwith='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user'
alias defhist='history 1 | grep "defaults"'

# Directories
alias downloads='cd ~/Downloads'
alias desktop='cd ~/Desktop'
alias sites='cd ~/Documents/Sites/'
alias projects='cd ~/Documents/Sites/git/repo/projects/'
alias researchprivate='cd ~/Documents/Sites/git/repo/research.private/'
alias researchpublic='cd ~/Documents/Sites/git/repo/research.public/'
alias websites='cd ~/Documents/Sites/git/repo/websites/'

# Applications
alias markdown='open -a /Applications/Obsidian.app/'

# Git shortcuts
alias ga='git add'
alias gp='git push'
alias gl='git log'
alias gs='git status'
alias gd='git diff'
alias gm='git commit -m'
alias gma='git commit -am'
alias gb='git branch'
alias gc='git checkout'
alias gra='git remote add'
alias grr='git remote rm'
alias gpu='git pull'
alias gcl='git clone'
alias gta='git tag -a -m'
alias gf='git reflog'

# Docker
alias dl="docker ps -l -q" # Get latest container ID
alias dps="docker ps" # Get container process
alias dpa="docker ps -a" # Get process included stop container
alias di="docker images" # Get images
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'" # Get container IP
alias dkd="docker run -d -P" # Run deamonized container, e.g., $dkd base /bin/echo hello
alias dki="docker run -i -t -P" # Run interactive container, e.g., $dki base /bin/bash
alias dex="docker exec -i -t" # Execute interactive container, e.g., $dex base /bin/bash
dstop() { docker stop $(docker ps -a -q); } # Stop all containers
drm() { docker rm $(docker ps -a -q); } # Remove all containers
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)' # Stop and remove all containers
dri() { docker rmi $(docker images -q); } # Remove all images
dbu() { docker build -t=$1 .; } # # Dockerfile build, e.g., $dbu tcnksm/test
dalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; } # # Show all alias related docker
dbash() { docker exec --interactive --tty $(docker ps -aqf "name=$1") bash; } # Bash into running container

# Nerd stuff
# Source: http://aur.archlinux.org/packages/lolbash/lolbash/lolbash.sh
alias wtf='dmesg'
alias rtfm='man'
alias visible='echo'
alias invisible='cat'
alias moar='more'
alias icanhas='mkdir'
alias donotwant='rm'
alias dowant='cp'
alias gtfo='mv'
alias hai='cd'
alias plz='pwd'
alias inur='locate'
alias nomz='ps aux | less'
alias nomnom='killall'
alias cya='reboot'
alias kthxbai='halt'
