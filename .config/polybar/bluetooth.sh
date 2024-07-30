#!/bin/sh

# Check if Bluetooth is powered on
if bluetoothctl show | grep -q "Powered: yes"; then
    # Check if any devices are connected
    if bluetoothctl info | grep -q 'Device'; then
        # Device is connected
        echo "%{F#2193ff}"  # Blue icon
    else
        # Device is not connected
        echo "%{F#ffae00}"  # Orange icon
    fi
else
    # Bluetooth is off
    echo "%{F#ff0000}"  # Red icon
fi

