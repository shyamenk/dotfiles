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
    error "Usage: sudo ./setup.sh [user-password]"
    exit 1
fi

# User is always shyamenk on this machine
REGULAR_USER="shyamenk"
USER_HOME="/home/$REGULAR_USER"

if ! id "$REGULAR_USER" &>/dev/null; then
    error "User '$REGULAR_USER' does not exist. Create it first during archinstall."
    exit 1
fi

# Accept password as first arg — used to pre-seed sudo and set account password.
# Never hardcode here; pass at runtime: sudo ./setup.sh yourpassword
USER_PASS="${1:-}"

# ============================================================================
# Password & NOPASSWD setup — eliminates ALL prompts during yay/makepkg/flatpak
# ============================================================================
SUDOERS_TMP="/etc/sudoers.d/zzz-setup-nopasswd"
echo "$REGULAR_USER ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_TMP"
chmod 440 "$SUDOERS_TMP"
trap 'rm -f "$SUDOERS_TMP"; log "NOPASSWD sudoers removed."' EXIT

# Set user password so sudo cache is valid from the start
if [ -n "$USER_PASS" ]; then
    echo "$REGULAR_USER:$USER_PASS" | chpasswd
    log "Password set for $REGULAR_USER"
    # Pre-seed sudo timestamp so yay's internal sudo calls don't prompt
    sudo -u "$REGULAR_USER" sudo -S -v <<< "$USER_PASS" 2>/dev/null || true
fi

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
# Stow BEFORE package installs — apps create default .config dirs that
# conflict with stow symlinks if they run first.
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

# Create target dirs BEFORE stow to prevent package-created defaults from conflicting
sudo -u "$REGULAR_USER" mkdir -p "$USER_HOME/.config"

STOW_PACKAGES=(
    zsh tmux nvim alacritty wezterm kitty
    hyprland waybar wofi dunst
    yazi bat scripts cmdx
    starship zathura systemd
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        sudo -u "$REGULAR_USER" stow --adopt -R "$pkg" 2>/dev/null && \
            SUCCESSFUL+=("stow: $pkg") || SKIPPED+=("stow: $pkg - conflicts")
    fi
done

cd /
SUCCESSFUL+=("Dotfiles stowed")

# Copy wallpapers to Pictures
WALLPAPER_SRC="$DOTFILES_DIR/wallpapers"
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
    # ---- Hyprland Stack ----
    hyprland hypridle hyprlock waybar wofi dunst

    # ---- Wayland Essentials ----
    grim slurp wl-clipboard brightnessctl
    qt5-wayland qt6-wayland
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    xdg-user-dirs xdg-utils
    polkit-gnome qt5ct

    # ---- Wayland Tools (all in extra/) ----
    swww hyprpicker wtype cliphist wf-recorder

    # ---- Audio ----
    pipewire pipewire-pulse pipewire-alsa wireplumber
    pavucontrol

    # ---- Bluetooth (bluez installed by archinstall, add GUI) ----
    blueman

    # ---- Network (using iwd backend for impala TUI) ----
    networkmanager iwd impala

    # ---- Shell & Terminals ----
    zsh alacritty wezterm kitty

    # ---- Dev Tools ----
    neovim tmux ripgrep fzf bat zoxide fd jq tree unzip zip
    htop btop openssh github-cli lazydocker lazygit man-db
    eza starship

    # ---- File Manager ----
    thunar tumbler ffmpegthumbnailer

    # ---- OCR ----
    tesseract tesseract-data-eng

    # ---- Office & Productivity ----
    libreoffice-fresh xournalpp

    # ---- Flatpak ----
    flatpak

    # ---- Fonts ----
    ttf-jetbrains-mono-nerd ttf-victor-mono-nerd noto-fonts noto-fonts-emoji

    # ---- GPU Drivers - NVIDIA (Lenovo LOQ / RTX 4050) ----
    linux-headers
    nvidia-dkms nvidia-utils nvidia-settings
    libva-nvidia-driver

    # ---- Docker ----
    docker docker-compose

    # ---- Referenced in dotfiles ----
    pass trash-cli libnotify
    zathura zathura-pdf-poppler
    atuin nushell yazi
    go jdk17-openjdk
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
    # --noconfirm: no prompts; NOPASSWD sudoers handles the pacman install step
    sudo -u "$REGULAR_USER" makepkg -si --noconfirm --noprogressbar
    cd /
    rm -rf "$TEMP_YAY"
    SUCCESSFUL+=("yay-bin")
else
    SKIPPED+=("yay - already installed")
fi

# ============================================================================
# PHASE 5: AUR Packages (only truly AUR-only packages)
# ============================================================================
log "PHASE 5: Installing AUR packages..."

AUR_PKGS=(
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

    # Dev tools
    bun-bin
    spicetify-cli
)

for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        SKIPPED+=("$pkg - already installed")
    else
        if sudo -u "$REGULAR_USER" yay -S --noconfirm --sudoloop --noprogressbar \
                --answerclean None --answerdiff None --answeredit None "$pkg" 2>/dev/null; then
            SUCCESSFUL+=("$pkg")
        else
            FAILED+=("$pkg")
        fi
    fi
done

# ============================================================================
# PHASE 6: Dev Runtimes (nvm, uv, tpm)
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
if ! sudo -u "$REGULAR_USER" bash -c 'command -v uv' &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    SUCCESSFUL+=("uv")
else
    SKIPPED+=("uv - already installed")
fi

# Tmux Plugin Manager (tpm)
TPM_DIR="$USER_HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    sudo -u "$REGULAR_USER" git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    SUCCESSFUL+=("tpm (tmux plugin manager)")
else
    SKIPPED+=("tpm - already installed")
fi

# ============================================================================
# PHASE 7: Docker Setup
# ============================================================================
log "PHASE 7: Docker setup..."

systemctl enable docker
systemctl start docker
if ! id -nG "$REGULAR_USER" | grep -qw docker; then
    usermod -aG docker "$REGULAR_USER"
    SUCCESSFUL+=("docker group added")
    warn "Log out and back in for docker group"
else
    SKIPPED+=("docker group - already member")
fi
SUCCESSFUL+=("docker service enabled")

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

# ---- Bluetooth ----
systemctl enable bluetooth && SUCCESSFUL+=("bluetooth service") || SKIPPED+=("bluetooth - already enabled or not available")

# ---- Network ----
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

# ---- Flatpak ----
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && \
    SUCCESSFUL+=("Flathub remote") || warn "Flathub remote already exists or failed"

# ---- rclone-gdrive user service (stowed via systemd/ package) ----
RCLONE_SERVICE="$USER_HOME/.config/systemd/user/rclone-gdrive.service"
if [ -f "$RCLONE_SERVICE" ]; then
    sudo -u "$REGULAR_USER" systemctl --user daemon-reload
    sudo -u "$REGULAR_USER" systemctl --user enable rclone-gdrive.service
    SUCCESSFUL+=("rclone-gdrive service enabled")
    warn "Run 'rclone config' then start rclone-gdrive.service (needs gdrive remote)"
else
    warn "rclone-gdrive.service not stowed — check dotfiles/systemd package"
    SKIPPED+=("rclone-gdrive service")
fi

# ---- XDG dirs ----
sudo -u "$REGULAR_USER" xdg-user-dirs-update 2>/dev/null || true

# ============================================================================
# PHASE 10: Shell, Directories & Dev Tooling
# ============================================================================
log "PHASE 10: Final setup..."

# Workspace + standard dirs
sudo -u "$REGULAR_USER" mkdir -p \
    "$USER_HOME"/{Pictures/wallpaper,Videos,Documents,workspace,.local/bin} \
    "$USER_HOME/workspace"/{personal,brand-levo,xed} \
    "$USER_HOME/automations"
SUCCESSFUL+=("Directory structure created")

# Auto set zsh as default shell
CURRENT_SHELL=$(getent passwd "$REGULAR_USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "/bin/zsh" ] && [ "$CURRENT_SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /bin/zsh "$REGULAR_USER"
    SUCCESSFUL+=("Default shell set to zsh")
else
    SKIPPED+=("zsh - already default shell")
fi

# ---- SSH key setup ----
SSH_DIR="$USER_HOME/.ssh"
if [ ! -f "$SSH_DIR/id_ed25519" ]; then
    sudo -u "$REGULAR_USER" mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    warn "No SSH key found. Generate one manually:"
    warn "  ssh-keygen -t ed25519 -C \"$REGULAR_USER\" && gh auth login"
    SKIPPED+=("SSH key — manual step required")
else
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_DIR"/id_* 2>/dev/null || true
    chmod 644 "$SSH_DIR"/*.pub 2>/dev/null || true
    SUCCESSFUL+=("SSH key permissions set")
fi

# ---- Atuin shell history ----
if command -v atuin &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'atuin init zsh > /dev/null 2>&1 || true'
    # Import existing shell history into atuin
    sudo -u "$REGULAR_USER" bash -c '
        export HOME='"$USER_HOME"'
        atuin import auto 2>/dev/null || true
    '
    SUCCESSFUL+=("atuin initialized")
else
    SKIPPED+=("atuin — not installed")
fi


# ============================================================================
# FINAL REPORT
# ============================================================================

# Remove temporary sudoers (trap also handles this on exit)
rm -f "$SUDOERS_TMP"

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
echo -e "${YELLOW}HOW TO RUN:${NC}"
echo "  sudo ./setup.sh yourpassword"
echo
echo -e "${YELLOW}POST-INSTALL:${NC}"
echo "  1. Reboot (docker group + shell change take effect)"
echo "  2. Start Hyprland: Hyprland"
echo "  3. Tmux: prefix + I to install plugins"
echo "  4. SSH: ssh-keygen -t ed25519 -C \"shyamenk@gmail.com\" && gh auth login"
echo "  5. Atuin: atuin login && atuin sync"
echo "  6. rclone: rclone config  →  systemctl --user start rclone-gdrive"
echo "  7. pass: gpg --import gpg-private.asc  →  clone pass-store"
echo "  See: ~/dotfiles/secrets-checklist.md"
echo
log "Setup complete! Report: $LOG_FILE"
