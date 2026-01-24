# Dotfiles

Personal dotfiles for Arch Linux with Hyprland.

**Hardware**: Lenovo LOQ 15ARP9 (AMD Ryzen 7 7435HS + NVIDIA RTX 4050)

## Fresh Arch Install (archinstall)

```bash
# 1. Boot Arch ISO and connect to WiFi
iwctl
> station wlan0 connect YOUR_WIFI
> exit

# 2. Run archinstall
archinstall

# 3. archinstall settings:
#    - Mirrors: Select your region
#    - Disk: Select drive → btrfs → wipe
#    - Bootloader: systemd-boot
#    - Hostname: your-hostname
#    - Root password: set it
#    - User: create user with sudo
#    - Profile: Minimal (NOT Desktop/Hyprland)
#    - Audio: pipewire
#    - Network: NetworkManager
#    - Additional packages: git linux-headers
#    - Graphics driver: SKIP (setup.sh handles this)
#    - Timezone: your timezone

# 4. Reboot and login, then run Quick Install below
```

## Quick Install

```bash
git clone https://github.com/shyamenk/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo bash setup.sh

# Post-install
chsh -s /bin/zsh
sudo reboot
```

## Start Hyprland

```bash
Hyprland
```

## Manual Install

### Requirements

```bash
sudo pacman -S git stow
```

### Stow Individual Packages

```bash
cd ~/dotfiles

stow hyprland    # Hyprland, hypridle, hyprlock, hyprpaper
stow waybar      # Status bar
stow wofi        # Application launcher
stow dunst       # Notifications
stow alacritty   # Terminal
stow wezterm     # Terminal (alt)
stow nvim        # Neovim (LazyVim)
stow zsh         # Zsh + Zim
stow tmux        # Tmux
stow yazi        # File manager
stow bat         # Better cat
stow scripts     # Custom scripts (~/.local/bin)
```

### Stow All

```bash
stow */
```

## Structure

```
dotfiles/
├── hyprland/     # Hyprland + hypr* configs + scripts
├── waybar/       # Waybar config + styles
├── wofi/         # Wofi launcher
├── dunst/        # Notifications
├── alacritty/    # Alacritty terminal
├── wezterm/      # WezTerm terminal
├── nvim/         # Neovim (LazyVim)
├── zsh/          # .zshrc + .zimrc
├── tmux/         # .tmux.conf
├── yazi/         # File manager
├── bat/          # Syntax highlighting
├── scripts/      # ~/.local/bin scripts
├── wallpaper/    # Wallpapers (copied to ~/Pictures/wallpaper)
└── .archive/     # Legacy (i3, polybar, rofi, picom) - hidden, not stowed
```

## Wayland Stack

| Component     | Package    |
|---------------|------------|
| Compositor    | Hyprland   |
| Bar           | Waybar     |
| Launcher      | Wofi       |
| Notifications | Dunst      |
| Lock          | Hyprlock   |
| Idle          | Hypridle   |
| Wallpaper     | Hyprpaper/swww |

## Keybindings (Hyprland)

| Key | Action |
|-----|--------|
| `Super+Return` | Alacritty |
| `Super+Space` | Wofi |
| `Super+Q` | Kill window |
| `Super+G` | Chrome |
| `Super+Shift+N` | Thunar |
| `Super+Shift+V` | Screen record |
| `Super+Shift+O` | OCR text extract |
| `Super+Shift+G` | Color picker |
| `Super+.` | Emoji picker |
| `Print` | Screenshot |
| `Shift+Print` | Area screenshot |

## Scripts

| Script | Description |
|--------|-------------|
| `tmux-dev` | Dev session (3 windows: code, server, shell) |
| `power-menu.sh` | Shutdown/reboot/lock menu |
| `screen-recording.sh` | wf-recorder toggle |
| `text-extractor.sh` | OCR with tesseract |
| `color-picker.sh` | hyprpicker color picker |

## Apps Installed

- **Dev**: Neovim, tmux, lazygit, lazydocker, bruno (API), opencode (AI)
- **Browsers**: Google Chrome
- **Office**: LibreOffice, Xournal++ (PDF annotation), Typora (markdown)
- **Apps**: Obsidian, Spotify (with adblock), Thunar, Zoom, Pinta
- **Tools**: ripgrep, fzf, bat, eza, yazi, zoxide, impala (WiFi TUI)
- **GPU**: nvidia-dkms, envycontrol

## Unstow

```bash
stow -D hyprland   # Remove symlinks
```

## NVIDIA GPU (RTX 4050)

The setup script automatically configures:
- `nvidia-dkms` driver with kernel modules
- Hardware video acceleration (`libva-nvidia-driver`)
- Proper mkinitcpio and modprobe settings
- Suspend/resume services

### GPU Commands

```bash
# Check NVIDIA is working
nvidia-smi

# Check video acceleration (YouTube HW decode)
vainfo

# GPU temperature and usage
watch -n 1 nvidia-smi
```

### GPU Mode Switching (envycontrol)

```bash
# NVIDIA only - max performance, higher power
sudo envycontrol -s nvidia

# Hybrid - both GPUs, NVIDIA on-demand
sudo envycontrol -s hybrid

# Integrated only - AMD iGPU, max battery
sudo envycontrol -s integrated

# Check current mode
envycontrol --status
```

**Note**: Reboot required after switching modes.

## Network (WiFi)

Uses `iwd` backend with `impala` TUI.

```bash
# Open WiFi manager
impala

# Or via waybar: click network module
```

## Troubleshooting

### Black screen on boot
```bash
# Switch to TTY: Ctrl+Alt+F2
# Rebuild initramfs
sudo mkinitcpio -P
sudo reboot
```

### No video acceleration
```bash
# Verify NVIDIA VA-API
vainfo
# Should show: libva info: VA-API version: 1.x
```

### Hyprland won't start
```bash
# Check NVIDIA modules loaded
lsmod | grep nvidia

# Check Hyprland logs
cat ~/.local/share/hyprland/hyprland.log
```
