#!/usr/bin/env bash

# Password manager menu using pass and wofi
# Lists entries from pass store and copies selected password to clipboard

PASSWORD_STORE="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

if [ ! -d "$PASSWORD_STORE" ]; then
    notify-send "Pass" "Password store not found at $PASSWORD_STORE" -u critical
    exit 1
fi

# List all .gpg entries, strip path prefix and .gpg suffix
entries=$(find "$PASSWORD_STORE" -name '*.gpg' -type f | \
    sed "s|${PASSWORD_STORE}/||;s|\.gpg$||" | sort)

if [ -z "$entries" ]; then
    notify-send "Pass" "No entries found in password store"
    exit 1
fi

# Select entry via wofi
selected=$(printf '%s\n' "$entries" | wofi --dmenu -i -p "Pass")

if [ -n "$selected" ]; then
    # Copy password to clipboard (clears after 45s by default)
    pass show -c "$selected" 2>/dev/null
    if [ $? -eq 0 ]; then
        notify-send "Pass" "Password for '$selected' copied to clipboard (clears in 45s)"
    else
        notify-send "Pass" "Failed to retrieve password for '$selected'" -u critical
    fi
fi
