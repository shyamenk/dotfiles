# Dotfiles

Personal dotfiles for Arch Linux with Hyprland.

## Quick Install

```bash
git clone https://github.com/shyamenk/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo ./setup.sh
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

- **Dev**: Neovim, tmux, lazygit, bruno (API)
- **Browsers**: Google Chrome
- **Apps**: Obsidian, Spotify (with adblock), Thunar
- **Tools**: ripgrep, fzf, bat, eza, yazi, zoxide

## Unstow

```bash
stow -D hyprland   # Remove symlinks
```
