#!/usr/bin/env bash
# Stage 20: Install all packages/apps from Brewfile (friendly output, sudo keepalive, Keychain optional)
set -uo pipefail

BFILE="$(cd "$(dirname "$0")/.." && pwd)/Brewfile"
[ -f "$BFILE" ] || { echo "Brewfile not found at $BFILE" >&2; exit 1; }

# ---------- Pretty output ----------
if [ -t 1 ]; then RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'; else RED=; GREEN=; YELLOW=; BLUE=; BOLD=; DIM=; RESET=; fi
say()  { printf "%b\n" "$1"; }
sec()  { printf "\n${BOLD}%s${RESET}\n" "$1"; }
info() { printf "${DIM}→ %s${RESET}\n" "$1"; }
ok()   { printf "${GREEN}✓ %s${RESET}\n" "$1"; }
warn() { printf "${YELLOW}⚠ %s${RESET}\n" "$1"; }
err()  { printf "${RED}✗ %s${RESET}\n" "$1"; }

# ---------- Ensure Homebrew on PATH ----------
if ! command -v brew >/dev/null 2>&1; then
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$p" ] && eval "$($p shellenv)" && break; done
fi
command -v brew >/dev/null 2>&1 || { err "Homebrew not found. Install from https://brew.sh"; exit 1; }

# ---------- Optional: use Keychain for one-time sudo caching ----------
# If you store your admin password in Login Keychain with service "mac-bootstrap-sudo",
# this block will cache sudo without prompting (safer than env vars).
try_keychain_sudo() {
  if security find-generic-password -a "$USER" -s mac-bootstrap-sudo -w >/dev/null 2>&1; then
    ASK="/tmp/mb2_askpass_$$.sh"
    umask 077
    cat >"$ASK" <<'EOF'
#!/usr/bin/env bash
security find-generic-password -a "$USER" -s mac-bootstrap-sudo -w 2>/dev/null
EOF
    chmod 700 "$ASK"
    export SUDO_ASKPASS="$ASK"
    sudo -A -v && return 0
  fi
  return 1
}

# Cache sudo once & keep alive if we're an admin user
if id -Gn | grep -qw admin; then
  sec "Authenticating admin (one time)"
  if try_keychain_sudo; then
    ok "Using Keychain for sudo (no prompt)"
  else
    info "Enter password once to cache sudo (recommended)."
    sudo -v || warn "Could not cache sudo; some casks may prompt later."
  fi
  # Quiet, background sudo keep-alive (no job-control termination message)
  set +m
  keep_sudo_alive() { while true; do sudo -n true 2>/dev/null || exit; sleep 60; done; }
  keep_sudo_alive >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID=$!
  disown "$SUDO_KEEPALIVE_PID"
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true; wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true; [ -n "${SUDO_ASKPASS:-}" ] && rm -f "${SUDO_ASKPASS}"' EXIT
fi

# ---------- Update Homebrew ----------
sec "Updating Homebrew"
export HOMEBREW_NO_EMOJI=1
brew update || warn "brew update failed; continuing"

# ---------- Ensure taps (including fonts if requested) ----------
sec "Ensuring taps"
TAPS=$(awk -F '"' '/^[[:space:]]*tap[[:space:]]*/{print $2}' "$BFILE" | sort -u)
for t in $TAPS; do
  [ -z "$t" ] && continue
  if [ "$t" = "homebrew/cask-fonts" ]; then warn "skipping deprecated tap $t"; continue; fi; if brew tap | grep -qx "$t"; then info "tap $t (already tapped)"; else info "tap $t"; brew tap "$t" || warn "failed tapping $t"; fi
done

# ---------- Helpers: detect already-installed GUI apps ----------
cask_app_path() {
  case "$1" in
    google-chrome) echo "/Applications/Google Chrome.app";;
    arc) echo "/Applications/Arc.app";;
    visual-studio-code) echo "/Applications/Visual Studio Code.app";;
    warp) echo "/Applications/Warp.app";;
    docker) echo "/Applications/Docker.app";;
    cursor) echo "/Applications/Cursor.app";;
    kiro) echo "/Applications/Kiro.app";;
    dbeaver-community) echo "/Applications/DBeaver.app";;
    notion) echo "/Applications/Notion.app";;
    microsoft-excel) echo "/Applications/Microsoft Excel.app";;
    microsoft-word) echo "/Applications/Microsoft Word.app";;
    microsoft-powerpoint) echo "/Applications/Microsoft PowerPoint.app";;
    onedrive) echo "/Applications/OneDrive.app";;
    notion-calendar) echo "/Applications/Notion Calendar.app";;
    github) echo "/Applications/GitHub Desktop.app";;
    chrome-remote-desktop-host) echo "";; # no .app bundle
    raspberry-pi-imager) echo "/Applications/Raspberry Pi Imager.app";;
    telegram) echo "/Applications/Telegram.app";;
    whatsapp) echo "/Applications/WhatsApp.app";;
    discord) echo "/Applications/Discord.app";;
    spotify) echo "/Applications/Spotify.app";;
    raycast) echo "/Applications/Raycast.app";;
    rectangle) echo "/Applications/Rectangle.app";;
    monitorcontrol) echo "/Applications/MonitorControl.app";;
    hiddenbar) echo "/Applications/Hidden Bar.app";;
    stats) echo "/Applications/Stats.app";;
    *) echo "";;
  esac
}

is_cask_present_locally() {
  local p; p="$(cask_app_path "$1")"
  if [ -n "$p" ]; then
    if [ -d "$p" ]; then echo "$p"; return 0; fi
    if [ -d "$HOME/Applications/$(basename "$p")" ]; then echo "$HOME/Applications/$(basename "$p")"; return 0; fi
  fi
  return 1
}

# ---------- Read items from Brewfile ----------
FORMULAE=$(awk -F '"' '/^[[:space:]]*brew[[:space:]]*/{print $2}' "$BFILE")
CASKS=$(awk -F '"' '/^[[:space:]]*cask[[:space:]]*/{print $2}' "$BFILE")
FCOUNT=$(printf "%s\n" "$FORMULAE" | sed '/^$/d' | wc -l | tr -d ' ')
CCOUNT=$(printf "%s\n" "$CASKS" | sed '/^$/d' | wc -l | tr -d ' ')
TOTAL=$(( FCOUNT + CCOUNT ))
COUNT=0
FAILED=()

sec "Installing $TOTAL items from Brewfile"

for name in $FORMULAE; do
  COUNT=$((COUNT+1))
  printf "${BLUE}[%d/%d]${RESET} formula %s\n" "$COUNT" "$TOTAL" "$name"
  if brew list --formula "$name" >/dev/null 2>&1; then ok "$name already installed"; continue; fi
  if brew install "$name"; then ok "$name installed"; else err "$name failed"; FAILED+=("brew:$name"); fi
done

for name in $CASKS; do
  COUNT=$((COUNT+1))
  printf "${BLUE}[%d/%d]${RESET} cask %s\n" "$COUNT" "$TOTAL" "$name"
  if brew list --cask "$name" >/dev/null 2>&1; then
    ok "$name already installed"
    continue
  fi
  if localpath=$(is_cask_present_locally "$name"); then
    ok "$name already installed (found at $localpath)"
    continue
  fi
  output="$(brew install --cask "$name" 2>&1)"; status=$?
  printf "%s\n" "$output" | sed 's/^/    /'
  if [ $status -ne 0 ]; then
    if printf "%s" "$output" | grep -qiE 'already an App at|already installed|newer version .* already installed'; then
      ok "$name already installed"
    else
      err "$name failed"; FAILED+=("cask:$name")
    fi
  else
    ok "$name installed"
  fi
done

sec "Cleanup"
brew cleanup -s || warn "cleanup failed"

if [ ${#FAILED[@]} -gt 0 ]; then
  sec "Summary"
  err "The following items failed:"
  for f in "${FAILED[@]}"; do echo "  $f"; done
  exit 1
else
  sec "All done"
  ok "Everything installed from Brewfile."
fi