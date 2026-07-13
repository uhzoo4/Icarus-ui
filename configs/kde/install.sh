#!/usr/bin/env bash
# configs/kde/install.sh
# Multi-distro installation script for Icarus UI KDE Plasma Variant (Fedora & CachyOS/Arch)

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
        qt-style-kvantum python3-pillow gettext git unzip || true
else
    info "Arch/CachyOS system detected. Installing dependencies via pacman..."
    sudo pacman -S --needed --noconfirm extra-cmake-modules kwin qt6-base cmake gcc \
        kvantum python-pillow gettext git unzip || true
fi

# 2. Extract and Copy Themes
step "2. Extracting and deploying Mystical-Blue (Jux) assets..."
cp "${BASE_DIR}/JuxTheme.colors" "$COLOR_DIR/" && ok "Installed color scheme: JuxTheme"
tar -xzf "${BASE_DIR}/JuxDeco.tar.gz" -C "$AURORAE_DIR/" && ok "Installed Aurorae window decorations: JuxDeco"
tar -xzf "${BASE_DIR}/JuxPlasma.tar.gz" -C "$PLASMA_DIR/" && ok "Installed Plasma desktop theme: JuxPlasma"

if [[ -f "${BASE_DIR}/NoMansSkyJux.tar.gz" ]]; then
    tar -xzf "${BASE_DIR}/NoMansSkyJux.tar.gz" -C "$KVANTUM_DIR/"
    ok "Installed Kvantum styling template: NoMansSkyJux"
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

# 3. Dynamic Tiling - Krohnkite
step "3. Setting up dynamic window tiling (Krohnkite)..."
PLASMAPKG=""
if command -v kpackagetool6 &>/dev/null; then
    PLASMAPKG="kpackagetool6"
elif command -v plasmapkg2 &>/dev/null; then
    PLASMAPKG="plasmapkg2"
fi

if [[ -n "$PLASMAPKG" ]] && [[ -d "${REPO_ROOT}/pkgs/kde/krohnkite" ]]; then
    info "Installing Krohnkite KWin tiling extension using ${PLASMAPKG}..."
    # Remove existing script first if installed to avoid conflict
    "$PLASMAPKG" --type=KWin/Script -r krohnkite 2>/dev/null || true
    # Install krohnkite
    ( cd "${REPO_ROOT}/pkgs/kde/krohnkite" && "$PLASMAPKG" --type=KWin/Script -i res/ ) && ok "Krohnkite tiling script registered!"
else
    warn "kpackagetool6/plasmapkg2 not found, or krohnkite source files are missing. Skipping tiling setup."
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

# 5. Automatically Apply KDE Plasma Theme & Decoration Configuration
step "5. Auto-applying KDE Plasma configuration (Jux Variant)..."
if command -v kwriteconfig6 &>/dev/null; then
    info "Applying Jux color scheme..."
    kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "JuxTheme" 2>/dev/null || true
    
    info "Applying Jux Plasma desktop theme..."
    kwriteconfig6 --file plasmarc --group "Theme" --key "name" "JuxPlasma" 2>/dev/null || true
    
    info "Applying Jux window decoration borders..."
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae" 2>/dev/null || true
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__JuxDeco" 2>/dev/null || true
    
    # Configure Kvantum to use NoMansSkyJux
    if command -v kvantummanager &>/dev/null; then
        info "Applying NoMansSkyJux Kvantum theme..."
        kvantummanager --set NoMansSkyJux 2>/dev/null || true
        kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "kvantum" 2>/dev/null || true
    fi
    
    # Auto-enable tiling scripts if successfully registered
    if [[ -n "${PLASMAPKG:-}" ]]; then
        info "Enabling Krohnkite tiling..."
        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "true" 2>/dev/null || true
    fi
    
    # Auto-enable KWin Force Blur if built
    if [[ -d "${REPO_ROOT}/pkgs/kde/kwin-forceblur" ]]; then
        info "Enabling KWin Force Blur plugin..."
        kwriteconfig6 --file kwinrc --group "Plugins" --key "kwin-effects-forceblurEnabled" "true" 2>/dev/null || true
    fi
    
    # Force KWin configuration reload
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    if pgrep -x "plasmashell" >/dev/null; then
        info "Restarting plasmashell to apply desktop styles..."
        plasmashell --replace >/dev/null 2>&1 &
    fi
    ok "KDE settings applied dynamically."
else
    warn "kwriteconfig6 utility not found. Please apply theme elements manually in System Settings."
fi

step "KDE Plasma theme variant deployment complete!"
info "Jux Theme has been applied dynamically to your desktop."
info "Enable Krohnkite tiling in System Settings -> Window Management -> KWin Scripts if needed."
