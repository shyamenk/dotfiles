# Fedora Workstation + Hyprland + NVIDIA Setup

Complete automated setup for Fedora Workstation with Hyprland, NVIDIA drivers, and development tools for Salesforce, AWS, and fullstack development.

## 📋 What's Included

### System Components
- ✅ Fedora Workstation 41+ (mutable system)
- ✅ Hyprland (tiling Wayland compositor) via COPR
- ✅ NVIDIA drivers (proprietary) from RPM Fusion
- ✅ CUDA toolkit for ML/AI development
- ✅ Docker with NVIDIA Container Toolkit
- ✅ Podman and Distrobox for containerized development

### Your Dotfiles
- ✅ Automatic clone from https://github.com/shyamenk/dotfiles
- ✅ GNU Stow for dotfile management
- ✅ Hyprland, Waybar, Wofi, Dunst configs
- ✅ Neovim, Tmux, Zsh, Alacritty configs
- ✅ Wallpapers copied to ~/Pictures/wallpaper

### Development Runtimes
- ✅ Node.js via nvm (LTS version)
- ✅ Python 3 with uv and pyenv
- ✅ Rust/Cargo for Rust tools
- ✅ Docker and Podman containers

### Development Tools
- ✅ **Salesforce**: sf CLI, SFDX Scanner, Apex tools
- ✅ **AWS**: CLI v2, SAM, CDK, eksctl, kubectl, k9s
- ✅ **Fullstack**: React, Vue, Angular CLIs, databases, API tools
- ✅ **TUI Apps**: lazygit, lazydocker, yazi, btop, nvtop, k9s
- ✅ **Git Tools**: GitHub CLI, GitLab CLI, delta, tig
- ✅ **Editors**: Neovim, VS Code, Helix, micro

## 🚀 Quick Start

### Prerequisites
- Fresh Fedora Workstation 41+ installation
- NVIDIA GPU (RTX 4050 in your case)
- Sudo access
- Internet connection

### Step 1: Download Scripts
```bash
# Create setup directory
mkdir -p ~/setup && cd ~/setup

# Download all scripts
wget https://raw.githubusercontent.com/YOUR_REPO/fedora-hyprland-setup.sh
wget https://raw.githubusercontent.com/YOUR_REPO/install-dev-tools.sh

# Make executable
chmod +x *.sh
```

### Step 2: Run Main Setup
```bash
# Run the main setup script
sudo ./fedora-hyprland-setup.sh
```

**This will:**
1. Enable RPM Fusion and COPR repositories
2. Update system
3. Clone your dotfiles and stow configurations
4. Install Hyprland and Wayland ecosystem
5. Install NVIDIA drivers and CUDA
6. Set up Docker and Podman
7. Install development runtimes (nvm, uv, rust)
8. Configure system services

**Time estimate:** 30-45 minutes

### Step 3: Reboot
```bash
sudo reboot
```

### Step 4: Install Additional Dev Tools
```bash
cd ~/setup
sudo ./install-dev-tools.sh
```

**This will install:**
- Salesforce CLI and plugins
- AWS tools (SAM, CDK, eksctl, terraform)
- Database CLIs (pgcli, mycli, usql)
- TUI applications (many!)
- Kubernetes tools (helm, k9s, kubectx)
- API testing tools (httpie, curlie)

**Time estimate:** 15-20 minutes

### Step 5: Configure Shell
```bash
# Change default shell to zsh
chsh -s /bin/zsh

# Log out and back in
```

### Step 6: Start Hyprland
```bash
# From TTY (Ctrl+Alt+F3) or login screen
Hyprland

# Or if you installed SDDM, select Hyprland from the display manager
```

## 📦 Package Lists

### Core Packages Installed

#### Hyprland Ecosystem (from COPR)
- hyprland, hypridle, hyprlock, hyprpaper
- waybar, wofi, dunst
- hyprpicker

#### Wayland Essentials
- grim, slurp, wl-clipboard
- brightnessctl
- qt5/qt6-qtwayland
- xdg-desktop-portal-hyprland

#### Audio (Pre-installed on Fedora)
- pipewire, pipewire-pulseaudio
- wireplumber, pavucontrol

#### Terminals
- alacritty, wezterm, kitty

#### Dev Tools
- neovim, tmux, ripgrep, fzf, bat
- fd-find, jq, tree, zoxide
- htop, btop, lazygit
- GitHub CLI (gh)

#### File Manager
- thunar, tumbler, ffmpegthumbnailer

#### NVIDIA (from RPM Fusion)
- akmod-nvidia (auto-compiles for kernel)
- nvidia-settings
- nvidia-vaapi-driver
- cuda, cuda-toolkit
- nvidia-container-toolkit

#### Fonts
- jetbrains-mono-fonts-all
- google-noto-* (sans, serif, emoji, mono)
- fira-code-fonts

### Flatpak Applications
- Obsidian
- Spotify
- Zoom
- Signal
- Slack
- Telegram

### Additional Tools (install-dev-tools.sh)

#### Salesforce
- @salesforce/cli (sf)
- SFDX Scanner
- Prettier + Apex plugin
- ESLint with LWC config
- Jest for LWC testing

#### AWS
- AWS CLI v2
- AWS SAM CLI
- AWS CDK
- eksctl, kubectl, k9s
- Terraform, Terragrunt
- Helm, kubectx/kubens

#### Databases
- pgcli (PostgreSQL TUI)
- mycli (MySQL TUI)
- litecli (SQLite TUI)
- usql (Universal SQL)
- mongosh (MongoDB Shell)

#### API Testing
- HTTPie
- curlie (curl + httpie)
- xh (Rust HTTP client)

#### TUI Applications
- lazygit, lazydocker
- yazi (file manager)
- ranger, nnn, lf, mc
- bottom (btm), ctop, nvtop
- zellij (tmux alternative)
- tig (git interface)

#### System Tools
- dive (Docker image explorer)
- steampipe (Cloud asset inventory)
- dog (DNS client)
- bandwhich (network monitor)

#### Productivity
- taskwarrior, timewarrior
- calcurse (calendar)
- glow (Markdown renderer)

## 🔧 Post-Installation Configuration

### 1. Verify NVIDIA
```bash
# Check driver
nvidia-smi

# Should show your RTX 4050 with driver version
```

### 2. Configure Salesforce CLI
```bash
# Login to org
sf org login web

# Set default org
sf config set target-org your-org-alias

# Verify
sf org list
```

### 3. Configure AWS CLI
```bash
# Configure credentials
aws configure

# Or use AWS SSO
aws configure sso
```

### 4. Set up Development Container (Recommended)
```bash
# Create a dev toolbox
toolbox create dev

# Enter the container
toolbox enter dev

# Inside container, install tools
sudo dnf install nodejs postgresql-server
```

### 5. Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main

# GitHub CLI authentication
gh auth login
```

### 6. Set up Docker
```bash
# Test Docker
docker run hello-world

# Test NVIDIA in Docker
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

## 🎨 Hyprland Configuration

Your dotfiles from https://github.com/shyamenk/dotfiles are automatically stowed.

### Key Bindings (assuming standard Hyprland config)
- `Super + Enter` - Terminal
- `Super + D` - Launcher (wofi)
- `Super + Q` - Close window
- `Super + [1-9]` - Switch workspace
- `Super + Shift + [1-9]` - Move to workspace
- `Super + Mouse` - Move/resize windows

### Customize
```bash
# Edit Hyprland config
nvim ~/.config/hypr/hyprland.conf

# Reload Hyprland
Super + Shift + R
```

## 📚 Usage Examples

### Salesforce Development
```bash
# Create new project
sf project generate -n my-project

# Retrieve metadata
sf project retrieve start -m ApexClass

# Deploy
sf project deploy start -d force-app

# Run Apex tests
sf apex run test -t MyTestClass

# Open org
sf org open
```

### AWS Development
```bash
# SAM application
sam init
sam build
sam deploy --guided

# CDK application
cdk init app --language typescript
cdk deploy

# Kubernetes
kubectl get pods
k9s  # Launch TUI
```

### Database Work
```bash
# PostgreSQL
pgcli postgresql://user@host/database

# MySQL
mycli -u user -h host database

# Universal SQL
usql postgres://user@host/db
usql mysql://user@host/db
```

### Container Development
```bash
# Create dev environment
toolbox create nodejs-dev
toolbox enter nodejs-dev

# Or use distrobox for other distros
distrobox create --name ubuntu-dev --image ubuntu:22.04
distrobox enter ubuntu-dev
```

## 🐛 Troubleshooting

### NVIDIA Issues
```bash
# Check if driver is loaded
lsmod | grep nvidia

# Rebuild initramfs
sudo dracut --force

# Check kernel parameters
grubby --info ALL | grep nvidia

# Reinstall if needed
sudo dnf reinstall akmod-nvidia
```

### Hyprland Won't Start
```bash
# Check logs
journalctl --user -u hyprland

# Try from TTY
Ctrl+Alt+F3
Hyprland

# Check SELinux
sudo setenforce 0  # Temporary
```

### Docker Permission Issues
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
```

### Node.js/npm Issues
```bash
# Check nvm
nvm list

# Reinstall node
nvm install --lts
nvm use --lts

# Check npm prefix
npm config get prefix
# Should be ~/.nvm/versions/node/vXX.XX.X
```

### Dotfiles Conflicts
```bash
# Backup existing configs
mv ~/.config/nvim ~/.config/nvim.backup

# Re-stow
cd ~/dotfiles
stow -R nvim
```

## 🔄 Updates & Maintenance

### Update System
```bash
# Update Fedora
sudo dnf update -y

# Update Flatpaks
flatpak update

# Update npm globals
npm update -g

# Update cargo tools
cargo install-update -a
```

### Update Hyprland
```bash
# Hyprland from COPR updates with system
sudo dnf update hyprland
```

### Update NVIDIA
```bash
# NVIDIA updates with kernel
# akmod auto-compiles for new kernels
sudo dnf update
```

### Rebuild Dotfiles
```bash
cd ~/dotfiles
git pull
stow -R */
```

## 📁 Directory Structure

```
$HOME/
├── dotfiles/           # Your dotfiles repo
├── Projects/           # Your projects
├── workspace/          # Development workspace
├── Pictures/
│   └── wallpaper/     # Wallpapers from dotfiles
├── .nvm/              # Node.js versions
├── .cargo/            # Rust tools
├── .local/
│   └── bin/           # Local binaries
└── .config/           # Application configs
    ├── hypr/
    ├── waybar/
    ├── nvim/
    └── ...
```

## 🎯 What's Different from Arch?

### Package Manager
- `pacman -S` → `dnf install`
- `pacman -Syu` → `dnf update`
- AUR → COPR or manual install

### Init System
- `mkinitcpio` → `dracut`
- Direct GRUB edit → `grubby` commands

### NVIDIA
- `nvidia-dkms` → `akmod-nvidia`
- Auto-compiles for each kernel
- RPM Fusion instead of official repos

### System Defaults
- Fedora comes with GNOME, Pipewire, Flatpak
- SELinux is enforcing (may need permissive for Hyprland)
- Firewalld is active

## 🆘 Getting Help

### Logs
```bash
# Setup logs
sudo tail -f /var/log/fedora-hyprland-setup-*.log
sudo tail -f /var/log/dev-tools-*.log

# System logs
journalctl -xb

# Hyprland logs
cat ~/.local/share/hyprland/hyprland.log
```

### Community
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Fedora Docs](https://docs.fedoraproject.org/)
- [NVIDIA on Fedora](https://rpmfusion.org/Howto/NVIDIA)

## 📊 System Requirements

### Minimum
- CPU: 64-bit processor
- RAM: 8GB
- Storage: 50GB
- GPU: NVIDIA with proprietary driver support

### Your System (from fastfetch)
- ✅ CPU: AMD Ryzen 7 7435HS (16 cores)
- ✅ RAM: 23.15 GiB
- ✅ Storage: 475.94 GiB
- ✅ GPU: NVIDIA RTX 4050 Max-Q
- ✅ Display: 1920x1080 @ 60Hz

**Your system exceeds all requirements!** 🚀

## 📝 Notes

### SELinux
The script asks if you want to set SELinux to permissive. This is recommended for Hyprland but reduces security. If you keep it enforcing, some Hyprland features may not work.

### Display Manager
The script asks if you want SDDM. If you skip it, you'll need to start Hyprland manually from TTY.

### Toolbox vs Host
For cleanest setup:
- Install language-specific tools in toolbox
- Keep system minimal
- Use containers for projects

### GitHub Dotfiles
Make sure your dotfiles repo is public or you have SSH keys set up before running the script.

## 🎉 You're All Set!

After running both scripts and rebooting:

1. ✅ Hyprland is configured with your dotfiles
2. ✅ NVIDIA drivers are working with CUDA support
3. ✅ Docker and containers are ready
4. ✅ All development tools are installed
5. ✅ Salesforce, AWS, and fullstack tools ready to go

Start coding! 🚀

---

**Created for:** Transition from Arch Linux to Fedora Workstation  
**Hardware:** Lenovo LOQ 15ARP9, Ryzen 7 7435HS, RTX 4050  
**Date:** 2025
