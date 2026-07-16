#!/usr/bin/env bash
# tools/random_image.sh
# Displays a random wallpaper / GIF on terminal launch using Kitty's icat protocol.

IMAGE_DIR="/usr/share/backgrounds/icarus/references"

if [[ ! -d "$IMAGE_DIR" ]]; then
    # Fallback to local repo references if not installed to system yet
    IMAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../configs/wallpaper/references" && pwd)"
fi

if [[ -d "$IMAGE_DIR" ]]; then
    # Find random image or GIF
    RANDOM_IMAGE=$(find "$IMAGE_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' \) 2>/dev/null | shuf -n 1)

    # Check if we are running in Kitty terminal to render high-res image
    if [[ -n "$RANDOM_IMAGE" ]] && [[ "${TERM:-}" == "xterm-kitty" || "${GHOSTTY_BIN:-}" == *ghostty* ]]; then
        # Draw image on left
        kitty +kitten icat --align left --place 38x18@0x0 "$RANDOM_IMAGE" 2>/dev/null || true
        # Pause slightly to allow terminal grids to align
        sleep 0.05
    fi
fi

# Run fastfetch with custom layout settings
if command -v fastfetch &>/dev/null; then
    if [[ "${TERM:-}" == "xterm-kitty" ]]; then
        fastfetch --logo-type none --logo-width 0
    else
        fastfetch
    fi
elif command -v neofetch &>/dev/null; then
    neofetch
fi
