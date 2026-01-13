#!/usr/bin/env bash

# Power menu for i3 (rofi)
# Dependencies: rofi, systemd, i3-msg (optional for logout), loginctl

options=(
  "󰐥 Shutdown"
  "󰜉 Reboot"
  "󰤄 Suspend"
  "󰍃 Logout"
  "󰌾 Lock"
  "󰑓 Hibernate"
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
*Hibernate)
  systemctl hibernate
  ;;
*Logout)
  i3-msg exit
  ;;
*Lock)
  # change this to your lock command
  i3lock -c 000000
  ;;
esac
