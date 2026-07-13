#!/usr/bin/env bash
# Icarus Wallpaper Daemon — handles intelligent pausing of mpvpaper
# Inspired by Caelestia-AW

SOCKET="/tmp/mpvpaper-socket"
INTERVAL=3

# Avoid duplicate instances
if pgrep -f "icarus-wallpaper-daemon" | grep -v "$$" &>/dev/null; then
    exit 0
fi

# Helper to check if battery is discharging/on battery
on_battery() {
    for bat in /sys/class/power_supply/BAT*; do
        if [[ -f "$bat/status" ]]; then
            if grep -q "Discharging" "$bat/status"; then
                return 0 # yes, on battery
            fi
        fi
    done
    return 1 # no
}

# Helper to check if there is a fullscreen window in Hyprland
has_fullscreen() {
    if command -v hyprctl &>/dev/null; then
        if hyprctl activewindow -j | jq -e '.fullscreen == true or .fullscreenClient == true' &>/dev/null; then
            return 0 # yes, fullscreen active
        fi
    fi
    return 1 # no
}

# Helper to control mpvpaper pause status
set_pause() {
    local pause_val="$1"
    if [[ -S "$SOCKET" ]] && command -v socat &>/dev/null; then
        echo "{\"command\": [\"set_property\", \"pause\", ${pause_val}]}" | socat - "$SOCKET" &>/dev/null || true
    fi
}

# Loop forever checking state
was_paused=false
while true; do
    if pgrep mpvpaper &>/dev/null; then
        should_pause=false
        if on_battery || has_fullscreen; then
            should_pause=true
        fi

        if [[ "$should_pause" == "true" ]]; then
            if [[ "$was_paused" == "false" ]]; then
                set_pause "true"
                was_paused=true
            fi
        else
            if [[ "$was_paused" == "true" ]]; then
                set_pause "false"
                was_paused=false
            fi
        fi
    fi
    sleep "$INTERVAL"
done
