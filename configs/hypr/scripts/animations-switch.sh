#!/usr/bin/env bash
# ~/.config/hypr/scripts/animations-switch.sh
# Dynamic Rofi-based animations switcher for Icarus-OS

ANIM_DIR="${HOME}/.config/hypr/animations"

if [[ ! -d "$ANIM_DIR" ]]; then
    notify-send -i "preferences-desktop-display" "Error" "Animations directory not found!"
    exit 1
fi

# List animations
choices=$(find -L "$ANIM_DIR" -type f -name "*.conf" | sed "s|.*/||;s|\.conf$||" | sort)

if [[ -z "$choices" ]]; then
    notify-send -i "preferences-desktop-display" "Error" "No animation configurations found!"
    exit 1
fi

selected=$(echo "$choices" | rofi -dmenu -i -p "Animations" -theme icarus-spotlight)

if [[ -n "$selected" ]]; then
    conf_file="${HOME}/.config/hypr/animations.conf"
    echo "source = ~/.config/hypr/animations/${selected}.conf" > "$conf_file"
    notify-send -i "preferences-desktop-display" "Icarus-OS" "Animations updated to: ${selected}"
fi
