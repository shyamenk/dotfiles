#!/bin/bash
# Rotate to a random wallpaper
# Run on startup or manually to change wallpaper

WALLPAPER_DIR="$HOME/Pictures/wallpaper"

# Find a random wallpaper
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n 1)

if [ -n "$WALLPAPER" ]; then
    swww img "$WALLPAPER" --transition-type fade --transition-duration 2
fi
