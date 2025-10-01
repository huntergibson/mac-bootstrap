#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 90: Post‑install polish
#  - Installs VS Code extensions (with progress & skip-if-present)
#  - Merges desired VS Code user settings (safe, via jq when available)
#  - Adds a Python‑only keybinding (Shift+Enter → Jupyter Interactive)
#  - Clear progress output and robust error handling
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

# Resolve VS Code CLI
CODE_BIN="code"
if ! command -v "$CODE_BIN" >/dev/null 2>&1; then
  if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
    CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  elif [[ -x "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code" ]]; then
    CODE_BIN="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
  else
    CODE_BIN=""
  fi
fi

# ---------------- (1/4) Install VS Code extensions ----------------
step "VS Code extensions (1/4)"
if [[ -z "$CODE_BIN" ]]; then
  warn "VS Code CLI ('code') not found."
  info "Open VS Code → Command Palette → 'Shell Command: Install \"code\" command in PATH'"
  info "Then re-run: scripts/90_postinstall.sh"
else
  info "Using CLI: $CODE_BIN"
  # Capture installed list once for fast checks
  INSTALLED_LIST_FILE="$(mktemp)"; trap 'rm -f "$INSTALLED_LIST_FILE"' EXIT
  if "$CODE_BIN" --list-extensions >"$INSTALLED_LIST_FILE" 2>/dev/null; then :; else
    warn "Could not list current extensions; proceeding with installs"
    : >"$INSTALLED_LIST_FILE"
  fi

  INSTALLED=0; SKIPPED=0; FAILED=0; TOTAL=0

  while IFS= read -r line; do
    # Trim trailing comments & whitespace; skip blanks
    ext="${line%%#*}"; ext="${ext%%[[:space:]]*}"; ext="${ext//[[:space:]]/}"
    [[ -z "$ext" ]] && continue
    TOTAL=$((TOTAL+1))
  done <<'EOF'
# ---- Data / Analysis ----
analysis-services.tmdl          # Tabular Model Definition Language (SSAS/Power BI)
dotjoshjohnson.xml              # XML syntax support

# ---- Git & Collaboration ----
eamodio.gitlens                 # Supercharged Git insights
ms-vsliveshare.vsliveshare      # Live Share collaboration
github.copilot                  # GitHub Copilot AI coding
github.copilot-chat             # GitHub Copilot Chat
github.remotehub                # Work with repos in GitHub directly
ms-vscode.azure-repos           # Azure Repos integration
ms-vscode.remote-repositories   # Work with remote repos

# ---- Formatting & UI ----
esbenp.prettier-vscode          # Prettier code formatter
vscode-icons-team.vscode-icons  # File icons
yoavbls.pretty-ts-errors        # Pretty TypeScript errors
johnpapa.vscode-peacock         # Peacock: color VS Code windows by project

# ---- Design / Visualization ----
figma.figma-vscode-extension    # Figma integration
hediet.vscode-drawio            # Draw.io diagrams inside VS Code
tomoki1207.pdf                  # PDF viewer

# ---- Power BI / Onelake ----
gerhardbrueckl.onelake-vscode   # Microsoft OneLake tools
gerhardbrueckl.powerbi-vscode   # Power BI tools
gerhardbrueckl.powerbi-vscode-extensionpack # Power BI extension pack

# ---- Excel / CSV ----
grapecity.gc-excelviewer        # Excel viewer
local-smart.excel-live-server   # Excel Live Server
mechatroner.rainbow-csv         # CSV highlighter

# ---- Cloud / Azure ----
ms-azuretools.azure-dev         # Azure dev extension pack
ms-azuretools.vscode-azureappservice   # Azure App Service
ms-azuretools.vscode-azurecontainerapps# Azure Container Apps
ms-azuretools.vscode-azurefunctions    # Azure Functions
ms-azuretools.vscode-azureresourcegroups # Azure Resource Groups
ms-azuretools.vscode-azurestaticwebapps # Azure Static Web Apps
ms-azuretools.vscode-azurestorage      # Azure Storage
ms-azuretools.vscode-azurevirtualmachines # Azure VMs
ms-azuretools.vscode-cosmosdb          # Cosmos DB
ms-vscode.azurecli                     # Azure CLI
ms-vscode.vscode-node-azure-pack       # Node.js Azure tools

# ---- Containers / DevOps ----
ms-azuretools.vscode-docker      # Docker integration
postman.postman-for-vscode       # Postman client
ms-playwright.playwright         # Playwright testing
okeeffdp.snowflake-vscode        # Snowflake DB
snowflake.snowflake-vsc          # Another Snowflake extension

# ---- Python & Jupyter ----
ms-python.python                 # Python support
ms-python.debugpy                # Python debug adapter
ms-python.vscode-pylance         # Python type checking / IntelliSense
ms-toolsai.jupyter               # Jupyter notebooks
ms-toolsai.jupyter-keymap        # Jupyter keybindings
ms-toolsai.jupyter-renderers     # Rich rendering for Jupyter
ms-toolsai.vscode-ai             # AI integration
ms-toolsai.vscode-ai-remote      # Remote AI
ms-toolsai.vscode-jupyter-cell-tags    # Jupyter cell tags
ms-toolsai.vscode-jupyter-slideshow    # Jupyter slideshow

# ---- Other Languages ----
jianfajun.dax-language           # DAX language support
redhat.vscode-xml                # XML tools
redhat.vscode-yaml               # YAML tools

# ---- Data Viz / Tables ----
randomfractalsinc.vscode-data-table # Data table viewer
visualstudioexptteam.intellicode-api-usage-examples # Intellicode examples
visualstudioexptteam.vscodeintellicode             # AI-assisted IntelliSense

# ---- Remote / SSH ----
ms-vscode-remote.remote-ssh      # Remote SSH
ms-vscode-remote.remote-ssh-edit # SSH config editing
ms-vscode.remote-explorer        # Remote explorer
ms-vscode.remote-server          # Remote server

openai.chatgpt                   # ChatGPT (OpenAI) — official
Continue.continue                # Continue — LLM chat/coding in VS Code
EOF

  COUNT=0
  while IFS= read -r line; do
    raw="$line"
    # Strip comments and whitespace
    ext="${raw%%#*}"; ext="${ext%%[[:space:]]*}"; ext="${ext//[[:space:]]/}"
    [[ -z "$ext" ]] && continue
    COUNT=$((COUNT+1))
    printf "[%d/%d] %s\n" "$COUNT" "$TOTAL" "$ext"

    if grep -qx "$ext" "$INSTALLED_LIST_FILE" 2>/dev/null; then
      info "already installed: $ext"
      SKIPPED=$((SKIPPED+1))
      continue
    fi

    EXTRA_FLAGS=(--force --log error)
    if "$CODE_BIN" --help 2>/dev/null | grep -q -- "do-not-sync"; then
      EXTRA_FLAGS+=(--do-not-sync)
    fi
    if "$CODE_BIN" --install-extension "$ext" "${EXTRA_FLAGS[@]}" >/dev/null 2>&1; then
      ok "installed: $ext"
      INSTALLED=$((INSTALLED+1))
    else
      warn "failed installing: $ext (continuing)"
      FAILED=$((FAILED+1))
    fi
  done <<'EOF'
# ---- Data / Analysis ----
analysis-services.tmdl          # Tabular Model Definition Language (SSAS/Power BI)
dotjoshjohnson.xml              # XML syntax support

# ---- Git & Collaboration ----
eamodio.gitlens                 # Supercharged Git insights
ms-vsliveshare.vsliveshare      # Live Share collaboration
github.copilot                  # GitHub Copilot AI coding
github.copilot-chat             # GitHub Copilot Chat
github.remotehub                # Work with repos in GitHub directly
ms-vscode.azure-repos           # Azure Repos integration
ms-vscode.remote-repositories   # Work with remote repos

# ---- Formatting & UI ----
esbenp.prettier-vscode          # Prettier code formatter
vscode-icons-team.vscode-icons  # File icons
yoavbls.pretty-ts-errors        # Pretty TypeScript errors
johnpapa.vscode-peacock         # Peacock: color VS Code windows by project

# ---- Design / Visualization ----
figma.figma-vscode-extension    # Figma integration
hediet.vscode-drawio            # Draw.io diagrams inside VS Code
tomoki1207.pdf                  # PDF viewer

# ---- Power BI / Onelake ----
gerhardbrueckl.onelake-vscode   # Microsoft OneLake tools
gerhardbrueckl.powerbi-vscode   # Power BI tools
gerhardbrueckl.powerbi-vscode-extensionpack # Power BI extension pack

# ---- Excel / CSV ----
grapecity.gc-excelviewer        # Excel viewer
local-smart.excel-live-server   # Excel Live Server
mechatroner.rainbow-csv         # CSV highlighter

# ---- Cloud / Azure ----
ms-azuretools.azure-dev         # Azure dev extension pack
ms-azuretools.vscode-azureappservice   # Azure App Service
ms-azuretools.vscode-azurecontainerapps# Azure Container Apps
ms-azuretools.vscode-azurefunctions    # Azure Functions
ms-azuretools.vscode-azureresourcegroups # Azure Resource Groups
ms-azuretools.vscode-azurestaticwebapps # Azure Static Web Apps
ms-azuretools.vscode-azurestorage      # Azure Storage
ms-azuretools.vscode-azurevirtualmachines # Azure VMs
ms-azuretools.vscode-cosmosdb          # Cosmos DB
ms-vscode.azurecli                     # Azure CLI
ms-vscode.vscode-node-azure-pack       # Node.js Azure tools

# ---- Containers / DevOps ----
ms-azuretools.vscode-docker      # Docker integration
postman.postman-for-vscode       # Postman client
ms-playwright.playwright         # Playwright testing
okeeffdp.snowflake-vscode        # Snowflake DB
snowflake.snowflake-vsc          # Another Snowflake extension

# ---- Python & Jupyter ----
ms-python.python                 # Python support
ms-python.debugpy                # Python debug adapter
ms-python.vscode-pylance         # Python type checking / IntelliSense
ms-toolsai.jupyter               # Jupyter notebooks
ms-toolsai.jupyter-keymap        # Jupyter keybindings
ms-toolsai.jupyter-renderers     # Rich rendering for Jupyter
ms-toolsai.vscode-ai             # AI integration
ms-toolsai.vscode-ai-remote      # Remote AI
ms-toolsai.vscode-jupyter-cell-tags    # Jupyter cell tags
ms-toolsai.vscode-jupyter-slideshow    # Jupyter slideshow

# ---- Other Languages ----
jianfajun.dax-language           # DAX language support
redhat.vscode-xml                # XML tools
redhat.vscode-yaml               # YAML tools

# ---- Data Viz / Tables ----
randomfractalsinc.vscode-data-table # Data table viewer
visualstudioexptteam.intellicode-api-usage-examples # Intellicode examples
visualstudioexptteam.vscodeintellicode             # AI-assisted IntelliSense

# ---- Remote / SSH ----
ms-vscode-remote.remote-ssh      # Remote SSH
ms-vscode-remote.remote-ssh-edit # SSH config editing
ms-vscode.remote-explorer        # Remote explorer
ms-vscode.remote-server          # Remote server

openai.chatgpt                   # ChatGPT (OpenAI) — official
Continue.continue                # Continue — LLM chat/coding in VS Code
EOF

  info ""
  info "Extensions summary: $INSTALLED installed, $SKIPPED skipped, $FAILED failed"
fi

# ---------------- (2/4) VS Code settings ----------------
step "VS Code settings (2/4)"
SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Use a safe heredoc assignment (no read -d '') to avoid nonzero exit under set -e
DESIRED_JSON=$(cat <<'JSON'
{
  // Cursor style: expand = animated widening
  "editor.cursorBlinking": "expand",

  // Smooth caret animation when moving cursor
  "editor.cursorSmoothCaretAnimation": "on",

  // Enable word wrap so long lines wrap instead of scrolling horizontally
  "editor.wordWrap": "on",

  // Colorize matching bracket pairs for readability
  "editor.bracketPairColorization.enabled": true
}
JSON
)

if [[ -d "$SETTINGS_DIR" ]]; then
  if command -v jq >/dev/null 2>&1; then
    EXISTING_JSON='{}'
    if [[ -f "$SETTINGS_FILE" ]]; then
      EXISTING_JSON="$(cat "$SETTINGS_FILE" 2>/dev/null || echo '{}')"
    fi
    TMP_A="$(mktemp)"; TMP_B="$(mktemp)"; trap 'rm -f "$TMP_A" "$TMP_B"' EXIT
    printf '%s' "$EXISTING_JSON" > "$TMP_A"
    printf '%s' "$DESIRED_JSON"  > "$TMP_B"
    if jq -s '.[0] * .[1]' "$TMP_A" "$TMP_B" > "$SETTINGS_FILE" 2>/dev/null; then
      ok "settings merged → $SETTINGS_FILE"
    else
      warn "jq merge failed; writing desired settings only"
      printf '%s' "$DESIRED_JSON" > "$SETTINGS_FILE"
    fi
  else
    warn "jq not found; writing desired settings only"
    printf '%s' "$DESIRED_JSON" > "$SETTINGS_FILE"
  fi
else
  warn "VS Code user directory not found: $SETTINGS_DIR"
  info "Open VS Code once to initialize it, then re-run this script to apply settings."
fi

# ---------------- (3/4) VS Code keybindings ----------------
step "VS Code keybindings (3/4)"
KEYB_FILE="$SETTINGS_DIR/keybindings.json"
DESIRED_KB=$(cat <<'JSON'
[
  {
    "key": "shift+enter",
    "command": "jupyter.execSelectionInteractive",
    "when": "editorTextFocus && editorLangId == 'python'"
  }
]
JSON
)

if [[ -d "$SETTINGS_DIR" ]]; then
  if command -v jq >/dev/null 2>&1; then
    EXISTING_KB='[]'
    if [[ -f "$KEYB_FILE" ]]; then
      EXISTING_KB="$(cat "$KEYB_FILE" 2>/dev/null || echo '[]')"
    fi
    TMP_A="$(mktemp)"; TMP_B="$(mktemp)"; trap 'rm -f "$TMP_A" "$TMP_B"' EXIT
    printf '%s' "$EXISTING_KB" > "$TMP_A"
    printf '%s' "$DESIRED_KB" > "$TMP_B"
    if jq -s '.[0] as $a | .[1] as $b | ($a + $b) | unique_by(.key + "|" + .command + "|" + (.when // ""))' "$TMP_A" "$TMP_B" > "$KEYB_FILE" 2>/dev/null; then
      ok "keybindings merged → $KEYB_FILE"
    else
      warn "jq merge failed; writing minimal keybindings"
      printf '%s' "$DESIRED_KB" > "$KEYB_FILE"
    fi
  else
    warn "jq not found; writing minimal keybindings"
    printf '%s' "$DESIRED_KB" > "$KEYB_FILE"
  fi
else
  warn "VS Code user directory not found; skipping keybindings."
  info "Open VS Code once to initialize it, then re-run this script to apply keybindings."
fi

# ---------------- (4/4) Summary ----------------
step "Summary (4/4)"
info "Settings : $SETTINGS_FILE"
info "Keys     : $KEYB_FILE"
if [[ -n "${CODE_BIN:-}" ]]; then info "CLI      : $CODE_BIN"; fi
ok "Postinstall complete"
