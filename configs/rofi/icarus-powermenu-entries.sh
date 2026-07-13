#!/usr/bin/env bash
# Icarus power menu entries for Rofi -modi script mode.
# Installed as /usr/local/bin/icarus-powermenu-entries
set -euo pipefail

if [[ -z "${1:-}" ]]; then
    echo "  Lock"
    echo "  Logout"
    echo "  Suspend"
    echo "  Reboot"
    echo "  Shutdown"
    exit 0
fi

case "$1" in
    *Lock)     hyprlock ;;
    *Logout)   hyprctl dispatch exit ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
