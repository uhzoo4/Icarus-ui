#!/usr/bin/env bash
# Icarus weather fetcher for Eww dashboard.
# Uses wttr.in with a 30-minute cache to avoid hammering the API.
set -uo pipefail

CACHE="$HOME/.cache/icarus/weather.json"
CACHE_DIR="$(dirname "$CACHE")"
CACHE_MAX_AGE=1800  # 30 minutes

mkdir -p "$CACHE_DIR"

needs_refresh() {
    [[ ! -f "$CACHE" ]] && return 0
    local age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
    (( age > CACHE_MAX_AGE ))
}

if needs_refresh; then
    # Bound the network operation: the dashboard must never hang just because
    # the weather endpoint is slow, captive, or unavailable.
    curl -fsS --connect-timeout 3 --max-time 8 "wttr.in/?format=j1" > "${CACHE}.tmp" 2>/dev/null \
        && mv "${CACHE}.tmp" "$CACHE"
fi

if [[ ! -f "$CACHE" ]]; then
    case "${1:-}" in
        temp)      echo "--" ;;
        icon)      echo "󰖐" ;;
        condition) echo "Unavailable" ;;
    esac
    exit 0
fi

case "${1:-}" in
    temp)
        jq -r '.current_condition[0].temp_C // "--"' "$CACHE" 2>/dev/null || echo "--"
        ;;
    icon)
        code=$(jq -r '.current_condition[0].weatherCode // "0"' "$CACHE" 2>/dev/null)
        case "$code" in
            113)  echo "󰖙" ;; # Sunny/Clear
            116)  echo "󰖐" ;; # Partly cloudy
            119|122) echo "󰖐" ;; # Cloudy/Overcast
            176|263|266|293|296|299|302|305|308|353|356|359) echo "󰖗" ;; # Rain
            200|386|389|392|395) echo "󰖓" ;; # Thunder
            227|230|323|326|329|332|335|338|368|371|374|377) echo "󰼶" ;; # Snow
            143|248|260) echo "󰖑" ;; # Fog/Mist
            *)    echo "󰖐" ;;
        esac
        ;;
    condition)
        jq -r '.current_condition[0].weatherDesc[0].value // "Unknown"' "$CACHE" 2>/dev/null || echo "Unknown"
        ;;
    *)
        echo "Usage: $0 {temp|icon|condition}"
        exit 1
        ;;
esac
