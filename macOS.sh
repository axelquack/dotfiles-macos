#!/usr/bin/env bash

# macOS Configuration Script
# ==========================
# Sets various system and application preferences via the command line.
# Inspired by Mathias Bynens' .macos script and others.
# Review settings carefully before running. Some changes require logout/restart.

# --- Initial Setup ---

# Ask for the administrator password upfront to avoid prompts later.
echo "Requesting administrator privileges for setup..."
sudo -v

# Keep-alive: Update existing `sudo` timestamp in the background until the script finishes.
# Prevents sudo from timing out during longer operations.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
echo "Sudo credentials cached."

###############################################################################
# General UI/UX                                                               #
###############################################################################
echo "Applying General UI/UX settings..."

# Disable the sound effects on boot (requires sudo).
# Note: This changes an NVRAM variable, affecting the boot chime.
sudo nvram SystemAudioVolume=" "

# Set default Finder view style to List View (`Nlsv`).
# Other options: Icon View (`icnv`), Column View (`clmv`), Gallery View (`glyv`).
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable unnecessary window opening/closing animations for potentially faster UI.
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Expand save panel by default
# defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
# defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
# defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
# defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################
echo "Applying Input Device settings..."

# Enable tap to click for this user and for the login screen
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Automatically illuminate built-in MacBook keyboard in low light conditions.
defaults write com.apple.BezelServices kDim -bool true

# Turn off keyboard illumination automatically after 5 minutes of inactivity (300 seconds).
defaults write com.apple.BezelServices kDimTime -int 300

###############################################################################
# Screen & Screensaver                                                        #
###############################################################################
echo "Applying Screen & Screensaver settings..."

# Require password immediately after sleep or screen saver begins.
# defaults write com.apple.screensaver askForPassword -int 1
# defaults write com.apple.screensaver askForPasswordDelay -int 0

# Optional: Set a specific screensaver module (requires knowing the path)
# Example using "Drift" screensaver (path might vary slightly between macOS versions)
# defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName -string "Drift" path -string "/System/Library/Screen Savers/Drift.saver" type -int 0

###############################################################################
# Finder                                                                      #
###############################################################################
echo "Applying Finder settings..."

# Show all filename extensions (e.g., .txt, .jpg) in Finder. Recommended.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files (files starting with '.') in Finder. Useful for development.
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show the user's Library folder (`~/Library`). Useful for accessing config files.
# `chflags` modifies file system flags directly.
chflags nohidden ~/Library

# Show path bar in Finder windows (displays current directory path at the bottom).
# defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder windows (displays item count, disk space).
# defaults write com.apple.finder ShowStatusBar -bool true

# Keep folders on top when sorting by name in Finder windows.
# defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default (instead of "This Mac").
# defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension.
# defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes.
# defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show icons for external hard drives, servers, and removable media on the desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false # Keep internal drives off desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

###############################################################################
# Menu Bar                                                                    #
###############################################################################
echo "Applying Menu Bar settings..."

# Show battery percentage in the menu bar.
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Optional: Customize which icons appear in the Menu Bar Control Center vs always visible.
# This often requires more complex plist manipulation or GUI interaction.

###############################################################################
# Dock & Hot Corners                                                          #
###############################################################################
echo "Applying Dock & Hot Corners settings..."

# Automatically hide and show the Dock.
defaults write com.apple.dock autohide -bool true

# Optional: Change Dock position (left, bottom, right)
# defaults write com.apple.dock orientation -string "left"

# Optional: Set the icon size of Dock items in pixels
# defaults write com.apple.dock tilesize -int 36

# Optional: Minimize windows into their application’s icon
# defaults write com.apple.dock minimize-to-application -bool true

# Configure Hot corners (trigger actions by moving mouse to screen corners).
# Possible values for corner actions (`-int` value):
#  0: no-op (disabled)
#  2: Mission Control
#  3: Show Application Windows
#  4: Desktop
#  5: Start Screen Saver
#  6: Disable Screen Saver
#  7: Dashboard (obsolete)
# 10: Put Display to Sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen
# Possible values for modifier keys (`-int` value):
#  0: no modifier
#  262144: Shift
#  524288: Control
# 1048576: Option/Alt
# 1310720: Command (Cmd)
# Combine modifiers by adding their values.

# Top left screen corner → Mission Control (no modifier)
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# Top right screen corner → Desktop (no modifier)
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0

# Bottom left screen corner → Start screen saver (no modifier)
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# Bottom right screen corner → (disabled)
# defaults write com.apple.dock wvous-br-corner -int 0
# defaults write com.apple.dock wvous-br-modifier -int 0

###############################################################################
# Safari & WebKit                                                             #
###############################################################################
echo "Applying Safari settings..."

# Set Safari’s home page to `about:blank` for potentially faster loading.
defaults write com.apple.Safari HomePage -string "about:blank"

# Prevent Safari from automatically opening files deemed ‘safe’ after downloading.
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Enable Safari’s experimental hidden Debug menu.
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu (shows Web Inspector, Responsive Design Mode, etc.).
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Optional: Privacy - Prevent cross-site tracking
# defaults write com.apple.Safari WebKitPreferences.crossOriginTrackingPreventionEnabled -bool true

# Optional: Show the full URL in the address bar
# defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

###############################################################################
# Mail                                                                        #
###############################################################################
echo "Applying Mail settings..."

# Display emails in threaded mode (conversations).
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"

# Sort emails in threads by date, with the oldest message at the top.
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"
# Note: Applying complex dict changes like this can sometimes be fragile across macOS updates.

# Disable rendering attachments inline within the email body (show as icons instead).
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

# Optional: Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>`
# defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

###############################################################################
# Time Machine                                                                #
###############################################################################
echo "Applying Time Machine settings..."

# Prevent Time Machine from automatically prompting to use newly connected disks as backup volumes.
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Note: Manually excluding /System, /Applications, /Library is generally redundant.
# Time Machine excludes these intelligently by default.

# Optional: Exclude the user's Desktop from Time Machine backups. Uncomment if desired.
# echo "Excluding Desktop from Time Machine backups..."
# tmutil addexclusion -p ~/Desktop

# Optional: Disable local Time Machine snapshots on laptops.
# WARNING: This saves disk space but REMOVES the ability to restore files from Time Machine
#          when the main backup disk is not connected. Not generally recommended on modern systems.
# echo "Disabling local Time Machine snapshots (use with caution)..."
# sudo tmutil disablelocal

###############################################################################
# TextEdit                                                                    #
###############################################################################
echo "Applying TextEdit settings..."

# Use plain text mode (TXT) instead of rich text (RTF) for new TextEdit documents.
defaults write com.apple.TextEdit RichText -int 0

# Set the default text encoding to UTF-8 for opening and saving plain text files.
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

###############################################################################
# Kill affected applications to apply changes                                 #
###############################################################################
echo "Restarting affected applications to apply settings..."

# List of apps whose preferences were changed and might need a restart.
# Add other apps here if you modify their defaults (e.g., "Calendar", "Contacts").
apps_to_restart=(
    "Finder"
    "Dock"
    "Safari"
    "Mail"
    "SystemUIServer" # Handles Menu Bar extras
    "TextEdit"
    # Add "cfprefsd" here if some settings aren't sticking - it manages preferences cache.
    # "cfprefsd"
)

for app in "${apps_to_restart[@]}"; do
    echo " Restarting ${app}..."
    # Use killall -HUP for some apps if a full kill causes issues, but killall is usually needed for prefs.
    killall "${app}" > /dev/null 2>&1 || true # Use '|| true' to prevent script exit if app wasn't running
    # Add a small delay to allow apps to restart gracefully if needed
    # sleep 1
done

echo ""
echo "macOS configuration script finished!"
echo "Done. Note that some changes might require a full logout/restart to take effect."
echo "Please review any warnings or errors above."
