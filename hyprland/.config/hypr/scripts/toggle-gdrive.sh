#!/bin/bash
# Toggle Google Drive rclone mount on/off

MOUNT_POINT="$HOME/GoogleDrive"

if mountpoint -q "$MOUNT_POINT"; then
    fusermount3 -u "$MOUNT_POINT"
    notify-send "Google Drive" "Unmounted" -i drive-removable-media
else
    mkdir -p "$MOUNT_POINT"
    "$HOME/.local/bin/rclone" mount gdrive: "$MOUNT_POINT" --vfs-cache-mode full &
    disown
    notify-send "Google Drive" "Mounting..." -i drive-removable-media
fi
