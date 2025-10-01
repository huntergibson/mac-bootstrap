#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 80: Services (no persistent DB)
#  - PostgreSQL is no longer managed here
#  - Supabase CLI is installed via Homebrew and started on-demand per project
# ----------------------------------------------------------
set -euo pipefail

# Try to use shared logging helpers if available
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh" 2>/dev/null || true

# Compatibility shims (in case _lib.sh is not present)
if ! command -v step >/dev/null 2>&1; then step(){ printf "\n==> %s\n" "$*"; }; fi
if ! command -v info >/dev/null 2>&1; then info(){ printf "%s\n" "$*"; }; fi
if ! command -v ok   >/dev/null 2>&1; then ok(){ printf "✓ %s\n" "$*"; }; fi
if ! command -v warn >/dev/null 2>&1; then warn(){ printf "⚠ %s\n" "$*"; }; fi

step "Services overview (1/1)"
if command -v supabase >/dev/null 2>&1; then
  info "Supabase CLI detected. Local stack is started on-demand (no auto background service)."
  info "Per project commands:"
  info "  supabase init    # run once in a project folder"
  info "  supabase start   # start local services in Docker"
  info "  supabase stop    # stop local services"
  ok "No persistent services started by this stage."
else
  warn "Supabase CLI not found on PATH. After Brewfile install, it will be available as 'supabase'."
fi