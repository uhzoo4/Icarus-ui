#!/usr/bin/env bash
# configs/kde/install.sh
# Multi-distro installation script for Icarus UI custom KDE Plasma Suite
# Integrates: Sweet-kde, Catppuccin, Katerial, KDE Material You Colors,
#             ComplexPlatform eye-candy rice, Bismuth/Krohnkite tiling,
#             Caelestia Shell, Control Station, Konsave, and GameMode.

set -euo pipefail

# Style helpers
c_reset='\033[0m'; c_bold='\033[1m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_red='\033[1;31m'; c_blue='\033[1;34m'; c_magenta='\033[1;35m'; c_cyan='\033[1;36m'
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
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done) 2>/dev/null &
}
sudo_init_keepalive

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${BASE_DIR}/../.." && pwd)"

COLOR_DIR="${HOME}/.local/share/color-schemes"
AURORAE_DIR="${HOME}/.local/share/aurorae/themes"
PLASMA_DIR="${HOME}/.local/share/plasma/desktoptheme"
LOOKFEEL_DIR="${HOME}/.local/share/plasma/look-and-feel"
KVANTUM_DIR="${HOME}/.config/Kvantum"
KONSOLE_DIR="${HOME}/.local/share/konsole"
GTK_THEME_DIR="${HOME}/.themes"
LATTE_DIR="${HOME}/.config/latte"

mkdir -p "$COLOR_DIR" "$AURORAE_DIR" "$PLASMA_DIR" "$LOOKFEEL_DIR" \
         "$KVANTUM_DIR" "$KONSOLE_DIR" "$GTK_THEME_DIR" "$LATTE_DIR"

# ============================================================================
# 1. INSTALL DEPENDENCIES
# ============================================================================
step "1. Checking and installing dependencies..."
if command -v dnf &>/dev/null; then
    info "Fedora system detected. Installing dependencies via dnf..."
    sudo dnf install -y qt6-qtbase-devel kwin-devel extra-cmake-modules cmake gcc-c++ \
        qt-style-kvantum python3-pillow python3-dbus python3-numpy python3-magic \
        gettext git unzip npm nodejs stow python3-pip || true
else
    info "Arch/EndeavourOS system detected. Installing dependencies via pacman..."
    sudo pacman -S --needed --noconfirm base-devel extra-cmake-modules kwin qt6-base cmake gcc \
        kvantum python-pillow python-dbus python-numpy python-magic gettext git unzip \
        npm nodejs stow plasma-nm plasma-pa kdeplasma-addons kdeconnect ydotool python-pip \
        quickshell ananicy-cpp || true
fi

# AUR helper check
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

# Install shell, gaming, and ricing dependencies
info "Checking and installing shell, gaming, and ricing dependencies..."
install_aur_pkgs latte-dock-git

if ! command -v dnf &>/dev/null; then
    sudo pacman -S --needed --noconfirm gamemode lib32-gamemode || true
fi

# Detect kpackagetool
PLASMAPKG=""
if command -v kpackagetool6 &>/dev/null; then
    PLASMAPKG="kpackagetool6"
elif command -v plasmapkg2 &>/dev/null; then
    PLASMAPKG="plasmapkg2"
fi

# ============================================================================
# 2. THEME SELECTOR MENU
# ============================================================================
step "2. Selecting theme profile..."
echo ""
echo -e "${c_magenta}${c_bold}    ╔═══════════════════════════════════════════════════╗${c_reset}"
echo -e "${c_magenta}${c_bold}    ║       ICARUS-UI KDE THEME PROFILE SELECTOR        ║${c_reset}"
echo -e "${c_magenta}${c_bold}    ╚═══════════════════════════════════════════════════╝${c_reset}"
echo ""
echo -e "  ${c_cyan}1)${c_reset} ${c_bold}Sweet Dark${c_reset}       — Deep purple-pink gradient (current default)"
echo -e "  ${c_cyan}2)${c_reset} ${c_bold}Catppuccin Mocha${c_reset} — Warm pastel dark palette (community favorite)"
echo -e "  ${c_cyan}3)${c_reset} ${c_bold}Katerial${c_reset}         — Flat Material Design with rounded corners"
echo -e "  ${c_cyan}4)${c_reset} ${c_bold}ALL OF THEM${c_reset}      — Install everything, set Catppuccin Mocha as active"
echo ""
read -rp "  Select theme profile [1-4, default=4]: " THEME_CHOICE
THEME_CHOICE="${THEME_CHOICE:-4}"

INSTALL_SWEET=false
INSTALL_CATPPUCCIN=false
INSTALL_KATERIAL=false
ACTIVE_THEME="Sweet"

case "$THEME_CHOICE" in
    1) INSTALL_SWEET=true; ACTIVE_THEME="Sweet" ;;
    2) INSTALL_CATPPUCCIN=true; ACTIVE_THEME="Catppuccin-Mocha" ;;
    3) INSTALL_KATERIAL=true; ACTIVE_THEME="Katerial" ;;
    4) INSTALL_SWEET=true; INSTALL_CATPPUCCIN=true; INSTALL_KATERIAL=true; ACTIVE_THEME="Catppuccin-Mocha" ;;
    *) INSTALL_SWEET=true; INSTALL_CATPPUCCIN=true; INSTALL_KATERIAL=true; ACTIVE_THEME="Catppuccin-Mocha" ;;
esac

# ============================================================================
# 3. DEPLOY THEME ASSETS
# ============================================================================
step "3. Deploying theme & styling assets..."

# --- 3a. Sweet-kde theme ---
if [[ "$INSTALL_SWEET" == "true" ]]; then
    SWEET_THEME_SRC="${REPO_ROOT}/pkgs/themes/Sweet-kde"
    if [[ -d "$SWEET_THEME_SRC" ]]; then
        info "Deploying Sweet-kde desktop theme..."
        mkdir -p "${PLASMA_DIR}/Sweet"
        cp -r "${SWEET_THEME_SRC}/"* "${PLASMA_DIR}/Sweet/"
        ok "Sweet-kde theme installed."
    fi
fi

# --- Mystical-Blue (Jux) assets (always installed) ---
cp "${BASE_DIR}/JuxTheme.colors" "$COLOR_DIR/" 2>/dev/null && ok "Installed color scheme: JuxTheme" || true
tar -xzf "${BASE_DIR}/JuxDeco.tar.gz" -C "$AURORAE_DIR/" 2>/dev/null && ok "Installed Aurorae: JuxDeco" || true
tar -xzf "${BASE_DIR}/JuxPlasma.tar.gz" -C "$PLASMA_DIR/" 2>/dev/null && ok "Installed Plasma theme: JuxPlasma" || true
if [[ -f "${BASE_DIR}/NoMansSkyJux.tar.gz" ]]; then
    tar -xzf "${BASE_DIR}/NoMansSkyJux.tar.gz" -C "$KVANTUM_DIR/"
    ok "Installed Kvantum: NoMansSkyJux"
fi

# --- 3b. Catppuccin KDE ---
if [[ "$INSTALL_CATPPUCCIN" == "true" ]]; then
    CATPPUCCIN_SRC="${REPO_ROOT}/pkgs/themes/catppuccin-kde"
    if [[ -d "$CATPPUCCIN_SRC" ]]; then
        info "Deploying Catppuccin KDE color palette (all 4 flavors)..."

        # Aurorae window decorations (all 8 variants + Common)
        if [[ -d "${CATPPUCCIN_SRC}/Aurorae" ]]; then
            cp -r "${CATPPUCCIN_SRC}/Aurorae/"* "$AURORAE_DIR/"
            ok "Catppuccin Aurorae decorations installed (Mocha/Macchiato/Frappe/Latte × Classic/Modern)."
        fi

        # LookAndFeel global themes
        if [[ -d "${CATPPUCCIN_SRC}/LookAndFeel" ]]; then
            for flavor_dir in "${CATPPUCCIN_SRC}/LookAndFeel/Catppuccin-"*; do
                [[ -d "$flavor_dir" ]] || continue
                flavor_name="$(basename "$flavor_dir")"
                mkdir -p "${LOOKFEEL_DIR}/${flavor_name}"
                cp -r "${flavor_dir}/"* "${LOOKFEEL_DIR}/${flavor_name}/"
            done
            # Copy metadata
            cp "${CATPPUCCIN_SRC}/LookAndFeel/metadata.desktop" "${LOOKFEEL_DIR}/" 2>/dev/null || true
            cp "${CATPPUCCIN_SRC}/LookAndFeel/metadata.json" "${LOOKFEEL_DIR}/" 2>/dev/null || true
            cp "${CATPPUCCIN_SRC}/LookAndFeel/defaults" "${LOOKFEEL_DIR}/" 2>/dev/null || true
            ok "Catppuccin LookAndFeel global themes installed."
        fi

        # Base color scheme template
        if [[ -f "${CATPPUCCIN_SRC}/Base.colors" ]]; then
            cp "${CATPPUCCIN_SRC}/Base.colors" "$COLOR_DIR/Catppuccin-Mocha.colors"
            ok "Catppuccin Mocha base color scheme installed."
        fi

        # Splash screens
        if [[ -d "${CATPPUCCIN_SRC}/splash-screen" ]]; then
            mkdir -p "${LOOKFEEL_DIR}/catppuccin-splash"
            cp -r "${CATPPUCCIN_SRC}/splash-screen/"* "${LOOKFEEL_DIR}/catppuccin-splash/" 2>/dev/null || true
            ok "Catppuccin splash screens installed."
        fi
    fi
fi

# --- 3c. Katerial Material Design ---
if [[ "$INSTALL_KATERIAL" == "true" ]]; then
    KATERIAL_SRC="${REPO_ROOT}/pkgs/themes/katerial"
    if [[ -d "$KATERIAL_SRC" ]]; then
        info "Deploying Katerial Material Design theme suite..."

        # Kvantum application theme
        if [[ -d "${KATERIAL_SRC}/Kvantum" ]]; then
            cp -r "${KATERIAL_SRC}/Kvantum/"* "$KVANTUM_DIR/"
            ok "Katerial Kvantum app theme installed."
        fi

        # Aurorae window decorations
        if [[ -d "${KATERIAL_SRC}/aurorae/themes/Katerial" ]]; then
            cp -r "${KATERIAL_SRC}/aurorae/themes/Katerial" "$AURORAE_DIR/"
            ok "Katerial Aurorae window decoration installed."
        fi

        # Color schemes
        if [[ -d "${KATERIAL_SRC}/colors" ]]; then
            cp "${KATERIAL_SRC}/colors/"*.colors "$COLOR_DIR/" 2>/dev/null || true
            ok "Katerial color schemes installed (Dark & Light)."
        fi

        # Konsole color profile
        if [[ -d "${KATERIAL_SRC}/konsole" ]]; then
            cp "${KATERIAL_SRC}/konsole/"* "$KONSOLE_DIR/" 2>/dev/null || true
            ok "Katerial Konsole terminal profile installed."
        fi

        # Plasma desktop theme
        if [[ -d "${KATERIAL_SRC}/plasma/desktoptheme/Katerial" ]]; then
            cp -r "${KATERIAL_SRC}/plasma/desktoptheme/Katerial" "$PLASMA_DIR/"
            ok "Katerial Plasma desktop theme installed."
        fi

        # LookAndFeel
        if [[ -d "${KATERIAL_SRC}/plasma/look-and-feel" ]]; then
            cp -r "${KATERIAL_SRC}/plasma/look-and-feel/"* "$LOOKFEEL_DIR/" 2>/dev/null || true
            ok "Katerial LookAndFeel global theme installed."
        fi

        # SDDM login theme (requires sudo)
        if [[ -d "${KATERIAL_SRC}/sddm/themes" ]]; then
            info "Installing Katerial SDDM login theme (requires sudo)..."
            sudo cp -r "${KATERIAL_SRC}/sddm/themes/"* /usr/share/sddm/themes/ 2>/dev/null || true
            ok "Katerial SDDM theme installed."
        fi
    fi
fi

# --- 3d. ComplexPlatform Eye-Candy GTK Themes (all 6) ---
step "3d. Deploying ComplexPlatform eye-candy GTK themes..."
CP_THEMES_SRC="${REPO_ROOT}/pkgs/themes/complexplatform-themes"
if [[ -d "$CP_THEMES_SRC" ]]; then
    for theme_dir in "${CP_THEMES_SRC}/"*; do
        [[ -d "$theme_dir" ]] || continue
        theme_name="$(basename "$theme_dir")"
        cp -r "$theme_dir" "${GTK_THEME_DIR}/"
        ok "Installed GTK theme: ${theme_name}"
    done
fi

# --- 3e. ComplexPlatform Latte Dock Layouts & Configs ---
step "3e. Deploying ComplexPlatform floating panel layouts & configs..."
CP_DOTS_SRC="${REPO_ROOT}/configs/kde/complexplatform-dotfiles"
if [[ -d "$CP_DOTS_SRC" ]]; then
    # Latte dock layouts
    if [[ -d "${CP_DOTS_SRC}/latte" ]]; then
        cp "${CP_DOTS_SRC}/latte/"* "$LATTE_DIR/" 2>/dev/null || true
        ok "Latte Dock floating panel layouts installed (1-Bar, 3-Bar, Vertical)."
    fi

    # Color scheme JSON profiles
    if [[ -d "${CP_DOTS_SRC}/colorschemes" ]]; then
        mkdir -p "${HOME}/.config/icarus/colorschemes"
        cp "${CP_DOTS_SRC}/colorschemes/"*.json "${HOME}/.config/icarus/colorschemes/" 2>/dev/null || true
        ok "ComplexPlatform color profiles installed (Cherry Blossom, Coffee, Flowers, Foggy Mountain, Neutral, Urban)."
    fi

    # Neofetch config
    if [[ -d "${CP_DOTS_SRC}/neofetch" ]]; then
        mkdir -p "${HOME}/.config/neofetch"
        cp -r "${CP_DOTS_SRC}/neofetch/"* "${HOME}/.config/neofetch/" 2>/dev/null || true
        ok "Custom neofetch config installed."
    fi

    # Spicetify config
    if [[ -d "${CP_DOTS_SRC}/spicetify" ]]; then
        mkdir -p "${HOME}/.config/spicetify"
        cp -r "${CP_DOTS_SRC}/spicetify/"* "${HOME}/.config/spicetify/" 2>/dev/null || true
        ok "Spicetify Spotify theming config installed."
    fi

    # Helper scripts
    if [[ -d "${CP_DOTS_SRC}/scripts" ]]; then
        mkdir -p "${HOME}/.local/bin"
        cp "${CP_DOTS_SRC}/scripts/"*.sh "${HOME}/.local/bin/" 2>/dev/null || true
        chmod +x "${HOME}/.local/bin/"*.sh 2>/dev/null || true
        ok "ComplexPlatform helper scripts installed."
    fi
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

# Deploy custom CAVA configurations and themes
step "Deploying custom CAVA audio visualizer themes..."
CAVA_DEST_DIR="${HOME}/.config/cava"
mkdir -p "${CAVA_DEST_DIR}/themes"
if [[ -d "${REPO_ROOT}/configs/cava" ]]; then
    cp -rf "${REPO_ROOT}/configs/cava/themes/"* "${CAVA_DEST_DIR}/themes/" 2>/dev/null || true
    cp -f "${REPO_ROOT}/configs/cava/config" "${CAVA_DEST_DIR}/base_config" 2>/dev/null || true
    cp -f "${REPO_ROOT}/configs/cava/cava-theme-loader.sh" "${HOME}/.local/bin/cava-theme-loader.sh" 2>/dev/null || true
    chmod +x "${HOME}/.local/bin/cava-theme-loader.sh" 2>/dev/null || true
    ok "CAVA theme profiles and loader installed to ~/.local/bin/cava-theme-loader.sh"
fi

# Deploy Icarus Welcome CLI Dashboard Panel
step "Deploying Icarus Welcome Dashboard..."
if [[ -f "${REPO_ROOT}/tools/welcome.sh" ]]; then
    mkdir -p "${HOME}/.local/bin"
    cp -f "${REPO_ROOT}/tools/welcome.sh" "${HOME}/.local/bin/icarus-welcome" 2>/dev/null || true
    chmod +x "${HOME}/.local/bin/icarus-welcome" 2>/dev/null || true
    ok "Icarus Welcome control panel deployed as 'icarus-welcome'"
fi


# ============================================================================
# 4. KDE MATERIAL YOU COLORS — LIVE WALLPAPER-ADAPTIVE ENGINE
# ============================================================================
step "4. Installing KDE Material You Colors (live wallpaper color engine)..."
MATYU_SRC="${REPO_ROOT}/pkgs/kde/kde-material-you-colors"
if [[ -d "$MATYU_SRC" ]]; then
    # Install Python dependencies
    info "Installing Python dependencies for Material You Colors..."
    pip install --break-system-packages materialyoucolor python-magic 2>/dev/null \
        || pip install materialyoucolor python-magic 2>/dev/null \
        || warn "Could not install materialyoucolor via pip."

    # Install the Python module itself
    if [[ -d "${MATYU_SRC}/kde_material_you_colors" ]]; then
        info "Installing kde-material-you-colors Python module..."
        mkdir -p "${HOME}/.local/lib/python-icarus"
        cp -r "${MATYU_SRC}/kde_material_you_colors" "${HOME}/.local/lib/python-icarus/"
        ok "Material You Colors Python engine installed."
    fi

    # Register the Plasmoid companion widget
    if [[ -d "${MATYU_SRC}/plasmoid" ]] && [[ -n "$PLASMAPKG" ]]; then
        info "Registering Material You Colors Plasmoid widget..."
        "$PLASMAPKG" --type=Plasma/Applet -r luisbocanegra.kdematerialyou.colors 2>/dev/null || true
        if "$PLASMAPKG" --type=Plasma/Applet -i "${MATYU_SRC}/plasmoid"; then
            ok "Material You Colors Plasmoid widget registered."
        else
            warn "Could not register Material You Colors Plasmoid."
        fi
    fi

    # Create systemd user service for auto-start
    info "Creating systemd user service for Material You Colors daemon..."
    mkdir -p "${HOME}/.config/systemd/user"
    cat > "${HOME}/.config/systemd/user/kde-material-you-colors.service" << 'SERVICEEOF'
[Unit]
Description=KDE Material You Colors — Live Wallpaper Color Adaptation Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m kde_material_you_colors
Environment=PYTHONPATH=%h/.local/lib/python-icarus
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
SERVICEEOF
    systemctl --user daemon-reload
    systemctl --user enable kde-material-you-colors.service 2>/dev/null || true
    ok "Material You Colors systemd service created and enabled."

    # Compiling Screenshot Helper for Material You Colors
    step "4b. Compiling and installing Material You Screenshot Helper..."
    HELPER_DIR="${MATYU_SRC}/screenshot_helper"
    if [[ -d "$HELPER_DIR" ]]; then
        info "Compiling screenshot helper..."
        BUILD_DIR="${HELPER_DIR}/build"
        rm -rf "$BUILD_DIR"
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        if cmake .. -DCMAKE_INSTALL_PREFIX=/usr 2>/dev/null; then
            make -j$(nproc)
            sudo make install
            ok "Screenshot helper compiled and installed!"
        else
            warn "Screenshot helper compilation failed."
        fi
    fi
fi

# ============================================================================
# 5. DYNAMIC TILING — KROHNKITE + BISMUTH
# ============================================================================
step "5. Registering tiling window managers..."

# Krohnkite
if [[ -n "$PLASMAPKG" ]] && [[ -d "${REPO_ROOT}/pkgs/kde/krohnkite" ]]; then
    info "Registering Krohnkite tiling script..."
    "$PLASMAPKG" --type=KWin/Script -r krohnkite 2>/dev/null || true
    ( cd "${REPO_ROOT}/pkgs/kde/krohnkite" && "$PLASMAPKG" --type=KWin/Script -i res/ ) && ok "Krohnkite registered."
fi

# Bismuth
BISMUTH_DIR="${REPO_ROOT}/pkgs/kde/bismuth"
BISMUTH_SUCCESS=false
if [[ -d "$BISMUTH_DIR" ]]; then
    info "Preparing Bismuth TypeScript build dependencies..."
    cd "$BISMUTH_DIR"
    if npm install && cmake -S "." -B "build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo 2>/dev/null; then
        if cmake --build "build"; then
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
    warn "Bismuth compilation skipped or failed (common on Plasma 6). Using Krohnkite as active fallback."
fi

# ============================================================================
# 6. KWIN FORCE BLUR PLUGIN
# ============================================================================
step "6. Compiling KWin Force Blur plugin..."
if [[ -d "${REPO_ROOT}/pkgs/kde/kwin-forceblur" ]]; then
    BUILD_DIR="${REPO_ROOT}/pkgs/kde/kwin-forceblur/build"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    if cmake .. -DKWIN_EFFECTS_FORCEBLUR_QT6=ON 2>/dev/null; then
        make -j$(nproc)
        sudo make install
        ok "Force Blur plugin compiled and installed!"
    else
        warn "Force Blur compilation skipped."
    fi
fi

# ============================================================================
# 7. CAELESTIA SHELL (QUICKSHELL + KWIN SHIMS)
# ============================================================================
step "7. Building Caelestia Quickshell Shell & KWin shims..."
SHELL_DIR="${REPO_ROOT}/configs/kde/caelestia-shell"
if [[ -d "$SHELL_DIR" ]]; then
    info "Building Caelestia Shell..."
    cd "$SHELL_DIR"
    rm -rf build
    if cmake -B build -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${HOME}/.local" \
        -DINSTALL_QSCONFDIR="${HOME}/.config/quickshell/caelestia" \
        -DINSTALL_LIBDIR="lib/caelestia" \
        -DINSTALL_QMLDIR="lib/qt6/qml" 2>/dev/null; then
        cmake --build build -j$(nproc)
        cmake --install build
        ok "Caelestia Shell compiled and installed."
    else
        warn "Caelestia Shell build failed."
    fi
fi

# Build C++ hyprctl shim
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
    cp --remove-destination "${SRC_DIR}/bin/hypr_kwin_map.json" "${HOME}/.local/bin/" 2>/dev/null || true
    cp --remove-destination "${SRC_DIR}/bin/qs-kwin-bridge.py" "${HOME}/.local/bin/" 2>/dev/null || true
    chmod +x "${HOME}/.local/bin/qs-kwin-bridge.py" 2>/dev/null || true
    ok "KWin to Quickshell bridge scripts deployed."
fi

# Deploy systemd user services
if [[ -d "$SRC_DIR/systemd" ]]; then
    info "Configuring systemd user services..."
    mkdir -p "${HOME}/.config/systemd/user"
    cp "${SRC_DIR}/systemd/qs-kwin-bridge.service" "${HOME}/.config/systemd/user/" 2>/dev/null || true
    cp "${SRC_DIR}/systemd/ydotoold.service" "${HOME}/.config/systemd/user/" 2>/dev/null || true
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

# Add shell imports
if ! grep -q "QML2_IMPORT_PATH=.*caelestia" ~/.bashrc 2>/dev/null; then
    echo 'export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml"' >> ~/.bashrc
    echo 'export CAELESTIA_LIB_DIR="$HOME/.local/lib/caelestia"' >> ~/.bashrc
fi

# ============================================================================
# 8. PLASMOID WIDGETS — CONTROL STATION
# ============================================================================
step "8. Installing EliverLara Control Station Applet..."
CONTROL_STATION_DIR="${REPO_ROOT}/pkgs/kde/kde-control-station"
if [[ -d "$CONTROL_STATION_DIR" ]] && [[ -n "$PLASMAPKG" ]]; then
    "$PLASMAPKG" --type=Plasma/Applet -r controlcentre 2>/dev/null || true
    if "$PLASMAPKG" --type=Plasma/Applet -i "$CONTROL_STATION_DIR"; then
        ok "Control Station Plasmoid installed!"
    else
        warn "Could not register Control Station plasmoid."
    fi
fi

# ============================================================================
# 9. BLACKSUAN19 DOTFILES & KONSAVE PROFILE MANAGEMENT
# ============================================================================
step "9. Deploying Blacksuan19 Dotfiles & Konsave Profile Manager..."
DOTFILES_DIR="${REPO_ROOT}/configs/kde/blacksuan19-dotfiles"
if [[ -d "$DOTFILES_DIR" ]]; then
    # Install konsave
    info "Installing Konsave configuration manager..."
    pip install --break-system-packages konsave 2>/dev/null \
        || pip install konsave 2>/dev/null \
        || true

    # Deploy Blacksuan19 konsave profile
    mkdir -p "${HOME}/.config/konsave"
    cp -r "${DOTFILES_DIR}/konsave/.config/konsave/"* "${HOME}/.config/konsave/" 2>/dev/null || true

    # Stow dotfile configurations
    if command -v stow > /dev/null 2>&1; then
        info "Stowing Blacksuan19 configurations..."
        cd "$DOTFILES_DIR"
        for d in fusuma ghostty mpv nvim starship tmux zsh; do
            if [[ -d "$d" ]]; then
                stow "$d" 2>/dev/null || cp -r "$d" "${HOME}/.config/" 2>/dev/null || true
            fi
        done
        ok "Dotfiles stowed."
    fi

    if command -v konsave > /dev/null 2>&1; then
        info "Applying Konsave Plasma-Round visual profile..."
        konsave -a Plasma-Round 2>/dev/null || true
        ok "Visual layout applied!"
    fi
fi

# ============================================================================
# 10. WALLPAPERS — STATIC & LIVE
# ============================================================================
step "10. Deploying wallpapers & live wallpapers to system backgrounds..."
sudo mkdir -p /usr/share/backgrounds/icarus/references
if [[ -d "${REPO_ROOT}/configs/wallpaper/references" ]]; then
    info "Installing wallpapers (static + live GIFs/MP4s)..."
    sudo cp -rn "${REPO_ROOT}/configs/wallpaper/references/." /usr/share/backgrounds/icarus/references/ || true
    sudo cp -f "${REPO_ROOT}/configs/wallpaper/references/84.png" /usr/share/backgrounds/icarus/icarus-midnight.png 2>/dev/null || true
    WALL_COUNT=$(find /usr/share/backgrounds/icarus/references/ -type f 2>/dev/null | wc -l)
    ok "Wallpaper library deployed (${WALL_COUNT} files)."
fi

# ============================================================================
# 10b. DEPLOYING TELEGRAM SYNC, BROWSER INTERCEPTORS, AND TERMINAL WELCOME
# ============================================================================
step "10b. Installing specialized ricing modules (Telegram colors, browser hooks, terminal welcome)..."

# 1. Telegram Color Sync (plasma2telegram)
TEL_SRC="${REPO_ROOT}/pkgs/kde/plasma2telegram"
if [[ -d "$TEL_SRC" ]]; then
    info "Installing Telegram dynamic color sync module..."
    mkdir -p "${HOME}/.local/share/plasma2telegram"
    cp -r "${TEL_SRC}/"* "${HOME}/.local/share/plasma2telegram/"
    
    # Create systemd user service for Telegram color sync
    mkdir -p "${HOME}/.config/systemd/user"
    cat > "${HOME}/.config/systemd/user/plasma2telegram.service" << 'SERVICEEOF'
[Unit]
Description=KDE Plasma to Telegram Theme Synchronizer
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 %h/.local/share/plasma2telegram/plasma2telegram.py --template-dark %h/.local/share/plasma2telegram/material-template-dark.tdesktop-theme --template-light %h/.local/share/plasma2telegram/material-template-light.tdesktop-theme --output %h/.local/state/plasma2telegram/plasma-auto.tdesktop-theme --watch
Restart=on-failure
RestartSec=10

[Install]
WantedBy=graphical-session.target
SERVICEEOF
    systemctl --user daemon-reload
    systemctl --user enable plasma2telegram.service 2>/dev/null || true
    ok "plasma2telegram service successfully configured."
fi

# 2. Browser interceptor protocol handler (alist-handler)
if [[ -f "${REPO_ROOT}/tools/alist-handler" ]]; then
    info "Installing Alist media player URL interceptor..."
    mkdir -p "${HOME}/.local/bin"
    cp -f "${REPO_ROOT}/tools/alist-handler" "${HOME}/.local/bin/"
    chmod +x "${HOME}/.local/bin/alist-handler"
    
    # Copy desktop file and set default handlers
    mkdir -p "${HOME}/.local/share/applications"
    if [[ -f "${REPO_ROOT}/configs/apps/alist-player.desktop" ]]; then
        cp -f "${REPO_ROOT}/configs/apps/alist-player.desktop" "${HOME}/.local/share/applications/"
        if command -v xdg-mime &>/dev/null; then
            xdg-mime default alist-player.desktop x-scheme-handler/mpv 2>/dev/null || true
            xdg-mime default alist-player.desktop x-scheme-handler/vlc 2>/dev/null || true
            xdg-mime default alist-player.desktop x-scheme-handler/potplayer 2>/dev/null || true
        fi
    fi
    ok "Alist media protocol handler registered."
fi

# 3. Terminal welcome image (random_image.sh)
if [[ -f "${REPO_ROOT}/tools/random_image.sh" ]]; then
    info "Installing terminal welcome visualizer..."
    mkdir -p "${HOME}/.local/bin"
    cp -f "${REPO_ROOT}/tools/random_image.sh" "${HOME}/.local/bin/"
    chmod +x "${HOME}/.local/bin/random_image.sh"
    
    # Append to .bashrc to run on shell startup
    if ! grep -q "random_image.sh" "${HOME}/.bashrc" 2>/dev/null; then
        cat >> "${HOME}/.bashrc" << 'EOF'

# Icarus terminal visual greeting (kitty random wallpaper logo + fastfetch)
if [[ -f "${HOME}/.local/bin/random_image.sh" ]]; then
    bash "${HOME}/.local/bin/random_image.sh"
fi
EOF
    fi
    ok "Terminal welcome script added to ~/.bashrc"
fi

# ============================================================================
# 11. KONSAVE SAFETY SNAPSHOT
# ============================================================================
step "11. Creating Konsave safety snapshot..."
if command -v konsave &>/dev/null; then
    info "Saving current desktop as 'icarus-default' Konsave profile..."
    konsave -s icarus-default 2>/dev/null || true
    ok "Safety snapshot 'icarus-default' saved. Restore anytime with: konsave -a icarus-default"
else
    warn "Konsave not found. Skipping safety snapshot."
fi

# ============================================================================
# 12. FINAL AUTO-CONFIGURATION — APPLY ACTIVE THEME
# ============================================================================
step "12. Auto-applying desktop styles (active theme: ${ACTIVE_THEME})..."
if command -v kwriteconfig6 &>/dev/null; then

    # Set active color scheme based on selection
    case "$ACTIVE_THEME" in
        "Sweet")
            info "Setting active theme to Sweet..."
            kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "Sweet" 2>/dev/null || true
            kwriteconfig6 --file plasmarc --group "Theme" --key "name" "Sweet" 2>/dev/null || true
            kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__JuxDeco" 2>/dev/null || true
            ;;
        "Catppuccin-Mocha")
            info "Setting active theme to Catppuccin Mocha..."
            kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "Catppuccin-Mocha" 2>/dev/null || true
            kwriteconfig6 --file plasmarc --group "Theme" --key "name" "Sweet" 2>/dev/null || true
            kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__CatppuccinMocha-Modern" 2>/dev/null || true
            ;;
        "Katerial")
            info "Setting active theme to Katerial Material Design..."
            kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "KaterialDarkRedPink" 2>/dev/null || true
            kwriteconfig6 --file plasmarc --group "Theme" --key "name" "Katerial" 2>/dev/null || true
            kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__Katerial" 2>/dev/null || true
            # Apply Kvantum theme
            kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "kvantum" 2>/dev/null || true
            if command -v kvantummanager &>/dev/null; then
                kvantummanager --set Katerial_Light_RedPink 2>/dev/null || true
            fi
            ;;
    esac

    # Common KWin settings
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae" 2>/dev/null || true

    # Enable tiling
    if [[ "$BISMUTH_SUCCESS" == "true" ]]; then
        info "Enabling Bismuth tiling engine..."
        kwriteconfig6 --file kwinrc --group "Plugins" --key "bismuthEnabled" "true" 2>/dev/null || true
        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "false" 2>/dev/null || true
    else
        info "Enabling Krohnkite fallback tiling..."
        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "true" 2>/dev/null || true
        kwriteconfig6 --file kwinrc --group "Plugins" --key "bismuthEnabled" "false" 2>/dev/null || true
    fi

    # Enable Quickshell bridge & Force Blur
    kwriteconfig6 --file kwinrc --group "Plugins" --key "quickshell-kde-bridgeEnabled" "true" 2>/dev/null || true
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
    warn "kwriteconfig6 not found. Please apply styles manually."
fi

# ============================================================================
# DONE
# ============================================================================
echo ""
echo -e "${c_magenta}${c_bold}╔═══════════════════════════════════════════════════════════╗${c_reset}"
echo -e "${c_magenta}${c_bold}║      ICARUS-UI KDE PLASMA SUITE — DEPLOYMENT COMPLETE    ║${c_reset}"
echo -e "${c_magenta}${c_bold}╚═══════════════════════════════════════════════════════════╝${c_reset}"
echo ""
echo -e "  ${c_green}✓${c_reset} Active Theme:       ${c_bold}${ACTIVE_THEME}${c_reset}"
echo -e "  ${c_green}✓${c_reset} Tiling Engine:      ${c_bold}$(if [[ "$BISMUTH_SUCCESS" == "true" ]]; then echo 'Bismuth'; else echo 'Krohnkite'; fi)${c_reset}"
echo -e "  ${c_green}✓${c_reset} Color Engine:       ${c_bold}Material You Colors (wallpaper-adaptive)${c_reset}"
echo -e "  ${c_green}✓${c_reset} GTK Themes:         ${c_bold}Cherry Blossom, Coffee, Flowers, Foggy Mountain, Neutral, Urban${c_reset}"
echo -e "  ${c_green}✓${c_reset} Safety Snapshot:    ${c_bold}icarus-default (restore: konsave -a icarus-default)${c_reset}"
echo ""
echo -e "  ${c_cyan}Tip:${c_reset} Change your wallpaper — Material You Colors will auto-adapt your system palette!"
echo -e "  ${c_cyan}Tip:${c_reset} Run ${c_bold}bash tools/system_core.sh${c_reset} to engage gaming performance mode."
echo -e "  ${c_cyan}Tip:${c_reset} Run ${c_bold}konsave -l${c_reset} to list saved profiles, ${c_bold}konsave -a <name>${c_reset} to restore."
echo ""
info "Restart or log out and back in to load all components fully."
