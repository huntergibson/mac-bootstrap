#!/usr/bin/env bash
# ----------------------------------------------------------
# Bootstrap orchestrator
#  - Requests sudo keepalive (one prompt; hands‑off run)
#  - Installs Rosetta 2 on Apple Silicon if missing
#  - Runs all stage scripts with unified, friendly logs
# ----------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Shared logging helpers (prefer library; fall back to shims)
if [[ -f "$SCRIPT_DIR/scripts/_lib.sh" ]]; then
  . "$SCRIPT_DIR/scripts/_lib.sh"
else
  step(){ printf "\n==> %s\n" "$*"; }
  ok(){   printf "✓ %s\n" "$*"; }
  warn(){ printf "⚠ %s\n" "$*"; }
  info(){ printf "%s\n" "$*"; }
  err(){  printf "✗ %s\n" "$*"; }
  die(){  err "$*"; exit 1; }
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

# Nicer failure message if anything errors out
trap 'err "Bootstrap failed (line $LINENO). See logs above."; exit 1' ERR

step "Requesting sudo keepalive"
info "Keeping sudo credentials fresh so later steps run without extra prompts."
info "Enter your password once; I will keep sudo fresh during the run."
if ! sudo -v; then die "sudo required"; fi
# Keep sudo alive until this script exits
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

# ---------------- Preflight: Git identity (do this first) ----------------
step "Preflight: Git identity"
info "Checking that git commits will have the correct author name and email."
GNAME="$(git config --global user.name 2>/dev/null || true)"
GMAIL="$(git config --global user.email 2>/dev/null || true)"
if [[ -z "$GNAME" || -z "$GMAIL" ]]; then
  info "git user.name/email not set. Configure now so later steps don't prompt."
  if [[ -t 0 ]]; then
    if [[ -z "$GNAME" ]]; then read -r -p "  Your name for Git commits: " GNAME && run git config --global user.name "$GNAME"; fi
    if [[ -z "$GMAIL" ]]; then read -r -p "  Your email for Git commits: " GMAIL && run git config --global user.email "$GMAIL"; fi
    ok "Git identity configured"
  else
    warn "Non-interactive shell detected; skipping prompts. Set later with: git config --global user.name 'Your Name'; git config --global user.email you@example.com"
  fi
else
  ok "Git identity already set"
fi

# Rosetta for Apple Silicon (if needed)
if [[ "$(uname -m)" == "arm64" ]]; then
  step "Rosetta 2 check"
  if /usr/bin/pgrep oahd >/dev/null 2>&1; then
    info "Rosetta already present"
  else
    info "Installing Rosetta 2 (accept license if prompted)"
    run softwareupdate --install-rosetta --agree-to-license
  fi
fi

step "Stage 10: Xcode Command Line Tools & Homebrew"
info "Install Apple's developer tools and make sure Homebrew is ready to use."
run --comment "Run Stage 10 automation" "$SCRIPT_DIR/scripts/10_xcode_homebrew.sh"

step "Stage 20: Install apps with Homebrew Bundle"
info "Install command-line tools and apps listed in the Brewfile."
run --comment "Apply Brewfile bundle" "$SCRIPT_DIR/scripts/20_brew_bundle.sh"

# ---------------- Preflight: GitHub auth (optional, early) ----------------
if command -v gh >/dev/null 2>&1; then
  step "Preflight: GitHub CLI authentication (optional)"
  if gh auth status -h github.com >/dev/null 2>&1; then
    ok "gh is already authenticated"
  else
    info "We'll launch 'gh auth login' so SSH key upload works later."
    info "You can skip with Ctrl+C; the rest of the setup will continue."
    if [[ -t 0 ]]; then
      run gh auth login -h github.com -p https -s admin:public_key || warn "gh auth login was skipped or failed; you can run it later"
    else
      warn "Non-interactive shell; skipping gh auth. Run later: gh auth login -h github.com -p https -s admin:public_key"
    fi
  fi
fi

# ---------------- Preflight: Automation permission (optional) ----------------
# Trigger Automation permission prompts up front so wallpaper/Dock steps don't pause later.
step "Preflight: macOS Automation permission (optional)"
info "If prompted, allow Terminal to control Finder/System Events."
osascript -e 'tell application "System Events" to get count of desktops' >/dev/null 2>&1 || true
osascript -e 'tell application "Finder" to get name of startup disk' >/dev/null 2>&1 || true

step "Stage 30: macOS defaults"
info "Apply opinionated macOS preferences (Dock, Finder, screenshots, etc.)."
run --comment "Apply macOS defaults" "$SCRIPT_DIR/scripts/30_macos_defaults.sh"

step "Stage 40: Dock customization"
info "Rebuild the Dock with curated apps and layout."
run --comment "Customize the Dock" "$SCRIPT_DIR/scripts/40_dock.sh"

step "Stage 45: Wallpaper"
info "Copy the curated wallpaper and refresh desktops across Spaces."
run --comment "Apply wallpaper and refresh desktops" bash "$SCRIPT_DIR/scripts/45_wallpaper.sh"

step "Stage 50: Shell & Git setup"
info "Install shell tools, prompt, and baseline git configuration."
run --comment "Configure shell and git" "$SCRIPT_DIR/scripts/50_shell_git.sh"

step "Stage 55: Create ~/Code folders"
info "Create a tidy ~/Code directory tree for organizing projects."
run --comment "Create Code workspace folders" "$SCRIPT_DIR/scripts/55_code_folders.sh"

step "Stage 70: Languages & global dev tools"
info "Install language runtimes and widely-used developer tooling."
run --comment "Install language runtimes and tooling" "$SCRIPT_DIR/scripts/70_languages.sh"

step "Stage 80: Services (no persistent DB)"
info "Set up supporting services needed for local development (non-persistent)."
run --comment "Configure lightweight services" "$SCRIPT_DIR/scripts/80_services.sh"

step "Stage 90: VS Code extensions, settings & keybindings"
info "Install VS Code extensions and apply editor settings/keybindings."
run --comment "Apply VS Code configuration" "$SCRIPT_DIR/scripts/90_postinstall.sh"

ok "All done. Some changes may need a logout/restart."
