#!/bin/bash

CHOICE=$(echo -e "Search & Install Package" | rofi -dmenu -p "Package Tools")

case "$CHOICE" in
"Search & Install Package")
  # Open your fzf script inside a terminal
  alacritty -e /home/shyamenk/scripts/aur-pacman-fzf.sh
  ;;
*)
  exit
  ;;
esac
