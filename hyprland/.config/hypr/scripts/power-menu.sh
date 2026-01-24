#!/usr/bin/env bash

# Power menu for Hyprland (wofi)
# Migrated from i3 - xset/i3-msg replaced with Wayland equivalents

options=(
  "󰐥 Shutdown"
  "󰜉 Reboot"
  "󰤄 Suspend"
  "󰌾 Screen Off"
  "󰍃 Logout"
  "󰌿 Lock"
)

choice=$(printf '%s\n' "${options[@]}" | wofi --dmenu -i -p "Power")

case "$choice" in
*Shutdown)
  systemctl poweroff
  ;;
*Reboot)
  systemctl reboot
  ;;
*Suspend)
  systemctl suspend
  ;;
*"Screen Off")
  hyprctl dispatch dpms off
  ;;
*Logout)
  hyprctl dispatch exit
  ;;
*Lock)
  hyprlock
  ;;
esac
