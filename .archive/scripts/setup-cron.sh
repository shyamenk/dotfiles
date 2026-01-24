#!/bin/bash

# Save the script to a file
cat > ~/move_unused_videos.sh << 'EOF'
#!/bin/bash

# Script to move unused video files from Downloads to Videos folder
# Usage: This script should be scheduled with cron to run every 2 hours

# Define source and destination directories
SRC_DIR="$HOME/Downloads"
DEST_DIR="$HOME/Videos"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Log file
LOG_FILE="$HOME/video_mover.log"

echo "$(date): Starting video file check..." >> "$LOG_FILE"

# Video file extensions to look for
VIDEO_EXTENSIONS=("mp4" "mkv" "avi" "mov" "wmv" "flv" "webm" "m4v" "mpg" "mpeg" "3gp" "ts")

# Function to check if a file is being accessed
is_file_in_use() {
    local file="$1"
    # Check if any process is using the file
    if lsof "$file" > /dev/null 2>&1; then
        return 0  # File is in use
    else
        return 1  # File is not in use
    fi
}

# Find and process video files
for ext in "${VIDEO_EXTENSIONS[@]}"; do
    find "$SRC_DIR" -type f -name "*.$ext" -print0 | while IFS= read -r -d '' file; do
        # Skip files smaller than 10MB (likely incomplete downloads)
        file_size=$(stat -c%s "$file")
        if [ "$file_size" -lt 10485760 ]; then
            echo "$(date): Skipping $file (too small, likely incomplete)" >> "$LOG_FILE"
            continue
        fi

        # Check if file is being used
        if ! is_file_in_use "$file"; then
            # Get filename without path
            filename=$(basename "$file")
            
            # Move the file
            echo "$(date): Moving $filename to Videos folder" >> "$LOG_FILE"
            mv "$file" "$DEST_DIR/"
            
            # Check if move was successful
            if [ $? -eq 0 ]; then
                echo "$(date): Successfully moved $filename" >> "$LOG_FILE"
            else
                echo "$(date): Failed to move $filename" >> "$LOG_FILE"
            fi
        else
            echo "$(date): File $file is currently in use, skipping" >> "$LOG_FILE"
        fi
    done
done

echo "$(date): Finished video file check" >> "$LOG_FILE"
EOF

# Make the script executable
chmod +x ~/move_unused_videos.sh

# Create a cron job to run the script every 2 hours
(crontab -l | grep -v "$HOME/move_unused_videos.sh"; echo "*/5 * * * * $HOME/move_unused_videos.sh") | crontab -

echo "Script has been installed to ~/move_unused_videos.sh"
echo "Cron job has been set up to run every 2 hours"
echo "Logs will be written to ~/video_mover.log"
