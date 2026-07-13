#!/bin/sh
# /etc/profile.d/wine-wayland.sh
#
# Configures Wine's default prefix to use its native Wayland driver instead
# of routing through XWayland. Runs once per user (guarded by a marker file)
# rather than on every shell login, since spawning wine for a registry write
# on every login would be slow and pointless after the first run.
#
# Requires Wine 9.0+ for the native Wayland driver to exist at all.

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEWAYLAND_DETACHABLE_MDI=1

_icarus_wine_marker="${WINEPREFIX}/.icarus-wayland-configured"

if command -v wine >/dev/null 2>&1 && [ ! -f "$_icarus_wine_marker" ]; then
    _wine_version="$(wine --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
    _wine_major="$(echo "$_wine_version" | cut -d. -f1)"

    if [ -n "$_wine_major" ] && [ "$_wine_major" -ge 9 ] 2>/dev/null; then
        # Only touch the prefix if it already exists; don't force-create one
        # from a login shell as a side effect.
        if [ -d "$WINEPREFIX" ]; then
            wine reg add "HKCU\Software\Wine\Drivers" /v Graphics /d "wayland,x11" /f >/dev/null 2>&1 \
                && mkdir -p "$WINEPREFIX" \
                && touch "$_icarus_wine_marker"
        fi
    fi
fi

unset _icarus_wine_marker _wine_version _wine_major
