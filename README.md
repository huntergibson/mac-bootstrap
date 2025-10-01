# 🧰 mac-bootstrap

Spin up a repeatable, opinionated macOS dev environment from scratch. One command installs Xcode tools, Homebrew apps, language runtimes, editors, shell tweaks, wallpaper, and Dock layout so you can start building immediately.

> **One-liner:**
> ```bash
> git clone https://github.com/huntergibson/mac-bootstrap.git && cd mac-bootstrap && ./bootstrap.sh
> ```

The orchestrator walks through each stage with plain-English logging and smart fallbacks (permission checks, automation prompts, retries). You can rerun any stage safely—everything is idempotent.

---

## 📦 Stage-by-stage tour

| Stage | Script | What it does |
|-------|--------|--------------|
| Preflight | `bootstrap.sh` | Keeps `sudo` fresh, confirms Git identity, optional `gh auth login`, nudges macOS Automation permissions. |
| 10 | [`scripts/10_xcode_homebrew.sh`](scripts/10_xcode_homebrew.sh) | Installs Xcode Command Line Tools, bootstraps Homebrew, fixes permissions if needed, updates brew, and exports the shell environment. |
| 20 | [`scripts/20_brew_bundle.sh`](scripts/20_brew_bundle.sh) | Applies the Brewfile (48 curated apps/CLIs) with friendly progress, sudo keychain caching, cleanup hints, and per-item logging. |
| 30 | [`scripts/30_macos_defaults.sh`](scripts/30_macos_defaults.sh) | Tweaks Finder (show hidden files, path bar), screenshot location, and other sensible macOS defaults. |
| 40 | [`scripts/40_dock.sh`](scripts/40_dock.sh) | Sets Dock icon size to 50%, disables auto-hide & suggestions, clears current items, then rebuilds the Dock with Chrome → Notion → VS Code → Excel in that order. |
| 45 | [`scripts/45_wallpaper.sh`](scripts/45_wallpaper.sh) | Copies the bundled wallpaper, updates Dock DBs, falls back to Finder/System Events, writes ByHost prefs, and restarts UI services. Includes verification + `--flash` option. |
| 50 | [`scripts/50_shell_git.sh`](scripts/50_shell_git.sh) | Symlinks `.zshrc`, installs shared Git config, ensures SSH keys, sets VS Code as the Git editor, uploads the key with `gh` if available. |
| 55 | [`scripts/55_code_folders.sh`](scripts/55_code_folders.sh) | Creates `~/Code/{personal,work,sandbox,archived}` with helpful logging, leaving existing folders untouched. |
| 70 | [`scripts/70_languages.sh`](scripts/70_languages.sh) | Installs Node LTS via `fnm`, configures global `pnpm` packages, bootstraps Python tooling with `pipx`, and advertises `uv` usage. |
| 80 | [`scripts/80_services.sh`](scripts/80_services.sh) | Summarises background services (e.g., Supabase CLI) and points out anything missing. |
| 90 | [`scripts/90_postinstall.sh`](scripts/90_postinstall.sh) | Installs/updates VS Code extensions (60 curated), merges settings & keybindings, with fallbacks if `code` CLI is missing. |

Each script sources [`scripts/_lib.sh`](scripts/_lib.sh) for consistent logging (`step`, `ok`, `warn`, `run --comment`) and safety helpers.

---

## 🚀 What you get

- **Browsers & productivity:** Chrome, Arc, Notion, Notion Calendar, Office suite, OneDrive, GitHub Desktop, Chrome Remote Desktop Host.
- **Developer tools:** VS Code, Warp, Cursor, Kiro, Docker Desktop, DBeaver, PostgreSQL 16, Raspberry Pi Imager, Raycast, Rectangle, MonitorControl, Hidden Bar, Stats.
- **CLIs:** git, gh, jq, ripgrep, fd, eza, bat, fzf, zoxide, tree, wget, httpie, tldr, git-delta, pnpm, fnm, uv and more from the Brewfile.
- **Global JS/Python conveniences:** `pnpm` installs TypeScript, ts-node, npm-check-updates, mapshaper; `pipx` provides black, ruff, mypy, pre-commit, httpx.
- **Workspace hygiene:** Dotfile links, Git config includes, `~/Code` folder tree, curated wallpaper, Dock reset, macOS preferences.

The exact inventory (with comments) lives in [`Brewfile`](Brewfile).

---

## 🧪 Partial runs

Want to test or rerun just one part? Execute scripts directly:

```bash
./scripts/30_macos_defaults.sh
./scripts/40_dock.sh
./scripts/45_wallpaper.sh --flash   # vivid indication of change
./scripts/70_languages.sh
./scripts/90_postinstall.sh
```

All scripts are idempotent; re-running only refreshes the target state.

---

## 🛠️ Customize

- **Apps & CLIs:** edit [`Brewfile`](Brewfile) (grouped by category). Run `brew bundle dump` to capture new additions. 
- **Dock order & behavior:** tweak `APPS` or defaults in [`scripts/40_dock.sh`](scripts/40_dock.sh).
- **Wallpaper:** replace `assets/wallpapers/default.jpg` or adjust logic/automation in [`scripts/45_wallpaper.sh`](scripts/45_wallpaper.sh).
- **macOS defaults:** modify [`scripts/30_macos_defaults.sh`](scripts/30_macos_defaults.sh) for Finder, screenshots, etc.
- **VS Code:** update extension list & settings merge in [`scripts/90_postinstall.sh`](scripts/90_postinstall.sh).
- **Language runtimes:** adapt [`scripts/70_languages.sh`](scripts/70_languages.sh) (e.g., add Ruby via `asdf`).

---

## 🧯 Troubleshooting tips

| Issue | Fix |
|-------|-----|
| Dock/wallpaper didn’t change | Approve Terminal in **System Settings → Privacy & Security → Automation** (Finder + System Events), then re-run the relevant script. |
| `code` CLI missing | Launch VS Code once → Shift+Cmd+P → “Shell Command: Install ‘code’ in PATH”, then rerun Stage 90. |
| Brew permission errors | `scripts/10_xcode_homebrew.sh` auto-fixes `/opt/homebrew` ownership; manually run `sudo chown -R $(whoami):staff $(brew --prefix)` if needed. |
| VS Code settings didn’t merge | Ensure the `Code/User` folder exists by opening VS Code once before Stage 90. |
| Want factory Dock back | `defaults delete com.apple.dock; killall Dock` |

---

## 🗑️ Selective rollback

- Remove a cask: `brew uninstall --cask <token>`
- Remove a formula: `brew uninstall <formula> && brew cleanup`
- Reset Finder tweaks: `defaults delete com.apple.finder; killall Finder`
- Restore wallpaper manually: System Settings → Wallpaper → choose new image

---

## 📜 License

MIT — see [LICENSE](LICENSE).
