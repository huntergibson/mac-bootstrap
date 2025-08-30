#!/usr/bin/env bash
# ----------------------------------------------------------
# Stage 90: Post‑install polish
#  - Installs VS Code extensions (your full list, commented)
#  - Merges desired VS Code user settings (with inline comments)
#  - Adds a Python‑only keybinding so Shift+Enter runs selection in
#    the Jupyter Interactive Window (like classic Jupyter)
#    (requires jq for merging; otherwise writes minimal files)
# ----------------------------------------------------------
set -euo pipefail

# Install your VS Code extensions
# We'll try the PATH 'code' first; if missing, fall back to VS Code's bundled CLI path.
CODE_BIN="code"
if ! command -v "$CODE_BIN" >/dev/null 2>&1; then
  CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi

if [[ -x "$CODE_BIN" ]] || command -v "$CODE_BIN" >/dev/null 2>&1; then
  echo "Installing VS Code extensions..."
  # List of extensions to install (with comments so you remember what they do)
  while read -r ext; do
    # Skip comments and blanks
    [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue
    echo "  → $ext"
    "$CODE_BIN" --install-extension "$ext" --force || true
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
ms-vscode.powershell             # PowerShell

# ---- Data Viz / Tables ----
randomfractalsinc.vscode-data-table # Data table viewer
visualstudioexptteam.intellicode-api-usage-examples # Intellicode examples
visualstudioexptteam.vscodeintellicode             # AI-assisted IntelliSense

# ---- Remote / SSH ----
ms-vscode-remote.remote-ssh      # Remote SSH
ms-vscode-remote.remote-ssh-edit # SSH config editing
ms-vscode.remote-explorer        # Remote explorer
ms-vscode.remote-server          # Remote server
EOF

  echo "Configuring VS Code user settings..."
  SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
  mkdir -p "$SETTINGS_DIR"
  SETTINGS_FILE="$SETTINGS_DIR/settings.json"

  # Desired settings with comments for clarity
  read -r -d '' DESIRED_JSON <<'JSON'
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

  # Merge with existing settings if present (requires jq)
  if command -v jq >/dev/null 2>&1; then
    EXISTING_JSON='{}'
    if [[ -f "$SETTINGS_FILE" ]]; then
      EXISTING_JSON="$(cat "$SETTINGS_FILE")"
    fi
    printf '%s' "$EXISTING_JSON" > /tmp/vscode_existing.json
    printf '%s' "$DESIRED_JSON" > /tmp/vscode_desired.json
    jq -s '.[0] * .[1]' /tmp/vscode_existing.json /tmp/vscode_desired.json > "$SETTINGS_FILE"
    rm -f /tmp/vscode_existing.json /tmp/vscode_desired.json
  else
    # If jq isn't available, overwrite with desired settings
    printf '%s' "$DESIRED_JSON" > "$SETTINGS_FILE"
  fi

  # ------------------------------------------------------
  # Keybindings: make Shift+Enter run selection/line in the
  # Jupyter Interactive Window *for Python files only*.
  # This mimics classic Jupyter behavior inside VS Code.
  # ------------------------------------------------------
  echo "Configuring VS Code keybindings (Shift+Enter → Jupyter Interactive for Python)..."
  KEYB_FILE="$SETTINGS_DIR/keybindings.json"

  # Desired keybinding entry (JSON array element). Comments live in this script.
  read -r -d '' DESIRED_KB <<'JSON'
[
  {
    "key": "shift+enter",
    "command": "jupyter.execSelectionInteractive",
    "when": "editorTextFocus && editorLangId == 'python'"
  }
]
JSON

  if command -v jq >/dev/null 2>&1; then
    EXISTING_KB='[]'
    if [[ -f "$KEYB_FILE" ]]; then
      EXISTING_KB="$(cat "$KEYB_FILE")"
    fi
    printf '%s' "$EXISTING_KB" > /tmp/vscode_kb_existing.json
    printf '%s' "$DESIRED_KB" > /tmp/vscode_kb_desired.json
    # Merge arrays and de‑dupe by key|command|when triple
    jq -s '.[0] as $a | .[1] as $b | ($a + $b) | unique_by(.key + "|" + .command + "|" + (.when // ""))'       /tmp/vscode_kb_existing.json /tmp/vscode_kb_desired.json > "$KEYB_FILE"
    rm -f /tmp/vscode_kb_existing.json /tmp/vscode_kb_desired.json
  else
    # If jq not present, just write the minimal keybinding file
    printf '%s' "$DESIRED_KB" > "$KEYB_FILE"
  fi
else
  echo "VS Code CLI not found. After first launching VS Code, run 'Shell Command: Install "code" command in PATH' and re-run this script: scripts/90_postinstall.sh"
fi

echo "Postinstall complete."
