#!/usr/bin/env bash

# Script to convert all files and directories recursively to Title Case

ROOT_DIR="${1:-.}" # Default to current dir if none provided

find "$ROOT_DIR" -depth | while IFS= read -r path; do
  dir=$(dirname "$path")
  base=$(basename "$path")

  # Convert to title case (remove separators, capitalize words, restore space)
  newbase=$(
    echo "$base" | awk '
        {
            for (i = 1; i <= NF; i++) {
                $i = toupper(substr($i,1,1)) tolower(substr($i,2))
            }
            print
        }' FS='[^[:alnum:]]+' OFS=' '
  )

  newbase=$(echo "$newbase" | sed 's/ *$//' | tr -s ' ')
  newpath="$dir/$newbase"

  # Rename only if different
  if [[ "$path" != "$newpath" ]]; then
    mv "$path" "$newpath"
  fi
done
