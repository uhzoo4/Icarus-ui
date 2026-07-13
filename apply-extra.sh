#!/usr/bin/env bash
# apply-extra.sh
#
# Helper script to apply the newly integrated EXTRA themes, cursors,
# wallpapers, and dynamic video palette upgrades directly to an already booted system.
#
# Run this as your normal user (it will prompt for sudo when necessary).

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

REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "${REPO_PATH}/apply-extra.sh" ]]; then
    err "This script must be executed from inside the icarus-archos repository root."
    exit 1
fi

# Multi-distro package installer helper
install_pkgs() {
    local pkgs=("$@")
    if command -v dnf &>/dev/null; then
        local dnf_pkgs=()
        for pkg in "${pkgs[@]}"; do
            case "$pkg" in
                qt5-wayland) dnf_pkgs+=("qt5-qtwayland") ;;
                qt6-wayland) dnf_pkgs+=("qt6-qtwayland") ;;
                polkit-kde-agent) dnf_pkgs+=("polkit-kde") ;;
                ttf-jetbrains-mono-nerd) dnf_pkgs+=("jetbrains-mono-fonts") ;;
                noto-fonts) dnf_pkgs+=("google-noto-sans-fonts") ;;
                noto-fonts-emoji) dnf_pkgs+=("google-noto-emoji-fonts") ;;
                qt6-5compat) dnf_pkgs+=("qt6-qt5compat") ;;
                qt6-declarative) dnf_pkgs+=("qt6-qtdeclarative") ;;
                qt6-svg) dnf_pkgs+=("qt6-qtsvg") ;;
                qt6-multimedia-ffmpeg) dnf_pkgs+=("qt6-qtmultimedia") ;;
                ffmpeg) dnf_pkgs+=("ffmpeg-free") ;;
                bluez-utils) ;; # Integrated in bluez on Fedora
                pamixer) ;; # Unavailable, we use wpctl
                python-pillow) dnf_pkgs+=("python3-pillow") ;;
                wine-staging) dnf_pkgs+=("wine") ;;
                winetricks) dnf_pkgs+=("winetricks") ;;
                fd) dnf_pkgs+=("fd-find") ;;
                libreoffice-fresh) dnf_pkgs+=("libreoffice") ;;
                hunspell-en_us) dnf_pkgs+=("hunspell-en-US") ;;
                giflib|lib32-giflib|libpng|lib32-libpng|libldap|lib32-libldap|gnutls|lib32-gnutls|mpg123|lib32-mpg123|openal|lib32-openal|v4l-utils|lib32-v4l-utils|libclc|libxkbcommon|lib32-libxkbcommon) ;;
                adw-gtk-theme) dnf_pkgs+=("adw-gtk3-theme") ;;
                bibata-cursor-theme) dnf_pkgs+=("bibata-cursor-themes") ;;
                xfce-polkit) dnf_pkgs+=("xfce-polkit") ;;
                eww-wayland) dnf_pkgs+=("eww") ;;
                swayosd-git) dnf_pkgs+=("swayosd") ;;
                wl-clip-persist) ;; 
                helium-browser-bin) ;; 
                discord) dnf_pkgs+=("discord") ;;
                spotify) dnf_pkgs+=("spotify") ;;
                mpvpaper) dnf_pkgs+=("mpvpaper") ;;
                noctalia-shell) dnf_pkgs+=("noctalia-shell") ;;
                noctiluca) dnf_pkgs+=("noctalia-shell") ;;
                caelestia-shell) dnf_pkgs+=("caelestia-shell") ;;
                caelestia-cli) dnf_pkgs+=("caelestia-cli") ;;
                *) dnf_pkgs+=("$pkg") ;;
            esac
        done
        if [[ ${#dnf_pkgs[@]} -gt 0 ]]; then
            # Enable COPR repositories for key applications
            if [[ " ${dnf_pkgs[*]} " =~ " eww " || " ${dnf_pkgs[*]} " =~ " swayosd " || " ${dnf_pkgs[*]} " =~ " mpvpaper " || " ${dnf_pkgs[*]} " =~ " wlogout " || " ${dnf_pkgs[*]} " =~ " waypaper " ]]; then
                sudo dnf copr enable -y solopasha/hyprland || true
            fi
            if [[ " ${dnf_pkgs[*]} " =~ " starship " ]]; then
                sudo dnf copr enable -y atim/starship || true
            fi
            if [[ " ${dnf_pkgs[*]} " =~ " noctalia-shell " ]]; then
                sudo dnf copr enable -y zhangyi6324/noctalia-shell || true
            fi
            if [[ " ${dnf_pkgs[*]} " =~ " caelestia-shell " || " ${dnf_pkgs[*]} " =~ " caelestia-cli " ]]; then
                sudo dnf copr enable -y errornointernet/quickshell || true
                sudo dnf copr enable -y celestelove/libcava || true
                sudo dnf copr enable -y celestelove/app2unit || true
                sudo dnf copr enable -y brycensranch/gpu-screen-recorder-git || true
                sudo dnf copr enable -y celestelove/caelestia || true
            fi
            sudo dnf install -y --skip-broken "${dnf_pkgs[@]}"
            
            # Symlink fd-find as fd if missing
            if [[ " ${dnf_pkgs[*]} " =~ " fd-find " ]] && ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
                sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true
            fi
        fi
    else
        sudo pacman -S --needed --noconfirm "$@"
    fi
}

install_aur_pkgs() {
    if command -v dnf &>/dev/null; then
        install_pkgs "$@"
    else
        local helper=""
        if command -v paru &>/dev/null; then
            helper="paru"
        elif command -v yay &>/dev/null; then
            helper="yay"
        fi
        if [[ -n "$helper" ]]; then
            $helper -S --noconfirm --needed "$@" || true
        else
            warn "No AUR helper (paru/yay) detected. Skipped Arch package(s): $*"
        fi
    fi
}

step "1. Installing system dependencies"
info "Installing core desktop applications and utilities..."
install_pkgs \
    hyprland waybar rofi-wayland kitty dolphin dunst swaybg \
    hyprlock hypridle wlogout wl-clipboard cliphist \
    brightnessctl playerctl fastfetch cava pavucontrol \
    jq pamixer libnotify sassc ffmpeg socat \
    starship eza bat zoxide fzf ripgrep fd gum \
    nemo nwg-look swaync fuzzel wlsunset wmenu wget mpv

info "Installing extra packages..."
install_aur_pkgs \
    eww-wayland adw-gtk-theme bibata-cursor-theme \
    swayosd-git wl-clip-persist xfce-polkit waypaper \
    helium-browser-bin discord spotify mpvpaper \
    noctalia-shell caelestia-shell caelestia-cli || true

ok "System and AUR dependencies installed."

step "2. Copying Icarus wallpaper scripts & dynamic palette generator"
sudo cp "${REPO_PATH}/configs/wallpaper/switcher.sh" /usr/local/bin/icarus-wallpaper-switch
sudo cp "${REPO_PATH}/configs/wallpaper/icarus-wallpaper.sh" /usr/local/bin/icarus-wallpaper
sudo cp "${REPO_PATH}/configs/wallpaper/daemon.sh" /usr/local/bin/icarus-wallpaper-daemon
sudo cp "${REPO_PATH}/tools/icarus-palette.py" /usr/local/bin/icarus-palette

sudo chmod +x /usr/local/bin/icarus-wallpaper* /usr/local/bin/icarus-palette
ok "Scripts installed to /usr/local/bin/."

step "3. Compiling and installing Archos & WhiteSur themes"
# GTK Themes compilation (both Archos-Dark and original WhiteSur-Dark)
if [[ -d "${REPO_PATH}/pkgs/themes/Archos-gtk-theme" ]]; then
    info "Compiling Archos GTK Theme..."
    ( cd "${REPO_PATH}/pkgs/themes/Archos-gtk-theme" && sudo bash install.sh -d /usr/share/themes -l -c dark -n Archos --silent-mode || true )
    info "Compiling original WhiteSur GTK Theme..."
    ( cd "${REPO_PATH}/pkgs/themes/WhiteSur-gtk-theme" && sudo bash install.sh -d /usr/share/themes -l -c dark -n WhiteSur --silent-mode || true )
    ok "GTK themes compiled and installed."
else
    warn "GTK theme source not found."
fi

# Icon Themes installation (both Archos-dark and original WhiteSur-dark)
if [[ -d "${REPO_PATH}/pkgs/themes/Archos-icon-theme" ]]; then
    info "Installing Archos Icon Theme..."
    ( cd "${REPO_PATH}/pkgs/themes/Archos-icon-theme" && sudo bash install.sh -d /usr/share/icons -n Archos -t all || true )
    info "Installing original WhiteSur Icon Theme..."
    ( cd "${REPO_PATH}/pkgs/themes/WhiteSur-icon-theme" && sudo bash install.sh -d /usr/share/icons -n WhiteSur -t all || true )
    ok "Icon themes installed."
else
    warn "Icon theme source not found."
fi

# Cursors installation (both Archos-cursors and original WhiteSur-cursors)
if [[ -d "${REPO_PATH}/pkgs/themes/Archos-cursors" ]]; then
    info "Installing Archos Cursors..."
    sudo mkdir -p /usr/share/icons/Archos-cursors
    sudo cp -pr "${REPO_PATH}/pkgs/themes/Archos-cursors/dist/." /usr/share/icons/Archos-cursors/
    info "Installing original WhiteSur Cursors..."
    sudo mkdir -p /usr/share/icons/WhiteSur-cursors
    sudo cp -pr "${REPO_PATH}/pkgs/themes/WhiteSur-cursors/dist/." /usr/share/icons/WhiteSur-cursors/
    ok "Cursor themes installed."
else
    warn "Cursor themes source not found."
fi

# Aura Mew Cursor
if [[ -d "${REPO_PATH}/pkgs/themes/Aura-Mew-Cursor" ]]; then
    info "Installing Aura Mew Cursor..."
    sudo mkdir -p /usr/share/icons/Aura-Mew-Cursor
    sudo cp -pr "${REPO_PATH}/pkgs/themes/Aura-Mew-Cursor/." /usr/share/icons/Aura-Mew-Cursor/
    ok "Aura Mew cursor installed."
else
    warn "Aura Mew cursor source not found."
fi

step "3b. Installing SDDM and Plymouth Themes [SKIPPED]"
info "Skipped SDDM and Plymouth theme installation (system-level/bootloader configurations)."

# Install local custom fonts
if [[ -d "${REPO_PATH}/configs/fonts" ]]; then
    info "Installing custom local fonts..."
    sudo mkdir -p /usr/share/fonts/TTF
    sudo cp -rn "${REPO_PATH}/configs/fonts/." /usr/share/fonts/TTF/
    fc-cache -f &>/dev/null || true
fi

step "4. Copying and caching new wallpapers"
sudo mkdir -p /usr/share/backgrounds/icarus/references
if [[ -d "${REPO_PATH}/configs/wallpaper/references" ]]; then
    sudo cp -rn "${REPO_PATH}/configs/wallpaper/references/." /usr/share/backgrounds/icarus/references/
    # Ensure the root fallback static image is installed
    sudo cp -f "${REPO_PATH}/configs/wallpaper/references/84.png" /usr/share/backgrounds/icarus/icarus-midnight.png
fi
if [[ -d "${REPO_PATH}/pkgs/themes/WhiteSur-wallpapers" ]]; then
    info "Copying WhiteSur dynamic wallpapers..."
    for W_DIR in 1080p 2k 4k src; do
        if [[ -d "${REPO_PATH}/pkgs/themes/WhiteSur-wallpapers/${W_DIR}" ]]; then
            sudo cp -rn "${REPO_PATH}/pkgs/themes/WhiteSur-wallpapers/${W_DIR}/." /usr/share/backgrounds/icarus/references/ || true
        fi
    done
fi
ok "Wallpapers integrated into references."

# Hunt, rename, and copy static & live wallpapers from the STEAL folder (if present)
if [[ -d "${REPO_PATH}/STEAL" ]]; then
    info "Hunting for stolen wallpapers in STEAL folder..."
    count=108
    while read -r file; do
        ext="${file##*.}"
        ext="${ext,,}"
        if [[ "$ext" == "gif" || "$ext" == "mp4" || "$ext" == "webm" || "$ext" == "mkv" ]]; then
            new_name="${count}-live.${ext}"
        else
            new_name="${count}.${ext}"
        fi
        sudo cp -n "$file" "/usr/share/backgrounds/icarus/references/${new_name}" 2>/dev/null || true
        count=$((count + 1))
    done < <(find "${REPO_PATH}/STEAL" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) \
        \( -path "*wallpaper*" -o -path "*background*" \) \
        ! -path "*/WhiteSur-gtk-theme*" ! -path "*/WhiteSur-icon-theme*" ! -path "*/WhiteSur-cursors*" ! -path "*/Archos-*" 2>/dev/null)
fi

# Copy entire peak wallpaper bank from MORE folder if present
if [[ -d "${REPO_PATH}/STEAL/MORE/extracted/wallpaper-main/wallpaper-main" ]]; then
    info "Installing complete 780MB wallpaper bank to system backgrounds..."
    sudo cp -rn "${REPO_PATH}/STEAL/MORE/extracted/wallpaper-main/wallpaper-main/." /usr/share/backgrounds/icarus/references/ || true
fi


step "5. Caching Firefox Archos theme"
if [[ -d "${REPO_PATH}/pkgs/themes/Archos-firefox-theme" ]]; then
    sudo mkdir -p /usr/share/archos
    sudo cp -r "${REPO_PATH}/pkgs/themes/Archos-firefox-theme" /usr/share/archos/firefox-theme
    ok "Firefox theme cached. You can apply it anytime by running 'icarus-welcome'."
fi

step "6. Writing user GTK default preferences"
mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"
cat > "${HOME}/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Archos-Dark
gtk-icon-theme-name=Archos-dark
gtk-cursor-theme-name=Archos-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
cp "${HOME}/.config/gtk-3.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"
ok "User GTK parameters written."

step "6b. Copying user configurations (hypr, waybar, kitty, rofi, dunst, fastfetch, cava, wlogout, eww, nvim, yazi)"
mkdir -p "${HOME}/.config" "${HOME}/.themes" "${HOME}/.local/share/icons"

# Copy premium macOS assets to user directories
info "Installing premium macOS UI assets..."
if [[ -d "${REPO_PATH}/configs/themes/WhiteSur-gtk" ]]; then
    cp -rn "${REPO_PATH}/configs/themes/WhiteSur-gtk" "${HOME}/.themes/" || true
fi
if [[ -d "${REPO_PATH}/configs/icons/WhiteSur-icons" ]]; then
    cp -rn "${REPO_PATH}/configs/icons/WhiteSur-icons" "${HOME}/.local/share/icons/" || true
fi
if [[ -d "${REPO_PATH}/configs/cursors/WhiteSur-cursors" ]]; then
    cp -rn "${REPO_PATH}/configs/cursors/WhiteSur-cursors" "${HOME}/.local/share/icons/" || true
fi
if [[ -d "${REPO_PATH}/configs/sddm/WhiteSur" ]]; then
    sudo mkdir -p /usr/share/sddm/themes
    sudo cp -rn "${REPO_PATH}/configs/sddm/WhiteSur" /usr/share/sddm/themes/ || true
fi

for CFG_DIR in hypr waybar kitty rofi dunst fastfetch cava wlogout eww nvim yazi; do
    if [[ -d "${REPO_PATH}/configs/${CFG_DIR}" ]]; then
        info "Copying ${CFG_DIR} configuration..."
        # Backup existing config if it's not a symlink and already exists
        if [[ -d "${HOME}/.config/${CFG_DIR}" && ! -L "${HOME}/.config/${CFG_DIR}" ]]; then
            mv "${HOME}/.config/${CFG_DIR}" "${HOME}/.config/${CFG_DIR}.bak.$(date +%s)" || true
        fi
        mkdir -p "${HOME}/.config/${CFG_DIR}"
        cp -r "${REPO_PATH}/configs/${CFG_DIR}/." "${HOME}/.config/${CFG_DIR}/"
    fi
done

# Copy starship.toml configuration
if [[ -f "${REPO_PATH}/configs/starship.toml" ]]; then
    info "Copying starship configuration..."
    if [[ -f "${HOME}/.config/starship.toml" ]]; then
        mv "${HOME}/.config/starship.toml" "${HOME}/.config/starship.toml.bak.$(date +%s)" || true
    fi
    cp "${REPO_PATH}/configs/starship.toml" "${HOME}/.config/starship.toml"
fi

# Ensure all scripts are executable
chmod +x "${HOME}/.config/hypr/scripts/"* 2>/dev/null || true
[[ -d "${HOME}/.config/eww/scripts" ]] && chmod +x "${HOME}/.config/eww/scripts/"*.sh 2>/dev/null || true
if [[ -f "${HOME}/.config/rofi/icarus-powermenu-entries.sh" ]]; then
    chmod +x "${HOME}/.config/rofi/icarus-powermenu-entries.sh"
fi

# Copy theme defaults into the custom config layout (~/.config/icarus/theme)
if [[ -d "${REPO_PATH}/configs/theme" ]]; then
    info "Copying theme configurations..."
    if [[ -d "${HOME}/.config/icarus/theme" && ! -L "${HOME}/.config/icarus/theme" ]]; then
        mv "${HOME}/.config/icarus/theme" "${HOME}/.config/icarus/theme.bak.$(date +%s)" || true
    fi
    mkdir -p "${HOME}/.config/icarus/theme"
fi

# Append welcome animation to local .bashrc if not already present
if ! grep -q "welcome.sh" "${HOME}/.bashrc" 2>/dev/null; then
    info "Adding welcome.sh to ~/.bashrc..."
    cat >> "${HOME}/.bashrc" << 'EOF'

# Icarus-ArchOS — animated welcome screen & system info on terminal open
if [[ -f "${HOME}/.config/hypr/scripts/welcome.sh" ]]; then
    bash "${HOME}/.config/hypr/scripts/welcome.sh"
elif command -v fastfetch &>/dev/null; then
    fastfetch
fi
EOF
fi

ok "User configurations successfully updated and copied to ~/.config/."

step "7. Restarting wallpaper daemon services"
killall icarus-wallpaper-daemon mpvpaper swaybg 2>/dev/null || true
(icarus-wallpaper &)
ok "Wallpaper launcher & intelligente pausing daemon successfully booted!"

step "Setup complete! Enjoy the peak visuals."
