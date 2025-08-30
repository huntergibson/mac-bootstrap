#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 50: Shell + Git setup
#  - Symlink dotfiles (.zshrc, .gitconfig)
#  - Make VS Code the default Git editor
#  - Generate SSH key (ed25519) if missing and print public key
# ----------------------------------------------------------
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/.." && pwd)/dotfiles"

# Symlink dotfiles (idempotent: -f replaces existing links/files)
ln -sf "$DOTDIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTDIR/.gitconfig" "$HOME/.gitconfig"

# Make VS Code the default Git editor if available
if command -v code >/dev/null 2>&1; then
  git config --global core.editor "code --wait"
fi

# Generate SSH key if none, and print pubkey for GitHub
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "your_email@example.com" -N "" -f "$HOME/.ssh/id_ed25519"
fi

echo "
👉 Add this SSH public key to GitHub (Settings → SSH keys):"
cat "$HOME/.ssh/id_ed25519.pub" || true
