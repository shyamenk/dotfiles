#!/usr/bin/env bash

# Usage: ./restore_extensions.sh /your/target/folder
# Defaults to current dir if not provided

TARGET_DIR="${1:-.}"

# Loop through all files without extensions
find "$TARGET_DIR" -type f ! -name "*.*" | while read -r file; do
  # Detect MIME type
  mimetype=$(file --mime-type -b "$file")

  # Decide extension based on MIME type
  case "$mimetype" in
  video/mp4) ext="mp4" ;;
  video/x-matroska) ext="mkv" ;;
  image/png) ext="png" ;;
  image/jpeg) ext="jpg" ;;
  image/webp) ext="webp" ;;
  application/pdf) ext="pdf" ;;
  text/plain) ext="txt" ;;
  audio/mpeg) ext="mp3" ;;
  audio/x-wav) ext="wav" ;;
  *)
    echo "❓ Unknown MIME type for '$file' ($mimetype) – skipping"
    continue
    ;;
  esac

  # Rename file with new extension
  newname="${file}.${ext}"
  echo "🔄 Renaming '$file' → '${newname}'"
  mv "$file" "$newname"
done
