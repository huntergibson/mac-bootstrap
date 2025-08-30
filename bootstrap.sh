#!/usr/bin/env bash
# ----------------------------------------------------------
# Bootstrap entry point
# Runs each setup stage in a safe, idempotent order.
#  1) Ensure admin privileges / Rosetta on Apple silicon
#  2) Install Xcode CLT + Homebrew
#  3) Install everything from Brewfile
#  4) Apply macOS defaults (Finder, screenshots)
#  5) Build Dock layout
#  6) Dotfiles, Git defaults, SSH key generation
#  7) Languages & global tools (Node via fnm, Python via uv/pipx)
#  8) Start services (Postgres)
#  9) Post‑install (VS Code extensions + settings)
# ----------------------------------------------------------
set -euo pipefail

# Keep sudo alive for the whole run so prompts don’t interrupt
if ! sudo -v; then echo "sudo required"; exit 1; fi
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# If Apple Silicon, ensure Rosetta for best compatibility
if [[ "$(uname -m)" == "arm64" ]]; then
  if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
    echo "Installing Rosetta 2 (if prompted, accept license)..."
    softwareupdate --install-rosetta --agree-to-license || true
  fi
fi

# Run the setup stages (each script is safe to re‑run)
./scripts/10_xcode_homebrew.sh
./scripts/20_brew_bundle.sh
./scripts/30_macos_defaults.sh
./scripts/40_dock.sh || true
./scripts/50_shell_git.sh
./scripts/55_code_folders.sh   # ← create ~/Code/{personal,work,sandbox,archived}
./scripts/70_languages.sh
./scripts/80_services.sh || true
./scripts/90_postinstall.sh || true

echo "✅ All done. Some changes may need a logout/restart."
