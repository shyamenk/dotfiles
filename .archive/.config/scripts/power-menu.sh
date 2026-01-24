#!/usr/bin/env bash

# Power menu for i3 (rofi)
# Dependencies: rofi, systemd, i3-msg, xset, i3lock

options=(
  "󰐥 Shutdown"
  "󰜉 Reboot"
  "󰤄 Suspend"
  "󰌾 Screen Off"
  "󰍃 Logout"
  "󰌿 Lock"
)

choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p "Power")

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
  xset dpms force off
  ;;
*Logout)
  i3-msg exit
  ;;
*Lock)
  i3lock -c 000000
  ;;
esac

