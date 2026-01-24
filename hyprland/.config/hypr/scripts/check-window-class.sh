#!/bin/bash
# Helper script to identify window class names for workspace rules

echo "=== Current Windows ==="
hyprctl clients -j | jq -r '.[] | "Class: \(.class)\nTitle: \(.title)\nWorkspace: \(.workspace.id)\n---"'

echo ""
echo "=== Monitoring new windows (Ctrl+C to stop) ==="
echo "Open your apps now and watch for their class names..."
echo ""

socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
    if [[ $line == *"openwindow"* ]]; then
        # Extract address from openwindow event
        addr=$(echo "$line" | awk -F',' '{print $2}')
        # Wait a moment for window to fully initialize
        sleep 0.2
        # Get window info
        hyprctl clients -j | jq -r ".[] | select(.address == \"0x$addr\") | \"NEW WINDOW:\nClass: \(.class)\nTitle: \(.title)\nWorkspace: \(.workspace.id)\n---\""
    fi
done
