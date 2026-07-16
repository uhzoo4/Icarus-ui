#!/usr/bin/env bash
# configs/cava/cava-theme-loader.sh
# Merges the base configs with the selected color theme to run CAVA.

BASE_CONFIG="${HOME}/.config/cava/base_config"
THEME_DIR="${HOME}/.config/cava/themes"

# Deploy base config to user home if missing
if [[ ! -f "$BASE_CONFIG" ]]; then
    mkdir -p "${HOME}/.config/cava"
    cat > "$BASE_CONFIG" << 'EOF'
[general]
framerate = 60
autosens = 1
overshoot = 0
sensitivity = 100
bars = 0
lower_cutoff_freq = 50
higher_cutoff_freq = 10000
sleep_timer = 0

[input]
method = pulse
source = auto

[output]
method = noncurses
channels = stereo
mono_option = average
reverse = 0
raw_target = /dev/stdout
data_format = binary
bit_format = 16bit
ascii_max_range = 1000

[smoothing]
integral = 77
monstercat = 1
waves = 0
gravity = 100
ignore = 0
noise_reduction = 77

[eq]
1 = 1
2 = 1
3 = 1
4 = 1
5 = 1
EOF
fi

# Deploy theme definitions if missing
mkdir -p "$THEME_DIR"
for t in cava-sweet.conf cava-catppuccin.conf cava-katerial.conf cava-iceblue.conf; do
    if [[ ! -f "${THEME_DIR}/$t" ]]; then
        # If user has the templates in /usr/share/icarus/cava/themes, we can copy them
        # fallback copy from repo config
        cp -f "/usr/share/backgrounds/icarus/cava/themes/$t" "${THEME_DIR}/$t" 2>/dev/null \
            || cp -f "${HOME}/.config/icarus/cava/themes/$t" "${THEME_DIR}/$t" 2>/dev/null \
            || true
    fi
done

clear
echo -e "\033[1;35m==================================================\033[0m"
echo -e "\033[1;37m          ICARUS-UI CAVA THEME SELECTOR           \033[0m"
echo -e "\033[1;35m==================================================\033[0m"
echo -e "  \033[1;32m1)\033[0m \033[1;34m🍬 Sweet Gradient\033[0m"
echo -e "  \033[1;32m2)\033[0m \033[1;34m🐱 Catppuccin Mocha\033[0m"
echo -e "  \033[1;32m3)\033[0m \033[1;34m🎨 Katerial Material Design\033[0m"
echo -e "  \033[1;32m4)\033[0m \033[1;34m❄️ Ice Blue Gradient (Default)\033[0m"
echo -e "\033[1;35m==================================================\033[0m"
read -rp "Select visualizer theme [1-4, default=4]: " Choice
Choice="${Choice:-4}"

THEME_FILE="cava-iceblue.conf"
case $Choice in
    1) THEME_FILE="cava-sweet.conf" ;;
    2) THEME_FILE="cava-catppuccin.conf" ;;
    3) THEME_FILE="cava-katerial.conf" ;;
    4) THEME_FILE="cava-iceblue.conf" ;;
    *) THEME_FILE="cava-iceblue.conf" ;;
esac

cat "$BASE_CONFIG" "${THEME_DIR}/${THEME_FILE}" > "${HOME}/.config/cava/config" 2>/dev/null \
    || cat "$BASE_CONFIG" <(echo -e "\n[color]\ngradient = 1\ngradient_count = 4\ngradient_color_1 = #4A6D8C\ngradient_color_2 = #5B8BA8\ngradient_color_3 = #7AAEC0\ngradient_color_4 = #AEE3F0") > "${HOME}/.config/cava/config"

echo "Theme applied! Running CAVA..."
cava
