#!/bin/bash

# Color picker for Wayland using hyprpicker
# Migrated from xcolor

echo "Running hyprpicker" >> /tmp/color_picker.log

COLOR=$(hyprpicker -a 2>> /tmp/color_picker.log)

echo "Picked color: $COLOR" >> /tmp/color_picker.log

if [ -n "$COLOR" ]; then
    echo "$COLOR" | wl-copy
    notify-send "Color Picker" "Color picked: $COLOR"
else
    notify-send "Color Picker" "No color selected."
fi
