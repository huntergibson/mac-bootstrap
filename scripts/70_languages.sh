#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 70: Languages & global dev tools
#  - Node via fnm (installs LTS and sets default, with robust fallback)
#  - pnpm globals (TypeScript, ts-node, npm-check-updates, mapshaper)
#  - Python tools via pipx (black, ruff, mypy, pre-commit, httpx)
#  - uv usage hint for quick venvs
#  - Clear progress, helpful comments, and safe fallbacks
# ----------------------------------------------------------
set -euo pipefail

# Try to use shared logging helpers if available
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh" 2>/dev/null || true

# Compatibility shims (in case _lib.sh is not present)
if ! command -v step >/dev/null 2>&1; then step(){ printf "\n==> %s\n" "$*"; }; fi
if ! command -v info >/dev/null 2>&1; then info(){ printf "%s\n" "$*"; }; fi
if ! command -v ok   >/dev/null 2>&1; then ok(){ printf "✓ %s\n" "$*"; }; fi
if ! command -v warn >/dev/null 2>&1; then warn(){ printf "⚠ %s\n" "$*"; }; fi
if ! command -v err  >/dev/null 2>&1; then err(){ printf "✗ %s\n" "$*"; }; fi
if ! command -v run  >/dev/null 2>&1; then run(){ printf "+ %s\n" "$*"; "$@"; }; fi

# Ensure brew env (so fnm, pnpm, pipx, uv are on PATH)
if command -v brew >/dev/null 2>&1; then
  info "Loading Homebrew environment"
  eval "$(brew shellenv)"
else
  warn "Homebrew not found on PATH; some tools may be unavailable"
fi

# Small helper: prepend to PATH only if not already present
path_prepend(){
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

# ---------------- (1/3) Node via fnm + pnpm globals ----------------
step "Node & pnpm globals (1/3)"

if command -v fnm >/dev/null 2>&1; then
  info "Using fnm to install & set Node LTS"
  # Initialize fnm in this shell then install LTS
  eval "$(fnm env --use-on-cd)"
  if fnm install --lts; then
    ok "Installed Node LTS"
  else
    warn "fnm couldn't install Node LTS (it may already be installed)"
  fi
  # Try to set default to the LTS alias; if that fails, detect the latest LTS by parsing list-remote
  if fnm default lts; then
    ok "Set default Node to LTS"
  else
    warn "Could not set default Node to LTS alias; attempting version-resolved fallback"
    # Older fnm versions don't support --format=json. Parse text output of list-remote --lts.
    LTS_VER=$(fnm list-remote --lts 2>/dev/null | awk '/^v[0-9]/{ver=$1} END{print ver}')
    if [[ -n "${LTS_VER:-}" ]]; then
      info "Setting default Node to ${LTS_VER}"
      fnm install "$LTS_VER" >/dev/null 2>&1 || true
      if fnm default "$LTS_VER"; then
        ok "Default Node set to $LTS_VER"
      else
        warn "Failed to set default Node to $LTS_VER"
      fi
    else
      warn "Could not resolve latest LTS version from 'fnm list-remote --lts'"
    fi
  fi
else
  warn "fnm not found; skipping Node LTS install"
fi

if command -v pnpm >/dev/null 2>&1; then
  info "Configuring pnpm and installing global packages"
  # Ensure PNPM_HOME exists and is on PATH for this session so globals can be linked
  export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
  mkdir -p "$PNPM_HOME"
  path_prepend "$PNPM_HOME"
  # Tell pnpm explicitly where to place global binaries and run setup (quietly)
  pnpm config set global-bin-dir "$PNPM_HOME" --location user >/dev/null 2>&1 || true
  pnpm setup -y >/dev/null 2>&1 || true
  hash -r || true
  BIN_DIR="$(pnpm bin -g 2>/dev/null || true)"
  if [[ -z "$BIN_DIR" ]]; then
    warn "pnpm global bin directory not detected; PNPM_HOME=$PNPM_HOME"
    info "If globals are still not found later, open a new terminal or ensure ~/.zshrc sets PNPM_HOME and PATH."
  else
    info "pnpm global bin: $BIN_DIR"
  fi

  PNPM_PKGS=(typescript ts-node npm-check-updates mapshaper)
  total=${#PNPM_PKGS[@]}
  i=0
  for pkg in "${PNPM_PKGS[@]}"; do
    i=$((i+1))
    printf "[%d/%d] pnpm global %s\n" "$i" "$total" "$pkg"
    # Detect if already installed globally
    if pnpm ls -g --depth 0 2>/dev/null | grep -E "(^|[[:space:]])${pkg}@" >/dev/null 2>&1; then
      info "already installed: ${pkg}"
    else
      if pnpm add -g "$pkg"; then
        ok "installed: ${pkg}"
      else
        warn "failed installing: ${pkg} (continuing)"
      fi
    fi
  done
else
  warn "pnpm not found; skipping pnpm globals"
fi

# ---------------- (2/3) Python via pipx ----------------
step "Python dev tools via pipx (2/3)"
if command -v pipx >/dev/null 2>&1; then
  # Ensure pipx path is hooked into shell (no-op if already configured)
  pipx ensurepath >/dev/null 2>&1 || true
  # Make sure current session can see pipx-installed apps
  path_prepend "$HOME/.local/bin"

  PIPX_PKGS=(black ruff mypy pre-commit httpx)
  total=${#PIPX_PKGS[@]}
  i=0
  for pkg in "${PIPX_PKGS[@]}"; do
    i=$((i+1))
    printf "[%d/%d] pipx install %s\n" "$i" "$total" "$pkg"
    if pipx list --short 2>/dev/null | awk '{print $1}' | grep -qx "$pkg"; then
      info "already installed: ${pkg}"
    else
      if pipx install "$pkg"; then
        ok "installed: ${pkg}"
      else
        warn "failed installing: ${pkg} (continuing)"
      fi
    fi
  done
else
  warn "pipx not found; skipping Python dev tools"
fi

# ---------------- (3/3) uv hint ----------------
step "uv quick tip (3/3)"
if command -v uv >/dev/null 2>&1; then
  info "uv installed. Create a venv with:"
  info "  uv venv .venv && source .venv/bin/activate"
  ok "uv available"
else
  info "uv not found; install via Homebrew (stage 20) if you want super-fast venvs"
fi

ok "Languages & global tools configured"
