#!/bin/bash

# Project launcher for Hyprland
# Migrated from rofi to wofi

PROJECTS="/home/shyamenk/Desktop/Development/Private Repo"

cd "$PROJECTS" || exit 1

SELECTED=$(ls | wofi --dmenu -p "Projects")

[ -n "$SELECTED" ] && alacritty --working-directory "$PROJECTS/$SELECTED"
