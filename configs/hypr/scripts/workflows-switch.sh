#!/usr/bin/env bash
# ~/.config/hypr/scripts/workflows-switch.sh
# Dynamic Rofi-based system workflows switcher for Icarus-OS

WORKFLOW_DIR="${HOME}/.config/hypr/workflows"

if [[ ! -d "$WORKFLOW_DIR" ]]; then
    notify-send -i "preferences-desktop-display" "Error" "Workflows directory not found!"
    exit 1
fi

choices=$(find -L "$WORKFLOW_DIR" -type f -name "*.conf" | sed "s|.*/||;s|\.conf$||" | sort)

if [[ -z "$choices" ]]; then
    notify-send -i "preferences-desktop-display" "Error" "No workflow configurations found!"
    exit 1
fi

selected=$(echo "$choices" | rofi -dmenu -i -p "System Workflows" -theme icarus-spotlight)

if [[ -n "$selected" ]]; then
    conf_file="${HOME}/.config/hypr/workflows.conf"
    echo "source = ~/.config/hypr/workflows/${selected}.conf" > "$conf_file"
    
    # Handle Waybar transitions dynamically
    if [[ "$selected" == "mac-style" ]]; then
        killall waybar
        waybar -c ~/.config/waybar/mac-style/config.jsonc -s ~/.config/waybar/mac-style/style.css &
    else
        killall waybar
        waybar &
    fi

    notify-send -i "preferences-desktop-display" "Icarus-OS" "System workflow set to: ${selected}"
fi
