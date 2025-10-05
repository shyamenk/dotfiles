#!/bin/bash

# Base directory where your course is stored
BASE_DIR="/home/shyamenk/Desktop/Courses/Ryder Carroll - Bullet Journal Basics & Beyond Course"

# Find all .mp4 files recursively
find "$BASE_DIR" -type f -name "*.mp4" | while read -r file; do
  # Create corresponding output path with .mp3 extension
  output="${file%.mp4}.mp3"

  # Skip if already converted
  if [ -f "$output" ]; then
    echo "✅ Already converted: $output"
    continue
  fi

  echo "🎧 Converting: $file"

  # Convert to small, compressed MP3 (low bitrate, mono)
  ffmpeg -i "$file" -vn -ac 1 -b:a 48k -ar 22050 "$output" -y </dev/null

  echo "✅ Done: $output"
done

echo "🎉 All conversions completed!"
