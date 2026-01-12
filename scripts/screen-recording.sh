#!/bin/bash
LOG_FILE="$HOME/screen_recording.log"
ERROR_LOG="$HOME/screen_recording_error.log"
VIDEO_SIZE=""
RECORDING_FILE="$HOME/Videos/screen_record_$(date '+%Y-%m-%d_%H-%M-%S').mp4" # Changed to mp4

# Create Videos directory if it doesn't exist
mkdir -p "$HOME/Videos"

# Function to get video size
get_video_size() {
  if command -v xrandr >/dev/null 2>&1; then
    VIDEO_SIZE=$(xrandr | grep '\*' | awk '{print $1}' | head -n1)
    if [ -n "$VIDEO_SIZE" ]; then
      echo "$VIDEO_SIZE"
      return 0
    fi
  fi

  if command -v xdpyinfo >/dev/null 2>&1; then
    VIDEO_SIZE=$(xdpyinfo | grep dimensions | awk '{print $2}')
    if [ -n "$VIDEO_SIZE" ]; then
      echo "$VIDEO_SIZE"
      return 0
    fi
  fi

  echo "1920x1080"
}

VIDEO_SIZE=$(get_video_size)

echo "$(date '+%Y-%m-%d %H:%M:%S') - Using video size: $VIDEO_SIZE" >>"$LOG_FILE"

if command -v dunstify >/dev/null 2>&1; then
  dunstify -i camera-web -t 3000 "Screen Recording" "Recording started... ($VIDEO_SIZE)"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording started" >>"$LOG_FILE"

# Improved FFmpeg command with better compatibility


  # Get the monitor source for system audio (desktop sounds)
MONITOR_SOURCE=$(pactl get-default-sink).monitor

ffmpeg -video_size "$VIDEO_SIZE" \
  -framerate 30 \
  -f x11grab \
  -i :0.0 \
  -f pulse \
  -i default \
  -f pulse \
  -i "$MONITOR_SOURCE" \
  -filter_complex "amix=inputs=2:duration=longest" \
  -c:v libx264 \
  -preset medium \
  -crf 23 \
  -pix_fmt yuv420p \
  -c:a aac \
  -b:a 192k \
  -movflags +faststart \
  "$RECORDING_FILE" 2>>"$ERROR_LOG"

if [ $? -eq 0 ]; then
  if command -v dunstify >/dev/null 2>&1; then
    dunstify -i camera-web -t 3000 "Screen Recording" "Recording saved: $(basename "$RECORDING_FILE")"
  fi
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording saved successfully" >>"$LOG_FILE"
else
  if command -v dunstify >/dev/null 2>&1; then
    dunstify -i error -t 5000 "Screen Recording" "Recording failed!"
  fi
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording failed" >>"$LOG_FILE"
fi
