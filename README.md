# 🧰 mac-bootstrap

Bring a brand-new Mac to “ready for work” with a single command. This repo installs the apps you use every day, dials in macOS settings, sets up the Dock, drops in your wallpaper, and gets your shell, runtimes, and editor feeling like home.

> Copy, paste, go:
> ```bash
> git clone https://github.com/huntergibson/mac-bootstrap.git && cd mac-bootstrap && ./bootstrap.sh
> ```

The main script explains every step while it runs, asks for permissions up front, and retries common errors. If you rerun it later, it simply tops things up.

---

## 📦 What happens, stage by stage

| Stage | Script | Plain-English version |
|-------|--------|------------------------|
| Preflight | `bootstrap.sh` | Keeps `sudo` alive, checks your Git name/email, offers to log in with `gh`, and nudges macOS for Automation access so later steps don’t get blocked. |
| 10 | [`scripts/10_xcode_homebrew.sh`](scripts/10_xcode_homebrew.sh) | Installs Apple’s command-line tools, installs or refreshes Homebrew, fixes permissions if brew has been run with sudo, and makes sure `brew` is on your PATH right away. |
| 20 | [`scripts/20_brew_bundle.sh`](scripts/20_brew_bundle.sh) | Reads the Brewfile and installs 40+ hand-picked apps and CLIs, showing progress for each one and reminding you about anything deprecated or skipped. |
| 30 | [`scripts/30_macos_defaults.sh`](scripts/30_macos_defaults.sh) | Tweaks Finder so hidden files show, puts the path in the window title, and saves screenshots to a tidy `~/Downloads/Screenshots` folder. |
| 40 | [`scripts/40_dock.sh`](scripts/40_dock.sh) | Sets the Dock to 50% size, keeps it visible, hides Apple’s “suggested apps,” clears out the old icons, then adds Chrome → Notion → VS Code → Excel in that exact order. |
| 45 | [`scripts/45_wallpaper.sh`](scripts/45_wallpaper.sh) | Copies the bundled wallpaper into `~/Pictures/Wallpapers`, tries the fast Dock-database swap, falls back to Finder/System Events if needed, writes the preference file, and restarts the Dock/Finder/SystemUIServer so it sticks. Use `--flash` to see it change instantly. |
| 50 | [`scripts/50_shell_git.sh`](scripts/50_shell_git.sh) | Symlinks the included `.zshrc`, drops a shared Git config in place, offers to create an SSH key (with optional passphrase), sets VS Code as `git`’s editor, and lets you choose whether to upload the key with `gh`. |
| 55 | [`scripts/55_code_folders.sh`](scripts/55_code_folders.sh) | Builds a neat `~/Code` tree—`personal`, `work`, `sandbox`, `archived`—creating only what’s missing. |
| 70 | [`scripts/70_languages.sh`](scripts/70_languages.sh) | Installs Node LTS with `fnm`, adds global `pnpm` tools (TypeScript, ts-node, npm-check-updates, mapshaper), installs Python helpers with `pipx`, and points you at `uv` for quick virtualenvs. |
| 80 | [`scripts/80_services.sh`](scripts/80_services.sh) | Gives a quick report on background tooling (like Supabase CLI) so you know what’s running and what still needs attention. |
| 90 | [`scripts/90_postinstall.sh`](scripts/90_postinstall.sh) | Installs or confirms 60 VS Code extensions, merges in settings and keybindings, and tells you exactly where things landed. |

Every stage leans on the shared helper file [`scripts/_lib.sh`](scripts/_lib.sh) for consistent logging like `step`, `ok`, `warn`, and the handy `run --comment` wrapper you see in the terminal.

---

## 🚀 What lands on your Mac

- **Browsers & productivity:** Google Chrome, Arc, Notion, Notion Calendar, Microsoft Office (Excel, Word, PowerPoint), OneDrive, GitHub Desktop, Chrome Remote Desktop Host.
- **Developer essentials:** VS Code, Warp, Cursor, Kiro, Docker Desktop, DBeaver, PostgreSQL 16, Raspberry Pi Imager, Raycast, Rectangle, MonitorControl, Hidden Bar, Stats.
- **Command-line tools:** git, GitHub CLI, jq, ripgrep, fd, eza, bat, fzf, zoxide, tree, wget, httpie, tldr, git-delta, plus Node’s `pnpm`, `fnm`, and the `uv` toolkit.
- **Global dev helpers:** TypeScript and friends via `pnpm`, and `black`, `ruff`, `mypy`, `pre-commit`, `httpx` through `pipx`.
- **Quality-of-life polish:** Shared dotfiles, clean Git config includes, the `~/Code` folder structure, curated wallpaper, tuned Dock, and friendlier macOS defaults.

For the complete list (with comments grouped by category) open the [`Brewfile`](Brewfile).

---

enjoy and fork away 👋
