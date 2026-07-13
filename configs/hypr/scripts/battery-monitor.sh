#!/usr/bin/env bash
# Icarus-ArchOS Low Battery Notification Script
# Monitors battery level and sends desktop notifications
# Stolen and enhanced from JaKooLit configs

# Configuration
LOW_BATTERY_THRESHOLD=20
CRITICAL_BATTERY_THRESHOLD=10
CHECK_INTERVAL=60  # Check every 60 seconds

# Track notification state to avoid spam
NOTIFIED_LOW=false
NOTIFIED_CRITICAL=false

while true; do
    # Check if acpi exists
    if ! command -v acpi &>/dev/null; then
        sleep 300
        continue
    fi

    # Get battery percentage and status
    BATTERY_LEVEL=$(acpi -b 2>/dev/null | grep -P -o '[0-9]+(?=%)' | head -1)
    BATTERY_STATUS=$(acpi -b 2>/dev/null | grep -o 'Discharging\|Charging\|Full' | head -1)
    
    # Only send notifications when discharging
    if [[ "$BATTERY_STATUS" == "Discharging" && -n "$BATTERY_LEVEL" ]]; then
        if [ "$BATTERY_LEVEL" -le "$CRITICAL_BATTERY_THRESHOLD" ]; then
            if [ "$NOTIFIED_CRITICAL" = false ]; then
                notify-send -u critical -i battery-caution "Critical Battery" "Battery level is at ${BATTERY_LEVEL}%! Please plug in your charger immediately."
                NOTIFIED_CRITICAL=true
                NOTIFIED_LOW=true
            fi
        elif [ "$BATTERY_LEVEL" -le "$LOW_BATTERY_THRESHOLD" ]; then
            if [ "$NOTIFIED_LOW" = false ]; then
                notify-send -u normal -i battery-low "Low Battery" "Battery level is at ${BATTERY_LEVEL}%. Consider plugging in your charger."
                NOTIFIED_LOW=true
            fi
        fi
    else
        # Reset notification flags when charging or full
        NOTIFIED_LOW=false
        NOTIFIED_CRITICAL=false
    fi
    
    sleep "$CHECK_INTERVAL"
done
