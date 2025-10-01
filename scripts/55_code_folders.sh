#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 55: Create developer folders
#  - Creates a tidy ~/Code tree so all repos live in one place
#  - Idempotent: re‑running is safe; existing folders are not overwritten
#  - Clear terminal progress and friendly messages
# ----------------------------------------------------------
set -euo pipefail

# Optional: allow caller to override CODE_ROOT (e.g., CODE_ROOT=~/Projects)
CODE_ROOT="${CODE_ROOT:-$HOME/Code}"

# Try to use shared logging helpers if available
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh" 2>/dev/null || true

# Compatibility shims (in case _lib.sh is not present)
if ! command -v step >/dev/null 2>&1; then step(){ printf "\n==> %s\n" "$*"; }; fi
if ! command -v info >/dev/null 2>&1; then info(){ printf "%s\n" "$*"; }; fi
if ! command -v ok   >/dev/null 2>&1; then ok(){ printf "✓ %s\n" "$*"; }; fi
if ! command -v warn >/dev/null 2>&1; then warn(){ printf "⚠ %s\n" "$*"; }; fi
if ! command -v err  >/dev/null 2>&1; then err(){ printf "✗ %s\n" "$*"; }; fi
if ! command -v run  >/dev/null 2>&1; then run(){ printf "+ %s\n" "$*"; "$@"; }; fi

SUBFOLDERS=(personal work sandbox archived)

step "Creating developer folders (1/2)"
# Validate base path and create if missing
if [[ -e "$CODE_ROOT" && ! -d "$CODE_ROOT" ]]; then
  err "Path exists but is not a directory: $CODE_ROOT"
  exit 1
fi
if [[ -d "$CODE_ROOT" ]]; then
  info "Base exists: $CODE_ROOT"
else
  run mkdir -p "$CODE_ROOT"
  ok "Created base: $CODE_ROOT"
fi

# Permission check so we fail fast with guidance
if [[ ! -w "$CODE_ROOT" ]]; then
  err "No write permission to $CODE_ROOT for user $USER"
  info "Try: sudo chown -R \"$USER\":staff \"$CODE_ROOT\" && chmod -R u+rwX,g+rwX \"$CODE_ROOT\""
  exit 1
fi

step "Ensuring subfolders (2/2)"
TOTAL=${#SUBFOLDERS[@]}
COUNT=0
CREATED=0
SKIPPED=0
for name in "${SUBFOLDERS[@]}"; do
  COUNT=$((COUNT+1))
  TARGET="$CODE_ROOT/$name"
  printf "[%d/%d] %s\n" "$COUNT" "$TOTAL" "$name"
  if [[ -d "$TARGET" ]]; then
    info "already exists: $TARGET"
    SKIPPED=$((SKIPPED+1))
  elif [[ -e "$TARGET" ]]; then
    warn "exists but not a directory, skipping: $TARGET"
  else
    run mkdir -p "$TARGET"
    ok "created: $TARGET"
    CREATED=$((CREATED+1))
  fi
done

info ""
info "Summary under $CODE_ROOT: created $CREATED, skipped $SKIPPED"
ok "Developer folders ready"
