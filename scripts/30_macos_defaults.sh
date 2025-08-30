#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 30: macOS defaults
#  - Finder visibility & path bar
#  - Screenshot folder to ~/Downloads/Screenshots
#  - Restarts affected processes so changes apply immediately
# ----------------------------------------------------------
set -euo pipefail

echo "Configuring macOS defaults..."

# Finder: show hidden files and full path in title bar
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Screenshots: change save location (create folder if missing)
mkdir -p "$HOME/Downloads/Screenshots"
defaults write com.apple.screencapture location "$HOME/Downloads/Screenshots"

# Apply immediately
killall Finder || true
killall SystemUIServer || true
