#!/bin/bash
# Auto-rotate wallpapers every 5 minutes

WALLPAPER_DIR="/home/shyamenk/Pictures/wallpaper"
INTERVAL=300  # 5 minutes

while true; do
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1)
    swww img "$WALLPAPER" --transition-type fade --transition-duration 2
    sleep $INTERVAL
done
