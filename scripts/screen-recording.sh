#!/bin/bash

LOG_FILE="$HOME/screen_recording.log"
ERROR_LOG="$HOME/screen_recording_error.log"
VIDEO_SIZE=""
RECORDING_FILE="$HOME/Videos/screen_record_$(date '+%Y-%m-%d_%H-%M-%S').mkv"

# Retrieve video size for screen capture
VIDEO_SIZE=$(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d 'x' -f1,2)

# Check if the video size is empty (failed to retrieve)
if [ -z "$VIDEO_SIZE" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Unable to get video size." >> "$LOG_FILE"
  dunstify -i camera-web -t 3000 "Screen Recording" "Error: Unable to get video size."
  exit 1
fi

# Notify user that recording is starting
dunstify -i camera-web -t 3000 "Screen Recording" "Recording started..."
echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording started" >> "$LOG_FILE"

# Start the recording using FFmpeg (without audio capture)
ffmpeg -video_size "$VIDEO_SIZE" -framerate 30 -f x11grab -i :0.0 "$RECORDING_FILE" 2>> "$ERROR_LOG"

# Notify user that recording has stopped
dunstify -i camera-web -t 3000 "Screen Recording" "Recording stopped."
echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording stopped" >> "$LOG_FILE"
