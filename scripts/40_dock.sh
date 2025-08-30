#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 40: Dock layout and behavior
#  - Autohide and icon size
#  - Clear existing items and add desired apps in order
# ----------------------------------------------------------
set -euo pipefail

echo "Customizing Dock..."

# Behavior: autohide + icon size
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 36

# Build Dock using dockutil (installed via Brewfile)
if command -v dockutil >/dev/null 2>&1; then
  dockutil --remove all --no-restart || true
  dockutil --add "/Applications/Google Chrome.app" --no-restart || true
  dockutil --add "/Applications/Notion.app" --no-restart || true
  dockutil --add "/Applications/Visual Studio Code.app" --no-restart || true
  dockutil --add "/Applications/Microsoft Excel.app" --no-restart || true
fi

# Restart Dock to apply
killall Dock || true
