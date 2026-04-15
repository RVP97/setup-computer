#!/bin/bash

# Exit immediately if a command fails.
set -e

echo "Applying macOS settings..."

# -----------------------------------
# UI responsiveness
# -----------------------------------

# Disable many window open/close animations to make macOS feel snappier.
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Make Dock auto-hide/show much faster.
defaults write com.apple.dock autohide-time-modifier -float 0.15

# Hide the Dock automatically to free screen space.
defaults write com.apple.dock autohide -bool true

# Do not show recent apps in the Dock.
defaults write com.apple.dock show-recents -bool false


# -----------------------------------
# Keyboard behavior
# -----------------------------------

# Set a very fast key repeat rate when holding down a key.
# Lower numbers are faster.
defaults write NSGlobalDomain KeyRepeat -int 1

# Reduce delay before key repeat starts.
# Lower numbers are faster.
defaults write NSGlobalDomain InitialKeyRepeat -int 10


# -----------------------------------
# Trackpad behavior
# -----------------------------------

# Set trackpad tracking speed to maximum.
# Range is usually 0 to 3. 3 is fastest.
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3

# Enable tap to click.
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Also enable tap to click on the Bluetooth trackpad domain.
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1


# -----------------------------------
# Finder behavior
# -----------------------------------

# Always show all file extensions.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Keep folders at the top when sorting by name in Finder.
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Show the full POSIX path in Finder window titles.
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show hidden files in Finder.
# Useful for dev work (.env, .gitignore, etc.)
defaults write com.apple.finder AppleShowAllFiles -bool true

# Use list view in Finder by default.
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"


# -----------------------------------
# Screenshots
# -----------------------------------

# Send screenshots directly to the clipboard instead of saving files.
# This makes Cmd+Shift+3 / Cmd+Shift+4 copy the image only.
defaults write com.apple.screencapture target -string "clipboard"

# Remove any custom screenshot save location if one exists,
# since screenshots are going to clipboard instead of files.
defaults delete com.apple.screencapture location 2>/dev/null || true


# -----------------------------------
# Misc useful global behavior
# -----------------------------------

# Expand save panel by default in many apps.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default.
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true


# -----------------------------------
# Restart affected services
# -----------------------------------

# Restart Dock so Dock-related settings apply immediately.
killall Dock 2>/dev/null || true

# Restart Finder so Finder-related settings apply immediately.
killall Finder 2>/dev/null || true

# Restart system UI services so screenshot/global UI settings apply.
killall SystemUIServer 2>/dev/null || true

echo "Done. Some changes may require logging out and back in."