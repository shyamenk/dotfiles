#!/bin/bash

NOTES_FILE="$HOME/Documents/scratchpad.md"
mkdir -p "$(dirname "$NOTES_FILE")"
touch "$NOTES_FILE"

alacritty --class scratchpad -e nvim "+normal Go" "+startinsert" "$NOTES_FILE"
