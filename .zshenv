# Since .zshenv is always sourced, it often contains exported variables that should be available to other programs. 
# For example, $PATH, $EDITOR, and $PAGER are often set in .zshenv. Also, you can set $ZDOTDIR in .zshenv to specify an alternative location for the rest of your zsh configuration.

# Specify your defaults in this environment variable
## caskroom usually /opt/homebrew-cask/Caskroom
# Link Homebrew casks in `/Applications` rather than `~/Applications`
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# --caskroom=/my/path determines where the actual applications will be located. Default is /opt/homebrew-cask/Caskroom
# --appdir=/my/path changes the path where the symlinks to the applications (above) will be generated. This is commonly used to create the links in the root Applications directory instead of the home Applications directory by specifying --appdir=/Applications. Default is ~/Applications.
# --prefpanedir=/my/path changes the path for PreferencePane symlinks. Default is ~/Library/PreferencePanes
# --qlplugindir=/my/path changes the path for Quicklook Plugin symlinks. Default is ~/Library/QuickLook
# --widgetdir=/my/path changes the path for Dashboard Widget symlinks. Default is ~/Library/Widgets
# --fontdir=/my/path changes the path for Fonts symlinks. Default is ~/Library/Fonts
# --binarydir=/my/path changes the path for binary symlinks. Default is /usr/local/bin

# export EDITOR="vim"
# export ALTERNATE_EDITOR=""