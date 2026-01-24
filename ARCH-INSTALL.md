# Arch Linux Installation Guide

Reproducible Arch Linux installation for Hyprland Wayland environment.

## Target Hardware

- **Laptop**: Lenovo LOQ 15ARP9
- **CPU**: AMD Ryzen 7 7435HS
- **GPU**: NVIDIA GeForce RTX 4050 (Laptop)
- **Result**: Full Hyprland Wayland desktop with NVIDIA support

## Prerequisites

1. Download [Arch Linux ISO](https://archlinux.org/download/)
2. Create bootable USB:
   ```bash
   # Using dd (replace /dev/sdX with your USB device)
   sudo dd if=archlinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
3. Backup important data
4. Disable Secure Boot in BIOS

## Boot & Network Setup

1. Boot from USB in UEFI mode
2. Connect to internet:
   ```bash
   # WiFi
   iwctl
   station wlan0 connect "Your-SSID"
   exit

   # Verify connection
   ping -c 3 archlinux.org
   ```

## Automated Installation with archinstall

### Option 1: Using JSON Config (Recommended)

Save this configuration as `user_configuration.json`:

```json
{
  "additional-repositories": ["multilib"],
  "audio_config": {
    "audio": "pipewire"
  },
  "bootloader": "systemd-boot",
  "config_version": "2.8.1",
  "debug": false,
  "disk_config": {
    "config_type": "default_layout",
    "device_modifications": [
      {
        "device": "/dev/nvme0n1",
        "partitions": [
          {
            "btrfs": [],
            "flags": ["Boot"],
            "fs_type": "fat32",
            "mount_options": [],
            "mountpoint": "/boot",
            "size": {
              "sector_size": null,
              "unit": "MiB",
              "value": 1024
            },
            "type": "primary"
          },
          {
            "btrfs": [
              {
                "mountpoint": "/",
                "name": "@"
              },
              {
                "mountpoint": "/home",
                "name": "@home"
              },
              {
                "mountpoint": "/var",
                "name": "@var"
              },
              {
                "mountpoint": "/.snapshots",
                "name": "@snapshots"
              }
            ],
            "flags": [],
            "fs_type": "btrfs",
            "mount_options": ["compress=zstd", "noatime"],
            "mountpoint": null,
            "size": {
              "sector_size": null,
              "unit": "Percent",
              "value": 100
            },
            "type": "primary"
          }
        ],
        "wipe": true
      }
    ]
  },
  "hostname": "archlinux",
  "kernels": ["linux"],
  "locale_config": {
    "kb_layout": "us",
    "sys_enc": "UTF-8",
    "sys_lang": "en_US"
  },
  "network_config": {
    "type": "nm"
  },
  "no_pkg_lookups": false,
  "ntp": true,
  "packages": [
    "git",
    "base-devel",
    "stow",
    "networkmanager",
    "bluez",
    "bluez-utils"
  ],
  "parallel_downloads": 5,
  "profile_config": {
    "profile": {
      "main": "minimal"
    }
  },
  "swap": true,
  "timezone": "Asia/Kolkata",
  "uki": false
}
```

Run the installation:

```bash
# Download or create the config file
curl -O https://raw.githubusercontent.com/shyamenk/dotfiles/main/user_configuration.json
# OR create it manually with nano/vim

# Run archinstall with config
archinstall --config user_configuration.json
```

During installation, you'll be prompted to:
- Set root password
- Create a user account (add to wheel group, enable sudo)

### Option 2: Interactive archinstall

```bash
archinstall
```

Select these options:
- **Bootloader**: systemd-boot
- **Filesystem**: btrfs
- **Profile**: minimal
- **Audio**: pipewire
- **Network**: NetworkManager
- **Additional packages**: git base-devel stow

## Post-Installation

After rebooting into your new system:

```bash
# 1. Clone dotfiles
git clone https://github.com/shyamenk/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Run setup script (installs all packages + AUR helper)
sudo bash setup.sh

# 3. Stow all configurations
stow hyprland waybar wofi dunst alacritty wezterm nvim zsh tmux yazi bat scripts

# 4. Change default shell to zsh
chsh -s /bin/zsh

# 5. Reboot
sudo reboot

# 6. After reboot, start Hyprland from TTY
Hyprland
```

## NVIDIA Configuration

The `setup.sh` script handles NVIDIA setup automatically. For reference, it:

1. Installs NVIDIA drivers:
   ```bash
   nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
   ```

2. Configures kernel modules in `/etc/mkinitcpio.conf`:
   ```
   MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
   ```

3. Creates `/etc/modprobe.d/nvidia.conf`:
   ```
   options nvidia_drm modeset=1 fbdev=1
   ```

4. Sets environment variables in Hyprland config for proper Wayland support

## Verification Checklist

After completing the installation, verify:

- [ ] Hyprland launches without errors
- [ ] Waybar is visible at the top
- [ ] Audio works (test with `wpctl status`)
- [ ] WiFi connected (check with `nmcli`)
- [ ] NVIDIA detected (`nvidia-smi`)
- [ ] Terminal opens (`Super + Return`)
- [ ] Wofi launcher works (`Super + Space`)
- [ ] Brightness controls work (`Fn` keys)
- [ ] Screenshot tool works (`Super + Shift + S`)

## Troubleshooting

### Hyprland won't start
```bash
# Check for errors
cat ~/.local/share/hyprland/hyprland.log

# Ensure NVIDIA modules loaded
lsmod | grep nvidia
```

### No audio
```bash
# Restart PipeWire
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### WiFi not working
```bash
# Enable NetworkManager
sudo systemctl enable --now NetworkManager
nmcli device wifi connect "SSID" password "password"
```

## File Structure After Installation

```
~/dotfiles/
├── alacritty/      # Terminal emulator
├── bat/            # Better cat
├── dunst/          # Notifications
├── hyprland/       # Window manager + hyprlock, hypridle
├── nvim/           # Neovim (LazyVim)
├── scripts/        # Utility scripts
├── tmux/           # Terminal multiplexer
├── waybar/         # Status bar
├── wezterm/        # Alt terminal
├── wofi/           # App launcher
├── yazi/           # File manager
└── zsh/            # Shell config
```
