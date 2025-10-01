#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 50: Shell + Git setup (friendly output + auto GitHub key upload)
#  - Symlink dotfiles (.zshrc, .gitconfig)
#  - Make VS Code the default Git editor
#  - Ensure SSH key (ed25519), add to ssh-agent/Keychain
#  - Authentication is gh-only: run 'gh auth login' yourself (no PAT storage/import in this script)
# ----------------------------------------------------------
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOTDIR="$ROOT_DIR/dotfiles"
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh" 2>/dev/null || true

# --- Compatibility shims if _lib.sh is not loaded ---
if ! command -v step >/dev/null 2>&1; then step(){ printf "\n==> %s\n" "$*"; }; fi
if ! command -v info >/dev/null 2>&1; then info(){ printf "%s\n" "$*"; }; fi
if ! command -v ok   >/dev/null 2>&1; then ok(){ printf "✓ %s\n" "$*"; }; fi
if ! command -v warn >/dev/null 2>&1; then warn(){ printf "⚠ %s\n" "$*"; }; fi
if ! command -v err  >/dev/null 2>&1; then err(){ printf "✗ %s\n" "$*"; }; fi
if ! command -v run  >/dev/null 2>&1; then run(){ printf "+ %s\n" "$*"; "$@"; }; fi
if ! command -v require >/dev/null 2>&1; then require(){ command -v "$1" >/dev/null 2>&1 || { err "$1 not found"; exit 1; }; }; fi

# Prompts are limited to git identity if missing (no token handling in this script)
INTERACTIVE=1

# Ensure git user.name / user.email exist (prompt once if missing)
ensure_git_user(){
  local name email
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"
  if [[ -n "$name" && -n "$email" ]]; then
    info "git user.name/user.email already set"
    return 0
  fi
  if [[ $INTERACTIVE -eq 1 && -t 0 ]]; then
    if [[ -z "$name" ]]; then read -r -p "git user.name: " name; run git config --global user.name "$name"; fi
    if [[ -z "$email" ]]; then read -r -p "git user.email: " email; run git config --global user.email "$email"; fi
    ok "Configured git user.name/user.email"
  else
    warn "git user.name/email not set and prompts disabled; set via dotfiles or pass --set-git-user"
  fi
}

# ---------------- (1/4) Dotfiles ----------------
step "Shell & Git setup (1/4): configure dotfiles"
mkdir -p "$HOME"
if [[ -d "$DOTDIR" ]]; then
  # Always symlink .zshrc
  run ln -sf "$DOTDIR/.zshrc" "$HOME/.zshrc"

  # Prefer include-based Git config: ~/.gitconfig includes shared settings
  GITCFG_SHARED_SRC="$DOTDIR/.gitconfig.shared"
  GITCFG_FALLBACK_SRC="$DOTDIR/.gitconfig"
  GITCFG_DST="$HOME/.gitconfig"
  HOME_SHARED="$HOME/.gitconfig.shared"

  if [[ -r "$GITCFG_SHARED_SRC" ]]; then
    info "Configuring shared git settings via $HOME_SHARED"
    # Install or update a user-local copy of the shared config
    run install -m 0644 "$GITCFG_SHARED_SRC" "$HOME_SHARED"

    if [[ -f "$GITCFG_DST" ]]; then
      # If an include to any *.gitconfig.shared exists, normalize its path to $HOME_SHARED
      if grep -Eq '^\s*path\s*=.*\.gitconfig\.shared\s*$' "$GITCFG_DST" 2>/dev/null; then
        tmpfile="$(mktemp)"
        sed -E 's|^([[:space:]]*path[[:space:]]*=[[:space:]]*).*[/~A-Za-z0-9_.-]*/?\.gitconfig\.shared[[:space:]]*$|\1'"$HOME_SHARED"'|' "$GITCFG_DST" >"$tmpfile" || true
        run mv "$tmpfile" "$GITCFG_DST"
        ok "Normalized include path to $HOME_SHARED"
      else
        printf "\n[include]\n  path = %s\n" "$HOME_SHARED" >> "$GITCFG_DST"
        ok "Added include to existing ~/.gitconfig"
      fi
    else
      # Fresh file with include; user identity added by preflight or ensure_git_user
      cat >"$GITCFG_DST" <<EOF
[include]
  path = $HOME_SHARED
EOF
      ok "~/.gitconfig created with include → $HOME_SHARED"
    fi
  elif [[ -r "$GITCFG_FALLBACK_SRC" ]]; then
    warn ".gitconfig.shared not found; falling back to symlink of .gitconfig"
    run ln -sf "$GITCFG_FALLBACK_SRC" "$GITCFG_DST"
    ok "~/.gitconfig symlinked to $GITCFG_FALLBACK_SRC"
  else
    err "No gitconfig template found in $DOTDIR"
    exit 1
  fi

  ok "Dotfiles configured"
else
  warn "Dotfiles folder not found at $DOTDIR — skipping symlinks"
fi

# Optional: set git identity if missing (no token prompts)
ensure_git_user

# ---------------- (2/4) Git editor ----------------
step "Shell & Git setup (2/4): set VS Code as Git editor (if present)"
if command -v code >/dev/null 2>&1; then
  run git config --global core.editor "code --wait"
  ok "VS Code set as git editor"
else
  info "VS Code ('code') not on PATH — skip"
fi

# ---------------- (3/4) SSH key ----------------
step "Shell & Git setup (3/4): ensure SSH key"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
EMAIL="$(git config --global user.email 2>/dev/null || true)"
if [[ -z "${EMAIL}" ]]; then EMAIL="$USER@$(scutil --get LocalHostName 2>/dev/null || hostname)"; fi
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  info "Generating new ed25519 key for $EMAIL"
  run ssh-keygen -t ed25519 -C "$EMAIL" -N "" -f "$HOME/.ssh/id_ed25519"
else
  info "SSH key already exists — skipping generation"
fi
chmod 600 "$HOME/.ssh/id_ed25519" 2>/dev/null || true
chmod 644 "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true

# Add to ssh-agent and Keychain (macOS). Try modern flag first, then legacy.
if pgrep -q ssh-agent 2>/dev/null || ssh-add -l >/dev/null 2>&1; then :; fi
ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null || \
  ssh-add -K "$HOME/.ssh/id_ed25519" 2>/dev/null || true

# ---------------- (4/4) Upload to GitHub ----------------
step "Shell & Git setup (4/4): upload SSH public key to GitHub"
PUBKEY_PATH="$HOME/.ssh/id_ed25519.pub"
require ssh
require ssh-keygen
if [[ ! -f "$PUBKEY_PATH" ]]; then err "Public key missing at $PUBKEY_PATH"; exit 1; fi

TITLE="$(scutil --get ComputerName 2>/dev/null || hostname)-$(date +%Y%m%d-%H%M%S)"
PUB="$(cat "$PUBKEY_PATH")"

# gh-only authentication: user performs 'gh auth login' manually
if ! command -v gh >/dev/null 2>&1; then
  warn "GitHub CLI (gh) not found — install with: brew install gh"
else
  if gh auth status -h github.com >/dev/null 2>&1; then
    info "gh is authenticated; adding SSH key to your GitHub account"
    if gh ssh-key add "$PUBKEY_PATH" -t "$TITLE" --type authentication; then
      ok "SSH key uploaded via gh CLI"
    else
      warn "Failed to upload key via gh (it may already exist). You can manage keys in GitHub → Settings → SSH and GPG keys."
    fi
  else
    warn "gh is not authenticated."
    info "Run: gh auth login -h github.com -p https -s admin:public_key"
    info "Then re-run: scripts/50_shell_git.sh"
  fi
fi

# Always show the public key so the user can copy if needed
info "\n👉 SSH public key (add to GitHub if needed):"
cat "$PUBKEY_PATH" || true

ok "Shell + Git setup complete"
if command -v gh >/dev/null 2>&1; then
  gh auth status -h github.com || true  # informational; don't fail the stage
fi
