#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 80: Start background services
#  - Starts PostgreSQL 16 via brew services if installed
# ----------------------------------------------------------
set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

if brew list postgresql@16 >/dev/null 2>&1; then
  echo "Starting PostgreSQL 16 as a background service..."
  brew services start postgresql@16 || true
fi
