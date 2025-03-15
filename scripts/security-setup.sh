#!/bin/bash
# ===========================================================================
# Secure Environment Provisioning Tool for Cybersecurity Engineers
# ===========================================================================

set -e  # Exit on error
set -u  # Treat unset variables as errors

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}=====================================================================
      SECURE ENVIRONMENT PROVISIONING TOOL FOR ARCH LINUX
=====================================================================${NC}"

# Function to check if running with appropriate permissions
check_permissions() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}ERROR: This script must be run with sudo or as root${NC}"
        exit 1
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

# Function to handle errors
error() {
    echo -e "${RED}[-] ERROR: $1${NC}" >&2
    exit 1
}

# Function to check if a package is installed
is_installed() {
    pacman -Q "$1" &> /dev/null
}

# Function to install a package if not already installed
install_package() {
    if ! is_installed "$1"; then
        log "Installing $1..."
        pacman -S --noconfirm "$1" || error "Failed to install $1"
    else
        warn "Package $1 is already installed"
    fi
}

# Function to update package database
update_package_database() {
    log "Updating package database..."
    pacman -Syu --noconfirm || error "Failed to update package database"
}

# Function to install git and stow first
install_git_and_stow() {
    log "Installing git and stow first..."
    
    # Update package database
    update_package_database
    
    # Install git and stow first
    install_package "git"
    install_package "stow"
}

# Function to create a new user with appropriate permissions
create_user() {
    local username="$1"
    
    if id "$username" &>/dev/null; then
        warn "User $username already exists"
    else
        log "Creating user: $username"
        useradd -m -G wheel -s /bin/bash "$username"
        echo "Please set a password for $username:"
        passwd "$username"
    fi
}

# Function to setup dotfiles using stow
setup_dotfiles() {
    log "Setting up dotfiles..."
    
    # Create a function to set up dotfiles for a specific user
    setup_user_dotfiles() {
        local user="$1"
        local home_dir="$2"
        
        # Get user ID and group ID
        local uid=$(id -u "$user")
        local gid=$(id -g "$user")
        
        log "Setting up dotfiles for user $user"
        
        # Create dotfiles directory
        local dotfiles_dir="$home_dir/dotfiles"
        mkdir -p "$dotfiles_dir"
        
        # Clone dotfiles repository
        log "Cloning dotfiles repository..."
        sudo -u "$user" git clone https://github.com/shyamenk/dotfiles.git "$dotfiles_dir"
        
        # Use stow to apply dotfiles
        cd "$dotfiles_dir" || return
        
        # List all directories in the dotfiles repo to stow them
        for dir in */; do
            dir=${dir%/}  # Remove trailing slash
            log "Applying $dir configuration using stow..."
            sudo -u "$user" stow -t "$home_dir" "$dir"
        done
        
        # Download wallpapers
        log "Downloading wallpapers..."
        mkdir -p "$home_dir/Pictures/wallpapers"
        
        # Download a sample wallpaper
        wget -q "https://images.unsplash.com/photo-1579546929518-9e396f3cc809" -O "$home_dir/Pictures/wallpapers/gradient.jpg"
        wget -q "https://images.unsplash.com/photo-1492305175278-3b3afaa2f31f" -O "$home_dir/Pictures/wallpapers/landscape.jpg"
        wget -q "https://images.unsplash.com/photo-1605379399642-870262d3d051" -O "$home_dir/Pictures/wallpapers/abstract.jpg"
        
        # Set correct ownership
        chown -R "$uid":"$gid" "$home_dir/Pictures"
        chown -R "$uid":"$gid" "$dotfiles_dir"
    }
    
    # Ask which user to set up dotfiles for
    read -p "Set up dotfiles for which user? (default: current user): " dotfiles_user
    dotfiles_user=${dotfiles_user:-$(logname)}
    
    # Get the home directory of the specified user
    local user_home
    user_home=$(eval echo ~"$dotfiles_user")
    
    # Set up dotfiles for the specified user
    setup_user_dotfiles "$dotfiles_user" "$user_home"
    
    log "Dotfiles setup complete for $dotfiles_user"
}

# Function to install and configure development tools
install_dev_tools() {
    log "Installing development and security tools..."
    
    # Core utilities
    PACKAGES=(
        base-devel
        curl
        wget
        neovim
        ripgrep
        alacritty
        fzf
        bat
        zoxide
        tmux
        htop
        tree
        fd
        jq
        unzip
        python
        python-pip
        rustup
        nodejs
        npm
        yazi
        eza
        docker
        lazygit
        picom
        polybar
        rofi
        openssh
        github-cli
    )
    
    # Security tools
    SECURITY_PACKAGES=(
        nmap
        wireshark-qt
        tcpdump
        hashcat
        john
        metasploit
        burpsuite
        radare2
        gdb
        strace
        ltrace
    )
    
    # Install packages
    for pkg in "${PACKAGES[@]}"; do
        install_package "$pkg"
    done
    
    # Ask if security tools should be installed
    read -p "Do you want to install security tools as well? (y/n): " install_security
    if [ "$install_security" = "y" ] || [ "$install_security" = "Y" ]; then
        for pkg in "${SECURITY_PACKAGES[@]}"; do
            install_package "$pkg"
        done
    fi
    
    # Install JetBrainsMono Nerd Font
    log "Installing JetBrainsMono Nerd Font..."
    
    # Create fonts directory if it doesn't exist
    mkdir -p /usr/share/fonts/TTF
    
    # Download and install the font
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
    local temp_dir=$(mktemp -d)
    
    wget -q "$font_url" -O "$temp_dir/JetBrainsMono.zip"
    unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir"
    cp "$temp_dir"/*.ttf /usr/share/fonts/TTF/
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Update font cache
    fc-cache -f
    
    log "JetBrainsMono Nerd Font installed successfully"
}

# Function to apply basic system hardening
apply_system_hardening() {
    log "Applying basic system hardening..."
    
    # Update system security limits
    cat > /etc/security/limits.conf << EOF
* soft core 0
* hard core 0
* soft nproc 10000
* hard nproc 10000
EOF

    # Configure secure SSH settings
    if [ -f /etc/ssh/sshd_config ]; then
        log "Hardening SSH configuration..."
        sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
        systemctl restart sshd
    fi
    
    # Enable and configure firewall (using ufw for simplicity)
    if ! is_installed ufw; then
        install_package ufw
    fi
    
    log "Configuring firewall..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw --force enable
    
    # Disable unused network protocols
    log "Disabling unused network protocols..."
    echo "install dccp /bin/true" > /etc/modprobe.d/disable-dccp.conf
    echo "install sctp /bin/true" > /etc/modprobe.d/disable-sctp.conf
    echo "install rds /bin/true" > /etc/modprobe.d/disable-rds.conf
    echo "install tipc /bin/true" > /etc/modprobe.d/disable-tipc.conf
}

# Function to create a local security tools repository
setup_security_repo() {
    log "Setting up local security tools repository..."
    
    # Create directory structure
    local sec_tools_dir="/opt/security-tools"
    mkdir -p "$sec_tools_dir"
    
    # Clone some useful security repositories
    cd "$sec_tools_dir" || error "Failed to change directory to $sec_tools_dir"
    
    # Install some useful security tools from Git
    log "Cloning security tools repositories..."
    
    # List of tools to clone
    TOOLS=(
        "https://github.com/OWASP/CheatSheetSeries.git"
        "https://github.com/swisskyrepo/PayloadsAllTheThings.git"
        "https://github.com/danielmiessler/SecLists.git"
        "https://github.com/carlospolop/PEASS-ng.git"
    )
    
    for tool in "${TOOLS[@]}"; do
        tool_name=$(basename "$tool" .git)
        if [ ! -d "$sec_tools_dir/$tool_name" ]; then
            log "Cloning $tool_name..."
            git clone --depth 1 "$tool" "$sec_tools_dir/$tool_name" || warn "Failed to clone $tool"
        else
            log "Updating $tool_name..."
            (cd "$sec_tools_dir/$tool_name" && git pull) || warn "Failed to update $tool_name"
        fi
    done
    
    # Set permissions
    chown -R root:wheel "$sec_tools_dir"
    chmod -R 750 "$sec_tools_dir"
    
    # Create symlink to easily access the tools
    ln -sf "$sec_tools_dir" /usr/local/share/security-tools
    
    log "Security tools repository set up at $sec_tools_dir"
}

# Function to create a documentation template
create_documentation() {
    log "Creating documentation template..."
    
    local doc_dir="/opt/security-docs"
    mkdir -p "$doc_dir"
    
    # Create basic documentation
    cat > "$doc_dir/README.md" << EOF
# Security Development Environment Documentation

## Overview
This environment has been set up with security-focused tools and configurations for cybersecurity engineering and development work.

## Installed Tools

### Core Development Tools
- Neovim: Advanced text editor with security plugins
- Ripgrep: Fast search tool
- Alacritty: GPU-accelerated terminal emulator
- Zoxide: Smarter directory navigation
- Bat: Better cat with syntax highlighting
- FZF: Fuzzy finder for files and content
- Tmux: Terminal multiplexer
- Yazi: Terminal file manager
- Eza: Modern ls replacement with Git integration
- LazyGit: Terminal UI for Git
- Picom: Compositor for X11
- Polybar: Status bar for X11
- Rofi: Application launcher
- GitHub CLI: GitHub from the command line

### Security Tools
- (List depends on what was installed during setup)

## Security Configurations
- System has been hardened with secure defaults
- SSH has been configured for key-based authentication only
- Firewall is enabled with restrictive rules
- Development tools are configured with security-focused settings

## Usage Guidelines
- Always work in least-privilege mode when possible
- Use secure temporary directories for sensitive work
- Follow the secure coding practices documented in /opt/security-docs/coding-standards.md

## Team-specific Information
(Add team-specific details here)

## Support
(Add support contact information here)
EOF

    # Create secure coding guidelines
    cat > "$doc_dir/coding-standards.md" << EOF
# Secure Coding Standards

## General Principles
1. **Least Privilege**: Always operate with the minimum necessary permissions
2. **Defense in Depth**: Never rely on a single security control
3. **Secure by Default**: Systems should be secure out of the box
4. **Fail Securely**: Errors should not create security vulnerabilities

## Language-specific Guidelines

### Python
- Use virtual environments for isolation
- Pin dependencies with exact versions
- Use type hints and static analysis tools
- Never use eval() or exec() with untrusted input
- Use parameterized queries for database operations
- Validate all input data

### JavaScript/TypeScript
- Use npm/yarn audit regularly
- Implement Content Security Policy (CSP)
- Avoid eval() and new Function()
- Use modern frameworks with built-in XSS protection
- Apply strict CSP headers

### C/C++
- Use modern C++ features when possible
- Avoid unsafe functions (gets, strcpy, etc.)
- Use static analysis tools
- Implement proper memory management
- Check for buffer overflows

## Infrastructure Security
- Keep all systems updated
- Use infrastructure as code
- Implement proper logging and monitoring
- Use multi-factor authentication where possible
- Regular security scanning and testing

## Code Review Checklist
- [ ] Input validation
- [ ] Output encoding
- [ ] Authentication and authorization
- [ ] Session management
- [ ] Error handling
- [ ] Logging
- [ ] Data protection
- [ ] Communication security
EOF

    # Set permissions
    chown -R root:wheel "$doc_dir"
    chmod -R 750 "$doc_dir"
    
    log "Documentation created at $doc_dir"
}

# Function to configure Docker with security best practices
configure_docker() {
    log "Setting up Docker with security best practices..."
    
    # Install Docker if not already installed
    if ! is_installed docker; then
        install_package docker
    fi
    
    # Create Docker configuration directory
    mkdir -p /etc/docker
    
    # Create secure Docker daemon configuration
    cat > /etc/docker/daemon.json << EOF
{
  "icc": false,
  "userns-remap": "default",
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

    # Start and enable Docker service
    systemctl enable docker
    systemctl start docker
    
    # Create Docker security script
    local docker_sec_script="/usr/local/bin/docker-security-check"
    
    cat > "$docker_sec_script" << 'EOF'
#!/bin/bash
# Docker Security Checker

echo "=== Docker Security Check ==="
echo

# Check Docker version
echo "Docker version:"
docker version --format '{{.Server.Version}}' || echo "Docker not running!"
echo

# Check Docker daemon configuration
echo "Docker daemon configuration:"
if [ -f /etc/docker/daemon.json ]; then
    cat /etc/docker/daemon.json
else
    echo "No daemon.json configuration found!"
fi
echo

# Check running containers for vulnerabilities
echo "Running containers:"
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
echo

# Check for privileged containers
echo "Privileged containers (security risk):"
docker ps --quiet --all | xargs docker inspect --format '{{.Name}} {{if .HostConfig.Privileged}}PRIVILEGED{{end}}' | grep PRIVILEGED || echo "No privileged containers found (good)"
echo

# Check for containers with sensitive mounts
echo "Containers with sensitive mounts:"
docker ps --quiet --all | xargs docker inspect --format '{{.Name}} {{range .Mounts}}{{if or (eq .Source "/") (eq .Source "/etc") (eq .Source "/boot") (eq .Source "/proc") (eq .Source "/sys") (eq .Source "/var")}}SENSITIVE MOUNT: {{.Source}}{{end}}{{end}}' | grep "SENSITIVE MOUNT" || echo "No containers with sensitive mounts (good)"
echo

# Check container resource limits
echo "Containers without memory limits (security risk):"
docker ps --quiet --all | xargs docker inspect --format '{{.Name}} {{if not .HostConfig.Memory}}NO MEMORY LIMIT{{end}}' | grep "NO MEMORY LIMIT" || echo "All containers have memory limits (good)"
echo

# Check images with known vulnerabilities if Trivy is installed
if command -v trivy &> /dev/null; then
    echo "Scanning Docker images for vulnerabilities (using Trivy):"
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -v "<none>" | while read -r image; do
        echo "Scanning $image..."
        trivy image --severity HIGH,CRITICAL "$image"
    done
else
    echo "Trivy not installed. Install it to scan images for vulnerabilities."
    echo "Run: pacman -S trivy"
fi

echo
echo "=== Security Check Complete ==="
EOF

    # Make the script executable
    chmod +x "$docker_sec_script"
    
    log "Docker configured with security best practices"
}

# Main function
main() {
    # Check permissions
    check_permissions
    
    # 1. First, install git and stow
    install_git_and_stow
    
    # 2. Create user if needed
    read -p "Create a new user? (y/n): " create_new_user
    if [ "$create_new_user" = "y" ] || [ "$create_new_user" = "Y" ]; then
        read -p "Enter username: " username
        create_user "$username"
    fi
    
    # 3. Clone dotfiles and stow them
    read -p "Set up dotfiles? (y/n): " setup_dots
    if [ "$setup_dots" = "y" ] || [ "$setup_dots" = "Y" ]; then
        setup_dotfiles
    fi
    
    # 4. Now install other packages
    read -p "Install development tools? (y/n): " install_tools
    if [ "$install_tools" = "y" ] || [ "$install_tools" = "Y" ]; then
        install_dev_tools
    fi
    
    # 5. Apply system hardening
    read -p "Apply system hardening? (y/n): " apply_hardening
    if [ "$apply_hardening" = "y" ] || [ "$apply_hardening" = "Y" ]; then
        apply_system_hardening
    fi
    
    # 6. Set up security tools repository
    read -p "Set up security tools repository? (y/n): " setup_sec_repo
    if [ "$setup_sec_repo" = "y" ] || [ "$setup_sec_repo" = "Y" ]; then
        setup_security_repo
    fi
    
    # 7. Create documentation
    read -p "Create documentation? (y/n): " create_docs
    if [ "$create_docs" = "y" ] || [ "$create_docs" = "Y" ]; then
        create_documentation
    fi
    
    # 8. Configure Docker
    read -p "Configure Docker with security best practices? (y/n): " config_docker
    if [ "$config_docker" = "y" ] || [ "$config_docker" = "Y" ]; then
        configure_docker
    fi
    
    log "Secure environment setup complete!"
}

# Run the main function
main
