# 🧰 Mac Dev Bootstrap

A clean, one‑command setup for a fresh Mac tailored to **your** stack: Chrome + Arc, Warp, VS Code, Docker Desktop, Postgres + DBeaver, Notion & Office, plus sensible macOS defaults, Dock layout, VS Code extensions/settings, and a tidy `~/Code` structure.

<p align="left">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white">
  <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple%20Silicon-yes-111?logo=apple&logoColor=white">
  <img alt="Homebrew" src="https://img.shields.io/badge/Homebrew-bundle-111?logo=homebrew">
  <img alt="VS Code" src="https://img.shields.io/badge/VS%20Code-configured-007ACC?logo=visualstudiocode">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-Desktop-0db7ed?logo=docker">
  <a href="./LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-green.svg"></a>
</p>

---

## ✨ Features
- **One‑liner install** that sets up dev tools, apps, and preferences
- **Homebrew Bundle** to install/categorize apps & CLIs
- **Finder/Dock defaults** + curated Dock (Chrome → Notion → VS Code → Excel)
- **VS Code**: your extensions auto‑install, key settings applied, **Shift+Enter** runs selection in Jupyter Interactive (Python)
- **Languages**: Node (via `fnm` + `pnpm`), Python (via `uv` & helpers)
- **Databases**: PostgreSQL 16 (brew service), DBeaver GUI
- **Code folders**: `~/Code/{personal, work, sandbox, archived}` created on first run
- **Heavily commented** scripts & Brewfile so future‑you knows what's what

---

## 🚀 Quick start

### One‑liner (recommended)
```bash
git clone https://github.com/YOUR_GITHUB_USER/mac-bootstrap.git && cd mac-bootstrap && ./bootstrap.sh
```

> Tip: After the run, sign into apps on first launch (Chrome, Arc, Docker Desktop, Excel/Word/PowerPoint, Notion, OneDrive, Discord, Spotify, Chrome Remote Desktop).

### What it installs (high level)
- **Browsers**: Chrome, Arc
- **IDEs/Terminal**: VS Code, Warp, Cursor, Kiro
- **Containers**: Docker Desktop
- **Data/DB**: DBeaver, PostgreSQL 16
- **Productivity**: Notion, Notion Calendar, Office (Excel/Word/PowerPoint), OneDrive, GitHub Desktop, Chrome Remote Desktop Host, Raspberry Pi Imager
- **Comms/Media**: Telegram, WhatsApp, Discord, Spotify
- **CLIs**: git, gh, jq, ripgrep, fd, eza, bat, fzf, zoxide, tree, wget, httpie, tldr, git-delta
- **JS/Python**: fnm, pnpm, uv (+ a `mkvenv` helper); `pnpm` installs **mapshaper** globally
- **Fonts**: JetBrains Mono Nerd Font (for pretty icons/ligatures)

Full list lives in the [Brewfile](./Brewfile) (categorized & commented).

---

## 🧪 Safe testing (no risk to your main account)
1. **Create a new macOS user** (Admin) named “Bootstrap Test” and log into it.
2. Clone this repo and run stages individually before the full bootstrap:
   ```bash
   ./scripts/30_macos_defaults.sh     # Finder/Dock defaults
   ./scripts/40_dock.sh               # Dock layout
   ./scripts/90_postinstall.sh        # VS Code extensions/settings
   ./scripts/10_xcode_homebrew.sh     # CLT + Homebrew
   ./scripts/20_brew_bundle.sh        # installs apps/CLIs from Brewfile
   ```
3. Want GUI apps to land in **~/Applications** while testing?
   - Run: `brew install --cask --appdir=~/Applications <app>` or add `cask_args appdir: "~/Applications"` at the top of the Brewfile temporarily.
4. Rollback examples (only affect the test user):
   ```bash
   defaults delete com.apple.dock; killall Dock     # reset Dock
   defaults write com.apple.finder AppleShowAllFiles -bool false; killall Finder
   rm -f ~/Library/Application\ Support/Code/User/{settings,keybindings}.json
   ```

---

## 🛠️ Customize
- **Apps/CLIs** → edit [Brewfile](./Brewfile). It’s split into clear sections.
- **macOS defaults** → tweak [scripts/30_macos_defaults.sh](./scripts/30_macos_defaults.sh).
- **Dock** → edit [scripts/40_dock.sh](./scripts/40_dock.sh) (uses `dockutil`).
- **VS Code** → extensions & settings in [scripts/90_postinstall.sh](./scripts/90_postinstall.sh).
- **Languages** → Node/Python bits in [scripts/70_languages.sh](./scripts/70_languages.sh).
- **Folders** → adjust `~/Code` layout in [scripts/55_code_folders.sh](./scripts/55_code_folders.sh).

---

## 🧯 Troubleshooting
- **VS Code CLI not found**: Open VS Code once → Command+Shift+P → “Shell Command: Install ‘code’ in PATH”, then re‑run `scripts/90_postinstall.sh`.
- **Homebrew not on PATH**: open a new terminal or `eval "$('/opt/homebrew/bin/brew' shellenv)"`.
- **TCC prompts (Accessibility, Screen Recording)**: approve manually when prompted—macOS requires your consent.
- **Office sign‑in**: open Excel/Word/PowerPoint and sign in with your license.

---

## 🗑️ Uninstall / rollback (selective)
- **A cask app**: `brew uninstall --cask <token>` (then remove leftovers in `~/Library/Application Support/<App>` if desired).
- **A formula/CLI**: `brew uninstall <formula>`; remove symlinks with `brew cleanup`.
- **VS Code settings**: remove `~/Library/Application Support/Code/User/settings.json` or `keybindings.json` in the *test* account.

---

## 📜 License
MIT — see [LICENSE](./LICENSE).

---

### Credits
- Uses Homebrew, `dockutil`, VS Code, and AppleScript to automate a consistent macOS dev environment.
