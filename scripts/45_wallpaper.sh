#!/usr/bin/env bash
# Stage 45: Apply wallpaper (after Dock), robust across Spaces/DB
set -euo pipefail

. "$(cd "$(dirname "$0")" && pwd)/_lib.sh" 2>/dev/null || true
if ! command -v step >/dev/null 2>&1; then step(){ printf "\n==> %s\n" "$*"; }; fi
if ! command -v info >/dev/null 2>&1; then info(){ printf "%s\n" "$*"; }; fi
if ! command -v ok   >/dev/null 2>&1; then ok(){ printf "✓ %s\n" "$*"; }; fi
if ! command -v warn >/dev/null 2>&1; then warn(){ printf "⚠ %s\n" "$*"; }; fi
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
      warn "run requires a command"
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

# Args: optional --flash for a brief solid color to confirm change
FLASH=0
for arg in "$@"; do
  case "$arg" in
    --flash) FLASH=1 ;;
  esac
done

MECH=""
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WALL_SRC="$REPO_DIR/assets/wallpapers/default.jpg"
WALL_DST="$HOME/Pictures/Wallpapers/default.jpg"

list_desktop_pictures(){
  osascript <<'OSA' 2>/dev/null || true
  try
    tell application "System Events"
      set picturePaths to {}
      repeat with d in desktops
        copy POSIX path of (picture of d) to end of picturePaths
      end repeat
      set oldDelims to AppleScript's text item delimiters
      set AppleScript's text item delimiters to "\n"
      set joined to picturePaths as text
      set AppleScript's text item delimiters to oldDelims
      return joined
    end tell
  on error
    return ""
  end try
OSA
}

set_wallpaper_with_system_events(){
  local target="$1"
  info "Attempting to set wallpaper via System Events for every desktop."
  osascript - "$target" <<'OSA' || return 1
on run argv
  set targetPath to POSIX file (item 1 of argv)
  tell application "System Events"
    repeat with d in desktops
      set picture of d to targetPath
    end repeat
  end tell
end run
OSA
}

wallpaper_already_applied(){
  local target="$1"
  local matches=0
  local lines
  lines="$(list_desktop_pictures)"
  [[ -z "$lines" ]] && return 1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == "$target" ]]; then
      matches=1
      break
    fi
  done <<<"$lines"
  [[ $matches -eq 1 ]]
}

if [[ ! -f "$WALL_SRC" ]]; then
  warn "Wallpaper not found at $WALL_SRC (skipping)"
  exit 0
fi

step "Applying wallpaper (1/3)"
info "Copying the curated wallpaper into $WALL_DST so Finder can access it."
run --comment "Ensure wallpaper destination directory exists" mkdir -p "$(dirname "$WALL_DST")"
run --comment "Copy wallpaper asset into destination" cp -f "$WALL_SRC" "$WALL_DST"
info "Target wallpaper: $WALL_DST"

# Optional: flash a bright solid color first so the change is obvious
if [[ $FLASH -eq 1 ]]; then
  info "Flashing a temporary solid color so the wallpaper change stands out."
  for f in "Electric Blue.png" "Yellow.png" "Cyan.png" "Black.png"; do
    if [[ -f "/System/Library/Desktop Pictures/Solid Colors/$f" ]]; then
      info "Temporarily setting desktop to solid color: $f"
      osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"/System/Library/Desktop Pictures/Solid Colors/$f"'"' || true
      info "Restarting Dock to display the temporary solid color."
      killall Dock >/dev/null 2>&1 || true
      sleep 2
      break
    fi
  done
fi

# Prefer Dock DB updates across all DBs (avoids Automation prompts)
UPDATED_DB=0
if command -v sqlite3 >/dev/null 2>&1; then
  DOCK_DIR="$HOME/Library/Application Support/Dock"
  if [[ -d "$DOCK_DIR" ]]; then
    info "Updating Dock desktop picture databases directly when present."
    ESCAPED_DST=$(printf "%s" "$WALL_DST" | sed "s/'/''/g")
    shopt -s nullglob
    DBS=("$DOCK_DIR"/*desktoppicture*.db)
    shopt -u nullglob
    if (( ${#DBS[@]} > 0 )); then
      for DB in "${DBS[@]}"; do
        info "Setting wallpaper path inside: $DB"
        run --comment "Write wallpaper path into Dock database" sqlite3 "$DB" "update data set value = '$ESCAPED_DST'" || true
      done
      UPDATED_DB=1
      MECH="DockDB"
    else
      info "No Dock desktop picture databases found; falling back to Finder automation."
    fi
  else
    info "Dock support directory missing; falling back to Finder automation."
  fi
else
  info "sqlite3 not available; using Finder automation instead."
fi

if [[ "$UPDATED_DB" -ne 1 ]]; then
  info "Using Finder AppleScript to set the wallpaper (you may see an Automation prompt)."
  if osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$WALL_DST"'"'; then
    MECH="Finder"
  else
    warn "AppleScript failed; open System Settings → Privacy & Security → Automation to grant permission."
    run --comment "Open Automation privacy settings" open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation" || true
  fi
fi

if ! wallpaper_already_applied "$WALL_DST"; then
  warn "Wallpaper verification failed; this usually means macOS blocked automation."
  if set_wallpaper_with_system_events "$WALL_DST"; then
    MECH="${MECH:+$MECH+}SystemEvents"
  else
    warn "System Events automation could not apply the wallpaper."
  fi
fi

step "Finalizing wallpaper via preferences (2/3)"
info "Writing host-specific wallpaper preferences so future Spaces inherit the image."
TMP_PLIST="$(mktemp -t com.apple.desktop.XXXXXX.plist)"
if ! defaults -currentHost export com.apple.desktop "$TMP_PLIST" 2>/dev/null; then
  info "No existing wallpaper preferences detected; seeding a minimal plist."
  cat >"$TMP_PLIST" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
PLIST
fi
info "Ensuring Background preference dictionary exists"
/usr/libexec/PlistBuddy -c "Add :Background dict" "$TMP_PLIST" 2>/dev/null || true
info "Ensuring Background:default dictionary exists"
/usr/libexec/PlistBuddy -c "Add :Background:default dict" "$TMP_PLIST" 2>/dev/null || true
info "Recording wallpaper path inside the preferences plist"
/usr/libexec/PlistBuddy -c "Set :Background:default:ImageFilePath '$WALL_DST'" "$TMP_PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :Background:default:ImageFilePath string '$WALL_DST'" "$TMP_PLIST"
info "Locking wallpaper change frequency to Never"
/usr/libexec/PlistBuddy -c "Set :Background:default:Change Never" "$TMP_PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :Background:default:Change string Never" "$TMP_PLIST"
run --comment "Import wallpaper preferences for the current host" defaults -currentHost import com.apple.desktop "$TMP_PLIST"
run --comment "Remove temporary wallpaper preference file" rm -f "$TMP_PLIST"
info "Restarting cfprefsd to flush wallpaper preferences"
killall cfprefsd >/dev/null 2>&1 || true
info "Wallpaper preference written for current host"

step "Refreshing UI (3/3)"
info "Restarting key macOS services so the wallpaper shows everywhere."
info "Restarting Dock to apply wallpaper"
killall Dock >/dev/null 2>&1 || true
info "Restarting Finder to refresh desktop icons"
killall Finder >/dev/null 2>&1 || true
info "Restarting SystemUIServer to refresh menu bar"
killall SystemUIServer >/dev/null 2>&1 || true

CURRENT_WALLS="$(list_desktop_pictures)"
if [[ -n "$CURRENT_WALLS" ]]; then
  idx=1
  while IFS= read -r wall; do
    [[ -z "$wall" ]] && continue
    info "Final wallpaper (Desktop $idx): $wall"
    idx=$((idx+1))
  done <<<"$CURRENT_WALLS"
else
  warn "Could not query current desktop wallpapers (Automation permission?)."
fi
[ -n "${MECH:-}" ] && info "Wallpaper mechanism: $MECH"

ok "Wallpaper applied"
