#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 20: Install all packages/apps from Brewfile
#  - Taps homebrew/bundle and runs `brew bundle`
#  - Idempotent: safe to re‑run
# ----------------------------------------------------------
set -euo pipefail

# Put brew on PATH in case we’re a fresh shell
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

brew tap homebrew/bundle || true
brew bundle --file "$(cd "$(dirname "$0")/.." && pwd)/Brewfile" || true
