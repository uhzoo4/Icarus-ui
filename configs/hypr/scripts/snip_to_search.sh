#!/usr/bin/env bash
# Icarus-ArchOS Visual Crop Search (Google Lens)
# Stolen and enhanced from end-4 configs

TEMP_IMG="/tmp/icarus_snip_$(date +%s).png"

# Take screenshot of selected region
if ! grim -g "$(slurp)" "$TEMP_IMG"; then
    exit 1
fi

# Ensure the file exists (user didn't cancel)
if [[ ! -f "$TEMP_IMG" ]]; then
    exit 1
fi

notify-send "Visual Search" "Uploading crop to temporary hosting..." -i edit-find

# Upload and get URL
IMAGE_URL=$(curl -s -F "files[]=@${TEMP_IMG}" https://uguu.se/upload | jq -r '.files[0].url' 2>/dev/null)

if [[ -n "$IMAGE_URL" && "$IMAGE_URL" != "null" ]]; then
    notify-send "Visual Search" "Image uploaded. Opening Google Lens..." -i browser
    xdg-open "https://lens.google.com/uploadbyurl?url=${IMAGE_URL}"
else
    notify-send -u critical "Visual Search" "Failed to upload image. Check your internet connection." -i dialog-error
fi

rm -f "$TEMP_IMG"
