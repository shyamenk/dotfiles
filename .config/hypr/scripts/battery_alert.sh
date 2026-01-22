#!/bin/bash

# Battery alert for Hyprland
# Same logic as X11 version, works on Wayland

while true; do
    BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT1/capacity)
    CHARGING_STATUS=$(cat /sys/class/power_supply/BAT1/status)

    if [ "$BATTERY_LEVEL" -le 10 ] && [ "$CHARGING_STATUS" != "Charging" ]; then
        paplay ~/scripts/audio/battery_low.wav 2>/dev/null
        notify-send -u critical -i battery-caution "Battery Low" "Your battery level is low ($BATTERY_LEVEL%). Please plug in your charger."
    fi

    sleep 300
done
