#!/bin/bash

# OCR Text extractor for Wayland
# Migrated from maim + xclip to grim + slurp + wl-copy

export TESSDATA_PREFIX=/usr/share/

TEMP_FILE="/tmp/screenshot.png"

# Select area and capture screenshot using grim + slurp
grim -g "$(slurp)" "$TEMP_FILE"

# Check if screenshot file is created and not empty
if [ ! -s "$TEMP_FILE" ]; then
    notify-send -u low "OCR Error" "Screenshot capture failed or file is empty."
    exit 1
fi

# Perform OCR on the screenshot
result=$(tesseract "$TEMP_FILE" stdout --tessdata-dir /usr/share/tessdata/)

# Check if result is empty
if [ -z "$result" ]; then
    notify-send -u low "OCR Error" "No text detected."
else
    # Copy the OCR result to clipboard (Wayland)
    echo "$result" | wl-copy

    notify-send -u low "OCR Result" "Text copied to clipboard."
fi

rm -f "$TEMP_FILE"
