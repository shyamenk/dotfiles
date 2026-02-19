#!/bin/bash

# Project launcher for Hyprland with wofi

PROJECT_DIRS=(
  "$HOME/Desktop/sales-force-dev/"   # Private/personal projects
  "$HOME/Desktop/Development/Projects-Public"    # Open source/public projects
  "$HOME/Desktop/Development/Projects-Lab"       # Learning/practicing/experiments
)

# Temp file to store mappings
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

# Find all directories (depth 1) in project locations
for dir in "${PROJECT_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    find "$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while read -r path; do
      parent=$(basename "$(dirname "$path")" | sed 's/Projects-//')
      name=$(basename "$path")
      echo "$name [$parent]	$path" >> "$TMPFILE"
    done
  fi
done

# Check if any projects found
if [[ ! -s "$TMPFILE" ]]; then
  notify-send "Project Launcher" "No projects found. Add projects to:\n• Projects-Private\n• Projects-Public\n• Projects-Lab"
  exit 0
fi

# Sort and show wofi menu
SELECTED=$(cut -f1 "$TMPFILE" | sort -u | wofi --dmenu -i -p " Projects" --width 500 --height 400)

[[ -z "$SELECTED" ]] && exit 0

# Get full path from selection
PROJECT_PATH=$(grep -F "$SELECTED	" "$TMPFILE" | head -1 | cut -f2)

if [[ -z "$PROJECT_PATH" || ! -d "$PROJECT_PATH" ]]; then
  notify-send "Project Launcher" "Could not find: $SELECTED"
  exit 1
fi

# Open terminal in project folder
alacritty --working-directory "$PROJECT_PATH"
