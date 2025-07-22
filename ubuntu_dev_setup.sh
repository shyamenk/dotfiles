#!/bin/bash
# ===========================================================================
# Development Environment Setup Tool for Ubuntu/Debian
# ===========================================================================

set -e  # Exit on error
set -u  # Treat unset variables as errors

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}====================================================================="
echo -e "    Development Environment Setup for Ubuntu/Debian"
echo -e "====================================================================="
echo -e "${NC}"

# Function to check if running with appropriate permissions
check_permissions() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${RED}ERROR: This script should NOT be run as root${NC}"
        echo -e "${YELLOW}Please run as a regular user. The script will ask for sudo when needed.${NC}"
        exit 1
    fi
    
    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        error "sudo is required but not installed. Please install sudo first."
    fi
}

# Function to log actions
log() {
    echo -e "${GREEN}[+] $1${NC}"
}

# Function to warn
warn() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to handle errors (non-fatal)
handle_error() {
    echo -e "${RED}[-] ERROR: $1${NC}" >&2
    echo -e "${YELLOW}[!] Continuing with installation...${NC}"
}

# Function to handle fatal errors
error() {
    echo -e "${RED}[-] FATAL ERROR: $1${NC}" >&2
    exit 1
}

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to check if a snap package is installed
is_snap_installed() {
    snap list "$1" &> /dev/null 2>&1
}

# Function to check if a flatpak package is installed
is_flatpak_installed() {
    flatpak list | grep -q "$1" 2>/dev/null
}

# Function to install a package with error handling
install_package() {
    local package="$1"
    local method="${2:-apt}"
    
    case "$method" in
        "apt")
            if ! is_installed "$package"; then
                log "Installing $package via apt..."
                sudo apt install -y "$package" || handle_error "Failed to install $package via apt"
            else
                warn "Package $package is already installed"
            fi
            ;;
        "snap")
            if ! is_snap_installed "$package"; then
                log "Installing $package via snap..."
                sudo snap install "$package" || handle_error "Failed to install $package via snap"
            else
                warn "Snap package $package is already installed"
            fi
            ;;
        "flatpak")
            if ! is_flatpak_installed "$package"; then
                log "Installing $package via flatpak..."
                flatpak install -y flathub "$package" || handle_error "Failed to install $package via flatpak"
            else
                warn "Flatpak package $package is already installed"
            fi
            ;;
    esac
}

# Function to update package database
update_package_database() {
    log "Updating package database..."
    sudo apt update || error "Failed to update package database"
}

# Function to upgrade system packages
upgrade_system() {
    log "Upgrading system packages..."
    sudo apt upgrade -y || handle_error "Failed to upgrade some packages"
}

# Function to install essential dependencies
install_essential_dependencies() {
    log "Installing essential dependencies..."
    
    local essential_packages=(
        "curl"
        "wget"
        "git"
        "build-essential"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "unzip"
        "zip"
        "tree"
        "htop"
        "jq"
        "stow"
    )
    
    for pkg in "${essential_packages[@]}"; do
        install_package "$pkg" "apt"
    done
}

# Function to add repositories
add_repositories() {
    log "Adding necessary repositories..."
    
    # VS Code repository
    if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
        log "Adding VS Code repository..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm packages.microsoft.gpg || true
    fi
    
    # Google Chrome repository
    if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
        log "Adding Google Chrome repository..."
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - || handle_error "Failed to add Google Chrome key"
        sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' || handle_error "Failed to add Google Chrome repository"
    fi
    
    # Docker repository
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        log "Adding Docker repository..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || handle_error "Failed to add Docker key"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || handle_error "Failed to add Docker repository"
    fi
    
    # Update after adding repositories
    sudo apt update || handle_error "Failed to update after adding repositories"
}

# Function to install core development tools
install_core_dev_tools() {
    log "Installing core development tools..."
    
    local core_packages=(
        "neovim"
        "code"
        "git"
        "tmux"
        "fzf"
        "ripgrep"
        "bat"
        "exa"
        "fd-find"
        "zoxide"
    )
    
    for pkg in "${core_packages[@]}"; do
        install_package "$pkg" "apt"
    done
}

# Function to install terminal applications
install_terminal_apps() {
    log "Installing terminal applications..."
    
    local terminal_packages=(
        "alacritty"
        "zsh"
        "fonts-jetbrains-mono"
    )
    
    for pkg in "${terminal_packages[@]}"; do
        install_package "$pkg" "apt"
    done
    
    # Install Kitty terminal
    if ! command -v kitty &> /dev/null; then
        log "Installing Kitty terminal..."
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin || handle_error "Failed to install Kitty"
        
        # Create desktop file for Kitty
        mkdir -p ~/.local/share/applications
        cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/ || handle_error "Failed to create Kitty desktop file"
        
        # Add to PATH
        mkdir -p ~/.local/bin
        ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/ || handle_error "Failed to link Kitty to PATH"
    fi
}

# Function to setup Zsh with Starship and Zimfw
setup_zsh_environment() {
    log "Setting up Zsh environment with Starship and Zimfw..."
    
    # Install Starship
    if ! command -v starship &> /dev/null; then
        log "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y || handle_error "Failed to install Starship"
    fi
    
    # Install Zimfw
    if [ ! -d "${HOME}/.zim" ]; then
        log "Installing Zimfw..."
        curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh || handle_error "Failed to install Zimfw"
    fi
    
    # Configure Zsh as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        log "Setting Zsh as default shell..."
        chsh -s "$(which zsh)" || handle_error "Failed to set Zsh as default shell"
    fi
    
    # Create basic .zshrc if it doesn't exist
    if [ ! -f ~/.zshrc ]; then
        log "Creating basic .zshrc configuration..."
        cat > ~/.zshrc << 'EOF'
# Zimfw initialization
if [[ -s ${ZDOTDIR:-${HOME}}/.zim/init.zsh ]]; then
  source ${ZDOTDIR:-${HOME}}/.zim/init.zsh
fi

# Starship prompt
eval "$(starship init zsh)"

# Aliases
alias ll='exa -la'
alias la='exa -a'
alias ls='exa'
alias cat='bat'
alias cd='z'

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'
EOF
    fi
}

# Function to install programming languages
install_programming_languages() {
    log "Installing programming languages and runtimes..."
    
    # Python and UV package manager
    install_package "python3" "apt"
    install_package "python3-pip" "apt"
    install_package "python3-venv" "apt"
    
    # Install UV package manager
    if ! command -v uv &> /dev/null; then
        log "Installing UV package manager..."
        curl -LsSf https://astral.sh/uv/install.sh | sh || handle_error "Failed to install UV"
    fi
    
    # Install NVM and Node.js
    if [ ! -d "$HOME/.nvm" ]; then
        log "Installing NVM and Node.js..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash || handle_error "Failed to install NVM"
        
        # Source NVM and install latest LTS Node.js
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        
        nvm install --lts || handle_error "Failed to install Node.js LTS"
        nvm use --lts || handle_error "Failed to use Node.js LTS"
    fi
    
    # Install Go
    if ! command -v go &> /dev/null; then
        log "Installing Go..."
        local go_version="1.21.3"
        wget -c "https://golang.org/dl/go${go_version}.linux-amd64.tar.gz" -O /tmp/go.tar.gz || handle_error "Failed to download Go"
        sudo tar -xzf /tmp/go.tar.gz -C /usr/local || handle_error "Failed to extract Go"
        rm /tmp/go.tar.gz || true
        
        # Add Go to PATH
        if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        fi
        if ! grep -q "/usr/local/go/bin" ~/.zshrc; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
        fi
    fi
}

# Function to install Docker and PostgreSQL
install_docker_postgres() {
    log "Installing Docker and Docker Compose..."
    
    local docker_packages=(
        "docker-ce"
        "docker-ce-cli"
        "containerd.io"
        "docker-buildx-plugin"
        "docker-compose-plugin"
    )
    
    for pkg in "${docker_packages[@]}"; do
        install_package "$pkg" "apt"
    done
    
    # Add user to docker group
    sudo usermod -aG docker "$USER" || handle_error "Failed to add user to docker group"
    
    # Enable Docker service
    sudo systemctl enable docker || handle_error "Failed to enable Docker service"
    sudo systemctl start docker || handle_error "Failed to start Docker service"
    
    log "Docker installed. You may need to log out and back in for group changes to take effect."
}

# Function to install text editors and IDEs
install_editors_ides() {
    log "Installing text editors and IDEs..."
    
    # VS Code is already installed via repository
    
    # Install Cursor editor
    if ! command -v cursor &> /dev/null; then
        log "Installing Cursor editor..."
        wget -O /tmp/cursor.deb "https://download.cursor.sh/linux/appImage/x64" || handle_error "Failed to download Cursor"
        # Note: Cursor might be distributed as AppImage, adjust accordingly
        chmod +x /tmp/cursor.deb
        mv /tmp/cursor.deb ~/.local/bin/cursor || handle_error "Failed to install Cursor"
    fi
    
    # Install Claude Code (if available)
    if ! command -v claude-code &> /dev/null; then
        log "Attempting to install Claude Code..."
        # Note: This might need to be adjusted based on actual distribution method
        warn "Claude Code installation might need manual setup"
    fi
    
    # Install Typora
    if ! command -v typora &> /dev/null; then
        log "Installing Typora..."
        wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add - || handle_error "Failed to add Typora key"
        sudo add-apt-repository 'deb https://typora.io/linux ./' || handle_error "Failed to add Typora repository"
        sudo apt update || handle_error "Failed to update after adding Typora repository"
        install_package "typora" "apt"
    fi
}

# Function to install web browsers
install_web_browsers() {
    log "Installing web browsers..."
    
    # Firefox (usually pre-installed)
    install_package "firefox" "apt"
    
    # Google Chrome
    install_package "google-chrome-stable" "apt"
}

# Function to install communication apps
install_communication_apps() {
    log "Installing communication applications..."
    
    # Slack
    install_package "com.slack.Slack" "flatpak"
    
    # Discord
    install_package "com.discordapp.Discord" "flatpak"
    
    # WhatsApp (web wrapper)
    install_package "io.github.mimbrero.WhatsAppDesktop" "flatpak"
}

# Function to install productivity apps
install_productivity_apps() {
    log "Installing productivity applications..."
    
    # Obsidian
    install_package "md.obsidian.Obsidian" "flatpak"
    
    # Beekeeper Studio
    if ! command -v beekeeper-studio &> /dev/null; then
        log "Installing Beekeeper Studio..."
        wget -O /tmp/beekeeper-studio.deb "https://github.com/beekeeper-studio/beekeeper-studio/releases/latest/download/beekeeper-studio_amd64.deb" || handle_error "Failed to download Beekeeper Studio"
        sudo dpkg -i /tmp/beekeeper-studio.deb || handle_error "Failed to install Beekeeper Studio"
        sudo apt install -f -y || handle_error "Failed to fix Beekeeper Studio dependencies"
        rm /tmp/beekeeper-studio.deb || true
    fi
}

# Function to install media and graphics applications
install_media_graphics() {
    log "Installing media and graphics applications..."
    
    # GIMP
    install_package "gimp" "apt"
    
    # VLC
    install_package "vlc" "apt"
    
    # FFmpeg
    install_package "ffmpeg" "apt"
}

# Function to install i3 window manager and related tools
install_i3_environment() {
    log "Installing i3 window manager environment..."
    
    local i3_packages=(
        "i3"
        "i3status"
        "i3lock"
        "picom"
        "polybar"
        "rofi"
        "feh"
        "dunst"
        "thunar"
        "network-manager-gnome"
        "xss-lock"
        "xdotool"
        "maim"
        "xclip"
        "pavucontrol"
        "brightnessctl"
        "tesseract-ocr"
        "tesseract-ocr-eng"
        "xdpyinfo"
        "libnotify-bin"
        "pulseaudio-utils"
    )
    
    for pkg in "${i3_packages[@]}"; do
        install_package "$pkg" "apt"
    done
    
    # Install xcolor (might not be in repositories)
    if ! command -v xcolor &> /dev/null; then
        log "Installing xcolor..."
        wget -O /tmp/xcolor "https://github.com/Soft/xcolor/releases/latest/download/xcolor-linux" || handle_error "Failed to download xcolor"
        chmod +x /tmp/xcolor
        sudo mv /tmp/xcolor /usr/local/bin/ || handle_error "Failed to install xcolor"
    fi
    
    # Install betterlockscreen
    if ! command -v betterlockscreen &> /dev/null; then
        log "Installing betterlockscreen..."
        wget -O /tmp/betterlockscreen "https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh" || handle_error "Failed to download betterlockscreen installer"
        chmod +x /tmp/betterlockscreen
        sudo /tmp/betterlockscreen || handle_error "Failed to install betterlockscreen"
        rm /tmp/betterlockscreen || true
    fi
}

# Function to install system utilities
install_system_utilities() {
    log "Installing system utilities..."
    
    local utilities=(
        "flatpak"
        "curl"
        "wget"
        "tree"
        "htop"
        "btop"
        "neofetch"
    )
    
    for pkg in "${utilities[@]}"; do
        install_package "$pkg" "apt"
    done
    
    # Setup Flatpak
    if command -v flatpak &> /dev/null; then
        log "Setting up Flatpak with Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || handle_error "Failed to add Flathub repository"
    fi
}

# Function to install cloud and DevOps tools
install_cloud_devops_tools() {
    log "Installing cloud and DevOps tools..."
    
    # AWS CLI
    if ! command -v aws &> /dev/null; then
        log "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip || handle_error "Failed to download AWS CLI"
        unzip -q /tmp/awscliv2.zip -d /tmp || handle_error "Failed to extract AWS CLI"
        sudo /tmp/aws/install || handle_error "Failed to install AWS CLI"
        rm -rf /tmp/aws /tmp/awscliv2.zip || true
    fi
    
    # GitHub CLI
    if ! command -v gh &> /dev/null; then
        log "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg || handle_error "Failed to add GitHub CLI key"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null || handle_error "Failed to add GitHub CLI repository"
        sudo apt update || handle_error "Failed to update after adding GitHub CLI repository"
        install_package "gh" "apt"
    fi
}

# Function to install fonts
install_fonts() {
    log "Installing fonts..."
    
    # JetBrains Mono Nerd Font
    if [ ! -d ~/.local/share/fonts ]; then
        mkdir -p ~/.local/share/fonts
    fi
    
    if [ ! -f ~/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf ]; then
        log "Installing JetBrains Mono Nerd Font..."
        wget -O /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" || handle_error "Failed to download JetBrains Mono Nerd Font"
        unzip -q /tmp/JetBrainsMono.zip -d /tmp/JetBrainsMono || handle_error "Failed to extract JetBrains Mono Nerd Font"
        cp /tmp/JetBrainsMono/*.ttf ~/.local/share/fonts/ || handle_error "Failed to copy JetBrains Mono Nerd Font"
        rm -rf /tmp/JetBrainsMono /tmp/JetBrainsMono.zip || true
        
        # Update font cache
        fc-cache -f -v || handle_error "Failed to update font cache"
    fi
}

# Function to setup dotfiles management
setup_dotfiles_management() {
    log "Setting up dotfiles management with GNU Stow..."
    
    # GNU Stow is already installed in essential dependencies
    
    echo -e "${CYAN}=== Dotfiles Setup Options ===${NC}"
    echo -e "${CYAN}1. Clone your dotfiles repository${NC}"
    echo -e "${CYAN}2. Clone the recommended repository (https://github.com/shyamenk/dotfiles.git)${NC}"
    echo -e "${CYAN}3. Skip dotfiles setup${NC}"
    echo -e "${CYAN}Enter your choice (1/2/3):${NC}"
    read -r dotfiles_choice
    
    case "$dotfiles_choice" in
        1)
            echo -e "${CYAN}Please enter your dotfiles repository URL:${NC}"
            read -r dotfiles_repo
            ;;
        2)
            dotfiles_repo="https://github.com/shyamenk/dotfiles.git"
            log "Using recommended dotfiles repository: $dotfiles_repo"
            ;;
        3)
            log "Skipping dotfiles setup"
            return
            ;;
        *)
            warn "Invalid choice, skipping dotfiles setup"
            return
            ;;
    esac
    
    if [ -n "$dotfiles_repo" ]; then
        log "Cloning dotfiles repository from: $dotfiles_repo"
        
        # Remove existing dotfiles directory if it exists
        if [ -d ~/dotfiles ]; then
            warn "Existing dotfiles directory found"
            echo -e "${CYAN}Remove existing dotfiles directory? (y/n):${NC}"
            read -r remove_existing
            if [[ "$remove_existing" =~ ^[Yy]$ ]]; then
                rm -rf ~/dotfiles
                log "Removed existing dotfiles directory"
            else
                warn "Keeping existing dotfiles directory, skipping clone"
                return
            fi
        fi
        
        # Clone the repository
        git clone "$dotfiles_repo" ~/dotfiles || handle_error "Failed to clone dotfiles repository"
        
        if [ -d ~/dotfiles ]; then
            log "Successfully cloned dotfiles repository"
            cd ~/dotfiles || handle_error "Failed to change to dotfiles directory"
            
            # Show repository information
            echo -e "${CYAN}=== Dotfiles Repository Information ===${NC}"
            echo -e "${GREEN}Repository URL: $dotfiles_repo${NC}"
            echo -e "${GREEN}Local path: ~/dotfiles${NC}"
            echo -e "${GREEN}Total size: $(du -sh ~/dotfiles | cut -f1)${NC}"
            
            # List available configurations
            echo -e "${CYAN}=== Available Configurations ===${NC}"
            local config_count=0
            for dir in */; do
                if [ -d "$dir" ]; then
                    config_count=$((config_count + 1))
                    echo -e "${GREEN}  $config_count. ${dir%/}${NC}"
                    
                    # Show what files are in this config
                    local file_count=$(find "$dir" -type f | wc -l)
                    echo -e "${YELLOW}     Contains: $file_count files${NC}"
                    
                    # Show first few files as examples
                    local example_files=$(find "$dir" -type f -name ".*" | head -3 | sed 's|^.*/||' | tr '\n' ' ')
                    if [ -n "$example_files" ]; then
                        echo -e "${YELLOW}     Examples: $example_files${NC}"
                    fi
                fi
            done
            
            if [ $config_count -eq 0 ]; then
                warn "No configuration directories found in dotfiles repository"
                return
            fi
            
            echo -e "${CYAN}=== Stow Application Options ===${NC}"
            echo -e "${CYAN}Would you like to apply dotfiles using GNU Stow? (y/n):${NC}"
            read -r apply_dotfiles
            
            if [[ "$apply_dotfiles" =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}Choose application method:${NC}"
                echo -e "${CYAN}1. Apply all configurations${NC}"
                echo -e "${CYAN}2. Select specific configurations${NC}"
                echo -e "${CYAN}3. Preview what would be linked (dry-run)${NC}"
                echo -e "${CYAN}Enter your choice (1/2/3):${NC}"
                read -r stow_choice
                
                case "$stow_choice" in
                    1)
                        log "Applying all configurations with GNU Stow..."
                        for dir in */; do
                            if [ -d "$dir" ]; then
                                config="${dir%/}"
                                log "Applying $config configuration..."
                                stow -v "$config" 2>&1 | while read -r line; do
                                    echo -e "${YELLOW}    $line${NC}"
                                done || handle_error "Failed to stow $config"
                            fi
                        done
                        ;;
                    2)
                        echo -e "${CYAN}Enter configuration names to apply (space-separated):${NC}"
                        echo -e "${YELLOW}Available: $(ls -d */ | tr -d '/' | tr '\n' ' ')${NC}"
                        read -r configs_to_apply
                        
                        for config in $configs_to_apply; do
                            if [ -d "$config" ]; then
                                log "Applying $config configuration..."
                                stow -v "$config" 2>&1 | while read -r line; do
                                    echo -e "${YELLOW}    $line${NC}"
                                done || handle_error "Failed to stow $config"
                            else
                                warn "Configuration '$config' not found"
                                echo -e "${YELLOW}Available configurations: $(ls -d */ | tr -d '/' | tr '\n' ' ')${NC}"
                            fi
                        done
                        ;;
                    3)
                        log "Preview mode - showing what would be linked..."
                        for dir in */; do
                            if [ -d "$dir" ]; then
                                config="${dir%/}"
                                echo -e "${CYAN}=== Preview for $config ===${NC}"
                                stow -n -v "$config" 2>&1 | while read -r line; do
                                    echo -e "${YELLOW}    $line${NC}"
                                done
                                echo
                            fi
                        done
                        
                        echo -e "${CYAN}Apply configurations after preview? (y/n):${NC}"
                        read -r apply_after_preview
                        if [[ "$apply_after_preview" =~ ^[Yy]$ ]]; then
                            echo -e "${CYAN}Apply all or select specific? (all/select):${NC}"
                            read -r apply_method
                            
                            if [ "$apply_method" = "all" ]; then
                                for dir in */; do
                                    if [ -d "$dir" ]; then
                                        config="${dir%/}"
                                        log "Applying $config configuration..."
                                        stow -v "$config" || handle_error "Failed to stow $config"
                                    fi
                                done
                            else
                                echo -e "${CYAN}Enter configurations to apply (space-separated):${NC}"
                                read -r configs_to_apply
                                for config in $configs_to_apply; do
                                    if [ -d "$config" ]; then
                                        log "Applying $config configuration..."
                                        stow -v "$config" || handle_error "Failed to stow $config"
                                    else
                                        warn "Configuration '$config' not found"
                                    fi
                                done
                            fi
                        fi
                        ;;
                    *)
                        warn "Invalid choice, skipping stow application"
                        ;;
                esac
                
                # Show summary of what was applied
                echo -e "${CYAN}=== Dotfiles Application Summary ===${NC}"
                log "Dotfiles have been processed with GNU Stow"
                log "Symlinks created in your home directory point to ~/dotfiles/"
                log "To manage dotfiles later:"
                log "  - Add new configs: 'cd ~/dotfiles && stow <config-name>'"
                log "  - Remove configs: 'cd ~/dotfiles && stow -D <config-name>'"
                log "  - Update from git: 'cd ~/dotfiles && git pull'"
                
                # Check for any conflicts or issues
                echo -e "${CYAN}=== Checking for potential issues ===${NC}"
                if [ -f ~/.bashrc ] && [ -f ~/.zshrc ]; then
                    warn "Both .bashrc and .zshrc exist - you may want to choose one shell"
                fi
                
                # Backup note
                warn "Important: Original files may have been moved to ~/.dotfiles-backup/ if conflicts occurred"
                
            else
                log "Dotfiles cloned but not applied. You can manually apply them later with:"
                log "  cd ~/dotfiles && stow <configuration-name>"
            fi
        else
            handle_error "Dotfiles directory not found after cloning"
        fi
    else
        warn "No repository URL provided, skipping dotfiles setup"
    fi
}

# Function to configure development environment
configure_dev_environment() {
    log "Configuring development environment..."
    
    # Create development directories
    mkdir -p ~/Development/{projects,scripts,tools}
    mkdir -p ~/Pictures/wallpapers
    mkdir -p ~/.config
    
    # Configure Git (basic template)
    if [ ! -f ~/.gitconfig ]; then
        log "Creating Git configuration template..."
        cat > ~/.gitconfig << EOF
[user]
    name = Your Name
    email = your.email@example.com

[core]
    editor = nvim
    autocrlf = input

[init]
    defaultBranch = main

[pull]
    rebase = false

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    ca = commit -a
    ps = push
    pl = pull
    lg = log --oneline --decorate --all --graph
    unstage = reset HEAD --
EOF
        warn "Please update ~/.gitconfig with your name and email"
    fi
    
    # Add development paths to shell profiles
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc")
    
    for config in "${shell_configs[@]}"; do
        if [ -f "$config" ]; then
            # Add Go paths
            if ! grep -q "GOPATH" "$config"; then
                echo 'export GOPATH=$HOME/go' >> "$config"
                echo 'export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin' >> "$config"
            fi
            
            # Add local bin to PATH
            if ! grep -q '.local/bin' "$config"; then
                echo 'export PATH=$PATH:$HOME/.local/bin' >> "$config"
            fi
            
            # Add UV to PATH
            if ! grep -q '.cargo/bin' "$config"; then
                echo 'export PATH=$PATH:$HOME/.cargo/bin' >> "$config"
            fi
        fi
    done
}

# Function to create documentation
create_documentation() {
    log "Creating system documentation..."
    
    local doc_dir="$HOME/Documents/dev-setup-docs"
    mkdir -p "$doc_dir"
    
    cat > "$doc_dir/README.md" << 'EOF'
# Ubuntu Development Environment Documentation

## Overview
This Ubuntu system has been configured with a comprehensive development environment.

## Installed Software

### Core Development Tools
- **Neovim**: Modern text editor
- **VS Code**: Feature-rich code editor
- **Cursor**: AI-powered code editor
- **Typora**: Markdown editor

### Terminal Environment
- **Alacritty**: Default GPU-accelerated terminal
- **Kitty**: Alternative terminal emulator
- **Zsh**: Default shell with Zimfw framework
- **Starship**: Modern shell prompt
- **Tmux**: Terminal multiplexer

### Programming Languages
- **Python**: With UV package manager
- **Node.js**: Managed via NVM
- **Go**: Latest stable version

### Databases & Containers
- **Docker**: With Docker Compose
- **PostgreSQL**: Via Docker
- **Beekeeper Studio**: Database management tool

### Web Browsers
- **Firefox**: Default browser
- **Google Chrome**: Alternative browser

### Communication
- **Slack**: Team communication
- **Discord**: Gaming/community chat
- **WhatsApp**: Messaging

### Productivity
- **Obsidian**: Note-taking and knowledge management

### Media & Graphics
- **GIMP**: Image editing
- **VLC**: Media player
- **FFmpeg**: Video processing

### i3 Window Manager Environment
- **i3**: Tiling window manager
- **Polybar**: Status bar
- **Rofi**: Application launcher
- **Picom**: Compositor
- **Dunst**: Notification daemon
- **Thunar**: File manager

### System Utilities
- **Flatpak**: Additional package management
- **Various CLI tools**: ripgrep, bat, exa, fzf, etc.

### Cloud & DevOps
- **AWS CLI**: Amazon Web Services command line
- **GitHub CLI**: GitHub integration

### Fonts
- **JetBrains Mono Nerd Font**: Programming font with icons

## Usage Tips

### Terminal Workflow
- Use `tmux` for session management
- Use `fzf` for fuzzy finding (Ctrl+T)
- Use `z` (zoxide) for smart directory navigation
- Use `bat` instead of `cat` for syntax highlighting
- Use `exa` instead of `ls` for better file listings

### Development
- Projects in `~/Development/projects/`
- Python: Use `uv` for package management
- Node.js: Use `nvm` for version management
- Go: Environment configured in shell

### Package Management
- **apt**: System packages
- **flatpak**: GUI applications
- **snap**: Alternative package format

## Next Steps
1. Update Git configuration with your credentials
2. Set up SSH keys for GitHub/GitLab
3. Configure your preferred i3 setup
4. Install additional language-specific tools as needed

## Troubleshooting
- Restart terminal or log out/in for PATH changes
- Use `source ~/.zshrc` to reload shell configuration
- Check `systemctl status docker` for Docker issues
EOF

    log "Documentation created at $doc_dir/README.md"
}

# Function to show final summary
show_summary() {
    echo
    echo -e "${BLUE}====================================================================="
    echo -e "                    Installation Complete!"
    echo -e "====================================================================="
    echo -e "${NC}"
    
    log "Development environment setup complete!"
    echo
    log "System Summary:"
    log "  ✓ Core development tools installed"
    log "  ✓ Terminal environment configured (Zsh + Starship + Zimfw)"
    log "  ✓ Programming languages ready (Python + UV, Node.js + NVM, Go)"
    log "  ✓ Docker and development containers available"
    log "  ✓ Text editors and IDEs installed"
    log "  ✓ Web browsers and communication apps ready"
    log "  ✓ i3 window manager environment installed"
    log "  ✓ Cloud and DevOps tools configured"
    log "  ✓ JetBrains Mono Nerd Font installed"
    log "  ✓ Dotfiles management with GNU Stow available"
    echo
    warn "Important Next Steps:"
    warn "  1. Log out and back in (or restart) for all changes to take effect"
    warn "  2. Configure Git with: git config --global user.name 'Your Name'"
    warn "  3. Configure Git with: git config --global user.email 'your@email.com'"
    warn "  4. Set up SSH keys for GitHub/GitLab access"
    warn "  5. Configure your i3 environment if needed"
    warn "  6. Review documentation at ~/Documents/dev-setup-docs/"
    echo
    echo -e "${GREEN}Happy coding! 🚀${NC}"
    echo -e "${CYAN}Tip: Start with 'nvim' for editing, 'tmux' for sessions, and 'z <dir>' for navigation${NC}"
    echo
}

# Main function with interactive prompts
main() {
    # Check permissions
    check_permissions
    
    echo -e "${CYAN}This script will install a comprehensive development environment.${NC}"
    echo -e "${CYAN}The installation includes programming languages, editors, terminal tools,${NC}"
    echo -e "${CYAN}i3 window manager, and various productivity applications.${NC}"
    echo
    echo -e "${YELLOW}Press Enter to continue or Ctrl+C to cancel...${NC}"
    read -r
    
    # Step 1: System updates
    echo -e "${MAGENTA}Step 1: Updating system packages...${NC}"
    update_package_database
    upgrade_system
    
    # Step 2: Essential dependencies
    echo -e "${MAGENTA}Step 2: Installing essential dependencies...${NC}"
    install_essential_dependencies
    
    # Step 3: Add repositories
    echo -e "${MAGENTA}Step 3: Adding necessary repositories...${NC}"
    add_repositories
    
    # Step 4: Dotfiles management (moved to beginning)
    echo -e "${MAGENTA}Step 4: Setting up dotfiles management and configurations...${NC}"
    echo -e "${CYAN}This will clone and apply your dotfiles before installing applications${NC}"
    read -p "Setup dotfiles management with GNU Stow? (y/N): " setup_dotfiles
    if [[ "$setup_dotfiles" =~ ^[Yy]$ ]] || [ -z "$setup_dotfiles" ]; then
        setup_dotfiles_management
    fi
    
    # Step 5: Core development tools
    echo -e "${MAGENTA}Step 5: Installing core development tools...${NC}"
    echo -e "${CYAN}Installing: Neovim, VS Code, Git, Tmux, and CLI utilities...${NC}"
    read -p "Continue with core development tools installation? (y/N): " install_core
    if [[ "$install_core" =~ ^[Yy]$ ]] || [ -z "$install_core" ]; then
        install_core_dev_tools
    fi
    
    # Step 6: Terminal applications
    echo -e "${MAGENTA}Step 6: Installing terminal applications...${NC}"
    echo -e "${CYAN}Installing: Alacritty, Kitty, Zsh, JetBrains Mono font...${NC}"
    read -p "Continue with terminal applications? (y/N): " install_terminal
    if [[ "$install_terminal" =~ ^[Yy]$ ]] || [ -z "$install_terminal" ]; then
        install_terminal_apps
    fi
    
    # Step 7: Zsh environment setup
    echo -e "${MAGENTA}Step 7: Setting up Zsh with Starship and Zimfw...${NC}"
    read -p "Setup Zsh environment with Starship prompt and Zimfw? (y/N): " setup_zsh
    if [[ "$setup_zsh" =~ ^[Yy]$ ]] || [ -z "$setup_zsh" ]; then
        setup_zsh_environment
    fi
    
    # Step 8: Programming languages
    echo -e "${MAGENTA}Step 8: Installing programming languages...${NC}"
    echo -e "${CYAN}Installing: Python + UV, Node.js + NVM, Go...${NC}"
    read -p "Continue with programming languages installation? (y/N): " install_langs
    if [[ "$install_langs" =~ ^[Yy]$ ]] || [ -z "$install_langs" ]; then
        install_programming_languages
    fi
    
    # Step 9: Docker and containers
    echo -e "${MAGENTA}Step 9: Installing Docker and container tools...${NC}"
    read -p "Install Docker and Docker Compose? (y/N): " install_docker
    if [[ "$install_docker" =~ ^[Yy]$ ]] || [ -z "$install_docker" ]; then
        install_docker_postgres
    fi
    
    # Step 10: Text editors and IDEs
    echo -e "${MAGENTA}Step 10: Installing text editors and IDEs...${NC}"
    echo -e "${CYAN}Installing: Cursor, Claude Code, Typora...${NC}"
    read -p "Continue with editors and IDEs? (y/N): " install_editors
    if [[ "$install_editors" =~ ^[Yy]$ ]] || [ -z "$install_editors" ]; then
        install_editors_ides
    fi
    
    # Step 11: Web browsers
    echo -e "${MAGENTA}Step 11: Installing web browsers...${NC}"
    echo -e "${CYAN}Installing: Firefox, Google Chrome...${NC}"
    read -p "Continue with web browsers? (y/N): " install_browsers
    if [[ "$install_browsers" =~ ^[Yy]$ ]] || [ -z "$install_browsers" ]; then
        install_web_browsers
    fi
    
    # Step 12: Communication apps
    echo -e "${MAGENTA}Step 12: Installing communication applications...${NC}"
    echo -e "${CYAN}Installing: Slack, Discord, WhatsApp...${NC}"
    read -p "Continue with communication apps? (y/N): " install_comm
    if [[ "$install_comm" =~ ^[Yy]$ ]] || [ -z "$install_comm" ]; then
        install_communication_apps
    fi
    
    # Step 13: Productivity apps
    echo -e "${MAGENTA}Step 13: Installing productivity applications...${NC}"
    echo -e "${CYAN}Installing: Obsidian, Beekeeper Studio...${NC}"
    read -p "Continue with productivity apps? (y/N): " install_prod
    if [[ "$install_prod" =~ ^[Yy]$ ]] || [ -z "$install_prod" ]; then
        install_productivity_apps
    fi
    
    # Step 14: Media and graphics
    echo -e "${MAGENTA}Step 14: Installing media and graphics applications...${NC}"
    echo -e "${CYAN}Installing: GIMP, VLC, FFmpeg...${NC}"
    read -p "Continue with media and graphics apps? (y/N): " install_media
    if [[ "$install_media" =~ ^[Yy]$ ]] || [ -z "$install_media" ]; then
        install_media_graphics
    fi
    
    # Step 15: i3 window manager environment
    echo -e "${MAGENTA}Step 15: Installing i3 window manager environment...${NC}"
    echo -e "${CYAN}Installing: i3, polybar, rofi, picom, dunst, and related tools...${NC}"
    read -p "Install i3 window manager environment? (y/N): " install_i3
    if [[ "$install_i3" =~ ^[Yy]$ ]] || [ -z "$install_i3" ]; then
        install_i3_environment
    fi
    
    # Step 16: System utilities
    echo -e "${MAGENTA}Step 16: Installing system utilities...${NC}"
    echo -e "${CYAN}Installing: Flatpak, system monitoring tools...${NC}"
    read -p "Continue with system utilities? (y/N): " install_utils
    if [[ "$install_utils" =~ ^[Yy]$ ]] || [ -z "$install_utils" ]; then
        install_system_utilities
    fi
    
    # Step 17: Cloud and DevOps tools
    echo -e "${MAGENTA}Step 17: Installing cloud and DevOps tools...${NC}"
    echo -e "${CYAN}Installing: AWS CLI, GitHub CLI...${NC}"
    read -p "Continue with cloud and DevOps tools? (y/N): " install_devops
    if [[ "$install_devops" =~ ^[Yy]$ ]] || [ -z "$install_devops" ]; then
        install_cloud_devops_tools
    fi
    
    # Step 18: Fonts
    echo -e "${MAGENTA}Step 18: Installing fonts...${NC}"
    echo -e "${CYAN}Installing: JetBrains Mono Nerd Font...${NC}"
    read -p "Continue with fonts installation? (y/N): " install_fonts_prompt
    if [[ "$install_fonts_prompt" =~ ^[Yy]$ ]] || [ -z "$install_fonts_prompt" ]; then
        install_fonts
    fi
    
    # Step 19: Development environment configuration
    echo -e "${MAGENTA}Step 19: Configuring development environment...${NC}"
    configure_dev_environment
    
    # Step 20: Documentation
    echo -e "${MAGENTA}Step 20: Creating documentation...${NC}"
    create_documentation
    
    # Final summary
    show_summary
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    sudo apt autoremove -y || true
    sudo apt autoclean || true
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run the main function
main "$@"
