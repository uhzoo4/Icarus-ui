#!/usr/bin/env bash
# Icarus-ArchOS Disk Space Monitoring Script
# Monitors disk usage and sends desktop notifications
# Stolen and enhanced from JaKooLit configs

# Configuration
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
CHECK_INTERVAL=300  # Check every 5 minutes

# Track notification state
declare -A NOTIFIED_WARNING
declare -A NOTIFIED_CRITICAL

while true; do
    # Get disk usage for all mounted filesystems starting with /dev/
    df -h | grep '^/dev/' | while read -r line; do
        DEVICE=$(echo "$line" | awk '{print $1}')
        MOUNT=$(echo "$line" | awk '{print $6}')
        USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        
        # Skip if usage is not a number
        if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        # Check disk usage thresholds
        if [ "$USAGE" -ge "$DISK_CRITICAL_THRESHOLD" ]; then
            if [ "${NOTIFIED_CRITICAL[$MOUNT]}" != "true" ]; then
                notify-send -u critical -i drive-harddisk "Critical Disk Space" "Mount point $MOUNT is ${USAGE}% full!\nDevice: $DEVICE"
                NOTIFIED_CRITICAL[$MOUNT]="true"
                NOTIFIED_WARNING[$MOUNT]="true"
            fi
        elif [ "$USAGE" -ge "$DISK_WARNING_THRESHOLD" ]; then
            if [ "${NOTIFIED_WARNING[$MOUNT]}" != "true" ]; then
                notify-send -u normal -i drive-harddisk "Low Disk Space" "Mount point $MOUNT is ${USAGE}% full\nDevice: $DEVICE"
                NOTIFIED_WARNING[$MOUNT]="true"
            fi
        else
            # Reset notifications when usage drops
            if [ "$USAGE" -lt $((DISK_WARNING_THRESHOLD - 5)) ]; then
                NOTIFIED_WARNING[$MOUNT]="false"
                NOTIFIED_CRITICAL[$MOUNT]="false"
            fi
        fi
    done
    
    sleep "$CHECK_INTERVAL"
done
