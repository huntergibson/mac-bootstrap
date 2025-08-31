#!/usr/bin/env bash
# Stage 20: Install all packages/apps from Brewfile
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

# Ensure brew on PATH
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

step "Tapping homebrew/bundle"
run brew tap homebrew/bundle

BREWFILE="$(cd "$(dirname "$0")/.." && pwd)/Brewfile"
[[ -f "$BREWFILE" ]] || die "Brewfile not found at $BREWFILE"

step "Running brew bundle"
run brew bundle --file "$BREWFILE"

ok "Brew bundle complete"
