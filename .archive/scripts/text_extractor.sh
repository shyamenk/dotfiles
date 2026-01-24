#!/bin/bash

# Set the TESSDATA_PREFIX environment variable
export TESSDATA_PREFIX=/usr/share/

# File path to save the screenshot
TEMP_FILE="/tmp/screenshot.png"

# Prompt user to select an area and capture the screenshot
maim --select "$TEMP_FILE"

# Check if screenshot file is created and not empty
if [ ! -s "$TEMP_FILE" ]; then
    dunstify -u low "OCR Error" "Screenshot capture failed or file is empty."
    exit 1
fi

# Perform OCR on the screenshot with explicit tessdata-dir
result=$(tesseract "$TEMP_FILE" stdout --tessdata-dir /usr/share/tessdata/)

# Check if result is empty
if [ -z "$result" ]; then
    dunstify -u low "OCR Error" "No text detected."
else
    # Copy the OCR result to clipboard
    echo "$result" | xclip -selection clipboard

    # Display the OCR result in a notification
    dunstify -u low "OCR Result" "Text copied to clipboard."
fi

# Optionally remove the temporary file
rm "$TEMP_FILE"
