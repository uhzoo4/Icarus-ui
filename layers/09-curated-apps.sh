#!/usr/bin/env bash
#
# layers/09-curated-apps.sh
#
# The Awesome Linux Software catalogue is valuable as a discovery source,
# but it is deliberately not treated as a dependency list.  This image has a
# 29 GB target and 8 GB of RAM, so installing every suggestion would make the
# default system needlessly large and harder to support.  Instead this layer
# installs the configured official-repository application profiles before the
# target's first boot. Additional profiles remain available afterward through
# the same profile tool.
#
# Attribution for the source catalogue is recorded in
# docs/AWESOME_LINUX_SOFTWARE.md and THIRD-PARTY-LICENSES.md.
#
set -euo pipefail

ICARUS_LOG_DIR="${ICARUS_LOG_DIR:-/var/log/icarus}"
ICARUS_REPO_PATH="${ICARUS_REPO_PATH:-/usr/usr_src/icarus-archos}"
SENTINEL="${ICARUS_LOG_DIR}/layer-9-curated-apps.done"
PREV_SENTINEL="${ICARUS_LOG_DIR}/layer-8-silent-boot.done"

log() { echo "[layer-9] $*"; }
warn() { echo "[layer-9] WARNING: $*" >&2; }
fatal() { echo "[layer-9] FATAL: $*" >&2; exit 1; }

[[ -f "$PREV_SENTINEL" ]] || fatal "Layer 8 sentinel not found (${PREV_SENTINEL})."

log "Installing the opt-in curated application profile tool..."
install -d -m 0755 /usr/local/bin
cat > /usr/local/bin/icarus-apps <<'EOF'
#!/usr/bin/env bash
# Install intentionally small, opt-in application profiles for Icarus-ArchOS.
# All package names below are from Arch's official repositories; no AUR
# package is installed by this tool.  See `icarus-apps list` before choosing.
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage:
  icarus-apps list
  icarus-apps install PROFILE [PROFILE ...]

Profiles are intentionally opt-in. They are not installed during OS assembly.
Run `icarus-apps list` to see their package sets and service notes.
USAGE
}

profile_description() {
    case "$1" in
        essentials)   printf '%s\n' "Small daily-use tools: resource monitor and local password manager." ;;
        creative)     printf '%s\n' "Image, vector, video, streaming, and media tools (large download)." ;;
        sharing)      printf '%s\n' "Device linking, file synchronization, and FTP/SFTP client." ;;
        development)  printf '%s\n' "Open-source VS Code build and distrobox for isolated dev environments." ;;
        gaming)       printf '%s\n' "Steam and Lutris for native, Proton, and Wine games (large download)." ;;
        connectivity) printf '%s\n' "Tailscale and firewalld; services remain disabled until you enable them." ;;
        *) return 1 ;;
    esac
}

profile_packages() {
    case "$1" in
        essentials)   printf '%s\n' btop keepassxc ;;
        creative)     printf '%s\n' gimp inkscape krita obs-studio kdenlive vlc ;;
        sharing)      printf '%s\n' kdeconnect syncthing filezilla ;;
        development)  printf '%s\n' code distrobox ;;
        gaming)       printf '%s\n' steam lutris ;;
        connectivity) printf '%s\n' tailscale firewalld ;;
        *) return 1 ;;
    esac
}

list_profiles() {
    local profile
    for profile in essentials creative sharing development gaming connectivity; do
        printf '%-14s %s\n' "$profile" "$(profile_description "$profile")"
        printf '  packages: '
        profile_packages "$profile" | paste -sd ' ' -
    done
    cat <<'NOTES'

Service notes (nothing is enabled automatically):
  Syncthing:  systemctl --user enable --now syncthing.service
  Tailscale:  sudo systemctl enable --now tailscaled.service && sudo tailscale up
  Firewalld:  sudo systemctl enable --now firewalld.service

The gaming and creative profiles consume substantial storage. Confirm free
space first with `df -h /` on the 29 GB minimum installation target.
NOTES
}

install_package() {
    local pkg="$1"
    if command -v dnf &>/dev/null; then
        case "$pkg" in
            code)
                if ! dnf repolist | grep -q "^code$"; then
                    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
                fi
                pkg="code"
                ;;
            libreoffice-fresh)
                pkg="libreoffice"
                ;;
            *)
                ;;
        esac
        if [[ ${EUID} -eq 0 ]]; then
            dnf install -y "$pkg"
        else
            sudo dnf install -y "$pkg"
        fi
    else
        if [[ ${EUID} -eq 0 ]]; then
            pacman -S --noconfirm --needed "$pkg"
        else
            sudo pacman -S --noconfirm --needed "$pkg"
        fi
    fi
}

install_profile() {
    local profile="$1"
    local package
    local -a failures=()

    if ! profile_description "$profile" >/dev/null; then
        echo "Unknown profile: ${profile}" >&2
        return 2
    fi

    echo "Installing '${profile}' profile: $(profile_description "$profile")"
    while IFS= read -r package; do
        if ! install_package "$package"; then
            failures+=("$package")
        fi
    done < <(profile_packages "$profile")

    if (( ${#failures[@]} > 0 )); then
        echo "Some packages could not be installed: ${failures[*]}" >&2
        return 1
    fi
}

case "${1:-}" in
    list)
        [[ $# -eq 1 ]] || { usage >&2; exit 2; }
        list_profiles
        ;;
    install)
        [[ $# -ge 2 ]] || { usage >&2; exit 2; }
        shift
        status=0
        for profile in "$@"; do
            install_profile "$profile" || status=1
        done
        exit "$status"
        ;;
    -h|--help|help|'')
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
EOF
chmod 0755 /usr/local/bin/icarus-apps

# ---------------------------------------------------------------------------
# Install the selected profiles now, while the target is being assembled.
# The repository config gives a useful first-boot default; --app-profiles on
# the conductor overrides it for a one-off image. Package failures are logged
# but do not prevent the base OS from completing (this layer is soft).
# ---------------------------------------------------------------------------
PROFILE_CONFIG="${ICARUS_REPO_PATH}/configs/apps/profiles.conf"
SELECTED_PROFILES="${ICARUS_APP_PROFILES:-}"
if [[ -z "$SELECTED_PROFILES" ]]; then
    [[ -f "$PROFILE_CONFIG" ]] || fatal "Missing application profile config: ${PROFILE_CONFIG}"
    # This file is part of the local Icarus repository and intentionally only
    # declares ICARUS_DEFAULT_APP_PROFILES.
    source "$PROFILE_CONFIG"
    SELECTED_PROFILES="${ICARUS_DEFAULT_APP_PROFILES:-}"
fi

if [[ -n "$SELECTED_PROFILES" ]]; then
    read -r -a PROFILES <<< "$SELECTED_PROFILES"
    log "Installing configured application profile(s) before first boot: ${PROFILES[*]}"
    if ! /usr/local/bin/icarus-apps install "${PROFILES[@]}"; then
        warn "One or more configured application packages failed to install. The base OS and 'icarus-apps' tool remain available; retry after boot with: icarus-apps install ${PROFILES[*]}"
    fi
else
    log "No application profiles selected; run 'icarus-apps list' after boot to choose them."
fi

mkdir -p "$ICARUS_LOG_DIR"
touch "$SENTINEL"
log "Layer 9 complete. Additional profiles can be installed later with 'icarus-apps list'."
