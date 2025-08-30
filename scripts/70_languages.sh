#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 70: Languages & global dev tools
#  - Node via fnm (installs LTS and sets default)
#  - pnpm globals (TypeScript, ts-node, ncu)
#  - Python tools via pipx (black, ruff, mypy, pre-commit, httpx)
#  - Print uv usage hint for quick venvs
# ----------------------------------------------------------
set -euo pipefail

# Ensure brew env (for fnm, pnpm, pipx, uv)
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# Node via fnm (install LTS and set default)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
  fnm install --lts || true
  fnm default lts || true
fi

# Ensure pnpm available (installed via brew)
if command -v pnpm >/dev/null 2>&1; then
  pnpm setup || true
  # Useful global packages
  pnpm add -g typescript ts-node npm-check-updates || true
  # Mapshaper CLI (vector GIS simplification/convert) — installed globally
  pnpm add -g mapshaper || true
fi

# Python via brew + uv + pipx
# Make sure pipx has its path set up for current shell
if command -v pipx >/dev/null 2>&1; then
  pipx ensurepath || true
fi

# Popular Python dev tools globally via pipx
if command -v pipx >/dev/null 2>&1; then
  pipx install black || true
  pipx install ruff || true
  pipx install mypy || true
  pipx install pre-commit || true
  pipx install httpx || true
fi

# uv quick tip (will just print a hint on first run)
if command -v uv >/dev/null 2>&1; then
  echo "uv installed. Create a venv with: uv venv .venv && source .venv/bin/activate"
fi
