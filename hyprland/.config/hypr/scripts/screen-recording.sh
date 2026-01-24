#!/bin/bash

# Screen recording for Wayland using wf-recorder
# Migrated from ffmpeg x11grab

LOG_FILE="$HOME/screen_recording.log"
ERROR_LOG="$HOME/screen_recording_error.log"
RECORDING_FILE="$HOME/Videos/screen_record_$(date '+%Y-%m-%d_%H-%M-%S').mp4"

mkdir -p "$HOME/Videos"

# Check if already recording
if pgrep -x wf-recorder > /dev/null; then
    pkill -INT wf-recorder
    notify-send -i camera-web "Screen Recording" "Recording stopped"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording stopped" >> "$LOG_FILE"
    exit 0
fi

# Get audio sources
MONITOR_SOURCE=$(pactl get-default-sink).monitor

echo "$(date '+%Y-%m-%d %H:%M:%S') - Recording started" >> "$LOG_FILE"

notify-send -i camera-web -t 3000 "Screen Recording" "Recording started..."

# Record with wf-recorder (Wayland native)
# -a for audio, -f for output file
wf-recorder \
    --audio="$MONITOR_SOURCE" \
    -c libx264 \
    -p preset=medium \
    -p crf=23 \
    -f "$RECORDING_FILE" 2>> "$ERROR_LOG" &

echo "$(date '+%Y-%m-%d %H:%M:%S') - wf-recorder started with PID $!" >> "$LOG_FILE"
