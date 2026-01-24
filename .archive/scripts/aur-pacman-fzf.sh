#!/bin/bash

# Temp file to store selected package
TMP_PKG=$(mktemp)

# Fetch all available packages from yay (includes AUR)
yay -Slq >/tmp/pkglist.txt

# Show fuzzy finder (fzf) with preview
cat /tmp/pkglist.txt |
  fzf --prompt="Search Packages: " \
    --preview='yay -Si {} 2>/dev/null | head -30' \
    --preview-window=right:60% >"$TMP_PKG"

pkg=$(cat "$TMP_PKG")

# Exit if no selection
[ -z "$pkg" ] && exit

# Confirm install via Rofi
confirm=$(echo -e "No\nYes" | rofi -dmenu -p "Install '$pkg'?")

if [[ "$confirm" == "Yes" ]]; then
  # Run yay with --noconfirm to avoid extra prompts
  # Keep terminal open after install to show output/errors
  alacritty -e bash -c "yay -S --noconfirm '$pkg'; echo 'Press Enter to exit...'; read"
fi
