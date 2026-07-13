#!/usr/bin/env bash
# ~/.config/hypr/scripts/shaders-switch.sh
# Dynamic Rofi-based screen shaders switcher for Icarus-OS

SHADER_DIR="${HOME}/.config/hypr/shaders"

if [[ ! -d "$SHADER_DIR" ]]; then
    notify-send -i "preferences-desktop-display" "Error" "Shaders directory not found!"
    exit 1
fi

# List shaders (excluding cache and config files)
choices=$(find -L "$SHADER_DIR" -type f -name "*.frag" | sed "s|.*/||;s|\.frag$||" | sort)

if [[ -z "$choices" ]]; then
    notify-send -i "preferences-desktop-display" "Error" "No shader files found!"
    exit 1
fi

selected=$(echo "$choices" | rofi -dmenu -i -p "Screen Shaders" -theme icarus-spotlight)

if [[ -n "$selected" ]]; then
    conf_file="${HOME}/.config/hypr/shaders.conf"
    cat << EOF > "$conf_file"
\$SCREEN_SHADER = ${selected}
\$SCREEN_SHADER_PATH = ~/.config/hypr/shaders/${selected}.frag
EOF
    notify-send -i "preferences-desktop-display" "Icarus-OS" "Screen shader updated to: ${selected}"
fi
