#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 55: Create developer folders
#  - Creates a tidy ~/Code tree so all repos live in one place
#  - Idempotent: re‑running is safe (mkdir -p)
# ----------------------------------------------------------
set -euo pipefail

CODE_ROOT="$HOME/Code"

# Create the standard subfolders
mkdir -p "$CODE_ROOT/personal"          "$CODE_ROOT/work"          "$CODE_ROOT/sandbox"          "$CODE_ROOT/archived"

echo "Created/confirmed dev folders under: $CODE_ROOT"
