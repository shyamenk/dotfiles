#!/bin/bash

while true; do
    # Get the battery percentage from /sys/class/power_supply
    BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT0/capacity)

    # Check if the battery level is below the threshold (10%)
    if [ "$BATTERY_LEVEL" -le 10 ]; then
        # Play a sound
        paplay ~/scripts/audio/battery_low.wav
        notify-send "Battery Low" "Your battery level is low ($BATTERY_LEVEL%). Please plug in your charger." -u critical -i battery-caution
    fi

    # Wait for 5 minutes before checking again
    sleep 300
done
