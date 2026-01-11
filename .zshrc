
export STARSHIP_CONFIG=~/.config/starship.toml

# GitHub token for MCP server
setopt HIST_IGNORE_ALL_DUPS
bindkey -e


WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------
# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

# ------------------------------
# Post-init module configuration
# ------------------------------

#
# zsh-history-substring-search
#


# Auto-activate/deactivate virtual environments when changing directories
function cd() {
  builtin cd "$@"
  
  # Path to your cybersec directory (adjust if needed)
  local cybersec_path="$HOME/cybersec"
  local current_path="$PWD"
  
  # Check if we're in the cybersec directory or any subdirectory
  if [[ "$current_path" == "$cybersec_path"* ]]; then
    # Only activate if not already in a venv
    if [[ -z "$VIRTUAL_ENV" ]]; then
      echo "🔒 Activating cybersecurity environment..."
      source "$HOME/cybersec/python-env/venv/bin/activate"
    fi
  # If we were in a venv and now we're leaving the cybersec directory
  elif [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == *"cybersec/python-env/venv"* ]]; then
    echo "🔓 Deactivating cybersecurity environment..."
    deactivate
  fi
}
zmodload -F zsh/terminfo +p:terminfo
export EDITOR=nvim

# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
# }}} End configuration added by Zim install

# source ~/dotfiles/fzf/fzf-tab.plugin.zsh
# Git
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
# alias go="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
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
alias fb='z ~/Desktop/future-builds/'
alias rm='trash-put'
alias logs='cat /var/log/system-monitor/system_stats.log'
# Alias to quickly jump to the cybersec directory
alias cybersec="cd ~/cybersec"

alias dcp='docker-compose up'   # For docker-compose up (build and start in detached mode)
alias dcd='docker-compose down'          # For docker-compose down
# Eza
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
# alias bat="batcat"
alias t="tmux -u"
alias n="nvim"
eval "$(fzf --zsh)"
# FZF setup
# source /usr/share/doc/fzf/examples/key-bindings.zsh
# source /usr/share/doc/fzf/examples/completion.zsh

# Use fd instead of find for fzf
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Functions for fzf path and directory completion
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# Setup fzf theme
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export PATH="$HOME/.local/bin:$PATH"

export MANPAGER='nvim +Man!'
# History setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
bindkey '^[[A' history-search-backward  # Completion using arrow keys (based on history)
bindkey '^[[B' history-search-forward

# FZF default options
export FZF_DEFAULT_OPTS=" \
--color=bg+:#171926,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

#export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
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

# Set BAT theme
export BAT_THEME="Catppuccin Mocha"

for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key

eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

alias lg='lazygit'
export PATH=/usr/local/share/npm/bin:$PATH
export PATH="$PATH:/opt/nvim-linux64/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

PATH=~/.console-ninja/.bin:$PATH

# ---- Eza (better ls) -----
eval "$(zoxide init zsh)"


export PATH=$PATH:/home/shyamenk/.spicetify

# bun completions
[ -s "/home/elliott/.bun/_bun" ] && source "/home/elliott/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export TESSDATA_PREFIX=/usr/share/

# export PATH=/usr/bin/aws_completer/:$PATH
#
# complete -C '/usr/bin/aws_completer' aws
export PATH="$HOME/bin:$PATH"

# Aliases for connecting to databases
alias cpd="db_connect prod"
alias cdd="db_connect dev"

# export PATH="$HOME/.pyenv/bin:$PATH"
# eval "$(pyenv init --path)"
# eval "$(pyenv init -)"

# Yazi Setup
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GOROOT=/usr/lib/go
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
export GOPATH=$HOME/go

[[ -s "/home/shyamenk/.gvm/scripts/gvm" ]] && source "/home/shyamenk/.gvm/scripts/gvm"

# Bug Bounty aliases
if [ -f ~/.bug_bounty_aliases ]; then
  . ~/.bug_bounty_aliases
fi


alias aws-default='export AWS_PROFILE=default && echo "✅ Switched to DEFAULT profile" && aws sts get-caller-identity --query "Account" --output text'
alias aws-dev='export AWS_PROFILE=developer && echo "✅ Switched to DEVELOPER profile" && aws sts get-caller-identity --query "Account" --output text'
alias aws-root='export AWS_PROFILE=root && echo "✅ Switched to ROOT profile" && aws sts get-caller-identity --query "Account" --output text'
alias aws-current='echo "Current profile: ${AWS_PROFILE:-default}" && aws sts get-caller-identity'


export PATH=~/.npm-global/bin:$PATH
export PATH="$HOME/.nvm/versions/node/$(nvm version)/bin:$PATH"


function killport() { sudo kill -9 $(sudo lsof -t -i:$1); }
function killport() {
  local pid
  pid=$(sudo lsof -t -i:$1)
  if [[ -z "$pid" ]]; then
    echo "No process is using port $1"
  else
    echo "Killing process on port $1 (PID: $pid)"
    sudo kill -9 $pid
  fi
}
function killport() {
  local pid
  pid=$(lsof -t -i:$1)
  if [[ -z "$pid" ]]; then
    echo "No process is using port $1"
  else
    echo "Killing process on port $1 (PID: $pid)"
    kill -9 $pid
  fi
}
function killport() {
  local pid
  pid=$(ss -ltnp | grep ":$1 " | grep -oP 'pid=\K[0-9]+')
  if [[ -z "$pid" ]]; then
    echo "No process is using port $1"
  else
    echo "Killing process on port $1 (PID: $pid)"
    kill -9 $pid
  fi
}
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

. "$HOME/.local/bin/env"

# Amp CLI
export PATH="/home/shyamenk/.amp/bin:$PATH"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=~/sf/bin:$PATH
?? () {
  if [[ -t 0 ]]; then
    fabric "$@"
  else
    cat - | fabric "$@"
  fi
}

