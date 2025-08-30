#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 10: Ensure Xcode Command Line Tools and Homebrew
#  - Installs CLT (compilers, git) and waits until complete
#  - Installs Homebrew and puts it on PATH for this shell
# ----------------------------------------------------------
set -euo pipefail

# Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  # Wait for CLT to finish installing to avoid race conditions
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for this shell (Apple silicon & Intel)
if [[ -d "/opt/homebrew/bin" ]]; then eval "$('/opt/homebrew/bin/brew' shellenv)"; fi
if [[ -d "/usr/local/bin" ]]; then export PATH="/usr/local/bin:$PATH"; fi

brew update
