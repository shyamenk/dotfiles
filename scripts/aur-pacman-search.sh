#!/bin/bash

# Combine pacman and AUR packages using yay
pkg=$(yay -Slq | fzf --prompt="Search package: " --preview='yay -Si {1}' --preview-window=right:60%)

[ -z "$pkg" ] && exit 0

# Confirm installation
rofi -dmenu -p "Install $pkg? (yes/no)" <<<"yes\nno" | grep -q yes || exit 0

# Install the selected package non-interactively
alacritty -e bash -c "yay -S --noconfirm $pkg; exec bash"
