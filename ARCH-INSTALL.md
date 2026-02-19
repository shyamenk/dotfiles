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

---

## Step 1: Boot the USB

1. Plug in the USB, restart laptop
2. Press **F12** (Lenovo LOQ) to open boot menu
3. Select the USB drive (UEFI mode)
4. Select **Arch Linux install medium** and press Enter
5. You'll land at a root shell: `root@archiso ~ #`

## Step 2: Connect to WiFi

```bash
iwctl
```

Inside the `iwctl` prompt:
```
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "Your-SSID"
# Enter WiFi password when prompted
exit
```

Verify connection:
```bash
ping -c 3 archlinux.org
```

## Step 3: Update archinstall (recommended)

The ISO may ship an older version. Get the latest:
```bash
pacman -Sy archinstall
```

## Step 4: Run archinstall

### Option A: Interactive (recommended for first time)

```bash
archinstall
```

You'll see the main menu with these options. Configure each one:

---

### Screen 1: Archinstall language
→ **English** (default, just press Enter)

---

### Screen 2: Locales
→ Keyboard layout: **us**
→ System language: **en_US**
→ Encoding: **UTF-8**

---

### Screen 3: Mirrors
→ Select your closest region (e.g., **India**)
→ This speeds up package downloads significantly

---

### Screen 4: Disk configuration
→ Select **Use a best-effort default partition layout**
→ Select your NVMe drive: `/dev/nvme0n1`
→ Filesystem: **btrfs**
→ Subvolumes will be created automatically: `@`, `@home`, `@var`, `@.snapshots`
→ Compression: **zstd** (recommended)
→ Confirm **wipe the disk** when prompted

> ⚠️ This erases everything on the selected drive!

---

### Screen 5: Disk encryption
→ **Skip** (press Enter to leave empty)
→ Unless you want full-disk encryption

---

### Screen 6: Bootloader
→ **Systemd-boot** (default, recommended for UEFI)
→ Unified kernel images: **No**

---

### Screen 7: Swap
→ **True** (enabled, uses zram by default)

---

### Screen 8: Hostname
→ Type: `archlinux` (or whatever you prefer)

---

### Screen 9: Root password
→ Set a root password
→ Or leave blank to disable root (sudo only)

---

### Screen 10: User account
→ **Add a user**
→ Username: `shyamenk` (your username)
→ Password: enter your password
→ Should this user be a superuser (sudo)?: **Yes**

---

### Screen 11: Profile
→ Select: **Minimal**
→ Do NOT pick Desktop or any DE — `setup.sh` handles Hyprland

---

### Screen 12: Audio
→ **pipewire**

---

### Screen 13: Kernels
→ **linux** (default)

---

### Screen 14: Additional packages
Type these space-separated:
```
git linux-headers base-devel stow bluez bluez-utils
```

> These are the minimum needed for `setup.sh` to work. NetworkManager is auto-installed via network config.

---

### Screen 15: Network configuration
→ **Use NetworkManager**
→ This installs and enables NetworkManager automatically

---

### Screen 16: Timezone
→ **Asia/Kolkata** (or your timezone)

---

### Screen 17: Automatic time sync (NTP)
→ **True**

---

### Screen 18: Optional repositories
→ Enable **multilib** (needed for 32-bit NVIDIA libs)

---

### Screen 19: Save configuration
→ **Yes** — saves your config to `/var/log/archinstall/` for future use
→ Save to a USB if you want to reuse it

---

### Screen 20: Install
→ Review the summary
→ Select **Install** and press Enter
→ Installation takes ~10-30 minutes depending on your internet

---

### Option B: Using JSON config (automated)

Upload `user_configuration.json` from this repo to the ISO:

```bash
# From another machine, copy to USB or download
curl -O https://raw.githubusercontent.com/shyamenk/dotfiles/main/user_configuration.json

# Run with config
archinstall --config user_configuration.json
```

During installation you'll still be prompted for:
- Root password
- User account + password

## Step 5: Reboot

When installation completes:
```bash
# Say "No" when asked about chroot
reboot
```

Remove the USB drive during reboot.

## Step 6: First Boot — Login & Setup

You'll boot to a TTY login. Log in with your username and password.

```bash
# 1. Connect to WiFi (NetworkManager is now installed)
nmcli device wifi connect "Your-SSID" password "your-password"

# 2. Clone dotfiles
git clone https://github.com/shyamenk/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Run the setup script (installs everything)
sudo bash setup.sh

# 4. Reboot
sudo reboot
```

## Step 7: Start Hyprland

After reboot, log into TTY and run:
```bash
Hyprland
```

## Verification Checklist

After completing the installation, verify:

- [ ] Hyprland launches without errors
- [ ] Waybar is visible at the top
- [ ] Audio works (test with `wpctl status`)
- [ ] WiFi connected (check with `nmcli`)
- [ ] Bluetooth works (`bluetoothctl power on`)
- [ ] NVIDIA detected (`nvidia-smi`)
- [ ] Terminal opens (`Super + Return`)
- [ ] Wofi launcher works (`Super + Space`)
- [ ] Brightness controls work (`Fn` keys)
- [ ] Screenshot tool works (`Print`)

## Troubleshooting

### Can't connect to WiFi after boot
```bash
sudo systemctl enable --now NetworkManager
nmcli device wifi connect "SSID" password "password"
```

### Hyprland won't start
```bash
# Check for errors
cat ~/.local/share/hyprland/hyprland.log

# Ensure NVIDIA modules loaded
lsmod | grep nvidia

# Rebuild initramfs
sudo mkinitcpio -P
sudo reboot
```

### No audio
```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Black screen on boot
```bash
# Switch to TTY: Ctrl+Alt+F2
sudo mkinitcpio -P
sudo reboot
```

## File Structure After Installation

```
~/dotfiles/
├── alacritty/      # Terminal emulator
├── bat/            # Better cat
├── cmdx/           # Command runner
├── dunst/          # Notifications
├── hyprland/       # Window manager + hyprlock, hypridle
├── kitty/          # Terminal emulator
├── nvim/           # Neovim (LazyVim)
├── scripts/        # Utility scripts (~/.local/bin)
├── sfdocs/         # Salesforce CLI docs
├── starship/       # Shell prompt
├── tmux/           # Terminal multiplexer
├── wallpapers/     # Wallpapers (copied to ~/Pictures/wallpaper)
├── waybar/         # Status bar
├── wezterm/        # Terminal (alt)
├── wofi/           # App launcher
├── yazi/           # File manager
├── zathura/        # PDF viewer
├── zsh/            # Shell config
├── setup.sh        # Automated setup script
└── user_configuration.json  # archinstall config
```
