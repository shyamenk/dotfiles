#pacman -Qs docker
!/bin/bash

PROJECTS="/home/shyamenk/Desktop/Development/Private Repo"

cd "$PROJECTS" || exit 1

SELECTED=$(ls | rofi -dmenu -p "Projects")

[ -n "$SELECTED" ] && alacritty --working-directory "$PROJECTS/$SELECTED"
