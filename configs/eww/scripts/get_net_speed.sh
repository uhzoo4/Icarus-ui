#!/usr/bin/env bash
# Icarus network speed indicator for Eww dashboard.
# Reports combined RX rate across active interfaces.
set -uo pipefail

IFACE=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')
[[ -n "$IFACE" ]] || { echo "offline"; exit 0; }

RX1=$(cat "/sys/class/net/${IFACE}/statistics/rx_bytes" 2>/dev/null || echo 0)
sleep 1
RX2=$(cat "/sys/class/net/${IFACE}/statistics/rx_bytes" 2>/dev/null || echo 0)

RATE=$(( (RX2 - RX1) ))
(( RATE < 0 )) && RATE=0

if (( RATE > 1048576 )); then
    awk -v rate="$RATE" 'BEGIN { printf "%.1f MB/s\n", rate / 1048576 }'
elif (( RATE > 1024 )); then
    awk -v rate="$RATE" 'BEGIN { printf "%.0f KB/s\n", rate / 1024 }'
else
    printf '%d B/s\n' "$RATE"
fi
