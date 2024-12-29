#!/bin/bash
echo "Running xcolor" >> /tmp/color_picker.log
COLOR=$(/usr/bin/xcolor 2>> /tmp/color_picker.log)
echo "Picked color: $COLOR" >> /tmp/color_picker.log
if [ -n "$COLOR" ]; then
    echo "$COLOR" | xclip -selection clipboard
    notify-send "Color picked: $COLOR"
else
    notify-send "No color selected."
fi
