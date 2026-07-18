#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  run.sh — Master Deployment Script for Icarus-UI Desktop Suite          ║
# ║                                                                          ║
# ║  This script orchestrates the entire Icarus-UI installation. It is       ║
# ║  split into clearly separated sections:                                  ║
# ║                                                                          ║
# ║    Section 1 — Preparation       (permissions, DE selection)             ║
# ║    Section 2 — Hyprland Suite    (tiling Wayland compositor setup)       ║
# ║    Section 3 — KDE Plasma Theme  (full Plasma desktop customization)     ║
# ║    Section 4 — GRUB Boot Themes  (animated bootloader screens)           ║
# ║    Section 5 — Custom Apps       (optional user-requested packages)      ║
# ║    Section 6 — Summary           (deployment report & tips)              ║
# ║                                                                          ║
# ║  Run this as your normal user — sudo is requested only when needed.      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ============================================================================
# PREAMBLE — Style Helpers, Guards & Shared Utilities
# ============================================================================
#
# Dissect: This block sets up terminal colors, logging functions, and safety
# guards. The root-check prevents accidental damage from running as root.
# The cleanup trap ensures the background sudo-keepalive process is killed
# when the script exits (normally or on error).
# ============================================================================

# -- Terminal color codes --
c_reset='\033[0m'
c_bold='\033[1m'
c_green='\033[1;32m'
c_yellow='\033[1;33m'
c_red='\033[1;31m'
c_blue='\033[1;34m'
c_magenta='\033[1;35m'
c_cyan='\033[1;36m'

# -- Logging helpers --
info()  { printf "    %s\n" "$1"; }
ok()    { printf "${c_green}[ok]${c_reset} %s\n" "$1"; }
warn()  { printf "${c_yellow}[warn]${c_reset} %s\n" "$1"; }
err()   { printf "${c_red}[error]${c_reset} %s\n" "$1"; }
step()  { printf "\n${c_blue}==>${c_reset} ${c_bold}%s${c_reset}\n" "$1"; }

# -- Section banner -- draws a prominent header to visually separate DE blocks
section_banner() {
    local title="$1"
    local color="${2:-$c_magenta}"
    echo ""
    echo -e "${color}${c_bold}╔═══════════════════════════════════════════════════════════╗${c_reset}"
    echo -e "${color}${c_bold}║  ${title}$(printf '%*s' $((55 - ${#title})) '')║${c_reset}"
    echo -e "${color}${c_bold}╚═══════════════════════════════════════════════════════════╝${c_reset}"
    echo ""
}

# -- Root guard --
# Dissect: Running as root can clobber user-local configs (~/.config/) with
# root-owned files. We enforce normal-user execution; sudo is used surgically.
if [[ "${EUID}" -eq 0 ]]; then
    err "Do not run this script as root. Run it as your normal user."
    err "Sudo will be requested only when needed for system-level operations."
    exit 1
fi

# -- Resolve repository path --
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "${REPO_PATH}/run.sh" ]]; then
    err "This script must be executed from inside the icarus-ui repository root."
    exit 1
fi

# -- Sudo keepalive --
# Dissect: We prompt for the password once, then refresh the sudo ticket every
# 50 seconds in a background loop. The cleanup trap ensures this process is
# killed when the script exits, preventing orphaned background jobs.
SUDO_KEEPALIVE_PID=""
sudo_init_keepalive() {
    info "Initializing sudo keepalive. You may be prompted for your password once..."
    sudo -v
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done) 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
}

# -- Cleanup trap --
cleanup() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

sudo_init_keepalive

# -- AUR helper detection (shared by Hyprland and custom apps sections) --
# Dissect: Both Hyprland (via apply-extra.sh) and the custom apps section need
# an AUR helper. We detect it once here so it can be reused everywhere.
detect_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}
AUR_HELPER="$(detect_aur_helper)"

# -- Desktop Environment auto-detection --
# Dissect: We inspect $XDG_CURRENT_DESKTOP and $HYPRLAND_INSTANCE_SIGNATURE
# to guess which DE is currently running. This sets a sensible default in the
# interactive menu so the user can just press Enter.
detect_de() {
    local xdg="${XDG_CURRENT_DESKTOP:-}"
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        echo "hyprland"
    elif [[ "${xdg,,}" == *"kde"* ]] || [[ "${xdg,,}" == *"plasma"* ]]; then
        echo "kde"
    else
        echo "unknown"
    fi
}
DETECTED_DE="$(detect_de)"

# Track what gets deployed (for the summary banner)
DEPLOYED_HYPRLAND=false
DEPLOYED_KDE=false
DEPLOYED_GRUB_RETRO=false
DEPLOYED_GRUB_POCHITA=false
DEPLOYED_CUSTOM_APPS=""


# ============================================================================
# SECTION 1 — PREPARATION
# ============================================================================
#
# Dissect: This section ensures all helper scripts have execute permissions
# and presents the user with an interactive menu to choose which desktop
# environment components to deploy. If the script detects a running DE, it
# pre-selects the matching option as the default.
# ============================================================================

section_banner "SECTION 1 — PREPARATION" "$c_blue"

step "1.1 Making installer scripts executable"
# Dissect: Shell scripts cloned from git may lose their +x bit depending on
# the platform. We force-set it here so all downstream calls work.
chmod +x "${REPO_PATH}/apply-extra.sh"
chmod +x "${REPO_PATH}/update.sh"
chmod +x "${REPO_PATH}/run.sh"
chmod +x "${REPO_PATH}/configs/wallpaper/"*.sh 2>/dev/null || true
chmod +x "${REPO_PATH}/configs/kde/install.sh" 2>/dev/null || true
chmod +x "${REPO_PATH}/configs/bootloader/install.sh" 2>/dev/null || true
chmod +x "${REPO_PATH}/tools/icarus-palette.py" 2>/dev/null || true
chmod +x "${REPO_PATH}/tools/system_core.sh" 2>/dev/null || true
chmod +x "${REPO_PATH}/tools/welcome.sh" 2>/dev/null || true
chmod +x "${REPO_PATH}/tools/random_image.sh" 2>/dev/null || true
chmod +x "${REPO_PATH}/tools/alist-handler" 2>/dev/null || true
ok "All scripts are executable."

step "1.2 Selecting deployment target"

# Build default choice based on auto-detection
DEFAULT_CHOICE=1
if [[ "$DETECTED_DE" == "kde" ]]; then
    DEFAULT_CHOICE=2
    info "Auto-detected: KDE Plasma is running — defaulting to KDE Plasma Variant."
elif [[ "$DETECTED_DE" == "hyprland" ]]; then
    DEFAULT_CHOICE=1
    info "Auto-detected: Hyprland is running — defaulting to Hyprland Preset Suite."
else
    info "Could not auto-detect DE. Defaulting to Hyprland Preset Suite."
fi

echo ""
echo -e "${c_bold}What components of Icarus UI would you like to deploy?${c_reset}"
echo ""
echo -e "  ${c_cyan}1)${c_reset} ${c_bold}Hyprland Preset Suite${c_reset}       — Tiling Wayland compositor + Waybar + Rofi"
echo -e "  ${c_cyan}2)${c_reset} ${c_bold}KDE Plasma Variant Theme${c_reset}    — Sweet/Catppuccin/Katerial + Material You"
echo -e "  ${c_cyan}3)${c_reset} ${c_bold}Animated GRUB (Retroboot)${c_reset}   — Retro-styled animated boot screen"
echo -e "  ${c_cyan}4)${c_reset} ${c_bold}Animated GRUB (Pochita)${c_reset}     — Pochita animated boot screen"
echo -e "  ${c_cyan}5)${c_reset} ${c_bold}Deploy Full Suite${c_reset}            — All of the above"
echo ""
read -rp "Enter choice [1-5, default: ${DEFAULT_CHOICE}]: " COMP_CHOICE
COMP_CHOICE="${COMP_CHOICE:-$DEFAULT_CHOICE}"

# Parse selection into boolean flags
INSTALL_HYPRLAND=false
INSTALL_KDE=false
INSTALL_GRUB_RETRO=false
INSTALL_GRUB_POCHITA=false

case "$COMP_CHOICE" in
    1) INSTALL_HYPRLAND=true ;;
    2) INSTALL_KDE=true ;;
    3) INSTALL_GRUB_RETRO=true ;;
    4) INSTALL_GRUB_POCHITA=true ;;
    5) INSTALL_HYPRLAND=true; INSTALL_KDE=true; INSTALL_GRUB_RETRO=true ;;
    *)
        warn "Invalid selection '${COMP_CHOICE}'. Defaulting to Hyprland Preset Suite."
        INSTALL_HYPRLAND=true
        ;;
esac


# ============================================================================
# SECTION 2 — HYPRLAND PRESET SUITE
# ============================================================================
#
# Dissect: This section deploys a complete Hyprland tiling Wayland compositor
# environment. The workflow is:
#
#   H1. Run apply-extra.sh → installs packages (hyprland, waybar, rofi, kitty,
#       dunst, cava, etc.), compiles GTK/icon/cursor themes, copies wallpapers,
#       deploys user configs to ~/.config/ (hypr, waybar, kitty, rofi, dunst,
#       fastfetch, cava, wlogout, eww, nvim, yazi, starship), writes GTK
#       preferences, installs fonts, and starts the wallpaper daemon.
#
#   H2. Initialize the dynamic color palette by running icarus-palette against
#       the default wallpaper. This generates Material You accent colors that
#       Hyprland, Waybar, and Rofi configs reference.
#
#   H3. Verify Hyprland-specific configs are properly deployed and scripts
#       are executable (hypr/scripts/*.sh, eww/scripts/*.sh).
#
#   H4. Hot-reload Hyprland so config changes take effect immediately without
#       requiring logout. Restart Waybar for the new theme.
#
#   H5. Restart wallpaper services (kill stale mpvpaper/swaybg, launch daemon).
#
# ============================================================================

if [[ "$INSTALL_HYPRLAND" == "true" ]]; then
    section_banner "SECTION 2 — HYPRLAND PRESET SUITE" "$c_green"

    # ── H1. Install system dependencies & deploy shared assets ──────────────
    # Dissect: apply-extra.sh is the heavy lifter. It installs ~50 packages
    # via pacman/dnf, compiles Archos & WhiteSur GTK/icon/cursor themes,
    # copies wallpapers (static + live), deploys all user dotfiles, writes
    # GTK settings, installs fonts, and boots the wallpaper daemon.
    step "H1. Installing system dependencies & deploying shared assets"
    info "Running apply-extra.sh (packages, themes, configs, wallpapers)..."
    bash "${REPO_PATH}/apply-extra.sh" --hyprland
    ok "Base system components installed."

    # ── H2. Initialize dynamic color palette ────────────────────────────────
    # Dissect: icarus-palette.py extracts dominant colors from a wallpaper
    # image using Material You algorithms and writes color variables that
    # Hyprland, Waybar, and Rofi configs source. Without this step, the
    # desktop would fall back to hardcoded default colors.
    step "H2. Initializing dynamic color palette"
    DEFAULT_WP="/usr/share/backgrounds/icarus/references/84.png"
    if [[ ! -f "$DEFAULT_WP" ]]; then
        DEFAULT_WP="/usr/share/backgrounds/icarus/icarus-midnight.png"
    fi

    if [[ -f "/usr/local/bin/icarus-palette" ]] && [[ -f "$DEFAULT_WP" ]]; then
        info "Generating color palette from: $(basename "$DEFAULT_WP")"
        /usr/local/bin/icarus-palette "$DEFAULT_WP" || warn "Palette generation encountered an issue (non-fatal)."
        ok "Dynamic color palette initialized."
    else
        warn "icarus-palette or default wallpaper not found. Skipping palette init."
        info "You can manually run: icarus-palette /path/to/wallpaper.png"
    fi

    # ── H3. Verify Hyprland-specific configurations ─────────────────────────
    # Dissect: After apply-extra.sh copies configs, we do a quick sanity check
    # to ensure the critical Hyprland config files landed correctly and scripts
    # are executable. This catches common issues like missing directories.
    step "H3. Verifying Hyprland configuration deployment"
    HYPR_CONFIG_DIR="${HOME}/.config/hypr"
    if [[ -f "${HYPR_CONFIG_DIR}/hyprland.conf" ]]; then
        ok "Hyprland main config: ${HYPR_CONFIG_DIR}/hyprland.conf"
    else
        warn "Hyprland config not found at ${HYPR_CONFIG_DIR}/hyprland.conf"
    fi

    # Ensure all hyprland helper scripts are executable
    if [[ -d "${HYPR_CONFIG_DIR}/scripts" ]]; then
        chmod +x "${HYPR_CONFIG_DIR}/scripts/"* 2>/dev/null || true
        ok "Hyprland helper scripts are executable."
    fi

    # Verify Waybar config exists
    if [[ -d "${HOME}/.config/waybar" ]]; then
        ok "Waybar config deployed."
    else
        warn "Waybar config directory missing."
    fi

    # Verify EWW scripts
    if [[ -d "${HOME}/.config/eww/scripts" ]]; then
        chmod +x "${HOME}/.config/eww/scripts/"*.sh 2>/dev/null || true
        ok "EWW widget scripts are executable."
    fi

    # ── H4. Reload Hyprland compositor & restart Waybar ─────────────────────
    # Dissect: hyprctl reload tells the running Hyprland instance to re-parse
    # its config files. We only do this if Hyprland is actually running
    # (detected by HYPRLAND_INSTANCE_SIGNATURE). Waybar is killed and
    # relaunched to pick up the new theme/config.
    step "H4. Reloading Hyprland compositor & Waybar"
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        info "Hyprland is running — hot-reloading configuration..."
        hyprctl reload >/dev/null 2>&1 || warn "hyprctl reload failed (compositor may not be ready)."
        ok "Hyprland configuration reloaded."

        info "Restarting Waybar..."
        killall waybar 2>/dev/null || true
        sleep 0.5
        (waybar &) >/dev/null 2>&1 &
        ok "Waybar restarted."
    else
        info "Hyprland is not currently running. Skipping live reload."
        info "Changes will take effect on next Hyprland session start."
    fi

    # ── H5. Start wallpaper services ────────────────────────────────────────
    # Dissect: The wallpaper system consists of three components:
    #   - icarus-wallpaper: main launcher that picks static/live wallpaper
    #   - icarus-wallpaper-daemon: monitors fullscreen apps to pause video WPs
    #   - swaybg/mpvpaper: backend renderers for static/video wallpapers
    # We kill any stale instances and relaunch cleanly.
    step "H5. Starting wallpaper services"
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        killall icarus-wallpaper-daemon mpvpaper swaybg 2>/dev/null || true
        if command -v icarus-wallpaper &>/dev/null; then
            (icarus-wallpaper &) >/dev/null 2>&1
            ok "Wallpaper daemon launched."
        else
            warn "icarus-wallpaper command not found. Wallpaper daemon not started."
        fi
    else
        info "Hyprland not running. Wallpaper services will start with compositor."
    fi

    DEPLOYED_HYPRLAND=true
    ok "Hyprland Preset Suite deployed successfully."
fi


# ============================================================================
# SECTION 3 — KDE PLASMA VARIANT THEME
# ============================================================================
#
# Dissect: This section deploys the full KDE Plasma desktop customization
# suite. The workflow is:
#
#   K1. Run apply-extra.sh → same shared asset installation as Hyprland
#       (packages, GTK themes, wallpapers, fonts, cursors). This ensures
#       consistent theming foundations regardless of DE choice.
#
#   K2. Run configs/kde/install.sh → the 750-line KDE-specific installer:
#       - Installs KDE build deps (cmake, qt6-base, extra-cmake-modules)
#       - Deploys Sweet-KDE, Catppuccin, and Katerial theme suites
#       - Compiles Bismuth tiling engine (fallback: Krohnkite)
#       - Builds KWin Force Blur plugin from source
#       - Builds Caelestia Quickshell panel + C++ hyprctl shim
#       - Installs KDE Material You Colors (wallpaper-adaptive daemon)
#       - Registers Plasmoid widgets (Control Station, Material You)
#       - Creates systemd user services (color daemon, Telegram sync)
#       - Sets up Konsave profile snapshots
#       - Auto-applies the selected theme via kwriteconfig6
#
#   K3. Post-deploy verification of critical KDE services.
#
# ============================================================================

if [[ "$INSTALL_KDE" == "true" ]]; then
    section_banner "SECTION 3 — KDE PLASMA VARIANT THEME" "$c_magenta"

    # ── K1. Install common system components ────────────────────────────────
    # Dissect: Even for KDE, we run apply-extra.sh to install shared assets:
    # Archos/WhiteSur GTK themes, icon themes, cursor themes, wallpapers,
    # fonts, and the base package set. This avoids duplicating theme
    # compilation logic between the two DE paths.
    step "K1. Installing common system components (shared assets)"
    info "Running apply-extra.sh (packages, themes, wallpapers, fonts)..."
    bash "${REPO_PATH}/apply-extra.sh" --kde
    ok "Shared system components installed."

    # ── K2. Execute KDE Plasma installer ────────────────────────────────────
    # Dissect: configs/kde/install.sh is a comprehensive 750-line installer
    # that handles everything KDE-specific:
    #
    #   Themes:  Sweet-KDE (purple-pink gradients)
    #            Catppuccin (4 pastel flavors + Aurorae + LookAndFeel)
    #            Katerial (Material Design Kvantum + SDDM)
    #            ComplexPlatform GTK (6 color schemes)
    #            Jux Mystical-Blue (Aurorae + Kvantum + colors)
    #
    #   Tiling:  Bismuth (compiled from TypeScript/CMake, Plasma 5)
    #            Krohnkite (fallback for Plasma 6)
    #
    #   Plugins: KWin Force Blur (compiled C++ effect)
    #            Caelestia Shell (Quickshell QML panel)
    #            Control Station (EliverLara Plasmoid widget)
    #
    #   Daemons: KDE Material You Colors (wallpaper-adaptive color engine)
    #            plasma2telegram (Telegram theme sync)
    #
    #   Tools:   Konsave (profile snapshot manager)
    #            CAVA audio visualizer themes
    #            Icarus Welcome CLI dashboard
    step "K2. Running KDE Plasma installer"
    if [[ -f "${REPO_PATH}/configs/kde/install.sh" ]]; then
        info "Executing KDE Plasma deployment (this may take several minutes)..."
        bash "${REPO_PATH}/configs/kde/install.sh"
        ok "KDE Plasma installer completed."
    else
        err "KDE installer not found at: ${REPO_PATH}/configs/kde/install.sh"
        err "Ensure the repository is complete. Try: bash update.sh"
    fi

    # ── K3. Verify KDE services ─────────────────────────────────────────────
    # Dissect: After the KDE installer finishes, we verify that critical
    # systemd user services were created and enabled. This gives the user
    # immediate feedback on whether the color engine and sync services
    # are ready to go.
    step "K3. Verifying KDE deployment"

    # Check Material You Colors service
    if [[ -f "${HOME}/.config/systemd/user/kde-material-you-colors.service" ]]; then
        if systemctl --user is-enabled kde-material-you-colors.service &>/dev/null; then
            ok "Material You Colors daemon: enabled (will auto-start on login)"
        else
            warn "Material You Colors service exists but is not enabled."
            info "Enable with: systemctl --user enable kde-material-you-colors.service"
        fi
    else
        warn "Material You Colors service not found. Color adaptation may be unavailable."
    fi

    # Check Telegram sync service
    if [[ -f "${HOME}/.config/systemd/user/plasma2telegram.service" ]]; then
        ok "Telegram color sync service: configured"
    fi

    # Check tiling engine
    if [[ -f "${HOME}/.config/systemd/user/qs-kwin-bridge.service" ]]; then
        ok "Quickshell KWin bridge: configured"
    fi

    # Report Kvantum status
    if command -v kvantummanager &>/dev/null; then
        ok "Kvantum theme engine: available"
    else
        info "Kvantum not installed — Katerial Material Design theme requires it."
    fi

    DEPLOYED_KDE=true
    ok "KDE Plasma Variant Theme deployed successfully."
fi


# ============================================================================
# SECTION 4 — GRUB BOOT THEMES (Optional)
# ============================================================================
#
# Dissect: Animated GRUB themes are independent of the desktop environment.
# They modify /boot/grub/themes/ and update grub.cfg. Two variants are
# available:
#   - Retroboot: retro pixel-art styled boot animation
#   - Pochita:   Pochita (Chainsaw Man) themed boot animation
#
# The bootloader/install.sh script handles theme extraction, installation
# to /boot, and grub-mkconfig regeneration.
# ============================================================================

if [[ "$INSTALL_GRUB_RETRO" == "true" ]] || [[ "$INSTALL_GRUB_POCHITA" == "true" ]]; then
    section_banner "SECTION 4 — GRUB BOOT THEMES" "$c_cyan"
fi

if [[ "$INSTALL_GRUB_RETRO" == "true" ]]; then
    step "4a. Deploying Animated GRUB Theme (Retroboot)"
    if [[ -f "${REPO_PATH}/configs/bootloader/install.sh" ]]; then
        bash "${REPO_PATH}/configs/bootloader/install.sh"
        DEPLOYED_GRUB_RETRO=true
        ok "Retroboot GRUB theme deployed."
    else
        warn "Bootloader installer not found."
    fi
fi

if [[ "$INSTALL_GRUB_POCHITA" == "true" ]]; then
    step "4b. Deploying Animated GRUB Theme (Pochita)"
    if [[ -f "${REPO_PATH}/configs/bootloader/install.sh" ]]; then
        bash "${REPO_PATH}/configs/bootloader/install.sh" --pochita
        DEPLOYED_GRUB_POCHITA=true
        ok "Pochita GRUB theme deployed."
    else
        warn "Bootloader installer not found."
    fi
fi


# ============================================================================
# SECTION 5 — CUSTOM APPLICATIONS (Optional)
# ============================================================================
#
# Dissect: This section lets the user install additional packages beyond
# what Icarus ships. It tries the official repos first (pacman/dnf), then
# falls back to the detected AUR helper (paru/yay). This is useful for
# apps like gimp, code, vlc, or obs-studio that aren't part of the core
# desktop setup but complement the workflow.
# ============================================================================

section_banner "SECTION 5 — CUSTOM APPLICATIONS" "$c_yellow"

step "5.1 Install custom applications"
echo ""
echo -e "${c_bold}Do you want to install additional custom applications?${c_reset}"
echo -e "Enter a space-separated list of packages (e.g. ${c_cyan}gimp code vlc obs-studio${c_reset}),"
echo -e "or press Enter to skip:"
echo ""
read -rp "Packages: " CUSTOM_APPS_INPUT

if [[ -n "$CUSTOM_APPS_INPUT" ]]; then
    INSTALLED_APPS=()
    FAILED_APPS=()

    for APP in $CUSTOM_APPS_INPUT; do
        info "Installing ${APP}..."

        # Dissect: Try pacman first (official repos are faster and more
        # reliable), then fall back to AUR helper for community packages.
        if command -v dnf &>/dev/null; then
            # Fedora path
            if sudo dnf install -y "$APP" 2>/dev/null; then
                ok "${APP} installed via dnf."
                INSTALLED_APPS+=("$APP")
            else
                warn "Could not install ${APP} via dnf."
                FAILED_APPS+=("$APP")
            fi
        else
            # Arch path
            if sudo pacman -S --needed --noconfirm "$APP" 2>/dev/null; then
                ok "${APP} installed via pacman."
                INSTALLED_APPS+=("$APP")
            elif [[ -n "$AUR_HELPER" ]]; then
                if $AUR_HELPER -S --noconfirm --needed "$APP" 2>/dev/null; then
                    ok "${APP} installed via ${AUR_HELPER} (AUR)."
                    INSTALLED_APPS+=("$APP")
                else
                    warn "Failed to install ${APP} via AUR."
                    FAILED_APPS+=("$APP")
                fi
            else
                warn "Could not install ${APP} (not in official repos, no AUR helper detected)."
                FAILED_APPS+=("$APP")
            fi
        fi
    done

    # Report results
    if [[ ${#INSTALLED_APPS[@]} -gt 0 ]]; then
        ok "Successfully installed: ${INSTALLED_APPS[*]}"
    fi
    if [[ ${#FAILED_APPS[@]} -gt 0 ]]; then
        warn "Failed to install: ${FAILED_APPS[*]}"
    fi

    DEPLOYED_CUSTOM_APPS="${INSTALLED_APPS[*]:-none}"
else
    ok "No custom apps requested. Skipping."
fi


# ============================================================================
# SECTION 6 — DEPLOYMENT SUMMARY
# ============================================================================
#
# Dissect: The summary banner gives the user a clear at-a-glance report of
# everything that was deployed. It also shows DE-specific tips — Hyprland
# users get keybind hints, KDE users get Konsave and Material You tips.
# ============================================================================

echo ""
echo ""
echo -e "${c_magenta}${c_bold}╔═══════════════════════════════════════════════════════════╗${c_reset}"
echo -e "${c_magenta}${c_bold}║          ICARUS-UI — DEPLOYMENT COMPLETE                 ║${c_reset}"
echo -e "${c_magenta}${c_bold}╚═══════════════════════════════════════════════════════════╝${c_reset}"
echo ""

# -- Deployed components --
echo -e "  ${c_bold}Deployed Components:${c_reset}"

if [[ "$DEPLOYED_HYPRLAND" == "true" ]]; then
    echo -e "    ${c_green}✓${c_reset} Hyprland Preset Suite"
    echo -e "      ${c_cyan}├─${c_reset} Packages: hyprland, waybar, rofi, kitty, dunst, cava, eww"
    echo -e "      ${c_cyan}├─${c_reset} Themes:   Archos-Dark GTK, WhiteSur GTK, Archos icons & cursors"
    echo -e "      ${c_cyan}├─${c_reset} Configs:  hypr, waybar, kitty, rofi, dunst, cava, wlogout, eww, nvim, yazi"
    echo -e "      ${c_cyan}├─${c_reset} Tools:    icarus-palette, icarus-wallpaper, welcome.sh"
    echo -e "      ${c_cyan}└─${c_reset} Palette:  Material You dynamic colors (wallpaper-adaptive)"
fi

if [[ "$DEPLOYED_KDE" == "true" ]]; then
    echo -e "    ${c_green}✓${c_reset} KDE Plasma Variant Theme"
    echo -e "      ${c_cyan}├─${c_reset} Themes:   Sweet-KDE, Catppuccin (4 flavors), Katerial, Jux Mystical-Blue"
    echo -e "      ${c_cyan}├─${c_reset} GTK:      Cherry Blossom, Coffee, Flowers, Foggy Mountain, Neutral, Urban"
    echo -e "      ${c_cyan}├─${c_reset} Tiling:   Bismuth / Krohnkite (auto-selected)"
    echo -e "      ${c_cyan}├─${c_reset} Plugins:  KWin Force Blur, Caelestia Shell, Control Station"
    echo -e "      ${c_cyan}├─${c_reset} Daemons:  Material You Colors, plasma2telegram"
    echo -e "      ${c_cyan}└─${c_reset} Profiles: Konsave safety snapshot (icarus-default)"
fi

if [[ "$DEPLOYED_GRUB_RETRO" == "true" ]]; then
    echo -e "    ${c_green}✓${c_reset} Animated GRUB Theme (Retroboot)"
fi

if [[ "$DEPLOYED_GRUB_POCHITA" == "true" ]]; then
    echo -e "    ${c_green}✓${c_reset} Animated GRUB Theme (Pochita)"
fi

if [[ -n "${DEPLOYED_CUSTOM_APPS}" ]] && [[ "$DEPLOYED_CUSTOM_APPS" != "none" ]]; then
    echo -e "    ${c_green}✓${c_reset} Custom Apps: ${DEPLOYED_CUSTOM_APPS}"
fi

# -- DE-specific tips --
echo ""
echo -e "  ${c_bold}Tips:${c_reset}"

if [[ "$DEPLOYED_HYPRLAND" == "true" ]]; then
    echo -e "    ${c_cyan}▸${c_reset} Press ${c_bold}SUPER+W${c_reset} to open the wallpaper selector"
    echo -e "    ${c_cyan}▸${c_reset} Press ${c_bold}SUPER+D${c_reset} to launch Rofi app launcher"
    echo -e "    ${c_cyan}▸${c_reset} Run ${c_bold}icarus-palette /path/to/wallpaper.png${c_reset} to regenerate colors"
    echo -e "    ${c_cyan}▸${c_reset} Edit ${c_bold}~/.config/hypr/hyprland.conf${c_reset} to customize keybinds"
fi

if [[ "$DEPLOYED_KDE" == "true" ]]; then
    echo -e "    ${c_cyan}▸${c_reset} Change your wallpaper — Material You Colors will auto-adapt the palette"
    echo -e "    ${c_cyan}▸${c_reset} Run ${c_bold}konsave -l${c_reset} to list saved profiles"
    echo -e "    ${c_cyan}▸${c_reset} Run ${c_bold}konsave -a icarus-default${c_reset} to restore the safety snapshot"
    echo -e "    ${c_cyan}▸${c_reset} Run ${c_bold}bash tools/system_core.sh${c_reset} to engage gaming performance mode"
    echo -e "    ${c_cyan}▸${c_reset} Run ${c_bold}icarus-welcome${c_reset} for the interactive CLI dashboard"
fi

echo ""
echo -e "  ${c_cyan}▸${c_reset} Run ${c_bold}bash update.sh${c_reset} anytime to pull latest changes and redeploy"
echo ""
info "Restart or log out and back in to load all components fully."
echo -e "${c_bold}Enjoy the peak visuals and layout setup. ⚡${c_reset}"
echo ""
