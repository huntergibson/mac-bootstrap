#!/usr/bin/env bash
# Stage 40: Dock layout and behavior (with clear progress + safe quoting)
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

step "Dock defaults"
info "Setting Dock size to 50%, disabling auto-hide, and hiding suggested apps."
run --comment "Set Dock icon size to 50%" defaults write com.apple.dock tilesize -int 64
run --comment "Disable Dock auto-hide" defaults write com.apple.dock autohide -bool false
run --comment "Hide suggested apps (Recents)" defaults write com.apple.dock show-recents -bool false

# Need dockutil for layout operations
require dockutil
DOCKUTIL_BIN="$(command -v dockutil || true)"

# Desired Dock order — update this list to customize
APPS=(
  "/Applications/Google Chrome.app"
  "/Applications/Notion.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Microsoft Excel.app"
  "/Applications/ChatGPT.app"
)

step "Rebuilding Dock layout"
info "Removing all current Dock items so we can apply the curated order."
run --comment "Remove all Dock items" "$DOCKUTIL_BIN" --remove all --no-restart

TOTAL=${#APPS[@]}
COUNT=0
for APP in "${APPS[@]}"; do
  COUNT=$((COUNT+1))
  APP_NAME="$(basename "$APP" .app)"
  if [[ ! -e "$APP" ]]; then
    warn "[${COUNT}/${TOTAL}] Skipping $APP_NAME — app not installed yet."
    continue
  fi
  info "[${COUNT}/${TOTAL}] Adding $APP_NAME to the Dock"
  if run --comment "Add $APP_NAME" "$DOCKUTIL_BIN" --add "$APP" --no-restart; then
    ok "Added $APP_NAME"
  else
    warn "Failed to add $APP_NAME"
  fi
done

step "Refreshing Dock"
run --comment "Restart Dock to apply layout" killall Dock || true
ok "Dock reset to curated order"
