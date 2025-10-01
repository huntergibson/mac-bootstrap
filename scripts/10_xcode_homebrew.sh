#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 10: Ensure Xcode Command Line Tools and Homebrew
#  - Installs CLT (compilers, git) and waits until complete
#  - Installs Homebrew and puts it on PATH for this shell
#  - Clear progress, error handling, and friendly messages
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
if ! command -v run  >/dev/null 2>&1; then
  run(){
    local comment=""
    if [[ "${1:-}" == "--comment" ]]; then
      comment="$2"
      shift 2
    fi
    if [[ -n "$comment" ]]; then
      info "$comment"
    fi
    if [[ $# -eq 0 ]]; then
      err "run requires a command"
      return 1
    fi
    printf "+"
    for arg in "$@"; do
      printf " %q" "$arg"
    done
    printf "\n"
    "$@"
  }
fi

has_clt(){
  xcode-select -p >/dev/null 2>&1 || [[ -d "/Library/Developer/CommandLineTools" ]]
}

wait_for_clt(){
  local timeout=1800  # 30 minutes
  local interval=5
  local waited=0
  local spin='|/-\\'
  local i=0
  while ! has_clt; do
    if (( waited >= timeout )); then return 1; fi
    printf "\r   Waiting for Xcode Command Line Tools to finish installing %s" "${spin:i++%4:1}"
    sleep "$interval"; waited=$((waited+interval))
  done
  printf "\r"
  return 0
}

# ---------------- (1/3) Xcode Command Line Tools ----------------
step "Xcode Command Line Tools (1/3)"
if has_clt; then
  ok "CLT already installed"
else
  info "Triggering macOS installer (you may see a popup — click Install)"
  # This command opens the Software Update dialog; it may exit nonzero even when it succeeded in opening the UI.
  xcode-select --install >/dev/null 2>&1 || true
  step "Waiting for CLT to complete (polling)"
  if wait_for_clt; then
    ok "CLT installation detected"
  else
    err "Timed out waiting for CLT. Open System Settings → Software Update and install 'Command Line Tools'."
    exit 1
  fi
fi

# ---------------- (2/3) Homebrew ----------------
step "Homebrew (2/3)"
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew (non‑interactive)"
  export NONINTERACTIVE=1
  # Prefer /usr/bin/curl if PATH isn't ready
  CURL_BIN="$(command -v curl || echo /usr/bin/curl)"
  if [[ ! -x "$CURL_BIN" ]]; then
    err "curl not found; cannot download Homebrew installer"
    exit 1
  fi
  if /bin/bash -c "$("$CURL_BIN" -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    ok "Homebrew installed"
  else
    err "Homebrew installer failed"
    exit 1
  fi
fi

# Ensure brew is on PATH for this shell
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$('/opt/homebrew/bin/brew' shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$('/usr/local/bin/brew' shellenv)"
fi

# Fix common Homebrew permission issues (happens if setup was run via sudo)
fix_homebrew_permissions(){
  command -v brew >/dev/null 2>&1 || return
  local prefix
  prefix="$(brew --prefix 2>/dev/null || true)"
  [[ -n "$prefix" && -d "$prefix" ]] || return

  local current_user current_group needs_fix="0"
  current_user="$(id -un)"
  current_group="$(id -gn)"

  # Check a handful of paths that Homebrew expects to be writable
  local dir
  for dir in "$prefix" "$prefix/Cellar" "$prefix/Caskroom" "$prefix/Homebrew"; do
    if [[ -e "$dir" && ! -w "$dir" ]]; then
      needs_fix="1"
      break
    fi
  done

  if [[ "$needs_fix" != "1" ]]; then
    info "Homebrew directories already writable by $current_user"
    return 0
  fi

  warn "Homebrew directory permissions look incorrect; fixing with sudo."
  run sudo chown -R "$current_user:$current_group" "$prefix"
}

fix_homebrew_permissions

# Verify brew and update
if command -v brew >/dev/null 2>&1; then
  info "brew: $(brew --version | head -n1)"
  if brew update >/dev/null 2>&1; then
    ok "Homebrew updated"
  else
    warn "brew update failed; network issues or permissions?"
  fi
else
  err "brew not found on PATH after install"
  exit 1
fi

ok "Stage 10 complete"
