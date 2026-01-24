#!/bin/bash
# ===========================================================================
# Arch Linux + Hyprland Environment Setup
# ===========================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUCCESSFUL=()
FAILED=()
SKIPPED=()

log() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[-] $1${NC}" >&2; }

echo -e "${BLUE}=====================================================================
       ARCH LINUX + HYPRLAND ENVIRONMENT SETUP
=====================================================================${NC}"

if [ "$(id -u)" -ne 0 ]; then
    error "Run with sudo"
    exit 1
fi

REGULAR_USER=$(logname)
USER_HOME=$(eval echo ~"$REGULAR_USER")

# ============================================================================
# PHASE 1: System Update + Prerequisites
# ============================================================================
log "PHASE 1: System update + prerequisites..."
pacman -Syu --noconfirm
pacman -S --needed --noconfirm git curl stow wget base-devel
SUCCESSFUL+=("System update + prerequisites")

# ============================================================================
# PHASE 2: Clone & Stow Dotfiles
# ============================================================================
log "PHASE 2: Setting up dotfiles..."

DOTFILES_DIR="$USER_HOME/dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    warn "Dotfiles directory exists, pulling latest..."
    cd "$DOTFILES_DIR"
    sudo -u "$REGULAR_USER" git pull || true
else
    sudo -u "$REGULAR_USER" git clone https://github.com/shyamenk/dotfiles.git "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

STOW_PACKAGES=(
    zsh tmux nvim alacritty wezterm
    hyprland waybar wofi dunst
    yazi bat scripts
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        sudo -u "$REGULAR_USER" stow -R "$pkg" 2>/dev/null && \
            SUCCESSFUL+=("stow: $pkg") || SKIPPED+=("stow: $pkg - conflicts")
    fi
done

cd /
SUCCESSFUL+=("Dotfiles stowed")

# ============================================================================
# PHASE 3: Pacman Packages (Bulk Install)
# ============================================================================
log "PHASE 3: Installing pacman packages..."

PACMAN_PKGS=(
    # Hyprland Stack
    hyprland hypridle hyprlock hyprpaper waybar wofi dunst

    # Wayland Tools
    grim slurp wl-clipboard brightnessctl
    qt5-wayland qt6-wayland xdg-desktop-portal-hyprland

    # Audio
    pipewire pipewire-pulse pipewire-alsa wireplumber
    pavucontrol

    # Network
    networkmanager network-manager-applet

    # Terminals
    alacritty wezterm

    # Dev Tools
    neovim tmux ripgrep fzf bat zoxide fd jq tree unzip zip
    htop btop openssh github-cli

    # File Manager
    thunar

    # OCR
    tesseract tesseract-data-eng

    # Flatpak
    flatpak

    # Fonts
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
)

pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" && \
    SUCCESSFUL+=("Pacman packages") || FAILED+=("Some pacman packages")

# ============================================================================
# PHASE 4: Yay AUR Helper
# ============================================================================
log "PHASE 4: Installing yay..."

if ! command -v yay &>/dev/null; then
    TEMP_YAY="$USER_HOME/tmp_yay"
    rm -rf "$TEMP_YAY"
    sudo -u "$REGULAR_USER" git clone https://aur.archlinux.org/yay-bin.git "$TEMP_YAY"
    cd "$TEMP_YAY"
    sudo -u "$REGULAR_USER" makepkg -si --noconfirm
    cd /
    rm -rf "$TEMP_YAY"
    SUCCESSFUL+=("yay-bin")
else
    SKIPPED+=("yay - already installed")
fi

# ============================================================================
# PHASE 5: AUR Packages (-bin preferred)
# ============================================================================
log "PHASE 5: Installing AUR packages..."

AUR_PKGS=(
    # Wayland Tools
    swww
    wf-recorder
    hyprpicker
    wtype
    cliphist

    # Dev Tools
    eza
    yazi
    lazygit
    starship-bin

    # Network TUI
    impala-bin

    # Browser
    google-chrome

    # Apps
    obsidian-bin
    bruno-bin
    spotify
    spotify-adblock-git

    # AWS
    aws-cli-v2-bin
)

for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Q "$pkg" &>/dev/null || yay -Q "$pkg" &>/dev/null 2>&1; then
        SKIPPED+=("$pkg - already installed")
    else
        if sudo -u "$REGULAR_USER" yay -S --noconfirm "$pkg" 2>/dev/null; then
            SUCCESSFUL+=("$pkg")
        else
            FAILED+=("$pkg")
        fi
    fi
done

# ============================================================================
# PHASE 6: Dev Runtimes (nvm, uv)
# ============================================================================
log "PHASE 6: Installing dev runtimes..."

# nvm + Node.js LTS
NVM_DIR="$USER_HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    sudo -u "$REGULAR_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    sudo -u "$REGULAR_USER" bash -c "
        export NVM_DIR=\"$NVM_DIR\"
        [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\"
        nvm install --lts
    "
    SUCCESSFUL+=("nvm + Node.js LTS")
else
    SKIPPED+=("nvm - already installed")
fi

# uv (Python)
if ! command -v uv &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    SUCCESSFUL+=("uv")
else
    SKIPPED+=("uv - already installed")
fi

# ============================================================================
# PHASE 7: Docker
# ============================================================================
log "PHASE 7: Docker setup..."

if ! command -v docker &>/dev/null; then
    pacman -S --needed --noconfirm docker docker-compose
    systemctl enable docker
    systemctl start docker
    usermod -aG docker "$REGULAR_USER"
    SUCCESSFUL+=("docker")
    warn "Log out and back in for docker group"
else
    SKIPPED+=("docker - already installed")
fi

# ============================================================================
# PHASE 8: Services
# ============================================================================
log "PHASE 8: Enabling services..."

systemctl enable NetworkManager
systemctl enable pipewire pipewire-pulse

# Flatpak remote
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# ============================================================================
# PHASE 9: Create directories
# ============================================================================
log "PHASE 9: Creating directories..."

sudo -u "$REGULAR_USER" mkdir -p "$USER_HOME"/{Pictures,Videos,Documents,Projects,.local/bin}

# ============================================================================
# FINAL REPORT
# ============================================================================
echo
echo -e "${BLUE}=====================================================================
                         INSTALLATION REPORT
=====================================================================${NC}"

echo -e "\n${GREEN}Successful (${#SUCCESSFUL[@]}):${NC}"
for item in "${SUCCESSFUL[@]}"; do echo -e "  ${GREEN}✓${NC} $item"; done

echo -e "\n${YELLOW}Skipped (${#SKIPPED[@]}):${NC}"
for item in "${SKIPPED[@]}"; do echo -e "  ${YELLOW}⚠${NC} $item"; done

echo -e "\n${RED}Failed (${#FAILED[@]}):${NC}"
for item in "${FAILED[@]}"; do echo -e "  ${RED}✗${NC} $item"; done

LOG_FILE="/var/log/hyprland-setup-$(date +%Y%m%d-%H%M%S).log"
{
    echo "Setup Report - $(date)"
    echo "Successful: ${SUCCESSFUL[*]}"
    echo "Skipped: ${SKIPPED[*]}"
    echo "Failed: ${FAILED[*]}"
} > "$LOG_FILE"

echo
echo -e "${YELLOW}POST-INSTALL:${NC}"
echo "  1. Log out/in for docker group"
echo "  2. Source shell: source ~/.zshrc"
echo "  3. Start Hyprland: Hyprland"
echo
log "Setup complete! Report: $LOG_FILE"
