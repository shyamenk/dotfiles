#!/bin/bash
# ===========================================================================
# Automated Clean Environment Provisioning for Arch Linux
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
      AUTOMATED ARCH LINUX ENVIRONMENT SETUP
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

pacman -Syu --noconfirm

log "Installing git, curl, stow, wget, base-devel..."
pacman -S --needed --noconfirm git curl stow wget base-devel

SUCCESSFUL_INSTALLS+=("Essential prerequisites: git, curl, stow, wget, base-devel")

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
if sudo -u "$REGULAR_USER" git clone https://github.com/shyamenk/dotfiles.git "$DOTFILES_DIR"; then
  log "Successfully cloned dotfiles"
  SUCCESSFUL_INSTALLS+=("Dotfiles clone")

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
else
  error "Failed to clone dotfiles repository"
  FAILED_INSTALLS+=("Dotfiles clone")
fi

# ============================================================================
# PHASE 3: Setup Package Managers (yay & flatpak)
# ============================================================================
log "PHASE 3: Setting up package managers..."

# Install yay
if ! command -v yay &>/dev/null; then
  log "Installing yay AUR helper..."

  TEMP_YAY="$USER_HOME/tmp_yay_install"
  rm -rf "$TEMP_YAY"

  if sudo -u "$REGULAR_USER" git clone https://aur.archlinux.org/yay.git "$TEMP_YAY"; then
    cd "$TEMP_YAY"
    if sudo -u "$REGULAR_USER" makepkg -si --noconfirm; then
      log "yay installed successfully"
      SUCCESSFUL_INSTALLS+=("yay AUR helper")
    else
      error "Failed to build/install yay"
      FAILED_INSTALLS+=("yay AUR helper")
    fi
    cd /
    rm -rf "$TEMP_YAY"
  else
    error "Failed to clone yay repository"
    FAILED_INSTALLS+=("yay clone")
  fi
else
  log "yay is already installed"
  SKIPPED_INSTALLS+=("yay - already installed")
fi

# Install flatpak
if ! command -v flatpak &>/dev/null; then
  log "Installing Flatpak..."
  pacman -S --noconfirm flatpak
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
  pacman)
    if pacman -Q "$pkg" &>/dev/null; then
      SKIPPED_INSTALLS+=("$pkg (already installed)")
      return 0
    fi

    if pacman -S --noconfirm "$pkg" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$pkg (pacman)")
      return 0
    else
      return 1
    fi
    ;;

  yay)
    if pacman -Q "$pkg" &>/dev/null || yay -Q "$pkg" &>/dev/null 2>&1; then
      SKIPPED_INSTALLS+=("$pkg (already installed)")
      return 0
    fi

    if sudo -u "$REGULAR_USER" yay -S --noconfirm "$pkg" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$pkg (yay)")
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
  local methods=("$@")

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
try_install "neovim" "pacman" "yay"
try_install "ripgrep" "pacman" "yay"
try_install "alacritty" "pacman" "yay" "flatpak:org.alacritty.Alacritty"
try_install "fzf" "pacman" "yay"
try_install "bat" "pacman" "yay"
try_install "zoxide" "pacman" "yay"
try_install "tmux" "pacman" "yay"
try_install "htop" "pacman" "yay"
try_install "btop" "pacman" "yay"
try_install "tree" "pacman"
try_install "fd" "pacman" "yay"
try_install "jq" "pacman" "yay"
try_install "unzip" "pacman"
try_install "zip" "pacman"
try_install "yazi" "pacman" "yay"
try_install "eza" "pacman" "yay"
try_install "lazygit" "pacman" "yay"
try_install "openssh" "pacman"
try_install "github-cli" "pacman" "yay"

# Starship (try pacman/yay first, curl as fallback)
if ! try_install "starship" "pacman" "yay"; then
  log "Installing starship via curl..."
  if curl -sS https://starship.rs/install.sh | sh -s -- --yes; then
    SUCCESSFUL_INSTALLS+=("starship (curl)")
  else
    FAILED_INSTALLS+=("starship (curl)")
  fi
fi

# Window Manager & Desktop
log "Installing window manager and desktop tools..."
try_install "i3-wm" "pacman"
try_install "picom" "pacman" "yay"
try_install "polybar" "pacman" "yay"
try_install "rofi" "pacman" "yay"
try_install "dunst" "pacman" "yay"
try_install "feh" "pacman"
try_install "maim" "pacman"
try_install "xclip" "pacman"
try_install "xdotool" "pacman"
try_install "thunar" "pacman"

# Browsers
log "Installing browsers..."
try_install "firefox" "pacman"
try_install "google-chrome" "yay"

# Applications
log "Installing applications..."
try_install "visual-studio-code-bin" "yay" "flatpak:com.visualstudio.code"
try_install "typora" "yay"
try_install "obsidian" "yay" "flatpak:md.obsidian.Obsidian"
try_install "libreoffice-fresh" "pacman"
try_install "spotify" "yay" "flatpak:com.spotify.Client"
try_install "localsend-bin" "yay"
try_install "beekeeper-studio-bin" "yay"
try_install "slack-desktop" "yay" "flatpak:com.slack.Slack"

# Additional System Tools
log "Installing additional system tools..."
try_install "ncdu" "pacman"
try_install "glow" "pacman" "yay"
try_install "zsh" "pacman"
try_install "unrar" "pacman"
try_install "zathura" "pacman"
try_install "zathura-pdf-poppler" "pacman"
try_install "tesseract" "pacman"
try_install "tesseract-data-eng" "pacman"
try_install "blueman" "pacman"
try_install "remmina" "pacman"
try_install "freerdp" "pacman"

# Docker & Database
log "Installing Docker and database tools..."
try_install "docker" "pacman"
try_install "docker-compose" "pacman"
try_install "postgresql" "pacman"
try_install "lazydocker" "yay"

# ============================================================================
# PHASE 5: Install Python with uv
# ============================================================================
log "PHASE 5: Installing Python and uv package manager..."

try_install "python" "pacman"
try_install "python-pip" "pacman"

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
try_install "aws-cli-v2" "yay"

# ============================================================================
# PHASE 8: Install JetBrains Mono Nerd Font
# ============================================================================
log "PHASE 8: Installing JetBrains Mono Nerd Font..."

if try_install "ttf-jetbrains-mono-nerd" "yay"; then
  log "JetBrains Mono Nerd Font installed from AUR"
else
  log "Installing JetBrains Mono Nerd Font manually..."

  mkdir -p /usr/share/fonts/TTF
  FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
  TEMP_FONT=$(mktemp -d)

  if wget -q "$FONT_URL" -O "$TEMP_FONT/JetBrainsMono.zip" 2>/dev/null; then
    if unzip -q "$TEMP_FONT/JetBrainsMono.zip" -d "$TEMP_FONT" 2>/dev/null; then
      cp "$TEMP_FONT"/*.ttf /usr/share/fonts/TTF/ 2>/dev/null
      fc-cache -f
      log "JetBrains Mono Nerd Font installed successfully"
      SUCCESSFUL_INSTALLS+=("JetBrains Mono Nerd Font (manual)")
    else
      error "Failed to extract font"
      FAILED_INSTALLS+=("JetBrains Mono Nerd Font - extraction")
    fi
  else
    error "Failed to download font"
    FAILED_INSTALLS+=("JetBrains Mono Nerd Font - download")
  fi

  rm -rf "$TEMP_FONT"
fi

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

# PostgreSQL initialization
if command -v postgres &>/dev/null; then
  log "Initializing PostgreSQL..."

  if [ ! -d "/var/lib/postgres/data" ]; then
    sudo -u postgres initdb -D /var/lib/postgres/data
    systemctl enable postgresql
    systemctl start postgresql
    log "PostgreSQL initialized and started"
    SUCCESSFUL_INSTALLS+=("PostgreSQL initialization")
  else
    log "PostgreSQL already initialized"
    SKIPPED_INSTALLS+=("PostgreSQL - already initialized")
  fi
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
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$cmd_duration\
$line_break\
$python\
$nodejs\
$rust\
$docker_context\
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
format = 'via [$symbol$pyenv_prefix($version )(\($virtualenv\) )]($style)'

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
LOG_FILE="/var/log/environment-setup-$(date +%Y%m%d-%H%M%S).log"
{
  echo "Environment Setup Report - $(date)"
  echo "========================================"
  echo
  echo "Successfully Installed:"
  printf '%s\n' "${SUCCESSFUL_INSTALLS[@]}"
  echo
  echo "Skipped:"
  printf '%s\n' "${SKIPPED_INSTALLS[@]}"
  echo
  echo "Failed:"
  printf '%s\n' "${FAILED_INSTALLS[@]}"
} >"$LOG_FILE"

log "Full report saved to $LOG_FILE"
log "Setup complete!"

echo
echo -e "${YELLOW}IMPORTANT NOTES:${NC}"
echo -e "  1. Log out and back in for docker group changes to take effect"
echo -e "  2. Source your shell configuration to use nvm: source ~/.bashrc (or ~/.zshrc)"
echo -e "  3. uv installed to: $USER_HOME/.cargo/bin/uv"
echo -e "  4. Dotfiles applied from: $DOTFILES_DIR"
echo
