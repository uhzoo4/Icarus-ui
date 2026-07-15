#!/usr/bin/env bash
# configs/kde/install.sh
# Multi-distro installation script for Icarus UI custom KDE Plasma Suite

set -euo pipefail

# Style helpers
c_reset='\033[0m'; c_bold='\033[1m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_red='\033[1;31m'; c_blue='\033[1;34m'
info()  { printf "    %s\n" "$1"; }
ok()    { printf "${c_green}[ok]${c_reset} %s\n" "$1"; }
warn()  { printf "${c_yellow}[warn]${c_reset} %s\n" "$1"; }
err()   { printf "${c_red}[error]${c_reset} %s\n" "$1"; }
step()  { printf "\n${c_blue}==>${c_reset} ${c_bold}%s${c_reset}\n" "$1"; }

if [[ "${EUID}" -eq 0 ]]; then
    err "Do not run this script as root. Run it as your normal user. Sudo will be requested when needed."
    exit 1
fi

# Sudo keepalive function
sudo_init_keepalive() {
    info "Initializing sudo keepalive. You may be prompted for your password once..."
    sudo -v
    # Keep sudo ticket alive in the background until the script exits
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done) 2>/dev/null &
}
sudo_init_keepalive

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${BASE_DIR}/../.." && pwd)"

COLOR_DIR="${HOME}/.local/share/color-schemes"
AURORAE_DIR="${HOME}/.local/share/aurorae/themes"
PLASMA_DIR="${HOME}/.local/share/plasma/desktoptheme"
KVANTUM_DIR="${HOME}/.config/Kvantum"

mkdir -p "$COLOR_DIR" "$AURORAE_DIR" "$PLASMA_DIR" "$KVANTUM_DIR"

# 1. Install Dependencies
step "1. Checking and installing dependencies..."
if command -v dnf &>/dev/null; then
    info "Fedora system detected. Installing dependencies via dnf..."
    sudo dnf install -y qt6-qtbase-devel kwin-devel extra-cmake-modules cmake gcc-c++ \
        qt-style-kvantum python3-pillow gettext git unzip npm nodejs stow || true
else
    info "Arch/EndeavourOS system detected. Installing dependencies via pacman..."
    sudo pacman -S --needed --noconfirm extra-cmake-modules kwin qt6-base cmake gcc \
        kvantum python-pillow gettext git unzip npm nodejs stow plasma-nm \
        plasma-pa kdeplasma-addons kdeconnect ydotool || true
fi

# AUR helper check (for Arch-based systems to install Quickshell)
install_aur_pkgs() {
    if ! command -v dnf &>/dev/null; then
        local helper=""
        if command -v paru &>/dev/null; then
            helper="paru"
        elif command -v yay &>/dev/null; then
            helper="yay"
        fi
        if [[ -n "$helper" ]]; then
            info "Installing AUR packages: $* via $helper..."
            $helper -S --noconfirm --needed "$@" || true
        else
            warn "No AUR helper (paru/yay) detected. Skipped AUR package(s): $*"
        fi
    fi
}

# Install quickshell and gaming dependencies if missing
info "Checking and installing shell and gaming performance dependencies..."
install_aur_pkgs quickshell-git ananicy-cpp-git

if ! command -v dnf &>/dev/null; then
    sudo pacman -S --needed --noconfirm gamemode lib32-gamemode || true
fi


# 2. Extract and Copy Themes
step "2. Deploying themes & styling assets..."

# Mystical-Blue (Jux) assets
cp "${BASE_DIR}/JuxTheme.colors" "$COLOR_DIR/" && ok "Installed color scheme: JuxTheme"
tar -xzf "${BASE_DIR}/JuxDeco.tar.gz" -C "$AURORAE_DIR/" && ok "Installed Aurorae window decorations: JuxDeco"
tar -xzf "${BASE_DIR}/JuxPlasma.tar.gz" -C "$PLASMA_DIR/" && ok "Installed Plasma desktop theme: JuxPlasma"

if [[ -f "${BASE_DIR}/NoMansSkyJux.tar.gz" ]]; then
    tar -xzf "${BASE_DIR}/NoMansSkyJux.tar.gz" -C "$KVANTUM_DIR/"
    ok "Installed Kvantum styling template: NoMansSkyJux"
fi

# Sweet-kde theme
SWEET_THEME_SRC="${REPO_ROOT}/pkgs/themes/Sweet-kde"
if [[ -d "$SWEET_THEME_SRC" ]]; then
    info "Deploying Sweet-kde desktop theme..."
    mkdir -p "${PLASMA_DIR}/Sweet"
    cp -r "${SWEET_THEME_SRC}/"* "${PLASMA_DIR}/Sweet/"
    ok "Sweet-kde theme installed to ${PLASMA_DIR}/Sweet/"
fi

# Deploy Jux Rofi Assets if present
ROFI_DIR="${HOME}/.config/rofi"
ROFI_IMG_DIR="${HOME}/.local/share/jux-rofi-images"
mkdir -p "$ROFI_DIR" "$ROFI_IMG_DIR"
if [[ -f "${REPO_ROOT}/configs/rofi/jux.rasi" ]]; then
    cp "${REPO_ROOT}/configs/rofi/jux.rasi" "$ROFI_DIR/config.rasi" && ok "Installed Jux Rofi config"
fi
if [[ -d "${BASE_DIR}/images" ]]; then
    cp -r "${BASE_DIR}/images/"* "$ROFI_IMG_DIR/" 2>/dev/null || true
    ok "Installed Jux Rofi images"
fi

# 3. Dynamic Tiling - Krohnkite Fallback
step "3. Registering Krohnkite tiling..."
PLASMAPKG=""
if command -v kpackagetool6 &>/dev/null; then
    PLASMAPKG="kpackagetool6"
elif command -v plasmapkg2 &>/dev/null; then
    PLASMAPKG="plasmapkg2"
fi

if [[ -n "$PLASMAPKG" ]] && [[ -d "${REPO_ROOT}/pkgs/kde/krohnkite" ]]; then
    info "Registering Krohnkite script..."
    "$PLASMAPKG" --type=KWin/Script -r krohnkite 2>/dev/null || true
    ( cd "${REPO_ROOT}/pkgs/kde/krohnkite" && "$PLASMAPKG" --type=KWin/Script -i res/ ) && ok "Krohnkite registered."
fi

# 4. KWin Force Blur
step "4. Compiling and installing KWin Force Blur plugin..."
if [[ -d "${REPO_ROOT}/pkgs/kde/kwin-forceblur" ]]; then
    info "Compiling Force Blur plugin..."
    BUILD_DIR="${REPO_ROOT}/pkgs/kde/kwin-forceblur/build"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    cd "$BUILD_DIR"
    if cmake .. -DKWIN_EFFECTS_FORCEBLUR_QT6=ON; then
        make -j$(nproc)
        sudo make install
        ok "Force Blur plugin successfully compiled and installed!"
    else
        warn "CMake configuration failed. KWin Force Blur compilation skipped."
    fi
else
    warn "Force Blur source directory not found. Skipping."
fi

# 5. Caelestia Shell (Quickshell and KDE shims)
step "5. Building Caelestia Quickshell Shell & KWin shims..."
SHELL_DIR="${REPO_ROOT}/configs/kde/caelestia-shell"
if [[ -d "$SHELL_DIR" ]]; then
    info "Configuring and building Caelestia Shell..."
    cd "$SHELL_DIR"
    rm -rf build
    if cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${HOME}/.local" -DINSTALL_QSCONFDIR="${HOME}/.config/quickshell/caelestia" -DINSTALL_LIBDIR="lib/caelestia" -DINSTALL_QMLDIR="lib/qt6/qml"; then
        cmake --build build -j$(nproc)
        cmake --install build
        ok "Caelestia Shell compiled and installed to ${HOME}/.local/"
    else
        warn "Caelestia Shell build failed."
    fi
fi

# Build C++ hyprctl shim and copy bridge scripts
SRC_DIR="${REPO_ROOT}/pkgs/kde/caelestia-src"
if [[ -d "$SRC_DIR/bin" ]]; then
    info "Building C++ hyprctl mock shim..."
    mkdir -p "${SRC_DIR}/bin/build"
    cd "${SRC_DIR}/bin/build"
    if cmake .. && make -j$(nproc); then
        mkdir -p "${HOME}/.local/bin"
        cp --remove-destination hyprctl "${HOME}/.local/bin/"
        chmod +x "${HOME}/.local/bin/hyprctl"
        ok "hyprctl shim built and deployed."
    else
        warn "Failed to compile hyprctl mock shim."
    fi
    
    # Deploy Python bridge and helper files
    cp --remove-destination "${SRC_DIR}/bin/hypr_kwin_map.json" "${HOME}/.local/bin/" || true
    cp --remove-destination "${SRC_DIR}/bin/qs-kwin-bridge.py" "${HOME}/.local/bin/" || true
    chmod +x "${HOME}/.local/bin/qs-kwin-bridge.py" 2>/dev/null || true
    ok "KWin to Quickshell bridge scripts deployed."
fi

# Deploy systemd user services for quickshell bridge & ydotool
if [[ -d "$SRC_DIR/systemd" ]]; then
    info "Configuring systemd user services..."
    mkdir -p "${HOME}/.config/systemd/user"
    cp "${SRC_DIR}/systemd/qs-kwin-bridge.service" "${HOME}/.config/systemd/user/" || true
    cp "${SRC_DIR}/systemd/ydotoold.service" "${HOME}/.config/systemd/user/" || true
    
    # Set up ydotool rules for key injections without root prompts
    SUDOERS_FILE="/etc/sudoers.d/ydotoold-nopasswd"
    if [[ ! -f "$SUDOERS_FILE" ]]; then
        echo "$USER ALL=(root) NOPASSWD: /usr/bin/ydotoold" | sudo tee "$SUDOERS_FILE" > /dev/null
        sudo chmod 440 "$SUDOERS_FILE"
    fi
    sudo chmod 660 /dev/uinput 2>/dev/null || true
    sudo chgrp input /dev/uinput 2>/dev/null || true
    
    systemctl --user daemon-reload
    systemctl --user enable --now qs-kwin-bridge.service 2>/dev/null || true
    systemctl --user enable --now ydotoold.service 2>/dev/null || true
    ok "Systemd user services registered and enabled."
fi

# Add imports to shell files
if ! grep -q "QML2_IMPORT_PATH=.*caelestia" ~/.bashrc; then
    echo 'export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml"' >> ~/.bashrc
    echo 'export CAELESTIA_LIB_DIR="$HOME/.local/lib/caelestia"' >> ~/.bashrc
fi
if [[ -f "$HOME/.config/fish/config.fish" ]]; then
    if ! grep -q "QML2_IMPORT_PATH" ~/.config/fish/config.fish; then
        echo 'set -gx QML2_IMPORT_PATH "$HOME/.local/lib/qt6/qml"' >> ~/.config/fish/config.fish
        echo 'set -gx CAELESTIA_LIB_DIR "$HOME/.local/lib/caelestia"' >> ~/.config/fish/config.fish
    fi
fi

# 6. Bismuth Tiling Engine Compilation & Fallback
step "6. Building and installing Bismuth Tiling Engine..."
BISMUTH_DIR="${REPO_ROOT}/pkgs/kde/bismuth"
BISMUTH_SUCCESS=false
if [[ -d "$BISMUTH_DIR" ]]; then
    info "Preparing Bismuth TypeScript build dependencies..."
    cd "$BISMUTH_DIR"
    if npm install && cmake -S "." -B "build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo; then
        if cmake --build "build"; then
            info "Registering Bismuth KWin tiling extension..."
            if [[ -n "$PLASMAPKG" ]]; then
                "$PLASMAPKG" --type=KWin/Script -r bismuth 2>/dev/null || true
                "$PLASMAPKG" --type=KWin/Script -i build/ 2>/dev/null || true
                ok "Bismuth tiling engine compiled and registered!"
                BISMUTH_SUCCESS=true
            fi
        fi
    fi
fi

if [[ "$BISMUTH_SUCCESS" == "false" ]]; then
    warn "Bismuth compilation skipped or failed (common on Plasma 6/Qt6 systems). Using Krohnkite tiling as active fallback."
fi

# 7. EliverLara Control Station Plasmoid
step "7. Installing EliverLara Control Station Applet..."
CONTROL_STATION_DIR="${REPO_ROOT}/pkgs/kde/kde-control-station"
if [[ -d "$CONTROL_STATION_DIR" ]] && [[ -n "$PLASMAPKG" ]]; then
    info "Registering KDE Control Station plasmoid..."
    "$PLASMAPKG" --type=Plasma/Applet -r controlcentre 2>/dev/null || true
    if "$PLASMAPKG" --type=Plasma/Applet -i "$CONTROL_STATION_DIR"; then
        ok "Control Station Plasmoid installed!"
    else
        warn "Could not register Control Station plasmoid."
    fi
fi

# 8. Blacksuan19 Dotfiles & Konsave
step "8. Deploying Blacksuan19 Custom Dotfiles & Konsave Profile..."
DOTFILES_DIR="${REPO_ROOT}/configs/kde/blacksuan19-dotfiles"
if [[ -d "$DOTFILES_DIR" ]]; then
    info "Installing Konsave..."
    pip install --break-system-packages konsave 2>/dev/null || pip install konsave 2>/dev/null || true
    
    # Deploy profile
    mkdir -p "${HOME}/.config/konsave"
    cp -r "${DOTFILES_DIR}/konsave/.config/konsave/"* "${HOME}/.config/konsave/" 2>/dev/null || true
    
    # Symlink configurations if stow is available
    if command -v stow >/dev/null 2>&1; then
        info "Stowing Blacksuan19 configurations..."
        cd "$DOTFILES_DIR"
        # Stow directories
        for d in fusuma ghostty mpv nvim starship tmux zsh; do
            if [[ -d "$d" ]]; then
                stow "$d" 2>/dev/null || cp -r "$d" "${HOME}/.config/" 2>/dev/null || true
            fi
        done
        ok "Dotfiles stowed."
    fi
    
    if command -v konsave >/dev/null 2>&1; then
        info "Applying Konsave Plasma-Round visual profile..."
        konsave -a Plasma-Round || true
        ok "Visual layout applied!"
    fi
fi

# 8b. Deploying custom wallpapers & live wallpapers
step "8b. Deploying custom wallpapers & live wallpapers to system backgrounds..."
sudo mkdir -p /usr/share/backgrounds/icarus/references
if [[ -d "${REPO_ROOT}/configs/wallpaper/references" ]]; then
    info "Installing wallpapers from repository to /usr/share/backgrounds/icarus/references/..."
    sudo cp -rn "${REPO_ROOT}/configs/wallpaper/references/." /usr/share/backgrounds/icarus/references/ || true
    sudo cp -f "${REPO_ROOT}/configs/wallpaper/references/84.png" /usr/share/backgrounds/icarus/icarus-midnight.png 2>/dev/null || true
fi

# 9. Apply Final Configuration & System Tweaks
step "9. Auto-applying desktop styles..."
if command -v kwriteconfig6 &>/dev/null; then
    info "Setting active color scheme to Sweet..."
    kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "Sweet" 2>/dev/null || true
    
    info "Setting active Plasma desktop theme to Sweet..."
    kwriteconfig6 --file plasmarc --group "Theme" --key "name" "Sweet" 2>/dev/null || true
    
    info "Setting Window Decoration Theme..."
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae" 2>/dev/null || true
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__JuxDeco" 2>/dev/null || true
    
    # Enable tiling script
    if [[ "$BISMUTH_SUCCESS" == "true" ]]; then
        info "Enabling Bismuth tiling engine..."
        kwriteconfig6 --file kwinrc --group "Plugins" --key "bismuthEnabled" "true" 2>/dev/null || true
        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "false" 2>/dev/null || true
    else
        info "Enabling Krohnkite fallback tiling..."
        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "true" 2>/dev/null || true
        kwriteconfig6 --file kwinrc --group "Plugins" --key "bismuthEnabled" "false" 2>/dev/null || true
    fi
    
    # Enable Quickshell KDE bridge
    kwriteconfig6 --file kwinrc --group "Plugins" --key "quickshell-kde-bridgeEnabled" "true" 2>/dev/null || true
    
    # Enable Force Blur if built
    if [[ -d "${REPO_ROOT}/pkgs/kde/kwin-forceblur" ]]; then
        kwriteconfig6 --file kwinrc --group "Plugins" --key "kwin-effects-forceblurEnabled" "true" 2>/dev/null || true
    fi
    
    # Reload KWin & Plasmashell
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    if pgrep -x "plasmashell" >/dev/null; then
        info "Restarting plasmashell to apply configuration..."
        plasmashell --replace >/dev/null 2>&1 &
    fi
    ok "KDE Plasma custom settings configured successfully."
else
    warn "kwriteconfig6 utility not found. Please apply styles manually."
fi

step "Custom KDE Plasma Suite deployment complete!"
info "Quickshell Caelestia UI, Bismuth/Krohnkite tiling, Sweet-kde theme, and Control Station are now installed."
info "Restart or log out and back in to load all components fully."
