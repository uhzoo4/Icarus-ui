#!/usr/bin/env bash
#
# layers/TEMPLATE.sh — copy this when adding a new layer.
#
# Conventions every layer follows:
#   1. Read global flags from environment variables first (the conductor
#      exports these once), with CLI flags as an optional override so the
#      script can also be run standalone while debugging.
#   2. Check the previous layer's sentinel before doing anything.
#   3. Do the work.
#   4. Write your own sentinel as the very last line, only on success.
#   5. For anything where a broken result must not take down a working
#      system (à la the custom kernel build), mark it "soft" in
#      layers/MANIFEST and use warn_and_exit_gracefully() instead of
#      fatal() for the failure path — exit 0, don't exit 1.
#
# Rename this file to NN-your-layer-name.sh, add one line to
# layers/MANIFEST, and you're done — icarus-assemble.sh doesn't need to
# change.
#
set -euo pipefail

ICARUS_LOG_DIR="${ICARUS_LOG_DIR:-/var/log/icarus}"          # chroot default;
                                                               # host layers get
                                                               # /mnt/var/log/icarus
                                                               # exported instead.
ICARUS_REPO_PATH="${ICARUS_REPO_PATH:-/usr/usr_src/icarus-archos}"

# --- Rename this to your layer's actual sentinel name, matching MANIFEST ---
SENTINEL="${ICARUS_LOG_DIR}/layer-NN-yourname.done"
PREV_SENTINEL="${ICARUS_LOG_DIR}/layer-PREVIOUS.done"

# --- Global flags, read from environment (exported by icarus-assemble.sh) ---
TARGET="${ICARUS_TARGET_DEVICE:-}"
FORCE_XE="${ICARUS_FORCE_XE:-0}"
DISABLE_MITIGATIONS="${ICARUS_DISABLE_MITIGATIONS:-0}"
REDUNDANT_METADATA="${ICARUS_REDUNDANT_METADATA:-0}"
ALLOW_INTERNAL="${ICARUS_ALLOW_INTERNAL:-0}"

log() { echo "[layer-NN] $*"; }
fatal() { echo "[layer-NN] FATAL: $*" >&2; exit 1; }
warn_and_exit_gracefully() {
    echo "[layer-NN] $*" >&2
    echo "[layer-NN] Not fatal to the overall install — continuing without this layer's changes." >&2
    exit 0
}

# --- CLI override, for standalone/debug invocation only ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --force-xe) FORCE_XE=1; shift ;;
        --disable-mitigations) DISABLE_MITIGATIONS=1; shift ;;
        --redundant-metadata) REDUNDANT_METADATA=1; shift ;;
        --allow-internal) ALLOW_INTERNAL=1; shift ;;
        *) fatal "Unknown argument: $1" ;;
    esac
done

[[ -f "$PREV_SENTINEL" ]] || fatal "Previous layer sentinel not found (${PREV_SENTINEL})."

# --- Your work goes here ---
log "Doing the thing this layer exists for..."

mkdir -p "$ICARUS_LOG_DIR"
touch "$SENTINEL"
log "Layer complete. Sentinel written: ${SENTINEL}"
