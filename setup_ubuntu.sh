#!/bin/bash
# ===========================================================================
# Automated Clean Environment Provisioning for Ubuntu
# ===========================================================================

set -e # Exit on error

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Installation tracking
SUCCESSFUL_INSTALLS=()
FAILED_INSTALLS=()
SKIPPED_INSTALLS=()

echo -e "${BLUE}=====================================================================
      AUTOMATED UBUNTU ENVIRONMENT SETUP
=====================================================================${NC}"

# Get regular user info
REGULAR_USER=$(logname)
USER_HOME=$(eval echo ~"$REGULAR_USER")
USER_UID=$(id -u "$REGULAR_USER")
USER_GID=$(id -g "$REGULAR_USER")

log() {
  echo -e "${GREEN}[+] $1${NC}"
}

warn() {
  echo -e "${YELLOW}[!] $1${NC}"
}

error() {
  echo -e "${RED}[-] ERROR: $1${NC}" >&2
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}ERROR: This script must be run with sudo or as root${NC}"
  exit 1
fi

# ============================================================================
# PHASE 1: System Update & Essential Prerequisites
# ============================================================================
log "PHASE 1: Updating system and installing essential prerequisites..."

apt update
apt upgrade -y

log "Installing git, curl, stow, wget, build-essential..."
apt install -y git curl stow wget build-essential software-properties-common

SUCCESSFUL_INSTALLS+=("Essential prerequisites: git, curl, stow, wget, build-essential")

# ============================================================================
# PHASE 2: Clone and Apply Dotfiles
# ============================================================================
log "PHASE 2: Setting up dotfiles..."

DOTFILES_DIR="$USER_HOME/dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
  warn "Existing dotfiles directory found. Backing up to dotfiles.backup..."
  mv "$DOTFILES_DIR" "$DOTFILES_DIR.backup.$(date +%Y%m%d_%H%M%S)"
fi

log "Cloning dotfiles repository..."
# Using the local path if we are already in the dotfiles dir, or cloning from github
if [ -d "$(pwd)/.git" ] && [[ "$(basename $(pwd))" == "dotfiles" ]]; then
    log "Using current directory as dotfiles source..."
    cp -r "$(pwd)" "$DOTFILES_DIR"
    chown -R "$USER_UID":"$USER_GID" "$DOTFILES_DIR"
else
    if sudo -u "$REGULAR_USER" git clone https://github.com/shyamenk/dotfiles.git "$DOTFILES_DIR"; then
      log "Successfully cloned dotfiles"
      SUCCESSFUL_INSTALLS+=("Dotfiles clone")
    else
      error "Failed to clone dotfiles repository"
      FAILED_INSTALLS+=("Dotfiles clone")
    fi
fi

if [ -d "$DOTFILES_DIR" ]; then
  cd "$DOTFILES_DIR"
  log "Applying dotfiles with stow..."
  if sudo -u "$REGULAR_USER" stow .; then
    log "Successfully applied dotfiles"
    SUCCESSFUL_INSTALLS+=("Dotfiles stow")
  else
    warn "Stow encountered conflicts (this may be normal)"
    SKIPPED_INSTALLS+=("Dotfiles stow - conflicts")
  fi
  cd /
fi

# ============================================================================
# PHASE 3: Setup Package Managers (Flatpak)
# ============================================================================
log "PHASE 3: Setting up package managers..."

# Install flatpak
if ! command -v flatpak &>/dev/null; then
  log "Installing Flatpak..."
  apt install -y flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  SUCCESSFUL_INSTALLS+=("Flatpak")
else
  log "Flatpak is already installed"
  SKIPPED_INSTALLS+=("Flatpak - already installed")
fi

# ============================================================================
# PHASE 4: Install All Packages
# ============================================================================
log "PHASE 4: Installing all packages..."

install_pkg() {
  local pkg=$1
  local method=$2

  case $method in
  apt)
    if dpkg -l "$pkg" &>/dev/null; then
      SKIPPED_INSTALLS+=("$pkg (already installed)")
      return 0
    fi

    if apt install -y "$pkg" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$pkg (apt)")
      return 0
    else
      return 1
    fi
    ;; 

  flatpak)
    if flatpak list | grep -q "$pkg" 2>/dev/null; then
      SKIPPED_INSTALLS+=("$pkg (already installed)")
      return 0
    fi

    if flatpak install -y flathub "$pkg" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$pkg (flatpak)")
      return 0
    else
      return 1
    fi
    ;; 
  esac
}

try_install() {
  local pkg=$1
  shift
  local methods=($@)

  for method in "${methods[@]}"; do
    if [[ $method == flatpak:* ]]; then
      local flatpak_id="${method#flatpak:}"
      if install_pkg "$flatpak_id" "flatpak"; then
        return 0
      fi
    else
      if install_pkg "$pkg" "$method"; then
        return 0
      fi
    fi
  done

  FAILED_INSTALLS+=("$pkg (all methods failed)")
  return 1
}

# Core Development Tools
log "Installing core development tools..."
try_install "neovim" "apt"
try_install "ripgrep" "apt"
try_install "alacritty" "apt" "flatpak:org.alacritty.Alacritty"
try_install "fzf" "apt"
try_install "bat" "apt"
try_install "zoxide" "apt"
try_install "tmux" "apt"
try_install "htop" "apt"
try_install "btop" "apt"
try_install "tree" "apt"
try_install "fd-find" "apt"
try_install "jq" "apt"
try_install "unzip" "apt"
try_install "zip" "apt"
try_install "lazygit" "flatpak:io.github.jesseduffield.lazygit"
try_install "openssh-client" "apt"
try_install "openssh-server" "apt"

# Alias batcat to bat and fdfind to fd
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -s /usr/bin/batcat /usr/local/bin/bat
fi
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -s /usr/bin/fdfind /usr/local/bin/fd
fi

# Github CLI
if ! command -v gh &>/dev/null; then
    log "Installing GitHub CLI..."
    (type -p wget >/dev/null || (apt update && apt-get install wget -y)) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y \
    && SUCCESSFUL_INSTALLS+=("GitHub CLI") || FAILED_INSTALLS+=("GitHub CLI")
fi

# Starship
if ! command -v starship &>/dev/null; then
  log "Installing starship via curl..."
  if curl -sS https://starship.rs/install.sh | sh -s -- --yes; then
    SUCCESSFUL_INSTALLS+=("starship (curl)")
  else
    FAILED_INSTALLS+=("starship (curl)")
  fi
fi

# Window Manager & Desktop
log "Installing window manager and desktop tools..."
try_install "i3" "apt"
try_install "picom" "apt"
try_install "polybar" "apt"
try_install "rofi" "apt"
try_install "dunst" "apt"
try_install "feh" "apt"
try_install "maim" "apt"
try_install "xclip" "apt"
try_install "xdotool" "apt"
try_install "thunar" "apt"

# Browsers
log "Installing browsers..."
try_install "firefox" "apt"
try_install "google-chrome" "flatpak:com.google.Chrome"

# Applications
log "Installing applications..."
try_install "vscode" "flatpak:com.visualstudio.code"
try_install "obsidian" "flatpak:md.obsidian.Obsidian"
try_install "libreoffice" "apt"
try_install "spotify" "flatpak:com.spotify.Client"
try_install "slack" "flatpak:com.slack.Slack"
try_install "discord" "flatpak:com.discordapp.Discord"

# Additional System Tools
log "Installing additional system tools..."
try_install "ncdu" "apt"
try_install "zsh" "apt"
try_install "unrar" "apt"
try_install "zathura" "apt"
try_install "tesseract-ocr" "apt"
try_install "blueman" "apt"
try_install "remmina" "apt"

# Docker & Database
log "Installing Docker and database tools..."
try_install "docker.io" "apt"
try_install "docker-compose" "apt"
try_install "postgresql" "apt"

# ============================================================================
# PHASE 5: Install Python with uv
# ============================================================================
log "PHASE 5: Installing Python and uv package manager..."

try_install "python3" "apt"
try_install "python3-pip" "apt"

log "Installing uv via curl..."
if sudo -u "$REGULAR_USER" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'; then
  log "uv installed successfully"
  SUCCESSFUL_INSTALLS+=("uv (curl)")
else
  error "Failed to install uv"
  FAILED_INSTALLS+=("uv")
fi

# ============================================================================
# PHASE 6: Install nvm and Node.js LTS
# ============================================================================
log "PHASE 6: Installing nvm and Node.js LTS..."

NVM_DIR="$USER_HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  log "Installing nvm..."
  if sudo -u "$REGULAR_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'; then
    log "nvm installed successfully"
    SUCCESSFUL_INSTALLS+=("nvm")

    # Load nvm and install LTS
    log "Installing Node.js LTS..."
    sudo -u "$REGULAR_USER" bash -c "
      export NVM_DIR=\"$NVM_DIR\"
      [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\"
      nvm install --lts
    "

    if [ $? -eq 0 ]; then
      log "Node.js LTS installed successfully"
      SUCCESSFUL_INSTALLS+=("Node.js LTS via nvm")
    else
      error "Failed to install Node.js LTS"
      FAILED_INSTALLS+=("Node.js LTS")
    fi
  else
    error "Failed to install nvm"
    FAILED_INSTALLS+=("nvm")
  fi
else
  log "nvm is already installed"
  SKIPPED_INSTALLS+=("nvm - already installed")
fi

# ============================================================================
# PHASE 7: Install AWS CLI v2
# ============================================================================
log "PHASE 7: Installing AWS CLI v2..."
if ! command -v aws &>/dev/null; then
    log "Downloading AWS CLI v2..."
    TEMP_AWS=$(mktemp -d)
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TEMP_AWS/awscliv2.zip"
unzip -q "$TEMP_AWS/awscliv2.zip" -d "$TEMP_AWS"
$TEMP_AWS/aws/install
rm -rf "$TEMP_AWS"
SUCCESSFUL_INSTALLS+=("AWS CLI v2")
else
    SKIPPED_INSTALLS+=("AWS CLI v2 - already installed")
fi

# ============================================================================
# PHASE 8: Install JetBrains Mono Nerd Font
# ============================================================================
log "PHASE 8: Installing JetBrains Mono Nerd Font..."

log "Installing JetBrains Mono Nerd Font manually..."
mkdir -p /usr/share/fonts/truetype/jetbrains-mono
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
TEMP_FONT=$(mktemp -d)

if wget -q "$FONT_URL" -O "$TEMP_FONT/JetBrainsMono.zip" 2>/dev/null; then
  if unzip -q "$TEMP_FONT/JetBrainsMono.zip" -d "$TEMP_FONT" 2>/dev/null; then
    cp "$TEMP_FONT"/*.ttf /usr/share/fonts/truetype/jetbrains-mono/ 2>/dev/null
    fc-cache -f
    log "JetBrains Mono Nerd Font installed successfully"
    SUCCESSFUL_INSTALLS+=("JetBrains Mono Nerd Font")
  else
    error "Failed to extract font"
    FAILED_INSTALLS+=("JetBrains Mono Nerd Font - extraction")
  fi
else
  error "Failed to download font"
  FAILED_INSTALLS+=("JetBrains Mono Nerd Font - download")
fi
rm -rf "$TEMP_FONT"

# ============================================================================
# PHASE 9: Configure Services
# ============================================================================
log "PHASE 9: Configuring services..."

# Docker configuration
if command -v docker &>/dev/null; then
  log "Configuring Docker..."

  mkdir -p /etc/docker
  cat >/etc/docker/daemon.json <<EOF
{
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

  systemctl enable docker
  systemctl start docker

  usermod -aG docker "$REGULAR_USER"

  log "Docker configured and started"
  SUCCESSFUL_INSTALLS+=("Docker configuration")
  warn "Note: $REGULAR_USER added to docker group. Log out and back in for changes to take effect."
fi

# PostgreSQL initialization (Ubuntu handles this during apt install)
if command -v psql &>/dev/null; then
  systemctl enable postgresql
  systemctl start postgresql
  log "PostgreSQL started"
  SUCCESSFUL_INSTALLS+=("PostgreSQL service")
fi

# ============================================================================
# PHASE 10: Setup Starship Configuration
# ============================================================================
log "PHASE 10: Setting up Starship configuration..."

CONFIG_DIR="$USER_HOME/.config"
sudo -u "$REGULAR_USER" mkdir -p "$CONFIG_DIR"

cat >"$CONFIG_DIR/starship.toml" <<'EOF'
# Starship configuration
format = """
$username\$hostname
$directory
$git_branch
$git_state
$git_status
$cmd_duration
$line_break
$python
$nodejs
$rust
$docker_context
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = "🌱 "
format = "[$symbol$branch]($style) "

[git_status]
format = '([$all_status$ahead_behind]($style) )'

[cmd_duration]
min_time = 4
show_milliseconds = false
disabled = false
style = "bold italic red"

[python]
symbol = "🐍 "
format = 'via [$symbol$pyenv_prefix($version )(\$virtualenv\ )]($style)'

[nodejs]
symbol = "⬢ "
format = 'via [$symbol($version )]($style)'

[rust]
symbol = "🦀 "
format = 'via [$symbol($version )]($style)'

[docker_context]
symbol = "🐳 "
format = 'via [$symbol$context]($style) '
EOF

chown -R "$USER_UID":"$USER_GID" "$CONFIG_DIR"
log "Starship configuration created"
SUCCESSFUL_INSTALLS+=("Starship configuration")

# ============================================================================
# FINAL REPORT
# ============================================================================
echo
echo -e "${BLUE}=====================================================================
                         INSTALLATION REPORT
=====================================================================${NC}"

echo -e "\n${GREEN}Successfully Installed (${#SUCCESSFUL_INSTALLS[@]} items):${NC}"
for item in "${SUCCESSFUL_INSTALLS[@]}"; do
  echo -e "  ${GREEN}✓${NC} $item"
done

echo -e "\n${YELLOW}Skipped (${#SKIPPED_INSTALLS[@]} items):${NC}"
for item in "${SKIPPED_INSTALLS[@]}"; do
  echo -e "  ${YELLOW}⚠${NC} $item"
done

echo -e "\n${RED}Failed Installations (${#FAILED_INSTALLS[@]} items):${NC}"
for item in "${FAILED_INSTALLS[@]}"; do
  echo -e "  ${RED}✗${NC} $item"
done

echo
echo -e "${BLUE}=====================================================================${NC}"

# Save report to file
LOG_FILE="/var/log/environment-setup-ubuntu-$(date +%Y%m%d-%H%M%S).log"
{
  echo "Environment Setup Report (Ubuntu) - $(date)"
  echo "========================================