# 🛠️ My Dotfiles 🖥️

This repository contains my personal dotfiles setup.## Requirements

ensure you have the following installed:

## 📋 Requirements

Make sure you have the following installed:

### Git

```bash
sudo apt install git
```

### GNU Stow

```bash
sudo apt install stow
```

### 🚀Installation

1. Clone the dotfiles repository into your home directory:

```bash
git clone git@github.com/shyamenk/dotfiles.git
cd dotfiles
```

2. Use GNU Stow to symlink the dotfiles you want to use:

```bash
stow .

or

stow --adopt .
```

### 📁 Included Configurations

This repository currently includes configurations for:

- `.zshrc`: Zsh configuration
- `zimrc`: Zim (Zsh configuration framework) configuration
- `alacritty`: Alacritty terminal emulator configuration
- `nvim`: Neovim configuration
- `tmux`: Tmux configuration

More configurations may be added in the future.

Feel free to customize and adapt these dotfiles to suit your needs!
