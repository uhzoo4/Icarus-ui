#!/usr/bin/env bash
# Icarus Dynamic Wallpaper Switcher
#
# Installed as /usr/local/bin/icarus-wallpaper-switch. It supports static
# images and live media; live selections fall back to their paired still when
# mpvpaper is unavailable. A selected scene is saved and restored next login.

set -euo pipefail

WALLPAPER_DIR="/usr/share/backgrounds/icarus/references"
DEFAULT_STATIC="/usr/share/backgrounds/icarus/icarus-midnight.png"
STATE_FILE="${HOME}/.config/icarus/wallpaper.sh"
MPVPAPER_OPTIONS="no-audio --loop-file=inf --hwdec=auto-copy --panscan=1.0 --input-ipc-server=/tmp/mpvpaper-socket"

usage() {
    cat <<'EOF'
Usage: icarus-wallpaper-switch [--set FILENAME | --random]

Without an argument, opens the wallpaper picker. --random chooses from the
original Icarus scenes. Files ending in .gif, .mp4, .webm, or .mkv are played
as live wallpapers when mpvpaper is available; otherwise their paired static
image is used.
EOF
}

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    notify-send "Wallpaper switcher" "No reference wallpapers found at $WALLPAPER_DIR" 2>/dev/null || true
    echo "Error: Wallpaper directory not found at $WALLPAPER_DIR" >&2
    exit 1
fi

is_live_media() {
    case "${1,,}" in
        *.gif|*.mp4|*.webm|*.mkv) return 0 ;;
        *) return 1 ;;
    esac
}

palette_source_for() {
    local file="$1" stem candidate extension
    stem="${file%.*}"
    stem="${stem%-live}"

    for extension in png jpg jpeg; do
        candidate="${stem}.${extension}"
        if [[ -f "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    if is_live_media "$file"; then
        printf '%s\n' "$file"
        return 0
    fi

    printf '%s\n' "$DEFAULT_STATIC"
}

write_state() {
    local renderer="$1" file="$2"
    mkdir -p "$(dirname "$STATE_FILE")"
    printf 'exec ' > "$STATE_FILE"

    if [[ "$renderer" == "mpvpaper" ]]; then
        printf '%q ' mpvpaper -o "$MPVPAPER_OPTIONS" '*' "$file" >> "$STATE_FILE"
    else
        printf '%q ' swaybg -i "$file" -m fill >> "$STATE_FILE"
    fi
    printf '\n' >> "$STATE_FILE"
    chmod 0755 "$STATE_FILE"
}

apply_wallpaper() {
    local file="$1" palette_source renderer="swaybg" rendered_file
    palette_source="$(palette_source_for "$file")"
    rendered_file="$palette_source"

    # A manual selection replaces either existing renderer. Killing a missing
    # process is harmless and avoids two renderers competing for the output.
    killall swaybg 2>/dev/null || true
    killall mpvpaper 2>/dev/null || true

    if is_live_media "$file" && command -v mpvpaper &>/dev/null; then
        mpvpaper -o "$MPVPAPER_OPTIONS" '*' "$file" &
        renderer="mpvpaper"
        rendered_file="$file"
        notify-send "Icarus live wallpaper" "$(basename "$file")" 2>/dev/null || true
    else
        local actual_bg="$palette_source"
        if is_live_media "$palette_source"; then
            icarus-palette "$palette_source"
            actual_bg="/tmp/icarus-video-frame.png"
        fi
        swaybg -i "$actual_bg" -m fill &
        if is_live_media "$file"; then
            notify-send "Icarus wallpaper" "mpvpaper is unavailable; using the static companion image." 2>/dev/null || true
        fi
    fi

    write_state "$renderer" "$rendered_file"
    if ! is_live_media "$palette_source"; then
        icarus-palette "$palette_source"
    fi
    killall -SIGUSR2 waybar 2>/dev/null || true
    eww reload 2>/dev/null || true
}

choose_random_icarus_scene() {
    local -a scenes=()
    local file
    shopt -s nullglob
    for file in "$WALLPAPER_DIR"/*; do
        if [[ -f "$file" ]]; then
            case "${file,,}" in
                *.png|*.jpg|*.jpeg|*.gif|*.mp4|*.webm|*.mkv)
                    scenes+=("$file")
                    ;;
            esac
        fi
    done
    shopt -u nullglob

    (( ${#scenes[@]} > 0 )) || { echo "No wallpapers found in $WALLPAPER_DIR." >&2; exit 1; }
    printf '%s\n' "${scenes[@]}" | shuf -n 1
}

if [[ "${1:-}" == "--set" ]]; then
    [[ $# -eq 2 && "$2" != */* ]] || { usage >&2; exit 2; }
    selected="$2"
elif [[ "${1:-}" == "--random" ]]; then
    selected="$(basename "$(choose_random_icarus_scene)")"
elif [[ -n "${1:-}" ]]; then
    usage >&2
    exit 2
else
    menu_items=""
    for file in "$WALLPAPER_DIR"/*; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file")
            menu_items+="${filename}\0icon\x1f${file}\n"
        fi
    done

    selected=$(echo -en "$menu_items" | rofi -dmenu -i -replace -config ~/.config/rofi/wallpaper.rasi -p "Select Wallpaper" || true)
fi

if [[ -n "$selected" ]]; then
    full_path="$WALLPAPER_DIR/$selected"
    if [[ -f "$full_path" ]]; then
        apply_wallpaper "$full_path"
    else
        notify-send "Wallpaper switcher" "Wallpaper not found: $selected" 2>/dev/null || true
        exit 1
    fi
fi
