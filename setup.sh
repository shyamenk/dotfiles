#!/bin/bash
# ===========================================================================
# Arch Linux + Hyprland Environment Setup
# ===========================================================================

# Don't use set -e - we handle errors manually for better tracking
set -o pipefail

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

# Get regular user - try multiple methods
REGULAR_USER="${SUDO_USER:-$(logname 2>/dev/null)}"
if [ -z "$REGULAR_USER" ] || [ "$REGULAR_USER" = "root" ]; then
    error "Cannot determine regular user. Run with: sudo ./setup.sh"
    exit 1
fi
USER_HOME=$(getent passwd "$REGULAR_USER" | cut -d: -f6)

log "Installing for user: $REGULAR_USER ($USER_HOME)"

# ============================================================================
# PHASE 1: System Update + Prerequisites
# ============================================================================
log "PHASE 1: System update + prerequisites..."
if pacman -Syu --noconfirm; then
    SUCCESSFUL+=("System update")
else
    FAILED+=("System update")
    error "System update failed - continuing anyway"
fi

if pacman -S --needed --noconfirm git curl stow wget base-devel; then
    SUCCESSFUL+=("Prerequisites")
else
    FAILED+=("Prerequisites")
    error "Prerequisites failed - this may cause issues"
fi

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
    yazi bat scripts cmdx
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        sudo -u "$REGULAR_USER" stow -R "$pkg" 2>/dev/null && \
            SUCCESSFUL+=("stow: $pkg") || SKIPPED+=("stow: $pkg - conflicts")
    fi
done

cd /
SUCCESSFUL+=("Dotfiles stowed")

# Copy wallpapers to Pictures
WALLPAPER_SRC="$DOTFILES_DIR/wallpaper"
WALLPAPER_DEST="$USER_HOME/Pictures/wallpaper"
if [ -d "$WALLPAPER_SRC" ]; then
    sudo -u "$REGULAR_USER" mkdir -p "$WALLPAPER_DEST"
    sudo -u "$REGULAR_USER" cp -r "$WALLPAPER_SRC"/* "$WALLPAPER_DEST"/ 2>/dev/null && \
        SUCCESSFUL+=("Wallpapers copied to ~/Pictures/wallpaper") || \
        FAILED+=("Wallpaper copy")
fi

# ============================================================================
# PHASE 3: Pacman Packages (Bulk Install)
# ============================================================================
log "PHASE 3: Installing pacman packages..."

PACMAN_PKGS=(
    # Hyprland Stack
    hyprland hypridle hyprlock hyprpaper waybar wofi dunst

    # Wayland Essentials
    grim slurp wl-clipboard brightnessctl
    qt5-wayland qt6-wayland xdg-desktop-portal-hyprland
    polkit-gnome xdg-user-dirs

    # Audio
    pipewire pipewire-pulse pipewire-alsa wireplumber
    pavucontrol

    # Network (using iwd backend for impala TUI)
    networkmanager iwd impala

    # Shell & Terminals
    zsh alacritty wezterm

    # Dev Tools
    neovim tmux ripgrep fzf bat zoxide fd jq tree unzip zip
    htop btop openssh github-cli lazydocker man-db

    # File Manager
    thunar tumbler ffmpegthumbnailer

    # OCR
    tesseract tesseract-data-eng

    # Office & Productivity
    libreoffice-fresh xournalpp

    # Flatpak
    flatpak

    # Fonts
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

    # GPU Drivers - NVIDIA Primary
    linux-headers
    nvidia-dkms nvidia-utils nvidia-settings
    libva-nvidia-driver
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

    # Browser
    google-chrome

    # Apps
    obsidian-bin
    bruno-bin
    spotify
    spotify-adblock-git

    # AWS
    aws-cli-v2-bin

    # Productivity
    pinta
    typora
    zoom
    opencode-bin

    # GPU Management
    envycontrol
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
# PHASE 8: NVIDIA Configuration
# ============================================================================
log "PHASE 8: Configuring NVIDIA drivers..."

# Add NVIDIA modules to mkinitcpio
if grep -q "^MODULES=" /etc/mkinitcpio.conf; then
    if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
        sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        SUCCESSFUL+=("mkinitcpio NVIDIA modules")
    else
        SKIPPED+=("mkinitcpio NVIDIA modules - already configured")
    fi
fi

# Create NVIDIA modprobe config
cat > /etc/modprobe.d/nvidia.conf << 'EOF'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
SUCCESSFUL+=("NVIDIA modprobe config")

# Rebuild initramfs
log "Rebuilding initramfs..."
mkinitcpio -P && SUCCESSFUL+=("mkinitcpio rebuild") || FAILED+=("mkinitcpio rebuild")

# Enable NVIDIA suspend/resume services
systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null && \
    SUCCESSFUL+=("NVIDIA power services") || warn "NVIDIA power services not available"

# ============================================================================
# PHASE 9: Services
# ============================================================================
log "PHASE 9: Enabling services..."

# Enable iwd first (required for NetworkManager iwd backend)
systemctl enable iwd && SUCCESSFUL+=("iwd service") || FAILED+=("iwd service")

# Configure NetworkManager to use iwd backend
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/wifi_backend.conf << 'EOF'
[device]
wifi.backend=iwd
EOF
SUCCESSFUL+=("NetworkManager iwd backend config")

systemctl enable NetworkManager && SUCCESSFUL+=("NetworkManager service") || FAILED+=("NetworkManager service")

# Note: pipewire user services are enabled by default, no need to enable system-wide

# Flatpak remote
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && \
    SUCCESSFUL+=("Flathub remote") || warn "Flathub remote already exists or failed"

# Create XDG user directories
sudo -u "$REGULAR_USER" xdg-user-dirs-update 2>/dev/null || true

# ============================================================================
# PHASE 10: Create directories
# ============================================================================
log "PHASE 10: Creating directories..."

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
echo "  1. Set zsh as default shell: chsh -s /bin/zsh"
echo "  2. Log out/in for docker group + shell change"
echo "  3. Start Hyprland: Hyprland"
echo
log "Setup complete! Report: $LOG_FILE"
