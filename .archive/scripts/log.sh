#!/bin/bash

# Define keywords to look for
KEYWORDS="Failed|Invalid|unauthorized|error|authentication failure"

# Log file for saving our monitoring results
MONITOR_LOG="$HOME/security_monitor.log"

# Function to log messages to both console and log file
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$MONITOR_LOG"
}

# Create or clear the log file
> "$MONITOR_LOG"

log_message "=== Security Monitoring Started ==="
log_message "Watching for keywords: $KEYWORDS"

# Monitor SSH service
log_message "Starting to monitor SSH authentication activities..."

# Define services to monitor
SERVICES=("sshd.service" "sudo.service" "systemd-logind.service")

for service in "${SERVICES[@]}"; do
    log_message "Checking logs for service: $service"
    
    # Get the last 10 entries to show initial state
    log_message "Recent activity in $service:"
    journalctl -u "$service" -n 10 --no-pager | while read line; do
        if echo "$line" | grep -E "$KEYWORDS" &> /dev/null; then
            log_message "[FOUND] Suspicious activity: $line"
        fi
    done
    
    log_message "Now monitoring $service in real-time..."
done

# Start real-time monitoring
log_message "Starting real-time monitoring of all authentication services..."
log_message "Press Ctrl+C to stop monitoring"

# Use a PID file to track our monitoring process
echo $$ > /tmp/security_monitor.pid

# Real-time monitoring of multiple authentication-related sources
journalctl -f _COMM=sshd _COMM=su _COMM=sudo | while read line; do
    # Log what we're processing periodically
    if (( RANDOM % 10 == 0 )); then
        log_message "Still monitoring... Last checked: $(date)"
    fi
    
    if echo "$line" | grep -E "$KEYWORDS" &> /dev/null; then
        log_message "[ALERT] Suspicious activity detected: $line"
        
        # Optional: Get context around the suspicious activity
        log_message "Collecting context for this alert..."
        ip=$(echo "$line" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)
        if [ ! -z "$ip" ]; then
            log_message "IP address involved: $ip"
            log_message "Recent activity from this IP:"
            journalctl | grep "$ip" | tail -5
        fi
    fi
done

log_message "Monitoring stopped."
