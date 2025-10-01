# Use Homebrew env if present
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$('/opt/homebrew/bin/brew' shellenv)"
fi

# Warp uses zsh by default; good to go

# Handy aliases
alias ll='ls -lah'
alias la='ls -la'
alias gs='git status'
alias gp='git pull'
alias gc='git commit'

# Tools
export EDITOR="code --wait"

# Python: uv helper to create & activate a venv (usage: mkvenv [.venv|custom-name])
mkvenv() { local dir=${1:-.venv}; uv venv "$dir" && source "$dir/bin/activate"; }

# FNM (Node)
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

# zoxide (better cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fzf keybindings (if installed)
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Created by `pipx`
export PATH="$PATH:$HOME/.local/bin"
