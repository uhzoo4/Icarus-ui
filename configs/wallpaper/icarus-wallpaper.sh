#!/usr/bin/env bash
#
# configs/wallpaper/icarus-wallpaper.sh
#
# Uses the live (video) wallpaper via mpvpaper if it's actually installed
# and present, falls back to the static PNG via swaybg otherwise — e.g. if
# Layer 7's AUR bootstrap (paru, which mpvpaper depends on) didn't succeed
# on this run. swaybg is installed in Layer 5 unconditionally, so the
# fallback path never depends on anything that can fail.
#
LIVE_VIDEO="/usr/share/backgrounds/icarus/references/84-live.gif"
STATIC_IMG="/usr/share/backgrounds/icarus/references/84.png"
STATE_FILE="${HOME}/.config/icarus/wallpaper.sh"

# A manual selection made with icarus-wallpaper-switch survives logout and
# reboot. The state script holds either a swaybg or mpvpaper command with the
# chosen path shell-escaped; execute it before falling back to the default.
if command -v mpvpaper &>/dev/null && command -v icarus-wallpaper-daemon &>/dev/null; then
    (icarus-wallpaper-daemon &)
fi

if [[ -x "$STATE_FILE" ]]; then
    exec "$STATE_FILE"
fi

if command -v mpvpaper &>/dev/null && [[ -f "$LIVE_VIDEO" ]]; then
    # Run palette generation in the background so it doesn't block startup
    (icarus-palette "$STATIC_IMG" &)
    exec mpvpaper -o "no-audio --loop-file=inf --hwdec=auto-copy --panscan=1.0 --input-ipc-server=/tmp/mpvpaper-socket" '*' "$LIVE_VIDEO"
else
    (icarus-palette "$STATIC_IMG" &)
    exec swaybg -m fill -i "$STATIC_IMG"
fi
