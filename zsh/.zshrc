# =============================================
# OPTIMIZED ZSHRC - Fast startup configuration
# =============================================

# -----------------
# Core settings (fast)
# -----------------
setopt HIST_IGNORE_ALL_DUPS
bindkey -e
WORDCHARS=${WORDCHARS//[\/]}
export EDITOR=nvim

# -----------------
# Zsh-autosuggestions config (before zim init)
# -----------------
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# -----------------
# Zim initialization
# -----------------
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
source ${ZIM_HOME}/init.zsh

# -----------------
# Key bindings (once only)
# -----------------
zmodload -F zsh/terminfo +p:terminfo
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key

# -----------------
# PATH - consolidated (fast)
# -----------------
typeset -U path  # Remove duplicates automatically
path=(
  $HOME/.local/bin
  $HOME/bin
  $HOME/.amp/bin
  $HOME/sf/bin
  $HOME/.console-ninja/.bin
  $HOME/.npm-global/bin
  $HOME/.nvm/versions/node/v24.13.0/bin  # nvm default node for Mason/LSP tools
  $HOME/.spicetify
  $HOME/.bun/bin
  $HOME/go/bin
  /usr/local/go/bin
  /usr/local/share/npm/bin
  /opt/nvim-linux64/bin
  /usr/lib/jvm/java-17-openjdk/bin
  $path
)
export PATH

# -----------------
# Environment variables (fast)
# -----------------
export GOPATH=$HOME/go
export GOROOT=/usr/lib/go
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export BUN_INSTALL="$HOME/.bun"
export TESSDATA_PREFIX=/usr/share/
export MANPAGER='nvim +Man!'
export BAT_THEME="Catppuccin Mocha"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# -----------------
# History setup
# -----------------
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history hist_expire_dups_first hist_ignore_dups hist_verify

# -----------------
# FZF configuration (deferred eval)
# -----------------
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#171926,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
_fzf_compgen_dir() { fd --type=d --hidden --exclude .git . "$1"; }

_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

# -----------------
# LAZY LOAD NVM (major speedup ~300ms)
# -----------------
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() { nvm --version >/dev/null 2>&1; unset -f node; node "$@"; }
npm() { nvm --version >/dev/null 2>&1; unset -f npm; npm "$@"; }
npx() { nvm --version >/dev/null 2>&1; unset -f npx; npx "$@"; }

# -----------------
# LAZY LOAD GVM (speedup ~100ms)
# -----------------
gvm() {
  unset -f gvm
  [[ -s "/home/shyamenk/.gvm/scripts/gvm" ]] && source "/home/shyamenk/.gvm/scripts/gvm"
  gvm "$@"
}

# -----------------
# Git aliases
# -----------------
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcoall='git checkout -- .'
alias gr='git remote'
alias gre='git reset'
alias glg='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset" --abbrev-commit --date=relative'
alias lg='lazygit'

# -----------------
# Eza aliases
# -----------------
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"

# -----------------
# Other aliases
# -----------------
alias fb='z ~/Desktop/future-builds/'
alias rm='trash-put'
alias logs='cat /var/log/system-monitor/system_stats.log'
alias cybersec="cd ~/cybersec"
alias dcp='docker-compose up'
alias dcd='docker-compose down'
alias t="tmux -u"
alias n="nvim"
alias cpd="db_connect prod"
alias cdd="db_connect dev"
alias yt="yt-insights"
alias '??'=fabric_wrapper

# AWS profile aliases
alias aws-default='export AWS_PROFILE=default && echo "Switched to DEFAULT profile" && aws sts get-caller-identity --query "Account" --output text'
alias aws-dev='export AWS_PROFILE=developer && echo "Switched to DEVELOPER profile" && aws sts get-caller-identity --query "Account" --output text'
alias aws-root='export AWS_PROFILE=root && echo "Switched to ROOT profile" && aws sts get-caller-identity --query "Account" --output text'
alias aws-current='echo "Current profile: ${AWS_PROFILE:-default}" && aws sts get-caller-identity'

# -----------------
# Functions (consolidated - single definitions)
# -----------------

# Auto-activate cybersec venv on cd
function cd() {
  builtin cd "$@" || return
  local cybersec_path="$HOME/cybersec"
  if [[ "$PWD" == "$cybersec_path"* ]]; then
    [[ -z "$VIRTUAL_ENV" ]] && source "$HOME/cybersec/python-env/venv/bin/activate"
  elif [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == *"cybersec/python-env/venv"* ]]; then
    deactivate
  fi
}

# Yazi file manager
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Kill process on port (single definition)
function killport() {
  local pid=$(ss -ltnp 2>/dev/null | grep ":$1 " | grep -oP 'pid=\K[0-9]+')
  if [[ -z "$pid" ]]; then
    echo "No process is using port $1"
  else
    echo "Killing process on port $1 (PID: $pid)"
    kill -9 $pid
  fi
}

# Pass fuzzy finder (single definition)
pf() {
  local entry=$(find ~/.password-store -name '*.gpg' 2>/dev/null | \
    sed 's|.*/\.password-store/||;s|\.gpg$||' | sort | \
    fzf --height 40% --reverse --prompt="pass> ")
  [[ -n "$entry" ]] && pass -c "$entry"
}

# Fabric wrapper
fabric_wrapper() {
  if [[ -t 0 ]]; then
    fabric "$@"
  else
    cat - | fabric "$@"
  fi
}

# -----------------
# Source external files (if they exist)
# -----------------
[ -f ~/.bug_bounty_aliases ] && . ~/.bug_bounty_aliases
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# -----------------
# Tool initializations (at end for speed)
# -----------------
eval "$(fzf --zsh)" 2>/dev/null
eval "$(zoxide init zsh)" 2>/dev/null
eval "$(starship init zsh)"

# Lazy load uv completions
if (( ${+commands[uv]} )); then
  _uv_completion_loaded=0
  _uv() {
    if (( ! _uv_completion_loaded )); then
      eval "$(uv generate-shell-completion zsh)"
      _uv_completion_loaded=1
    fi
  }
  compdef _uv uv
fi
