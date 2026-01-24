#!/bin/bash

# Check if bluetooth service is active
if [ "$(systemctl is-active bluetooth)" = "active" ]; then
    # Check if Bluetooth is powered on
    if bluetoothctl show | grep -q "Powered: yes"; then
        # Turn Bluetooth off
        bluetoothctl power off
        notify-send "Bluetooth" "Bluetooth powered off" -i bluetooth-disabled
    else
        # Turn Bluetooth on
        bluetoothctl power on
        notify-send "Bluetooth" "Bluetooth powered on" -i bluetooth
    fi
else
    # Start Bluetooth service if it's not running
    systemctl start bluetooth
    sleep 1
    bluetoothctl power on
    notify-send "Bluetooth" "Bluetooth service started" -i bluetooth
fi
