#!/usr/bin/env bash
# Bootstrap entry point — color logs, strict errors, safe order
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/scripts/_lib.sh"

step "Requesting sudo keepalive"
if ! sudo -v; then die "sudo required"; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Rosetta for Apple Silicon (if needed)
if [[ "$(uname -m)" == "arm64" ]]; then
  if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
    step "Installing Rosetta 2 (accept license if prompted)"
    run softwareupdate --install-rosetta --agree-to-license
  fi
fi

step "Stage 10: Xcode Command Line Tools + Homebrew"
./scripts/10_xcode_homebrew.sh

step "Stage 20: Install packages/apps from Brewfile"
./scripts/20_brew_bundle.sh

step "Stage 30: Apply macOS defaults"
./scripts/30_macos_defaults.sh

step "Stage 40: Customize Dock"
./scripts/40_dock.sh

step "Stage 50: Shell & Git dotfiles"
./scripts/50_shell_git.sh

step "Stage 55: Create ~/Code folders"
./scripts/55_code_folders.sh

step "Stage 70: Languages & global dev tools"
./scripts/70_languages.sh

step "Stage 80: Start background services"
./scripts/80_services.sh

step "Stage 90: VS Code extensions, settings & keybindings"
./scripts/90_postinstall.sh

ok "All done. Some changes may need a logout/restart."
