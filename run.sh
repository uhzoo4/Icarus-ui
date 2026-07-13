#!/usr/bin/env bash
# run.sh - Master script to initialize, update, and deploy the entire Icarus-ArchOS workspace.
# Run this as your normal user.

set -euo pipefail

# Style helpers
c_reset='\033[0m'; c_bold='\033[1m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_blue='\033[1;34m'
info()  { printf "    %s\n" "$1"; }
ok()    { printf "${c_green}[ok]${c_reset} %s\n" "$1"; }
warn()  { printf "${c_yellow}[warn]${c_reset} %s\n" "$1"; }
step()  { printf "\n${c_blue}==>${c_reset} ${c_bold}%s${c_reset}\n" "$1"; }

REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Sudo keepalive function
sudo_init_keepalive() {
    info "Initializing sudo keepalive. You may be prompted for your password once..."
    sudo -v
    # Keep sudo ticket alive in the background until the script exits
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done) 2>/dev/null &
}
sudo_init_keepalive

step "1. Making sure installer scripts are executable"
chmod +x "${REPO_PATH}/apply-extra.sh"
chmod +x "${REPO_PATH}/update.sh"
chmod +x "${REPO_PATH}/run.sh"
chmod +x "${REPO_PATH}/configs/wallpaper/"*.sh || true
chmod +x "${REPO_PATH}/configs/kde/install.sh" || true
chmod +x "${REPO_PATH}/configs/bootloader/install.sh" || true
chmod +x "${REPO_PATH}/tools/icarus-palette.py" || true
ok "All scripts are executable."

step "2. Executing workspace configuration and compilation"
bash "${REPO_PATH}/apply-extra.sh"

step "3. Initializing Dynamic Material Color Palette"
DEFAULT_WP="/usr/share/backgrounds/icarus/references/84.png"
[[ -f "$DEFAULT_WP" ]] || DEFAULT_WP="/usr/share/backgrounds/icarus/icarus-midnight.png"
if [[ -f "/usr/local/bin/icarus-palette" && -f "$DEFAULT_WP" ]]; then
    info "Running palette generator on default wallpaper..."
    /usr/local/bin/icarus-palette "$DEFAULT_WP" || true
    ok "Theme colors initialized."
else
    warn "Palette generator or default wallpaper not found. Dynamic colors will be generated when you switch wallpapers."
fi

step "4. Reloading Window Manager and Panel"
info "Reloading Hyprland configuration..."
hyprctl reload >/dev/null 2>&1 || true
info "Restarting Waybar panel..."
killall waybar 2>/dev/null || true
(waybar &) >/dev/null 2>&1 &
ok "Hyprland and Waybar successfully reloaded!"

step "5. Install Custom Applications"
CUSTOM_APPS=""
echo -e "\n${c_bold}Do you want to install additional custom applications?${c_reset}"
echo -e "Enter a space-separated list of packages (e.g. gimp code vlc), or press Enter to skip:"
read -rp "Packages: " CUSTOM_APPS

if [[ -n "$CUSTOM_APPS" ]]; then
    # Detect AUR helper
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    fi

    for APP in $CUSTOM_APPS; do
        info "Installing ${APP}..."
        # Try pacman first, fallback to AUR helper if available
        if sudo pacman -S --needed --noconfirm "$APP" 2>/dev/null; then
            ok "${APP} installed via pacman."
        elif [[ -n "$AUR_HELPER" ]]; then
            $AUR_HELPER -S --noconfirm --needed "$APP" || warn "Failed to install ${APP} via AUR."
        else
            warn "Could not install ${APP} (not in official repos, and no AUR helper detected)."
        fi
    done
    ok "Custom apps installation process completed."
else
    ok "No custom apps requested."
fi

step "All components have been configured and loaded successfully!"
echo -e "Enjoy the peak visuals and layout setup. Press SUPER+W to open the wallpaper selector."
