#!/bin/bash
# ===========================================================================
# Clean Environment Provisioning Tool for Developers
# ===========================================================================

set -e # Exit on error

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arrays to track installation results
SUCCESSFUL_INSTALLS=()
FAILED_INSTALLS=()
SKIPPED_INSTALLS=()

# Banner
echo -e "${BLUE}=====================================================================
      CLEAN ENVIRONMENT PROVISIONING TOOL FOR ARCH LINUX
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

# Function to handle errors (non-breaking)
error() {
  echo -e "${RED}[-] ERROR: $1${NC}" >&2
}

# Function to check if a package is installed via pacman
is_installed_pacman() {
  pacman -Q "$1" &>/dev/null
}

# Function to check if a package is installed via yay
is_installed_yay() {
  yay -Q "$1" &>/dev/null 2>&1
}

# Function to check if a package is installed via flatpak
is_installed_flatpak() {
  flatpak list | grep -q "$1" 2>/dev/null
}

# Function to check if yay is installed
check_yay() {
  if ! command -v yay &>/dev/null; then
    log "Installing yay AUR helper..."

    local regular_user=$(logname)
    local user_home=$(eval echo ~"$regular_user")

    pacman -S --needed --noconfirm base-devel git

    local temp_dir="$user_home/tmp_yay_install"
    rm -rf "$temp_dir"

    log "Cloning yay repository..."
    if sudo -u "$regular_user" git clone https://aur.archlinux.org/yay.git "$temp_dir"; then
      log "Building and installing yay..."
      cd "$temp_dir"
      if sudo -u "$regular_user" makepkg -si --noconfirm; then
        log "yay installed successfully"
        SUCCESSFUL_INSTALLS+=("yay AUR helper")
      else
        error "Failed to build/install yay"
        FAILED_INSTALLS+=("yay AUR helper")
      fi
      cd /
      rm -rf "$temp_dir"
    else
      error "Failed to clone yay repository"
      FAILED_INSTALLS+=("yay AUR helper - clone failed")
    fi
  else
    log "yay is already installed"
    SKIPPED_INSTALLS+=("yay AUR helper - already installed")
  fi
}

# Function to install flatpak if not available
setup_flatpak() {
  if ! command -v flatpak &>/dev/null; then
    log "Installing Flatpak..."
    pacman -S --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

# Function to try multiple installation methods
install_package() {
  local package="$1"
  local install_method="$2"
  local github_url=""
  local install_cmd=""

  if [ $# -gt 2 ]; then
    github_url="$3"
  fi
  if [ $# -gt 3 ]; then
    install_cmd="$4"
  fi

  case "$install_method" in
  "pacman")
    if is_installed_pacman "$package"; then
      warn "Package $package is already installed (pacman)"
      SKIPPED_INSTALLS+=("$package (pacman - already installed)")
      return 0
    fi

    log "Installing $package via pacman..."
    if pacman -S --noconfirm "$package" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$package (pacman)")
      log "Successfully installed $package via pacman"
      return 0
    else
      error "Failed to install $package via pacman"
      FAILED_INSTALLS+=("$package (pacman)")
      return 1
    fi
    ;;

  "yay")
    if is_installed_yay "$package" || is_installed_pacman "$package"; then
      warn "Package $package is already installed"
      SKIPPED_INSTALLS+=("$package (yay - already installed)")
      return 0
    fi

    log "Installing $package via yay..."
    if sudo -u "$(logname)" yay -S --noconfirm "$package" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$package (yay)")
      log "Successfully installed $package via yay"
      return 0
    else
      error "Failed to install $package via yay"
      FAILED_INSTALLS+=("$package (yay)")
      return 1
    fi
    ;;

  "flatpak")
    if is_installed_flatpak "$package"; then
      warn "Package $package is already installed (flatpak)"
      SKIPPED_INSTALLS+=("$package (flatpak - already installed)")
      return 0
    fi

    log "Installing $package via flatpak..."
    if flatpak install -y flathub "$package" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$package (flatpak)")
      log "Successfully installed $package via flatpak"
      return 0
    else
      error "Failed to install $package via flatpak"
      FAILED_INSTALLS+=("$package (flatpak)")
      return 1
    fi
    ;;

  "github")
    if [ -z "$github_url" ]; then
      error "GitHub URL required for $package"
      FAILED_INSTALLS+=("$package (github - no URL)")
      return 1
    fi

    log "Installing $package from GitHub..."
    local temp_dir=$(mktemp -d)
    if git clone "$github_url" "$temp_dir/$package" 2>/dev/null; then
      cd "$temp_dir/$package"
      if [ -n "$install_cmd" ]; then
        if eval "$install_cmd" 2>/dev/null; then
          SUCCESSFUL_INSTALLS+=("$package (github)")
          log "Successfully installed $package from GitHub"
          cd /
          rm -rf "$temp_dir"
          return 0
        fi
      else
        if [ -f "install.sh" ]; then
          chmod +x install.sh && ./install.sh
        elif [ -f "Makefile" ]; then
          make && make install
        elif [ -f "setup.py" ]; then
          python setup.py install
        fi
        SUCCESSFUL_INSTALLS+=("$package (github)")
        log "Successfully installed $package from GitHub"
        cd /
        rm -rf "$temp_dir"
        return 0
      fi
    fi

    error "Failed to install $package from GitHub"
    FAILED_INSTALLS+=("$package (github)")
    cd /
    rm -rf "$temp_dir"
    return 1
    ;;

  "curl")
    if [ -z "$install_cmd" ]; then
      error "Install command required for curl method"
      FAILED_INSTALLS+=("$package (curl - no command)")
      return 1
    fi

    log "Installing $package via curl..."
    if eval "$install_cmd" 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("$package (curl)")
      log "Successfully installed $package via curl"
      return 0
    else
      error "Failed to install $package via curl"
      FAILED_INSTALLS+=("$package (curl)")
      return 1
    fi
    ;;
  esac
}

# Function to try installing a package with multiple methods
try_install_package() {
  local package="$1"
  shift
  local methods=("$@")

  for method in "${methods[@]}"; do
    case "$method" in
    "pacman")
      if install_package "$package" "pacman"; then
        return 0
      fi
      ;;
    "yay")
      if install_package "$package" "yay"; then
        return 0
      fi
      ;;
    "flatpak:"*)
      local flatpak_id="${method#flatpak:}"
      if install_package "$flatpak_id" "flatpak"; then
        return 0
      fi
      ;;
    "github:"*)
      local github_info="${method#github:}"
      local github_url="${github_info%%:*}"
      local install_cmd="${github_info#*:}"
      if [ "$install_cmd" = "$github_url" ]; then
        install_cmd=""
      fi
      if install_package "$package" "github" "$github_url" "$install_cmd"; then
        return 0
      fi
      ;;
    "curl:"*)
      local curl_cmd="${method#curl:}"
      if install_package "$package" "curl" "" "$curl_cmd"; then
        return 0
      fi
      ;;
    esac
  done

  return 1
}

# Function to update package database
update_package_database() {
  log "Updating package database..."
  if pacman -Syu --noconfirm; then
    log "Package database updated successfully"
  else
    error "Failed to update package database"
  fi
}

# Function to install git and stow first
install_git_and_stow() {
  log "Installing git and stow first..."

  update_package_database

  log "Installing git via pacman..."
  if is_installed_pacman "git"; then
    warn "Package git is already installed"
    SKIPPED_INSTALLS+=("git (already installed)")
  else
    if pacman -S --noconfirm git 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("git")
      log "Successfully installed git"
    else
      error "Failed to install git"
      FAILED_INSTALLS+=("git")
    fi
  fi

  log "Installing stow via pacman..."
  if is_installed_pacman "stow"; then
    warn "Package stow is already installed"
    SKIPPED_INSTALLS+=("stow (already installed)")
  else
    if pacman -S --noconfirm stow 2>/dev/null; then
      SUCCESSFUL_INSTALLS+=("stow")
      log "Successfully installed stow"
    else
      error "Failed to install stow"
      FAILED_INSTALLS+=("stow")
    fi
  fi
}

# Function to setup dotfiles using stow
setup_dotfiles() {
  log "Setting up dotfiles..."

  read -p "Set up dotfiles for which user? (default: $(logname)): " dotfiles_user
  dotfiles_user=${dotfiles_user:-$(logname)}

  local user_home
  user_home=$(eval echo ~"$dotfiles_user")

  local uid=$(id -u "$dotfiles_user")
  local gid=$(id -g "$dotfiles_user")

  log "Setting up dotfiles for user $dotfiles_user"

  local dotfiles_dir="$user_home/dotfiles"

  if [ -d "$dotfiles_dir" ]; then
    warn "Existing dotfiles directory found. Removing it..."
    rm -rf "$dotfiles_dir"
  fi

  mkdir -p "$dotfiles_dir"
  chown "$uid":"$gid" "$dotfiles_dir"

  log "Cloning dotfiles repository..."
  log "Attempting to clone https://github.com/shyamenk/dotfiles.git to $dotfiles_dir"

  if sudo -u "$dotfiles_user" git clone https://github.com/shyamenk/dotfiles.git "$dotfiles_dir"; then
    log "Successfully cloned dotfiles repository"
  elif sudo -u "$dotfiles_user" git clone --depth 1 https://github.com/shyamenk/dotfiles.git "$dotfiles_dir"; then
    log "Successfully cloned dotfiles repository (shallow clone)"
  else
    error "Failed to clone dotfiles repository. Checking if repository exists..."

    if curl -s --head https://github.com/shyamenk/dotfiles | head -n 1 | grep -q "200 OK"; then
      error "Repository exists but clone failed. This might be a network or permissions issue."
    else
      error "Repository might not exist or is not accessible."
      warn "You can manually clone your dotfiles later with:"
      warn "  git clone https://github.com/yourusername/dotfiles.git ~/dotfiles"
    fi

    FAILED_INSTALLS+=("dotfiles setup")
    return 1
  fi

  cd "$dotfiles_dir" || return 1

  if ! ls -d */ >/dev/null 2>&1; then
    warn "No directories found in dotfiles repository to stow"
    FAILED_INSTALLS+=("dotfiles stowing - no directories")
    return 1
  fi

  for dir in */; do
    if [ -d "$dir" ]; then
      dir=${dir%/}
      log "Applying $dir configuration using stow..."
      if sudo -u "$dotfiles_user" stow -t "$user_home" "$dir"; then
        log "Successfully stowed $dir"
      else
        warn "Failed to stow $dir (this might be normal if conflicts exist)"
      fi
    fi
  done

  log "Downloading wallpapers..."
  mkdir -p "$user_home/Pictures/wallpapers"

  local wallpaper_urls=(
    "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=1920&h=1080&fit=crop gradient.jpg"
    "https://images.unsplash.com/photo-1492305175278-3b3afaa2f31f?w=1920&h=1080&fit=crop landscape.jpg"
    "https://images.unsplash.com/photo-1605379399642-870262d3d051?w=1920&h=1080&fit=crop abstract.jpg"
  )

  for url_info in "${wallpaper_urls[@]}"; do
    local url="${url_info% *}"
    local filename="${url_info##* }"
    log "Downloading wallpaper: $filename"
    if wget -q --timeout=10 --tries=2 "$url" -O "$user_home/Pictures/wallpapers/$filename"; then
      log "Successfully downloaded $filename"
    else
      warn "Failed to download wallpaper: $filename"
    fi
  done

  chown -R "$uid":"$gid" "$user_home/Pictures" 2>/dev/null || warn "Failed to set ownership for Pictures directory"
  chown -R "$uid":"$gid" "$dotfiles_dir" 2>/dev/null || warn "Failed to set ownership for dotfiles directory"

  log "Dotfiles setup complete for $dotfiles_user"
  SUCCESSFUL_INSTALLS+=("dotfiles setup")
}

# Function to install core development tools
install_core_tools() {
  log "Installing core development tools..."

  check_yay
  setup_flatpak

  declare -A CORE_PACKAGES=(
    ["base-devel"]="pacman"
    ["curl"]="pacman"
    ["wget"]="pacman"
    ["neovim"]="pacman yay"
    ["ripgrep"]="pacman yay"
    ["alacritty"]="pacman yay flatpak:org.alacritty.Alacritty"
    ["fzf"]="pacman yay"
    ["bat"]="pacman yay"
    ["zoxide"]="pacman yay"
    ["tmux"]="pacman yay"
    ["htop"]="pacman yay"
    ["btop"]="pacman yay"
    ["tree"]="pacman"
    ["fd"]="pacman yay"
    ["jq"]="pacman yay"
    ["unzip"]="pacman"
    ["zip"]="pacman"
    ["yazi"]="pacman yay"
    ["eza"]="pacman yay"
    ["lazygit"]="pacman yay"
    ["openssh"]="pacman"
    ["github-cli"]="pacman yay"
    ["starship"]="pacman yay curl:curl -sS https://starship.rs/install.sh | sh -s -- --yes"
  )

  for pkg in "${!CORE_PACKAGES[@]}"; do
    log "Attempting to install $pkg..."
    IFS=' ' read -ra methods <<<"${CORE_PACKAGES[$pkg]}"
    try_install_package "$pkg" "${methods[@]}"
  done
}

# Function to install Python development tools
install_python_tools() {
  log "Installing Python development tools..."

  declare -A PYTHON_PACKAGES=(
    # Core Python
    ["python"]="pacman"
    ["python-pip"]="pacman"
    ["python-pipx"]="pacman"
    ["python-virtualenv"]="pacman"
    ["python-poetry"]="pacman yay"
    ["pyenv"]="yay"

    # Development tools
    ["python-black"]="pacman"
    ["python-pylint"]="pacman"
    ["python-pytest"]="pacman"
    ["python-tox"]="pacman"
    ["ruff"]="pacman yay"
    ["mypy"]="pacman"
    ["ipython"]="pacman"

    # Data science tools
    ["python-numpy"]="pacman"
    ["python-pandas"]="pacman"
    ["python-matplotlib"]="pacman"
    ["jupyter-notebook"]="pacman"

    # Web frameworks
    ["python-django"]="pacman"
    ["python-flask"]="pacman"
    ["python-fastapi"]="pacman yay"

    # Utilities
    ["python-requests"]="pacman"
    ["python-click"]="pacman"
    ["python-pyyaml"]="pacman"
    ["python-toml"]="pacman"
  )

  for pkg in "${!PYTHON_PACKAGES[@]}"; do
    log "Attempting to install $pkg..."
    IFS=' ' read -ra methods <<<"${PYTHON_PACKAGES[$pkg]}"
    try_install_package "$pkg" "${methods[@]}"
  done
}

# Function to install JavaScript/Node.js development tools
install_javascript_tools() {
  log "Installing JavaScript/Node.js development tools..."

  declare -A JS_PACKAGES=(
    # Core Node.js
    ["nodejs"]="pacman yay"
    ["npm"]="pacman yay"
    ["yarn"]="pacman yay"
    ["pnpm"]="pacman yay"

    # Node version managers
    ["nvm"]="yay"

    # Build tools
    ["vite"]="npm"
    ["webpack"]="npm"

    # TypeScript
    ["typescript"]="pacman npm"

    # Linters and formatters
    ["eslint"]="npm"
    ["prettier"]="npm"

    # Testing frameworks
    ["jest"]="npm"
    ["vitest"]="npm"

    # Package managers and tools
    ["turbo"]="npm"
  )

  for pkg in "${!JS_PACKAGES[@]}"; do
    log "Attempting to install $pkg..."
    IFS=' ' read -ra methods <<<"${JS_PACKAGES[$pkg]}"

    # Special handling for npm packages
    if [[ " ${methods[@]} " =~ " npm " ]]; then
      if command -v npm &>/dev/null; then
        log "Installing $pkg globally via npm..."
        if npm install -g "$pkg" 2>/dev/null; then
          SUCCESSFUL_INSTALLS+=("$pkg (npm)")
          log "Successfully installed $pkg via npm"
          continue
        else
          warn "Failed to install $pkg via npm, trying other methods..."
        fi
      fi
    fi

    # Try other methods
    try_install_package "$pkg" "${methods[@]}"
  done
}

# Function to install containerization tools
install_container_tools() {
  log "Installing containerization tools..."

  declare -A CONTAINER_PACKAGES=(
    ["docker"]="pacman"
    ["docker-compose"]="pacman"
    ["podman"]="pacman"
    ["buildah"]="pacman"
    ["kubectl"]="pacman yay"
    ["helm"]="pacman yay"
    ["k9s"]="pacman yay"
    ["lazydocker"]="yay"
  )

  for pkg in "${!CONTAINER_PACKAGES[@]}"; do
    log "Attempting to install $pkg..."
    IFS=' ' read -ra methods <<<"${CONTAINER_PACKAGES[$pkg]}"
    try_install_package "$pkg" "${methods[@]}"
  done
}

# Function to install database tools
install_database_tools() {
  log "Installing database tools..."

  declare -A DB_PACKAGES=(
    ["postgresql"]="pacman"
    ["mysql"]="pacman"
    ["redis"]="pacman"
    ["mongodb-bin"]="yay"
    ["dbeaver"]="yay flatpak:io.dbeaver.DBeaverCommunity"
    ["sqlite"]="pacman"
  )

  for pkg in "${!DB_PACKAGES[@]}"; do
    log "Attempting to install $pkg..."
    IFS=' ' read -ra methods <<<"${DB_PACKAGES[$pkg]}"
    try_install_package "$pkg" "${methods[@]}"
  done
}

# Function to install GUI applications
install_gui_apps() {
  log "Installing GUI applications..."

  declare -A GUI_PACKAGES=(
    ["firefox"]="pacman flatpak:org.mozilla.firefox"
    ["chromium"]="pacman"
    ["code"]="yay flatpak:com.visualstudio.code"
    ["postman-bin"]="yay flatpak:com.getpostman.Postman"
    ["obsidian"]="yay flatpak:md.obsidian.Obsidian"
    ["slack-desktop"]="yay flatpak:com.slack.Slack"
    ["discord"]="pacman flatpak:com.discordapp.Discord"
    ["gimp"]="pacman"
    ["inkscape"]="pacman"
    ["vlc"]="pacman"
  )

  for pkg in "${!GUI_PACKAGES[@]}"; do
    log "Attempting to install $pkg..."
    IFS=' ' read -ra methods <<<"${GUI_PACKAGES[$pkg]}"
    try_install_package "$pkg" "${methods[@]}"
  done
}

# Function to install window manager tools
install_wm_tools() {
  log "Installing window manager and desktop tools..."

  declare -A WM_PACKAGES=(
    ["picom"]="pacman yay"
    ["polybar"]="pacman yay"
    ["rofi"]="pacman yay"
    ["dunst"]="pacman yay"
    ["nitrogen"]="pacman"
    ["feh"]="pacman"
    ["flameshot"]="pacman"
    ["redshift"]="pacman"
    ["xclip"]="pacman"
    ["xdotool"]="pacman"
  )

  for pkg in "${!WM_PACKAGES[@]}"; do
    log "Attempting to install $pkg..."
    IFS=' ' read -ra methods <<<"${WM_PACKAGES[$pkg]}"
    try_install_package "$pkg" "${methods[@]}"
  done
}

# Function to install fonts
install_fonts() {
  log "Installing fonts..."

  # Install JetBrainsMono Nerd Font
  log "Installing JetBrainsMono Nerd Font..."

  mkdir -p /usr/share/fonts/TTF

  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
  local temp_dir=$(mktemp -d)

  if wget -q "$font_url" -O "$temp_dir/JetBrainsMono.zip" 2>/dev/null; then
    if unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir" 2>/dev/null; then
      cp "$temp_dir"/*.ttf /usr/share/fonts/TTF/ 2>/dev/null
      fc-cache -f
      log "JetBrainsMono Nerd Font installed successfully"
      SUCCESSFUL_INSTALLS+=("JetBrainsMono Nerd Font")
    else
      error "Failed to extract JetBrainsMono font"
      FAILED_INSTALLS+=("JetBrainsMono Nerd Font - extraction failed")
    fi
  else
    error "Failed to download JetBrainsMono font"
    FAILED_INSTALLS+=("JetBrainsMono Nerd Font - download failed")
  fi

  rm -rf "$temp_dir"

  # Install additional fonts
  declare -A FONT_PACKAGES=(
    ["ttf-font-awesome"]="pacman"
    ["ttf-fira-code"]="pacman"
    ["ttf-dejavu"]="pacman"
    ["ttf-liberation"]="pacman"
    ["noto-fonts"]="pacman"
    ["noto-fonts-emoji"]="pacman"
  )

  for pkg in "${!FONT_PACKAGES[@]}"; do
    try_install_package "$pkg" "pacman"
  done
}

# Function to configure Docker
configure_docker() {
  log "Setting up Docker..."

  try_install_package "docker" "pacman"

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

  if systemctl enable docker && systemctl start docker; then
    log "Docker service enabled and started"

    # Add user to docker group
    local current_user=$(logname)
    if usermod -aG docker "$current_user"; then
      log "Added $current_user to docker group"
      warn "Please log out and back in for docker group changes to take effect"
    fi

    SUCCESSFUL_INSTALLS+=("Docker configuration")
  else
    error "Failed to start Docker service"
    FAILED_INSTALLS+=("Docker configuration")
  fi
}

# Function to setup Starship prompt
setup_starship() {
  log "Setting up Starship prompt configuration..."

  local current_user=$(logname)
  local user_home=$(eval echo ~"$current_user")
  local config_dir="$user_home/.config"

  sudo -u "$current_user" mkdir -p "$config_dir"

  cat >"$config_dir/starship.toml" <<EOF
# Starship configuration
format = """
\$username\
\$hostname\
\$directory\
\$git_branch\
\$git_state\
\$git_status\
\$cmd_duration\
\$line_break\
\$python\
\$nodejs\
\$rust\
\$docker_context\
\$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = "🌱 "
format = "[\$symbol\$branch](\$style) "

[git_status]
format = '([\$all_status\$ahead_behind](\$style) )'

[cmd_duration]
min_time = 4
show_milliseconds = false
disabled = false
style = "bold italic red"

[python]
symbol = "🐍 "
format = 'via [\$symbol\$pyenv_prefix(\$version )(\(\$virtualenv\) )](\$style)'

[nodejs]
symbol = "⬢ "
format = 'via [\$symbol(\$version )](\$style)'

[rust]
symbol = "🦀 "
format = 'via [\$symbol(\$version )](\$style)'

[docker_context]
symbol = "🐳 "
format = 'via [\$symbol\$context](\$style) '
EOF

  local uid=$(id -u "$current_user")
  local gid=$(id -g "$current_user")
  chown -R "$uid":"$gid" "$config_dir"

  log "Starship configuration created at $config_dir/starship.toml"
  SUCCESSFUL_INSTALLS+=("Starship configuration")
}

# Function to create a final report
create_final_report() {
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

  local log_file="/var/log/environment-setup-$(date +%Y%m%d-%H%M%S).log"
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
  } >"$log_file"

  log "Full report saved to $log_file"
}

# Main menu function
show_menu() {
  echo -e "\n${BLUE}Select components to install:${NC}"
  echo "1) Core development tools (git, neovim, tmux, htop, etc.)"
  echo "2) Python development tools (pip, poetry, black, pytest, etc.)"
  echo "3) JavaScript/Node.js tools (node, npm, yarn, pnpm, typescript, etc.)"
  echo "4) Containerization tools (docker, podman, kubectl, helm, etc.)"
  echo "5) Database tools (postgresql, mysql, redis, mongodb, dbeaver, etc.)"
  echo "6) GUI applications (browsers, VS Code, Postman, Obsidian, etc.)"
  echo "7) Window manager tools (picom, polybar, rofi, dunst, etc.)"
  echo "8) Fonts (JetBrains Mono, Font Awesome, Fira Code, etc.)"
  echo "9) Setup dotfiles"
  echo "10) Configure Docker"
  echo "11) Setup Starship prompt"
  echo "12) Install ALL components"
  echo "0) Exit"
  echo
}

# Main function
main() {
  check_permissions

  # Always install git and stow first
  install_git_and_stow

  while true; do
    show_menu
    read -p "Enter your choice (space-separated for multiple, e.g., '1 2 3'): " choices

    # Convert choices to array
    IFS=' ' read -ra choice_array <<<"$choices"

    for choice in "${choice_array[@]}"; do
      case $choice in
      1)
        install_core_tools
        ;;
      2)
        install_python_tools
        ;;
      3)
        install_javascript_tools
        ;;
      4)
        install_container_tools
        ;;
      5)
        install_database_tools
        ;;
      6)
        install_gui_apps
        ;;
      7)
        install_wm_tools
        ;;
      8)
        install_fonts
        ;;
      9)
        setup_dotfiles
        ;;
      10)
        configure_docker
        ;;
      11)
        setup_starship
        ;;
      12)
        log "Installing ALL components..."
        install_core_tools
        install_python_tools
        install_javascript_tools
        install_container_tools
        install_database_tools
        install_gui_apps
        install_wm_tools
        install_fonts

        read -p "Setup dotfiles? (y/n): " setup_dots
        if [ "$setup_dots" = "y" ] || [ "$setup_dots" = "Y" ]; then
          setup_dotfiles
        fi

        read -p "Configure Docker? (y/n): " config_docker
        if [ "$config_docker" = "y" ] || [ "$config_docker" = "Y" ]; then
          configure_docker
        fi

        read -p "Setup Starship prompt? (y/n): " setup_starship_prompt
        if [ "$setup_starship_prompt" = "y" ] || [ "$setup_starship_prompt" = "Y" ]; then
          setup_starship
        fi
        ;;
      0)
        log "Exiting..."
        create_final_report
        log "Clean environment setup complete!"
        exit 0
        ;;
      *)
        error "Invalid choice: $choice"
        ;;
      esac
    done

    echo
    read -p "Continue with more installations? (y/n): " continue_install
    if [ "$continue_install" != "y" ] && [ "$continue_install" != "Y" ]; then
      break
    fi
  done

  create_final_report
  log "Clean environment setup complete!"
}

# Run the main function
main
