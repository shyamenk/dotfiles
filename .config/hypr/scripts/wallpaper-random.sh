#!/bin/bash

# Random wallpaper setter for Hyprland using hyprpaper
# Replaces feh --randomize

WALLPAPER_DIR="$HOME/Pictures/wallpaper"

# Get a random wallpaper
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

if [ -n "$WALLPAPER" ]; then
  # Update hyprpaper config
  cat >"$HOME/.config/hypr/hyprpaper.conf" <<EOF
preload = $WALLPAPER
wallpaper = ,$WALLPAPER
splash = false
ipc = on
EOF

  # Reload hyprpaper if running
  if pgrep -x hyprpaper >/dev/null; then
    killall hyprpaper
    hyprpaper &
  fi
fi
