#!/usr/bin/env bash
# uninstall.sh - Safely removes Icarus-UI configurations, themes, scripts, and add-on packages.
# Designed to be safe for EndeavourOS / Arch systems with pre-installed KDE.
# Run this as your normal user. Sudo will be requested when needed.
#
# Usage:
#   bash uninstall.sh          — Remove Icarus-added configs, themes, and add-on packages only
#   bash uninstall.sh --full   — Also remove shared packages (kitty, cava, fastfetch, etc.)

set -euo pipefail

# Style helpers
c_reset='\033[0m'; c_bold='\033[1m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_red='\033[1;31m'; c_blue='\033[1;34m'; c_cyan='\033[1;36m'
info()  { printf "    %s\n" "$1"; }
ok()    { printf "${c_green}[ok]${c_reset} %s\n" "$1"; }
warn()  { printf "${c_yellow}[warn]${c_reset} %s\n" "$1"; }
err()   { printf "${c_red}[error]${c_reset} %s\n" "$1"; }
step()  { printf "\n${c_blue}==>${c_reset} ${c_bold}%s${c_reset}\n" "$1"; }

FULL_MODE=false
if [[ "${1:-}" == "--full" ]]; then
    FULL_MODE=true
fi

if [[ "${EUID}" -eq 0 ]]; then
    err "Do not run this script as root. Run it as your normal user."
    exit 1
fi

SUDO_KEEPALIVE_PID=""
sudo_init_keepalive() {
    info "Initializing sudo keepalive. You may be prompted for your password once..."
    sudo -v
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done) 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
}
cleanup() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT
sudo_init_keepalive

# Detect AUR helper
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

echo ""
echo -e "${c_red}${c_bold}╔═══════════════════════════════════════════════════════════╗${c_reset}"
echo -e "${c_red}${c_bold}║          ICARUS-UI SYSTEM CLEANUP (EndeavourOS Safe)      ║${c_reset}"
echo -e "${c_red}${c_bold}╚═══════════════════════════════════════════════════════════╝${c_reset}"
echo ""
if [[ "$FULL_MODE" == "true" ]]; then
    echo -e "${c_yellow}[FULL MODE]${c_reset} This will remove ALL Icarus packages including shared tools."
else
    echo "This will remove Icarus-specific configs, themes, and add-on packages."
    echo -e "Your ${c_bold}EndeavourOS system packages${c_reset} (dolphin, kitty, etc.) will NOT be touched."
    echo -e "Use ${c_cyan}bash uninstall.sh --full${c_reset} for a complete nuclear wipe."
fi
echo ""
read -rp "Are you sure you want to proceed? [y/N]: " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then
    info "Cleanup aborted."
    exit 0
fi

# ============================================================================
# 1. Remove Icarus user configurations (~/.config/)
# ============================================================================
step "1. Removing Icarus user configurations"

# Hyprland-specific configs (always safe to remove — not part of KDE)
for dir in hypr waybar rofi wlogout eww; do
    if [[ -d "${HOME}/.config/${dir}" ]]; then
        info "Removing ~/.config/${dir} (Hyprland-specific)..."
        rm -rf "${HOME}/.config/${dir}"
    fi
done

# Icarus-specific KDE configs
for dir in icarus latte quickshell; do
    if [[ -d "${HOME}/.config/${dir}" ]]; then
        info "Removing ~/.config/${dir} (Icarus-specific)..."
        rm -rf "${HOME}/.config/${dir}"
    fi
done

# Only remove shared tool configs in --full mode
if [[ "$FULL_MODE" == "true" ]]; then
    for dir in cava nvim yazi dunst; do
        if [[ -d "${HOME}/.config/${dir}" ]]; then
            info "Removing ~/.config/${dir} (shared tool — full mode)..."
            rm -rf "${HOME}/.config/${dir}"
        fi
    done
fi

ok "User configurations removed."

# ============================================================================
# 2. Remove Icarus themes, icons, cursors, and fonts
# ============================================================================
step "2. Removing Icarus-deployed themes and visual assets"

# User-local themes
info "Cleaning ~/.themes..."
rm -rf "${HOME}/.themes/WhiteSur"* 2>/dev/null || true
rm -rf "${HOME}/.themes/Archos"* 2>/dev/null || true
rm -rf "${HOME}/.themes/Cherry-Blossom"* "${HOME}/.themes/Coffee"* 2>/dev/null || true
rm -rf "${HOME}/.themes/Foggy-Mountain"* "${HOME}/.themes/Urban"* 2>/dev/null || true
rm -rf "${HOME}/.themes/Flowers"* "${HOME}/.themes/Neutral"* 2>/dev/null || true

# User-local icons and cursors
info "Cleaning ~/.local/share/icons..."
rm -rf "${HOME}/.local/share/icons/WhiteSur"* 2>/dev/null || true
rm -rf "${HOME}/.local/share/icons/Archos"* 2>/dev/null || true
rm -rf "${HOME}/.local/share/icons/Aura-Mew-Cursor" 2>/dev/null || true

# KDE-specific theme directories
rm -rf "${HOME}/.local/share/color-schemes" 2>/dev/null || true
rm -rf "${HOME}/.local/share/aurorae/themes" 2>/dev/null || true
rm -rf "${HOME}/.local/share/plasma/desktoptheme/Sweet" 2>/dev/null || true
rm -rf "${HOME}/.local/share/plasma/desktoptheme/Katerial" 2>/dev/null || true
rm -rf "${HOME}/.local/share/plasma/desktoptheme/JuxPlasma" 2>/dev/null || true
rm -rf "${HOME}/.local/share/plasma/look-and-feel/Catppuccin"* 2>/dev/null || true
rm -rf "${HOME}/.local/share/plasma/look-and-feel/catppuccin"* 2>/dev/null || true
rm -rf "${HOME}/.config/Kvantum/Katerial"* 2>/dev/null || true
rm -rf "${HOME}/.config/Kvantum/NoMansSkyJux"* 2>/dev/null || true

# System-wide assets installed by Icarus
info "Removing system-wide Icarus assets..."
sudo rm -rf /usr/share/backgrounds/icarus 2>/dev/null || true
sudo rm -rf /usr/share/archos 2>/dev/null || true
sudo rm -rf /usr/share/themes/Archos* 2>/dev/null || true
sudo rm -rf /usr/share/themes/WhiteSur* 2>/dev/null || true
sudo rm -rf /usr/share/icons/Archos* 2>/dev/null || true
sudo rm -rf /usr/share/icons/WhiteSur* 2>/dev/null || true
sudo rm -rf /usr/share/icons/Aura-Mew-Cursor 2>/dev/null || true
sudo rm -rf /usr/share/sddm/themes/Katerial 2>/dev/null || true
sudo rm -rf /usr/share/sddm/themes/WhiteSur 2>/dev/null || true

ok "Themes and visual assets removed."

# ============================================================================
# 3. Stop and remove Icarus systemd user services
# ============================================================================
step "3. Stopping and removing Icarus systemd services"

ICARUS_SERVICES=(kde-material-you-colors plasma2telegram qs-kwin-bridge ydotoold)
for svc in "${ICARUS_SERVICES[@]}"; do
    if systemctl --user is-active "${svc}.service" &>/dev/null; then
        info "Stopping ${svc}..."
        systemctl --user stop "${svc}.service" 2>/dev/null || true
    fi
    if [[ -f "${HOME}/.config/systemd/user/${svc}.service" ]]; then
        systemctl --user disable "${svc}.service" 2>/dev/null || true
        rm -f "${HOME}/.config/systemd/user/${svc}.service"
        info "Removed ${svc}.service"
    fi
done
systemctl --user daemon-reload 2>/dev/null || true

# Remove ydotoold sudoers entry
if [[ -f /etc/sudoers.d/ydotoold-nopasswd ]]; then
    sudo rm -f /etc/sudoers.d/ydotoold-nopasswd 2>/dev/null || true
    info "Removed ydotoold sudoers entry."
fi

ok "Icarus systemd services removed."

# ============================================================================
# 4. Remove Icarus custom scripts and binaries
# ============================================================================
step "4. Removing Icarus custom scripts and binaries"

# ~/.local/bin scripts
ICARUS_LOCAL_BINS=(icarus-welcome random_image.sh cava-theme-loader.sh alist-handler hyprctl qs-kwin-bridge.py hypr_kwin_map.json)
for bin in "${ICARUS_LOCAL_BINS[@]}"; do
    rm -f "${HOME}/.local/bin/${bin}" 2>/dev/null || true
done

# /usr/local/bin scripts
sudo rm -f /usr/local/bin/icarus-wallpaper* /usr/local/bin/icarus-palette 2>/dev/null || true

# Python module
rm -rf "${HOME}/.local/lib/python-icarus" 2>/dev/null || true
rm -rf "${HOME}/.local/lib/caelestia" 2>/dev/null || true

# Plasma2telegram data
rm -rf "${HOME}/.local/share/plasma2telegram" 2>/dev/null || true

# Jux rofi images
rm -rf "${HOME}/.local/share/jux-rofi-images" 2>/dev/null || true

# Desktop entries
rm -f "${HOME}/.local/share/applications/alist-player.desktop" 2>/dev/null || true

ok "Scripts and binaries removed."

# ============================================================================
# 5. Clean .bashrc hooks
# ============================================================================
step "5. Cleaning .bashrc hooks"

# Remove Icarus-specific blocks from .bashrc
if [[ -f "${HOME}/.bashrc" ]]; then
    sed -i '/# Icarus-ArchOS/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/# Icarus terminal visual greeting/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/icarus-wallpaper/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/random_image\.sh/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/welcome\.sh/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/QML2_IMPORT_PATH=.*caelestia/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/CAELESTIA_LIB_DIR/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/QT_PLUGIN_PATH.*local.*lib64/d' "${HOME}/.bashrc" 2>/dev/null || true
    # Clean up empty lines left behind (max 2 consecutive)
    sed -i '/^$/N;/^\n$/d' "${HOME}/.bashrc" 2>/dev/null || true
    ok "Bashrc cleaned."
else
    warn "No .bashrc found."
fi

# ============================================================================
# 6. Uninstall Icarus add-on packages (NOT EndeavourOS base packages)
# ============================================================================
step "6. Uninstalling Icarus add-on packages"
info "Only removing packages that Icarus added — your system packages are safe."

# These are packages Icarus adds that are NOT part of EndeavourOS base KDE:
ICARUS_ADDON_AUR=(
    eww-wayland
    swayosd-git
    mpvpaper
    noctalia-shell
    caelestia-shell
    caelestia-cli
    wl-clip-persist
    waypaper
    darkly
    kwin-effects-better-blur-dx
    latte-dock-git
)

ICARUS_ADDON_OFFICIAL=(
    wlogout
)

# Hyprland packages — only remove if NOT currently running Hyprland
HYPRLAND_PKGS=(hyprland waybar rofi-wayland swaybg hyprlock hypridle)
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    info "Hyprland is not running. Safe to remove Hyprland packages."
    for pkg in "${HYPRLAND_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null 2>&1; then
            sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || true
            info "Removed: $pkg"
        fi
    done
else
    warn "Hyprland is currently running! Skipping Hyprland package removal."
    warn "Run this script from a KDE session to remove Hyprland packages."
fi

# Remove official addon packages
for pkg in "${ICARUS_ADDON_OFFICIAL[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null 2>&1; then
        sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || true
        info "Removed: $pkg"
    fi
done

# Remove AUR addon packages
if [[ -n "$AUR_HELPER" ]]; then
    for pkg in "${ICARUS_ADDON_AUR[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null 2>&1; then
            $AUR_HELPER -Rns --noconfirm "$pkg" 2>/dev/null || true
            info "Removed: $pkg"
        fi
    done
else
    warn "No AUR helper detected. Skipping AUR package removal."
    warn "Manually remove with: yay -Rns ${ICARUS_ADDON_AUR[*]}"
fi

# Full mode: also remove shared tools that EndeavourOS might not ship
if [[ "$FULL_MODE" == "true" ]]; then
    step "6b. Full mode — removing shared tool packages"
    SHARED_REMOVABLE=(cava starship eza bat zoxide gum nwg-look swaync fuzzel wlsunset wmenu)
    for pkg in "${SHARED_REMOVABLE[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null 2>&1; then
            sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || true
            info "Removed: $pkg"
        fi
    done
fi

ok "Add-on packages cleaned up."

# ============================================================================
# 7. Reset KDE to defaults (optional, only if KDE is detected)
# ============================================================================
if command -v kwriteconfig6 &>/dev/null; then
    step "7. Resetting KDE application style to Breeze defaults"
    kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "breeze" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "BreezeDark" 2>/dev/null || true
    kwriteconfig6 --file kwinrc --group "Plugins" --key "kwin-effects-forceblurEnabled" "false" 2>/dev/null || true
    kwriteconfig6 --file kwinrc --group "Plugins" --key "kwin-effects-better-blur-dxEnabled" "false" 2>/dev/null || true
    kwriteconfig6 --file kwinrc --group "Plugins" --key "bismuthEnabled" "false" 2>/dev/null || true
    kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "false" 2>/dev/null || true
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    ok "KDE reset to Breeze defaults."
fi

# ============================================================================
# Done
# ============================================================================
echo ""
echo -e "${c_green}${c_bold}╔═══════════════════════════════════════════════════════════╗${c_reset}"
echo -e "${c_green}${c_bold}║              CLEANUP COMPLETE                             ║${c_reset}"
echo -e "${c_green}${c_bold}╚═══════════════════════════════════════════════════════════╝${c_reset}"
echo ""
echo -e "  Your system is clean of Icarus-UI installations."
echo -e "  ${c_bold}EndeavourOS base packages were NOT removed.${c_reset}"
echo ""
echo -e "  To start a fresh deployment, run:"
echo -e "    ${c_green}bash run.sh${c_reset}"
echo ""
info "Log out and back in for all changes to take full effect."
