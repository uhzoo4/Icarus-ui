#!/usr/bin/env bash
# Icarus-ArchOS Temperature Monitoring Script
# Monitors CPU and GPU temperatures and sends alerts
# Stolen and enhanced from JaKooLit configs

# Configuration
CPU_TEMP_WARNING=75
CPU_TEMP_CRITICAL=85
GPU_TEMP_WARNING=75
GPU_TEMP_CRITICAL=85
CHECK_INTERVAL=30  # Check every 30 seconds

# Track notification state
NOTIFIED_CPU_WARN=false
NOTIFIED_CPU_CRIT=false
NOTIFIED_GPU_WARN=false
NOTIFIED_GPU_CRIT=false

while true; do
    # Check if sensors command exists
    if ! command -v sensors &>/dev/null; then
        sleep 300
        continue
    fi

    # Get CPU temperature (average of all cores or Package id)
    CPU_TEMP=$(sensors 2>/dev/null | grep -i 'Package id 0:\|Tdie:' | awk '{print $4}' | sed 's/+//;s/°C//' | head -1)
    
    if [ -z "$CPU_TEMP" ]; then
        CPU_TEMP=$(sensors 2>/dev/null | grep -i 'Core 0:' | awk '{print $3}' | sed 's/+//;s/°C//' | head -1)
    fi
    
    # Get GPU temperature
    GPU_TEMP=$(sensors 2>/dev/null | grep -i 'edge:\|temp1:' | awk '{print $2}' | sed 's/+//;s/°C//' | head -1)
    
    # Check CPU temp
    if [ -n "$CPU_TEMP" ]; then
        CPU_TEMP_INT=${CPU_TEMP%.*}
        if [ "$CPU_TEMP_INT" -ge "$CPU_TEMP_CRITICAL" ]; then
            if [ "$NOTIFIED_CPU_CRIT" = false ]; then
                notify-send -u critical -i temperature-high "Critical CPU Temperature" "CPU temperature is ${CPU_TEMP}°C! System may throttle."
                NOTIFIED_CPU_CRIT=true
                NOTIFIED_CPU_WARN=true
            fi
        elif [ "$CPU_TEMP_INT" -ge "$CPU_TEMP_WARNING" ]; then
            if [ "$NOTIFIED_CPU_WARN" = false ]; then
                notify-send -u normal -i temperature-normal "High CPU Temperature" "CPU temperature is ${CPU_TEMP}°C"
                NOTIFIED_CPU_WARN=true
            fi
        else
            NOTIFIED_CPU_WARN=false
            NOTIFIED_CPU_CRIT=false
        fi
    fi
    
    # Check GPU temp
    if [ -n "$GPU_TEMP" ]; then
        GPU_TEMP_INT=${GPU_TEMP%.*}
        if [ "$GPU_TEMP_INT" -ge "$GPU_TEMP_CRITICAL" ]; then
            if [ "$NOTIFIED_GPU_CRIT" = false ]; then
                notify-send -u critical -i temperature-high "Critical GPU Temperature" "GPU temperature is ${GPU_TEMP}°C!"
                NOTIFIED_GPU_CRIT=true
                NOTIFIED_GPU_WARN=true
            fi
        elif [ "$GPU_TEMP_INT" -ge "$GPU_TEMP_WARNING" ]; then
            if [ "$NOTIFIED_GPU_WARN" = false ]; then
                notify-send -u normal -i temperature-normal "High GPU Temperature" "GPU temperature is ${GPU_TEMP}°C"
                NOTIFIED_GPU_WARN=true
            fi
        else
            NOTIFIED_GPU_WARN=false
            NOTIFIED_GPU_CRIT=false
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done
