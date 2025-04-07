#!/bin/bash

if [ "$(systemctl is-active bluetooth)" = "active" ]; then
    # Check if any devices are connected
    if bluetoothctl devices Connected | grep -q "Device"; then
        # Get first connected device name
        device_name=$(bluetoothctl devices Connected | head -n 1 | awk '{$1=$2=""; print $0}' | awk '{$1=$1};1')
        # Trim the name if too long
        if [ ${#device_name} -gt 15 ]; then
            device_name="${device_name:0:15}..."
        fi
        echo "󰂱 $device_name"
    else
        if bluetoothctl show | grep -q "Powered: yes"; then
            echo "󰂯 On"
        else
            echo "󰂲 Off"
        fi
    fi
else
    echo "󰂲 Off"
fi
