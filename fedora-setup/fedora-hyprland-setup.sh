#!/bin/bash
# ===========================================================================
# Fedora Workstation + Hyprland + NVIDIA Setup
# Converted from Arch Linux setup for Fedora 41+
# ===========================================================================

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
       FEDORA WORKSTATION + HYPRLAND + NVIDIA SETUP
=====================================================================${NC}"

if [ "$(id -u)" -ne 0 ]; then
    error "Run with sudo"
    exit 1
fi

# Get regular user
REGULAR_USER="${SUDO_USER:-$(logname 2>/dev/null)}"
if [ -z "$REGULAR_USER" ] || [ "$REGULAR_USER" = "root" ]; then
    error "Cannot determine regular user. Run with: sudo ./fedora-hyprland-setup.sh"
    exit 1
fi
USER_HOME=$(getent passwd "$REGULAR_USER" | cut -d: -f6)

log "Installing for user: $REGULAR_USER ($USER_HOME)"

# ============================================================================
# PHASE 0: Enable RPM Fusion & Third-Party Repos
# ============================================================================
log "PHASE 0: Enabling repositories..."

# Enable RPM Fusion Free & Nonfree
if ! dnf repolist | grep -q rpmfusion-free; then
    dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
        SUCCESSFUL+=("RPM Fusion repos") || FAILED+=("RPM Fusion repos")
else
    SKIPPED+=("RPM Fusion - already enabled")
fi

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null && \
    SUCCESSFUL+=("Flathub") || SKIPPED+=("Flathub - already added")

# Enable COPR for Hyprland
dnf copr enable -y solopasha/hyprland && \
    SUCCESSFUL+=("Hyprland COPR") || FAILED+=("Hyprland COPR")

# Enable better fonts
dnf copr enable -y kylegospo/gnome-vrr && \
    SUCCESSFUL+=("Better fonts COPR") || warn "Fonts COPR failed"

# ============================================================================
# PHASE 1: System Update + Prerequisites
# ============================================================================
log "PHASE 1: System update + prerequisites..."
if dnf update -y --refresh; then
    SUCCESSFUL+=("System update")
else
    FAILED+=("System update")
    error "System update failed - continuing anyway"
fi

if dnf install -y git curl stow wget @development-tools kernel-devel kernel-headers; then
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
    yazi bat scripts cmdx sfdocs kitty
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        sudo -u "$REGULAR_USER" stow -R "$pkg" 2>/dev/null && \
            SUCCESSFUL+=("stow: $pkg") || SKIPPED+=("stow: $pkg - conflicts")
    fi
done

cd /
SUCCESSFUL+=("Dotfiles stowed")

# Copy wallpapers
WALLPAPER_SRC="$DOTFILES_DIR/wallpaper"
WALLPAPER_DEST="$USER_HOME/Pictures/wallpaper"
if [ -d "$WALLPAPER_SRC" ]; then
    sudo -u "$REGULAR_USER" mkdir -p "$WALLPAPER_DEST"
    sudo -u "$REGULAR_USER" cp -r "$WALLPAPER_SRC"/* "$WALLPAPER_DEST"/ 2>/dev/null && \
        SUCCESSFUL+=("Wallpapers copied") || FAILED+=("Wallpaper copy")
fi

# ============================================================================
# PHASE 3: DNF Packages (Core System)
# ============================================================================
log "PHASE 3: Installing DNF packages..."

DNF_PKGS=(
    # Hyprland Stack (from COPR)
    hyprland hyprpaper hypridle hyprlock waybar wofi dunst

    # Wayland Essentials
    grim slurp wl-clipboard brightnessctl
    qt5-qtwayland qt6-qtwayland xdg-desktop-portal-hyprland
    polkit-gnome xdg-user-dirs xdg-user-dirs-gtk

    # Audio (Fedora uses pipewire by default)
    pipewire pipewire-pulseaudio pipewire-alsa
    wireplumber pavucontrol

    # Network
    NetworkManager NetworkManager-wifi
    iwd network-manager-applet

    # Shell & Terminals
    zsh alacritty util-linux-user

    # Dev Tools - Core
    neovim tmux ripgrep fzf bat fd-find jq tree
    unzip zip p7zip htop btop openssh git-delta
    man-db man-pages

    # File Manager
    thunar tumbler ffmpegthumbnailer

    # OCR
    tesseract tesseract-langpack-eng

    # Office & Productivity
    libreoffice xournalpp

    # Fonts
    google-noto-sans-fonts google-noto-serif-fonts
    google-noto-emoji-fonts google-noto-sans-mono-fonts
    jetbrains-mono-fonts-all
    fira-code-fonts
    liberation-fonts

    # System utilities
    ansible ansible-core
    util-linux

    # Compression
    bzip2 gzip tar xz

    # Python (system)
    python3 python3-pip python3-devel

    # Build essentials
    gcc gcc-c++ make cmake ninja-build

    # Additional utils
    trash-cli
    fastfetch
    zoxide
)

dnf install -y "${DNF_PKGS[@]}" && \
    SUCCESSFUL+=("DNF packages") || FAILED+=("Some DNF packages")

# ============================================================================
# PHASE 4: NVIDIA Drivers (RPM Fusion)
# ============================================================================
log "PHASE 4: Installing NVIDIA drivers..."

# Install NVIDIA drivers from RPM Fusion
NVIDIA_PKGS=(
    akmod-nvidia
    xorg-x11-drv-nvidia
    xorg-x11-drv-nvidia-cuda
    xorg-x11-drv-nvidia-cuda-libs
    nvidia-settings
    nvidia-vaapi-driver
    libva-utils
    vdpauinfo
)

dnf install -y "${NVIDIA_PKGS[@]}" && \
    SUCCESSFUL+=("NVIDIA drivers") || FAILED+=("NVIDIA drivers")

# Install CUDA toolkit for development
dnf install -y cuda cuda-toolkit && \
    SUCCESSFUL+=("CUDA toolkit") || warn "CUDA toolkit failed (optional)"

# ============================================================================
# PHASE 5: Additional Packages from Fedora Repos
# ============================================================================
log "PHASE 5: Installing additional packages..."

ADDITIONAL_PKGS=(
    # Terminals
    kitty wezterm

    # TUI Apps
    lazygit

    # System monitoring
    nvtop  # GPU monitoring
    
    # Clipboard
    wl-clipboard wl-clip-persist

    # Screenshot tools
    swappy

    # Media
    mpv vlc

    # Image viewers/editors
    imv gimp

    # Archive manager
    file-roller
)

dnf install -y "${ADDITIONAL_PKGS[@]}" && \
    SUCCESSFUL+=("Additional packages") || warn "Some additional packages failed"

# ============================================================================
# PHASE 6: Install Packages Not in Repos (Manual/Script)
# ============================================================================
log "PHASE 6: Installing packages from external sources..."

# Install starship prompt
if ! command -v starship &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y' && \
        SUCCESSFUL+=("starship") || FAILED+=("starship")
else
    SKIPPED+=("starship - already installed")
fi

# Install eza (modern ls replacement)
if ! command -v eza &>/dev/null; then
    dnf install -y eza && \
        SUCCESSFUL+=("eza") || FAILED+=("eza")
else
    SKIPPED+=("eza - already installed")
fi

# Install yazi (modern file manager)
if ! command -v yazi &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'cargo install --locked yazi-fm yazi-cli' 2>/dev/null && \
        SUCCESSFUL+=("yazi") || warn "yazi failed - requires rust"
fi

# Install GitHub CLI
if ! command -v gh &>/dev/null; then
    dnf install -y 'dnf-command(config-manager)'
    dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    dnf install -y gh && \
        SUCCESSFUL+=("GitHub CLI") || FAILED+=("GitHub CLI")
else
    SKIPPED+=("GitHub CLI - already installed")
fi

# Install Google Chrome
if ! command -v google-chrome &>/dev/null; then
    cat > /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    dnf install -y google-chrome-stable && \
        SUCCESSFUL+=("Google Chrome") || FAILED+=("Google Chrome")
else
    SKIPPED+=("Google Chrome - already installed")
fi

# Install VS Code
if ! command -v code &>/dev/null; then
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat > /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    dnf install -y code && \
        SUCCESSFUL+=("VS Code") || FAILED+=("VS Code")
else
    SKIPPED+=("VS Code - already installed")
fi

# ============================================================================
# PHASE 7: Flatpak Applications
# ============================================================================
log "PHASE 7: Installing Flatpak applications..."

FLATPAK_APPS=(
    com.obsidian.Obsidian
    com.spotify.Client
    us.zoom.Zoom
    org.signal.Signal
    com.slack.Slack
    org.telegram.desktop
)

for app in "${FLATPAK_APPS[@]}"; do
    if flatpak list | grep -q "$app"; then
        SKIPPED+=("flatpak: $app - already installed")
    else
        sudo -u "$REGULAR_USER" flatpak install -y flathub "$app" 2>/dev/null && \
            SUCCESSFUL+=("flatpak: $app") || FAILED+=("flatpak: $app")
    fi
done

# ============================================================================
# PHASE 8: Dev Runtimes (nvm, uv, rust)
# ============================================================================
log "PHASE 8: Installing dev runtimes..."

# Install Rust (needed for some tools)
if ! command -v cargo &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y' && \
        SUCCESSFUL+=("Rust/Cargo") || FAILED+=("Rust/Cargo")
else
    SKIPPED+=("Rust - already installed")
fi

# nvm + Node.js LTS
NVM_DIR="$USER_HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    sudo -u "$REGULAR_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    sudo -u "$REGULAR_USER" bash -c "
        export NVM_DIR=\"$NVM_DIR\"
        [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\"
        nvm install --lts
        nvm use --lts
    "
    SUCCESSFUL+=("nvm + Node.js LTS")
else
    SKIPPED+=("nvm - already installed")
fi

# uv (Python package manager)
if ! command -v uv &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh' && \
        SUCCESSFUL+=("uv") || FAILED+=("uv")
else
    SKIPPED+=("uv - already installed")
fi

# Install pyenv for Python version management
if ! command -v pyenv &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl https://pyenv.run | bash' && \
        SUCCESSFUL+=("pyenv") || warn "pyenv installation failed"
else
    SKIPPED+=("pyenv - already installed")
fi

# ============================================================================
# PHASE 9: Docker & Podman
# ============================================================================
log "PHASE 9: Docker & Container setup..."

# Install Docker
if ! command -v docker &>/dev/null; then
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable --now docker
    usermod -aG docker "$REGULAR_USER"
    SUCCESSFUL+=("Docker")
    warn "Log out and back in for docker group"
else
    SKIPPED+=("Docker - already installed")
fi

# Install lazydocker
if ! command -v lazydocker &>/dev/null; then
    sudo -u "$REGULAR_USER" bash -c 'curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash' && \
        SUCCESSFUL+=("lazydocker") || warn "lazydocker failed"
else
    SKIPPED+=("lazydocker - already installed")
fi

# Setup NVIDIA Container Toolkit
if command -v docker &>/dev/null; then
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
        tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    dnf install -y nvidia-container-toolkit
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker
    SUCCESSFUL+=("NVIDIA Container Toolkit")
fi

# Install Podman (Fedora's default container runtime)
dnf install -y podman podman-compose podman-docker && \
    SUCCESSFUL+=("Podman") || warn "Podman installation failed"

# Install distrobox for container-based development
dnf install -y distrobox && \
    SUCCESSFUL+=("Distrobox") || warn "Distrobox installation failed"

# ============================================================================
# PHASE 10: Toolbox Container Setup (Optional but recommended)
# ============================================================================
log "PHASE 10: Setting up development toolbox..."

# Create a development toolbox container
if command -v toolbox &>/dev/null; then
    sudo -u "$REGULAR_USER" toolbox create -y dev 2>/dev/null && \
        SUCCESSFUL+=("Dev toolbox container") || SKIPPED+=("Dev toolbox - may already exist")
else
    warn "Toolbox not available, skipping container setup"
fi

# ============================================================================
# PHASE 11: NVIDIA Configuration
# ============================================================================
log "PHASE 11: Configuring NVIDIA drivers..."

# Enable NVIDIA modeset
grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"
SUCCESSFUL+=("NVIDIA kernel parameters")

# Create NVIDIA modprobe config
cat > /etc/modprobe.d/nvidia.conf << 'EOF'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
SUCCESSFUL+=("NVIDIA modprobe config")

# Rebuild initramfs
dracut --force && SUCCESSFUL+=("initramfs rebuild") || FAILED+=("initramfs rebuild")

# Enable NVIDIA suspend/resume services
systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null && \
    SUCCESSFUL+=("NVIDIA power services") || warn "NVIDIA power services not available"

# Set NVIDIA as primary GPU
if command -v nvidia-smi &>/dev/null; then
    # Create env file for NVIDIA
    cat > /etc/environment.d/nvidia.conf << 'EOF'
# NVIDIA Environment Variables
LIBVA_DRIVER_NAME=nvidia
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
MOZ_ENABLE_WAYLAND=1
EOF
    SUCCESSFUL+=("NVIDIA environment variables")
fi

# ============================================================================
# PHASE 12: Hyprland Configuration
# ============================================================================
log "PHASE 12: Configuring Hyprland..."

# Create Hyprland desktop entry
cat > /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
SUCCESSFUL+=("Hyprland desktop entry")

# Set up SDDM (optional display manager)
read -p "Install SDDM display manager? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    dnf install -y sddm
    systemctl enable sddm
    SUCCESSFUL+=("SDDM display manager")
fi

# ============================================================================
# PHASE 13: Services
# ============================================================================
log "PHASE 13: Enabling services..."

# Enable iwd (optional, for impala TUI)
systemctl enable --now iwd && SUCCESSFUL+=("iwd service") || warn "iwd service failed"

# NetworkManager (should already be enabled on Fedora)
systemctl enable --now NetworkManager && SUCCESSFUL+=("NetworkManager service") || SKIPPED+=("NetworkManager - already running")

# ============================================================================
# PHASE 14: Shell Configuration
# ============================================================================
log "PHASE 14: Configuring shell..."

# Install Oh My Zsh (optional)
if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    sudo -u "$REGULAR_USER" bash -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' && \
        SUCCESSFUL+=("Oh My Zsh") || warn "Oh My Zsh failed"
else
    SKIPPED+=("Oh My Zsh - already installed")
fi

# Install zsh-autosuggestions
ZSH_CUSTOM="$USER_HOME/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    sudo -u "$REGULAR_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && \
        SUCCESSFUL+=("zsh-autosuggestions") || warn "zsh-autosuggestions failed"
fi

# Install zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    sudo -u "$REGULAR_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && \
        SUCCESSFUL+=("zsh-syntax-highlighting") || warn "zsh-syntax-highlighting failed"
fi

# ============================================================================
# PHASE 15: Additional Development Tools
# ============================================================================
log "PHASE 15: Installing additional dev tools..."

# AWS CLI v2
if ! command -v aws &>/dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
    SUCCESSFUL+=("AWS CLI v2")
else
    SKIPPED+=("AWS CLI - already installed")
fi

# Terraform
if ! command -v terraform &>/dev/null; then
    dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    dnf install -y terraform && \
        SUCCESSFUL+=("Terraform") || warn "Terraform failed"
else
    SKIPPED+=("Terraform - already installed")
fi

# kubectl
if ! command -v kubectl &>/dev/null; then
    cat > /etc/yum.repos.d/kubernetes.repo << 'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF
    dnf install -y kubectl && \
        SUCCESSFUL+=("kubectl") || warn "kubectl failed"
else
    SKIPPED+=("kubectl - already installed")
fi

# k9s (Kubernetes TUI)
if ! command -v k9s &>/dev/null; then
    curl -sS https://webinstall.dev/k9s | bash
    SUCCESSFUL+=("k9s")
else
    SKIPPED+=("k9s - already installed")
fi

# ============================================================================
# PHASE 16: Create directories
# ============================================================================
log "PHASE 16: Creating directories..."

sudo -u "$REGULAR_USER" mkdir -p "$USER_HOME"/{Pictures,Videos,Documents,Downloads,Projects,.local/bin,workspace}

# Create XDG user directories
sudo -u "$REGULAR_USER" xdg-user-dirs-update 2>/dev/null || true

# ============================================================================
# PHASE 17: Final System Configuration
# ============================================================================
log "PHASE 17: Final system configuration..."

# Disable SELinux for Hyprland (optional but recommended)
read -p "Disable SELinux? (Required for some Hyprland features) (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    SUCCESSFUL+=("SELinux set to permissive")
    warn "Reboot required for SELinux change"
fi

# Enable multilib (32-bit support)
dnf install -y glibc.i686 && SUCCESSFUL+=("32-bit support") || warn "32-bit support failed"

# ============================================================================
# FINAL REPORT
# ============================================================================
echo
echo -e "${BLUE}=====================================================================
                         INSTALLATION REPORT
=====================================================================${NC}"

echo -e "\n${GREEN}✓ Successful (${#SUCCESSFUL[@]}):${NC}"
for item in "${SUCCESSFUL[@]}"; do echo -e "  ${GREEN}✓${NC} $item"; done

echo -e "\n${YELLOW}⚠ Skipped (${#SKIPPED[@]}):${NC}"
for item in "${SKIPPED[@]}"; do echo -e "  ${YELLOW}⚠${NC} $item"; done

echo -e "\n${RED}✗ Failed (${#FAILED[@]}):${NC}"
for item in "${FAILED[@]}"; do echo -e "  ${RED}✗${NC} $item"; done

LOG_FILE="/var/log/fedora-hyprland-setup-$(date +%Y%m%d-%H%M%S).log"
{
    echo "Setup Report - $(date)"
    echo "Successful: ${SUCCESSFUL[*]}"
    echo "Skipped: ${SKIPPED[*]}"
    echo "Failed: ${FAILED[*]}"
} > "$LOG_FILE"

echo
echo -e "${YELLOW}POST-INSTALL STEPS:${NC}"
echo "  1. Reboot system: sudo reboot"
echo "  2. After reboot, set zsh as default shell: chsh -s /bin/zsh"
echo "  3. Log out and back in for group changes"
echo "  4. Start Hyprland from login screen or run: Hyprland"
echo "  5. Test NVIDIA: nvidia-smi"
echo "  6. Setup development toolbox: toolbox enter dev"
echo
log "Setup complete! Full report: $LOG_FILE"
