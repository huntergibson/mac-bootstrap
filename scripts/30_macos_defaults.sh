#!/usr/bin/env bash
# Stage 30: macOS defaults (Finder, screenshots, wallpaper)
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

step "Configuring Finder & screenshot settings"
run defaults write com.apple.finder AppleShowAllFiles -bool true
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

run mkdir -p "$HOME/Downloads/Screenshots"
run defaults write com.apple.screencapture location "$HOME/Downloads/Screenshots"

# Wallpaper: copy repo image and apply to all desktops (if present)
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WALL_SRC="$REPO_DIR/assets/wallpapers/default.jpg"
WALL_DST="$HOME/Pictures/Wallpapers/default.jpg"
if [[ -f "$WALL_SRC" ]]; then
  step "Applying wallpaper"
  run mkdir -p "$(dirname "$WALL_DST")"
  run cp -f "$WALL_SRC" "$WALL_DST"
  # Apply to all Spaces/Desktops
  run osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "'"$WALL_DST"'"'
else
  warn "Wallpaper not found at $WALL_SRC (skipping)"
fi

# Apply immediately
run killall Finder || true
run killall SystemUIServer || true
ok "macOS defaults applied"
