#!/usr/bin/env bash
# Stage 30: macOS defaults (Finder, screenshots)
set -euo pipefail

. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
# Compatibility: provide `info` (and `warn`) if not defined by _lib.sh
if ! command -v info >/dev/null 2>&1; then
  info(){ printf "%s\n" "$*"; }
fi
if ! command -v warn >/dev/null 2>&1; then
  warn(){ printf "%s\n" "$*"; }
fi

step "Configuring Finder & screenshot settings (1/1)"
run defaults write com.apple.finder AppleShowAllFiles -bool true
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

run mkdir -p "$HOME/Downloads/Screenshots"
run defaults write com.apple.screencapture location "$HOME/Downloads/Screenshots"
ok "macOS defaults applied"
