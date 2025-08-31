#!/usr/bin/env bash
# Stage 40: Dock layout and behavior
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

step "Customizing Dock (always visible, set order)"

# Always show Dock (no autohide) and set icon size
run defaults write com.apple.dock autohide -bool false
run defaults write com.apple.dock tilesize -int 36

# Need dockutil (installed in Stage 20)
require dockutil

# Rebuild Dock
run dockutil --remove all --no-restart

APPS=(
  "/Applications/Google Chrome.app"
  "/Applications/Notion.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Microsoft Excel.app"
)

for app in "${APPS[@]}"; do
  name="$(basename "$app" .app)"
  if [[ -e "$app" ]]; then
    run dockutil --add "$app" --no-restart
    ok "Added $name"
  else
    warn "Skipping $name — not installed yet. Re-run scripts/40_dock.sh after apps install."
  fi
done

# Apply changes
run killall Dock || true
ok "Dock updated"
