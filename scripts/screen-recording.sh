#!/bin/bash

LOG_FILE="$HOME/screen_recording.log"
ERROR_LOG="$HOME/screen_recording_error.log"
VIDEO_SIZE=$(xdpyinfo | grep dimensions | awk '{print $2}')
RECORDING_FILE="$HOME/Videos/screen_record_$(date '+%Y-%m-%d_%H-%M-%S').mkv"

if [ -z "$VIDEO_SIZE" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Unable to get video size." >> "$LOG_FILE"
  dunstify -i camera-web -t 3000 "Screen Recording" "Error: Unable to get video size." 
  exit 1
fi

dunstify -i camera-web -t 3000 "Screen Recording" "Recording started..."
echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording started" >> "$LOG_FILE"

# Start recording and capture errors
ffmpeg -video_size "$VIDEO_SIZE" -framerate 30 -f x11grab -i "$DISPLAY" -f pulse -ac 2 -i default "$RECORDING_FILE" 2>> "$ERROR_LOG"

dunstify -i camera-web -t 3000 "Screen Recording" "Recording stopped."
echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording stopped" >> "$LOG_FILE"
