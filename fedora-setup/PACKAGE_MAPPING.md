# Arch Linux to Fedora Package Mapping

## Package Manager Commands
| Arch Linux | Fedora Workstation |
|------------|-------------------|
| `pacman -Syu` | `dnf update` |
| `pacman -S package` | `dnf install package` |
| `pacman -R package` | `dnf remove package` |
| `pacman -Ss search` | `dnf search search` |
| `pacman -Q` | `dnf list installed` |
| `yay -S aur-package` | Use COPR or manual install |

## Core System Packages
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `base-devel` | `@development-tools` | Group package |
| `linux-headers` | `kernel-devel kernel-headers` | |
| `man-db` | `man-db man-pages` | |

## Hyprland Ecosystem
| Arch Package | Fedora Package | Repository |
|--------------|----------------|------------|
| `hyprland` | `hyprland` | COPR: solopasha/hyprland |
| `hypridle` | `hypridle` | COPR: solopasha/hyprland |
| `hyprlock` | `hyprlock` | COPR: solopasha/hyprland |
| `hyprpaper` | `hyprpaper` | COPR: solopasha/hyprland |
| `waybar` | `waybar` | Official Fedora repos |
| `wofi` | `wofi` | Official Fedora repos |
| `dunst` | `dunst` | Official Fedora repos |

## Wayland Tools
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `grim` | `grim` | |
| `slurp` | `slurp` | |
| `wl-clipboard` | `wl-clipboard` | |
| `brightnessctl` | `brightnessctl` | |
| `qt5-wayland` | `qt5-qtwayland` | |
| `qt6-wayland` | `qt6-qtwayland` | |
| `xdg-desktop-portal-hyprland` | `xdg-desktop-portal-hyprland` | COPR |
| `polkit-gnome` | `polkit-gnome` | |
| `xdg-user-dirs` | `xdg-user-dirs xdg-user-dirs-gtk` | |

## Audio Stack
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `pipewire` | `pipewire` | Pre-installed on Fedora |
| `pipewire-pulse` | `pipewire-pulseaudio` | Different package name |
| `pipewire-alsa` | `pipewire-alsa` | |
| `wireplumber` | `wireplumber` | Pre-installed on Fedora |
| `pavucontrol` | `pavucontrol` | |

## Network
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `networkmanager` | `NetworkManager` | Pre-installed, different case |
| `iwd` | `iwd` | |
| `impala` | ❌ Not available | Need alternative or build from source |

## Terminals
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `alacritty` | `alacritty` | |
| `wezterm` | `wezterm` | |
| `kitty` | `kitty` | |
| `zsh` | `zsh` | |

## Development Tools
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `neovim` | `neovim` | |
| `tmux` | `tmux` | |
| `ripgrep` | `ripgrep` | |
| `fzf` | `fzf` | |
| `bat` | `bat` | |
| `zoxide` | `zoxide` | |
| `fd` | `fd-find` | Different package name |
| `jq` | `jq` | |
| `tree` | `tree` | |
| `unzip` | `unzip` | |
| `zip` | `zip` | |
| `htop` | `htop` | |
| `btop` | `btop` | |
| `openssh` | `openssh` | Pre-installed |
| `github-cli` | `gh` | Via GitHub's official repo |
| `lazydocker` | ❌ Not in repos | Install via script |
| `lazygit` | `lazygit` | |

## File Manager
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `thunar` | `thunar` | |
| `tumbler` | `tumbler` | |
| `ffmpegthumbnailer` | `ffmpegthumbnailer` | |

## OCR
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `tesseract` | `tesseract` | |
| `tesseract-data-eng` | `tesseract-langpack-eng` | Different naming |

## Office & Productivity
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `libreoffice-fresh` | `libreoffice` | |
| `xournalpp` | `xournalpp` | |

## Flatpak
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `flatpak` | `flatpak` | Pre-installed on Fedora |

## Fonts
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `ttf-jetbrains-mono-nerd` | `jetbrains-mono-fonts-all` | No "nerd" suffix |
| `ttf-victor-mono-nerd` | ❌ Not in repos | Use flatpak or manual install |
| `noto-fonts` | `google-noto-sans-fonts` | Different naming |
| `noto-fonts-emoji` | `google-noto-emoji-fonts` | Different naming |

## NVIDIA Drivers
| Arch Package | Fedora Package | Repository |
|--------------|----------------|------------|
| `nvidia-dkms` | `akmod-nvidia` | RPM Fusion Nonfree |
| `nvidia-utils` | `xorg-x11-drv-nvidia` | RPM Fusion Nonfree |
| `nvidia-settings` | `nvidia-settings` | RPM Fusion Nonfree |
| `libva-nvidia-driver` | `nvidia-vaapi-driver` | RPM Fusion Nonfree |
| N/A | `xorg-x11-drv-nvidia-cuda` | CUDA support |
| N/A | `xorg-x11-drv-nvidia-cuda-libs` | CUDA libraries |

## AUR Packages (Require Alternative Installation)
| Arch AUR Package | Fedora Alternative | Method |
|------------------|-------------------|--------|
| `swww` | ❌ Not available | Build from source or use alternatives |
| `wf-recorder` | `wf-recorder` | Available in repos |
| `hyprpicker` | `hyprpicker` | COPR: solopasha/hyprland |
| `wtype` | `wtype` | COPR or build from source |
| `cliphist` | ❌ Not available | Build from source |
| `eza` | `eza` | Available in repos |
| `yazi` | ❌ Not in repos | Install via cargo |
| `lazygit` | `lazygit` | Available in repos |
| `starship-bin` | `starship` | Install via script |
| `google-chrome` | `google-chrome-stable` | Via Google's repo |
| `obsidian-bin` | `com.obsidian.Obsidian` | Flatpak |
| `bruno-bin` | ❌ Not available | AppImage or build from source |
| `spotify` | `com.spotify.Client` | Flatpak (no ads blocker) |
| `spotify-adblock-git` | ❌ Not available | Spotify flatpak doesn't support |
| `aws-cli-v2-bin` | AWS CLI v2 | Install via AWS script |
| `pinta` | `pinta` | Available in repos |
| `typora` | ❌ Not available | AppImage or subscription |
| `zoom` | `us.zoom.Zoom` | Flatpak |
| `opencode-bin` | `code` | VS Code via Microsoft repo |
| `envycontrol` | ❌ Not needed | Fedora handles GPU switching |

## Docker
| Arch Package | Fedora Package | Notes |
|--------------|----------------|-------|
| `docker` | `docker-ce` | From Docker's official repo |
| `docker-compose` | `docker-compose-plugin` | Plugin instead of standalone |

## Additional Fedora-Specific Packages
| Package | Purpose |
|---------|---------|
| `nvtop` | GPU monitoring (like nvidia-smi but better) |
| `podman` | Fedora's native container runtime |
| `podman-compose` | Docker-compose for Podman |
| `distrobox` | Container-based development environments |
| `toolbox` | Fedora's containerized dev environment tool |
| `grubby` | Bootloader configuration tool |
| `dracut` | Fedora's initramfs tool (replaces mkinitcpio) |
| `nvidia-container-toolkit` | NVIDIA GPU support in containers |

## Package Groups
| Arch Group | Fedora Group | Install Command |
|------------|--------------|-----------------|
| `base-devel` | `@development-tools` | `dnf groupinstall "Development Tools"` |
| N/A | `@c-development` | C development tools |
| N/A | `@python3` | Python development |

## Key Differences

### 1. Package Manager
- Fedora uses **DNF** instead of Pacman
- **COPR** replaces AUR for third-party repos
- Many packages need manual installation

### 2. NVIDIA Drivers
- Fedora uses **RPM Fusion** for NVIDIA drivers
- Uses `akmod-nvidia` (auto-compiles for each kernel)
- Uses `grubby` for kernel parameters instead of editing GRUB config
- Uses `dracut` instead of `mkinitcpio` for initramfs

### 3. System Configuration
- `/etc/environment.d/` for environment variables
- `systemctl` works the same
- SELinux may need adjustment for Hyprland

### 4. Missing Packages
Some Arch packages don't have direct Fedora equivalents:
- `impala` (network TUI) - use `nmtui` instead
- `cliphist` - build from source
- `bruno-bin` - use AppImage
- `envycontrol` - not needed, Fedora handles GPU switching

### 5. Pre-installed Software
Fedora Workstation comes with:
- GNOME desktop (can be removed after Hyprland setup)
- Pipewire audio
- Flatpak
- NetworkManager
- Many fonts

## Repository Priority
1. **Official Fedora repos** - Use first
2. **RPM Fusion** - For multimedia and NVIDIA
3. **COPR** - For Hyprland and specialized packages
4. **Official vendor repos** - Google Chrome, VS Code, Docker
5. **Flatpak** - For desktop applications
6. **Manual scripts** - For AWS CLI, Starship, etc.
7. **Build from source** - Last resort

## Migration Strategy
1. Enable RPM Fusion (Free + Nonfree)
2. Enable required COPR repos
3. Install from official Fedora repos
4. Add vendor repos (Chrome, VS Code, Docker)
5. Install Flatpaks
6. Run installation scripts
7. Build from source if necessary
