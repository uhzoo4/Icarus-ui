#!/usr/bin/env bash
#
# layers/05-ui-winhybrid.sh
# Hyprland/Waybar UI layer, native Wine-Wayland integration, lock screen,
# idle management, notifications, power menu, system info, audio
# visualizer, eww dashboard, and dynamic wallpaper-driven theming.
#
set -euo pipefail

ICARUS_LOG_DIR="${ICARUS_LOG_DIR:-/var/log/icarus}"
ICARUS_REPO_PATH="${ICARUS_REPO_PATH:-/usr/usr_src/icarus-archos}"
SENTINEL="${ICARUS_LOG_DIR}/layer-5-ui-winhybrid.done"
PREV_SENTINEL="${ICARUS_LOG_DIR}/layer-4-graphics.done"

log() { echo "[layer-5] $*"; }
fatal() { echo "[layer-5] FATAL: $*" >&2; exit 1; }

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
        pacman -S --noconfirm --needed "$@"
    fi
}

[[ -f "$PREV_SENTINEL" ]] || fatal "Layer 4 sentinel not found (${PREV_SENTINEL})."

log "Installing Hyprland desktop stack..."
install_pkgs \
    hyprland waybar rofi-wayland kitty dolphin dunst swaybg \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    qt5-wayland qt6-wayland xdg-desktop-portal-hyprland polkit-kde-agent \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji grim slurp \
    sddm qt6-5compat qt6-declarative qt6-svg qt6-multimedia-ffmpeg papirus-icon-theme \
    ffmpeg socat

log "Installing lock screen, idle management, and power menu..."
install_pkgs \
    hyprlock hypridle wlogout

log "Installing screenshot, clipboard, and brightness tools..."
install_pkgs \
    wl-clipboard cliphist brightnessctl playerctl

log "Installing dashboard connectivity controls..."
install_pkgs \
    network-manager-applet bluez bluez-utils blueman curl jq
systemctl enable bluetooth.service

log "Installing terminal extras and system info..."
install_pkgs \
    fastfetch cava pavucontrol python python-pillow \
    noctalia-shell caelestia-shell caelestia-cli

log "Installing Wine / Windows-app compatibility stack..."
install_pkgs \
    wine-staging winetricks  \
    giflib lib32-giflib libpng lib32-libpng \
    libldap lib32-libldap gnutls lib32-gnutls \
    mpg123 lib32-mpg123 openal lib32-openal \
    v4l-utils lib32-v4l-utils libclc  \
    libxkbcommon lib32-libxkbcommon

# ---------------------------------------------------------------------------
# Wayland application hints — real, widely used variables for making
# Qt/GTK/Electron apps prefer Wayland with an X11 fallback.
# ---------------------------------------------------------------------------
log "Writing Wayland session hints to /etc/environment..."
for VAR in XDG_SESSION_TYPE QT_QPA_PLATFORM GDK_BACKEND ELECTRON_OZONE_PLATFORM_HINT; do
    sed -i "/^${VAR}=/d" /etc/environment
done
cat >> /etc/environment <<'EOF'
XDG_SESSION_TYPE=wayland
QT_QPA_PLATFORM=wayland;xcb
GDK_BACKEND=wayland,x11
ELECTRON_OZONE_PLATFORM_HINT=wayland
EOF

# ---------------------------------------------------------------------------
# Config skeletons — installed to /etc/skel for future users, and also
# copied directly into /home/icarus, since that account was already created
# in Layer 3a before this skeleton existed.
# ---------------------------------------------------------------------------
log "Installing config skeletons..."
mkdir -p /etc/skel/.config/{hypr,waybar,rofi,dunst,kitty,fastfetch,cava,eww,icarus/theme,yazi}

require_config() {
    local src="$1" dst="$2"
    if [[ -f "$src" ]]; then
        cp "$src" "$dst"
    else
        fatal "Missing required config: $src"
    fi
}

require_config "${ICARUS_REPO_PATH}/configs/hypr/hyprland.conf" /etc/skel/.config/hypr/hyprland.conf
require_config "${ICARUS_REPO_PATH}/configs/hypr/hyprlock.conf" /etc/skel/.config/hypr/hyprlock.conf
require_config "${ICARUS_REPO_PATH}/configs/hypr/hypridle.conf" /etc/skel/.config/hypr/hypridle.conf
require_config "${ICARUS_REPO_PATH}/configs/hypr/animations.conf" /etc/skel/.config/hypr/animations.conf
require_config "${ICARUS_REPO_PATH}/configs/hypr/shaders.conf" /etc/skel/.config/hypr/shaders.conf
require_config "${ICARUS_REPO_PATH}/configs/hypr/workflows.conf" /etc/skel/.config/hypr/workflows.conf

# Install Icarus custom scripts
log "Installing Icarus custom utility scripts..."
mkdir -p /etc/skel/.config/hypr/scripts
if [[ -d "${ICARUS_REPO_PATH}/configs/hypr/scripts" ]]; then
    cp -r "${ICARUS_REPO_PATH}/configs/hypr/scripts/." /etc/skel/.config/hypr/scripts/
    chmod +x /etc/skel/.config/hypr/scripts/*
else
    fatal "Missing configs/hypr/scripts/ in repo payload."
fi

# Install HyDE features (animations, shaders, workflows)
log "Installing HyDE dynamic features (animations, shaders, workflows)..."
for DIR in animations shaders workflows; do
    if [[ -d "${ICARUS_REPO_PATH}/configs/hypr/${DIR}" ]]; then
        mkdir -p "/etc/skel/.config/hypr/${DIR}"
        cp -r "${ICARUS_REPO_PATH}/configs/hypr/${DIR}/." "/etc/skel/.config/hypr/${DIR}/"
    fi
done

require_config "${ICARUS_REPO_PATH}/configs/waybar/config.jsonc" /etc/skel/.config/waybar/config.jsonc
require_config "${ICARUS_REPO_PATH}/configs/waybar/style.css" /etc/skel/.config/waybar/style.css
require_config "${ICARUS_REPO_PATH}/configs/dunst/dunstrc" /etc/skel/.config/dunst/dunstrc
require_config "${ICARUS_REPO_PATH}/configs/kitty/kitty.conf" /etc/skel/.config/kitty/kitty.conf
require_config "${ICARUS_REPO_PATH}/configs/kitty/colors.conf" /etc/skel/.config/kitty/colors.conf
[[ -f "${ICARUS_REPO_PATH}/configs/kitty/open-actions.conf" ]] && cp "${ICARUS_REPO_PATH}/configs/kitty/open-actions.conf" /etc/skel/.config/kitty/open-actions.conf
mkdir -p /etc/skel/.config/wlogout
require_config "${ICARUS_REPO_PATH}/configs/wlogout/layout" /etc/skel/.config/wlogout/layout
require_config "${ICARUS_REPO_PATH}/configs/wlogout/style.css" /etc/skel/.config/wlogout/style.css
[[ -d "${ICARUS_REPO_PATH}/configs/wlogout/icons" ]] && cp -r "${ICARUS_REPO_PATH}/configs/wlogout/icons" /etc/skel/.config/wlogout/
require_config "${ICARUS_REPO_PATH}/configs/fastfetch/config.jsonc" /etc/skel/.config/fastfetch/config.jsonc
require_config "${ICARUS_REPO_PATH}/configs/fastfetch/logo.txt" /etc/skel/.config/fastfetch/logo.txt
require_config "${ICARUS_REPO_PATH}/configs/cava/config" /etc/skel/.config/cava/config

# Install starship and yazi configurations
if [[ -f "${ICARUS_REPO_PATH}/configs/starship.toml" ]]; then
    cp "${ICARUS_REPO_PATH}/configs/starship.toml" /etc/skel/.config/starship.toml
fi
if [[ -d "${ICARUS_REPO_PATH}/configs/yazi" ]]; then
    mkdir -p /etc/skel/.config/yazi
    cp -r "${ICARUS_REPO_PATH}/configs/yazi/." /etc/skel/.config/yazi/
fi

if [[ -f "${ICARUS_REPO_PATH}/configs/wine/wine-wayland.sh" ]]; then
    install -m 0755 "${ICARUS_REPO_PATH}/configs/wine/wine-wayland.sh" /etc/profile.d/wine-wayland.sh
else
    fatal "Missing configs/wine/wine-wayland.sh in repo payload."
fi

# --- Eww dashboard ---
if [[ -d "${ICARUS_REPO_PATH}/configs/eww" ]]; then
    cp -r "${ICARUS_REPO_PATH}/configs/eww/"* /etc/skel/.config/eww/
    [[ -d /etc/skel/.config/eww/scripts ]] && chmod +x /etc/skel/.config/eww/scripts/*.sh
else
    fatal "Missing configs/eww/ in repo payload."
fi

# --- Neovim config ---
if [[ -d "${ICARUS_REPO_PATH}/configs/nvim" ]]; then
    log "Installing Neovim configurations..."
    mkdir -p /etc/skel/.config/nvim
    cp -r "${ICARUS_REPO_PATH}/configs/nvim/." /etc/skel/.config/nvim/
fi

# --- Install local custom fonts ---
if [[ -d "${ICARUS_REPO_PATH}/configs/fonts" ]]; then
    log "Installing local custom fonts..."
    mkdir -p /usr/share/fonts/TTF
    cp -r "${ICARUS_REPO_PATH}/configs/fonts/"* /usr/share/fonts/TTF/
    fc-cache -f &>/dev/null || true
fi

# --- Rofi themes (system-wide default + skel copies of all variants) ---
if [[ -f "${ICARUS_REPO_PATH}/configs/rofi/icarus-spotlight.rasi" ]]; then
    log "Installing rofi themes..."
    install -d /usr/share/rofi/themes
    install -m 0644 "${ICARUS_REPO_PATH}/configs/rofi/icarus-spotlight.rasi" /usr/share/rofi/themes/icarus-spotlight.rasi
else
    fatal "Missing configs/rofi/icarus-spotlight.rasi in repo payload."
fi
if [[ -d "${ICARUS_REPO_PATH}/configs/rofi" ]]; then
    cp -r "${ICARUS_REPO_PATH}/configs/rofi/"* /etc/skel/.config/rofi/
    if [[ -f "${ICARUS_REPO_PATH}/configs/rofi/icarus-powermenu-entries.sh" ]]; then
        install -m 0755 "${ICARUS_REPO_PATH}/configs/rofi/icarus-powermenu-entries.sh" /usr/local/bin/icarus-powermenu-entries
    fi
else
    fatal "Missing configs/rofi/ in repo payload."
fi

# ---------------------------------------------------------------------------
# Wallpapers. Two distinct tools, two distinct names — this distinction
# matters and was a real bug earlier in this file's history:
#   icarus-wallpaper        — the startup daemon wrapper (live video via
#                              mpvpaper, falls back to static PNG via
#                              swaybg). Runs once, via exec-once.
#   icarus-wallpaper-switch — the interactive Rofi-based picker over
#                              configs/wallpaper/references/. Runs
#                              repeatedly, bound to SUPER+W.
# Installing both to the same path would make one silently overwrite the
# other depending on install order.
# ---------------------------------------------------------------------------
if [[ ! -f "${ICARUS_REPO_PATH}/configs/wallpaper/references/84.png" ]]; then
    fatal "Missing configs/wallpaper/references/84.png in repo payload."
fi
install -d /usr/share/backgrounds/icarus
install -m 0644 "${ICARUS_REPO_PATH}/configs/wallpaper/references/84.png" /usr/share/backgrounds/icarus/icarus-midnight.png

if [[ -f "${ICARUS_REPO_PATH}/configs/wallpaper/icarus-wallpaper.sh" ]]; then
    install -m 0755 "${ICARUS_REPO_PATH}/configs/wallpaper/icarus-wallpaper.sh" /usr/local/bin/icarus-wallpaper
else
    fatal "Missing configs/wallpaper/icarus-wallpaper.sh in repo payload."
fi

if [[ -f "${ICARUS_REPO_PATH}/configs/wallpaper/switcher.sh" ]]; then
    log "Installing wallpaper switcher..."
    install -m 0755 "${ICARUS_REPO_PATH}/configs/wallpaper/switcher.sh" /usr/local/bin/icarus-wallpaper-switch
else
    fatal "Missing configs/wallpaper/switcher.sh in repo payload."
fi

if [[ -f "${ICARUS_REPO_PATH}/configs/wallpaper/daemon.sh" ]]; then
    log "Installing wallpaper pause daemon..."
    install -m 0755 "${ICARUS_REPO_PATH}/configs/wallpaper/daemon.sh" /usr/local/bin/icarus-wallpaper-daemon
else
    fatal "Missing configs/wallpaper/daemon.sh in repo payload."
fi

if [[ -d "${ICARUS_REPO_PATH}/configs/wallpaper/references" ]]; then
    mkdir -p /usr/share/backgrounds/icarus/references
    cp -r "${ICARUS_REPO_PATH}/configs/wallpaper/references/"* /usr/share/backgrounds/icarus/references/
else
    fatal "Missing configs/wallpaper/references/ in repo payload — the switcher would error on first use without it."
fi

# Automatically hunt, rename, and copy static & live wallpapers from the STEAL folder (if present)
if [[ -d "${ICARUS_REPO_PATH}/STEAL" ]]; then
    log "Hunting for stolen wallpapers in STEAL folder..."
    count=108
    while read -r file; do
        ext="${file##*.}"
        ext="${ext,,}"
        if [[ "$ext" == "gif" || "$ext" == "mp4" || "$ext" == "webm" || "$ext" == "mkv" ]]; then
            new_name="${count}-live.${ext}"
        else
            new_name="${count}.${ext}"
        fi
        cp -n "$file" "/usr/share/backgrounds/icarus/references/${new_name}" 2>/dev/null || true
        count=$((count + 1))
    done < <(find "${ICARUS_REPO_PATH}/STEAL" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" \) \
        \( -path "*wallpaper*" -o -path "*background*" \) \
        ! -path "*/WhiteSur-gtk-theme*" ! -path "*/WhiteSur-icon-theme*" ! -path "*/WhiteSur-cursors*" ! -path "*/Archos-*" 2>/dev/null)
    log "Stolen wallpapers successfully integrated."
fi

# ---------------------------------------------------------------------------
# Dynamic palette generator + static theme defaults. The defaults matter:
# eww, GTK, and Waybar all import files under ~/.config/icarus/theme/ that
# only get (re)generated when icarus-palette runs — without a pre-shipped
# static default, those imports would fail on first login before the
# wallpaper switcher is ever used.
# ---------------------------------------------------------------------------
if [[ -f "${ICARUS_REPO_PATH}/tools/icarus-palette.py" && -d "${ICARUS_REPO_PATH}/configs/theme" ]]; then
    log "Installing icarus-palette generator and static theme defaults..."
    install -m 0755 "${ICARUS_REPO_PATH}/tools/icarus-palette.py" /usr/local/bin/icarus-palette
    cp -r "${ICARUS_REPO_PATH}/configs/theme" /etc/skel/.config/icarus/
else
    fatal "Missing tools/icarus-palette.py or configs/theme/ in repo payload."
fi

# ---------------------------------------------------------------------------
# Compile and install custom cursors, icons, and GTK theme from EXTRA folder
# ---------------------------------------------------------------------------
# Install Archos-cursors
if [[ -d "${ICARUS_REPO_PATH}/pkgs/themes/Archos-cursors" ]]; then
    log "Installing Archos cursor theme..."
    mkdir -p /usr/share/icons/Archos-cursors
    cp -pr "${ICARUS_REPO_PATH}/pkgs/themes/Archos-cursors/dist/." /usr/share/icons/Archos-cursors/
fi

# Install Aura-Mew-Cursor
if [[ -d "${ICARUS_REPO_PATH}/pkgs/themes/Aura-Mew-Cursor" ]]; then
    log "Installing Aura Mew cursor theme..."
    mkdir -p /usr/share/icons/Aura-Mew-Cursor
    cp -pr "${ICARUS_REPO_PATH}/pkgs/themes/Aura-Mew-Cursor/." /usr/share/icons/Aura-Mew-Cursor/
fi

# Compile and install GTK Theme as Archos-Dark
if [[ -d "${ICARUS_REPO_PATH}/pkgs/themes/Archos-gtk-theme" ]]; then
    log "Installing sassc dependency for GTK theme compilation..."
    pacman -S --noconfirm --needed sassc
    log "Compiling and installing Archos GTK Theme..."
    ( cd "${ICARUS_REPO_PATH}/pkgs/themes/Archos-gtk-theme" && ./install.sh -d /usr/share/themes -l -c dark -n Archos --silent-mode || true )
fi

# Install Icon Theme as Archos
if [[ -d "${ICARUS_REPO_PATH}/pkgs/themes/Archos-icon-theme" ]]; then
    log "Installing Archos Icon Theme..."
    ( cd "${ICARUS_REPO_PATH}/pkgs/themes/Archos-icon-theme" && ./install.sh -d /usr/share/icons -n Archos -t all || true )
fi

# Cache Firefox theme under /usr/share/archos/ for onboarding welcome script
if [[ -d "${ICARUS_REPO_PATH}/pkgs/themes/Archos-firefox-theme" ]]; then
    log "Caching Archos Firefox Theme..."
    mkdir -p /usr/share/archos
    cp -r "${ICARUS_REPO_PATH}/pkgs/themes/Archos-firefox-theme" /usr/share/archos/firefox-theme
fi

log "Writing GTK theme settings..."
mkdir -p /etc/skel/.config/gtk-3.0 /etc/skel/.config/gtk-4.0
for GTK_DIR in gtk-3.0 gtk-4.0; do
cat > "/etc/skel/.config/${GTK_DIR}/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Archos-Dark
gtk-icon-theme-name=Archos-dark
gtk-cursor-theme-name=Archos-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
# NOTE: exactly one ".." here, not two — this file lives at
# /etc/skel/.config/<gtk-dir>/gtk.css, and the theme lives at
# /etc/skel/.config/icarus/theme/gtk.css, which is one level up
# (out of <gtk-dir>/) then into icarus/theme/, not two.
cat > "/etc/skel/.config/${GTK_DIR}/gtk.css" << 'EOF'
@import url("../icarus/theme/gtk.css");
EOF
done

# ---------------------------------------------------------------------------
# Welcome Animation on terminal open — runs every time a new interactive bash
# session starts so the Icarus branding is the first thing you see.
# ---------------------------------------------------------------------------
log "Adding welcome animation to shell startup..."
if ! grep -q "welcome.sh" /etc/skel/.bashrc 2>/dev/null; then
    cat >> /etc/skel/.bashrc << 'EOF'

# Icarus-ArchOS — animated welcome screen & system info on terminal open
if [[ -f "${HOME}/.config/hypr/scripts/welcome.sh" ]]; then
    bash "${HOME}/.config/hypr/scripts/welcome.sh"
elif command -v fastfetch &>/dev/null; then
    fastfetch
fi
EOF
fi

# ---------------------------------------------------------------------------
# Display manager: SDDM with the Astronaut theme for graphical login.
# ---------------------------------------------------------------------------
log "Configuring SDDM + Astronaut Theme as the login manager..."

# Install astronaut theme from pkgs folder
if [[ -d "${ICARUS_REPO_PATH}/pkgs/sddm-themes/sddm-astronaut/sddm-astronaut-theme-master" ]]; then
    mkdir -p /usr/share/sddm/themes/sddm-astronaut-theme
    cp -r "${ICARUS_REPO_PATH}/pkgs/sddm-themes/sddm-astronaut/sddm-astronaut-theme-master/"* /usr/share/sddm/themes/sddm-astronaut-theme/
    
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/10-theme.conf <<'EOF'
[Theme]
Current=sddm-astronaut-theme
EOF
else
    fatal "SDDM Astronaut theme not found in pkgs/sddm-themes/sddm-astronaut/sddm-astronaut-theme-master"
fi

# Override any existing display manager symlink (e.g. from CachyOS defaults)
systemctl disable greetd.service display-manager.service --force 2>/dev/null || true
systemctl enable sddm.service --force

# ---------------------------------------------------------------------------
# Pipewire user services. Arch's pipewire packaging generally auto-enables
# these via systemd presets, but that isn't guaranteed across package
# revisions — enabling explicitly and globally (i.e. for every user, not
# just whoever is logged in when this script runs) removes the ambiguity.
# ---------------------------------------------------------------------------
log "Enabling Pipewire audio services for all users..."
systemctl --global enable pipewire.service pipewire-pulse.service wireplumber.service 2>&1 \
    || log "WARNING: could not globally enable Pipewire user services — verify manually after first login with 'systemctl --user status pipewire'."

if id icarus &>/dev/null; then
    log "Populating existing user 'icarus' home directory with the skeleton..."
    mkdir -p /home/icarus/.config
    cp -rn /etc/skel/.config/. /home/icarus/.config/
    chown -R icarus:icarus /home/icarus
fi

mkdir -p "$ICARUS_LOG_DIR"
touch "$SENTINEL"
log "Layer 5 complete. Sentinel written: ${SENTINEL}"
