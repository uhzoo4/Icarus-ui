#!/usr/bin/env bash
#
# layers/07-native-apps.sh
#
# Chrome doesn't need Wine — it has a native Linux build. Running it
# through Wine would be strictly worse (translation overhead, worse
# GPU acceleration) than running it natively, so that's what this does.
# Same logic applies to "Microsoft apps": there's no native Linux MS
# Office, but there are native alternatives with strong compatibility,
# and Office/Teams both work fine as web apps in a native browser without
# any Wine involved at all. Wine stays reserved (per Layer 5) for the
# things that genuinely have no native or web equivalent.
#
# Chrome and a few others aren't in Arch's official repos, so this layer
# bootstraps an AUR helper (paru) to get them. Worth knowing: AUR packages
# are community-maintained PKGBUILDs, not vetted the way extra/core
# packages are — reasonable for well-known, widely-used packages like
# these, worth being more careful about for anything obscure later.
#
set -uo pipefail  # deliberately not -e — per-app failures shouldn't cascade

ICARUS_LOG_DIR="${ICARUS_LOG_DIR:-/var/log/icarus}"
ICARUS_REPO_PATH="${ICARUS_REPO_PATH:-/usr/usr_src/icarus-archos}"
SENTINEL="${ICARUS_LOG_DIR}/layer-7-native-apps.done"
PREV_SENTINEL="${ICARUS_LOG_DIR}/layer-6-ai-engineering-perf.done"

log() { echo "[layer-7] $*"; }
warn() { echo "[layer-7] WARNING: $*" >&2; }
fatal() { echo "[layer-7] FATAL: $*" >&2; exit 1; }

[[ -f "$PREV_SENTINEL" ]] || fatal "Layer 6 sentinel not found (${PREV_SENTINEL})."
id icarus &>/dev/null || fatal "User 'icarus' not found — this layer needs a real user to build AUR packages as (makepkg refuses to run as root)."

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
                *) dnf_pkgs+=("$pkg") ;;
            esac
        done
        if [[ ${#dnf_pkgs[@]} -gt 0 ]]; then
            # Enable COPR repositories if needed
            if [[ " ${dnf_pkgs[*]} " =~ " eww " || " ${dnf_pkgs[*]} " =~ " swayosd " || " ${dnf_pkgs[*]} " =~ " mpvpaper " || " ${dnf_pkgs[*]} " =~ " wlogout " || " ${dnf_pkgs[*]} " =~ " waypaper " ]]; then
                sudo dnf copr enable -y solopasha/hyprland || true
            fi
            if [[ " ${dnf_pkgs[*]} " =~ " starship " ]]; then
                sudo dnf copr enable -y atim/starship || true
            fi
            sudo dnf install -y --skip-broken "${dnf_pkgs[@]}"
            
            # Symlink fd-find as fd
            if [[ " ${dnf_pkgs[*]} " =~ " fd-find " ]] && ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
                sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true
            fi
        fi
    else
        pacman -S --noconfirm --needed "$@"
    fi
}

try_install() {
    if ! install_pkgs "$@"; then
        warn "Failed to install one or more of: $* — continuing without it/them."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# 1. Chromium and Firefox now — official repo, zero AUR dependency, available
#    immediately even if the AUR bootstrap below fails for any reason.
# ---------------------------------------------------------------------------
log "Installing Chromium and Firefox (native, official repo)..."
try_install chromium firefox

# ---------------------------------------------------------------------------
# 1b. chafa — enables fastfetch to render images as ASCII/sixel in the
#     terminal. Official repo, no AUR needed.
# ---------------------------------------------------------------------------
log "Installing chafa (terminal image renderer for fastfetch)..."
try_install chafa

# ---------------------------------------------------------------------------
# 1c. Modern Terminal Toolchain (starship, eza, bat, zoxide, fzf, ripgrep, fd, gum)
# ---------------------------------------------------------------------------
log "Installing modern terminal toolchain and onboarding UI deps..."
try_install starship eza bat zoxide fzf ripgrep fd gum

log "Writing modern default .bashrc..."
cat > /etc/skel/.bashrc << 'EOF'
# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='eza --icons --group-directories-first'
alias ll='eza -alF --icons --group-directories-first'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'

eval "$(zoxide init bash)"
eval "$(starship init bash)"
EOF
# Copy to existing user if they exist
[[ -d /home/icarus ]] && cp /etc/skel/.bashrc /home/icarus/.bashrc && chown icarus:icarus /home/icarus/.bashrc

# ---------------------------------------------------------------------------
# 2. Bootstrap an AUR helper. paru-bin (prebuilt binary) avoids needing a
#    Rust toolchain just to get the helper itself running.
# ---------------------------------------------------------------------------
AUR_OK=0
if command -v dnf &>/dev/null; then
    log "Fedora system detected. Skipping paru (AUR helper) bootstrap."
    AUR_OK=1
else
    log "Bootstrapping paru (AUR helper)..."
    try_install base-devel git rust acpi lm_sensors
    if ! command -v paru &>/dev/null; then
        BUILD_DIR="/home/icarus/.cache/icarus-aur-bootstrap"
        sudo -u icarus mkdir -p "$BUILD_DIR"
        if sudo -u icarus bash -c "
            set -e
            cd '${BUILD_DIR}'
            [[ -d paru ]] || git clone https://aur.archlinux.org/paru.git
            cd paru
            git pull
            makepkg -sf --noconfirm
        "; then
            PKG_FILE=$(find "${BUILD_DIR}/paru" -maxdepth 1 -name '*.pkg.tar.zst' | head -1)
            if [[ -n "$PKG_FILE" ]] && pacman -U --noconfirm "$PKG_FILE"; then
                AUR_OK=1
                log "paru installed."
            else
                warn "paru package built but install failed."
            fi
        else
            warn "Could not build paru — AUR-dependent apps below will be skipped. Chromium/LibreOffice above are unaffected."
        fi
    else
        AUR_OK=1
    fi
fi

aur_install() {
    # Runs as icarus (paru refuses root, same as makepkg) — non-interactive.
    # --skipreview skips the PKGBUILD diff prompt; --useask additionally
    # routes pacman's own conflict/replace prompts through --noconfirm
    # instead of blocking. Both are needed together for this to actually
    # run unattended rather than hanging on the first conflict prompt.
    if command -v dnf &>/dev/null; then
        install_pkgs "$@"
    else
        if [[ $AUR_OK -eq 1 ]]; then
            if ! sudo -u icarus paru -S --noconfirm --skipreview --useask "$@"; then
                warn "paru failed to install: $* — check manually later with 'paru -S $*'."
            fi
        else
            warn "Skipping AUR package(s) '$*' — no working AUR helper."
        fi
    fi
}

# ---------------------------------------------------------------------------
# 3. Google Chrome and Spotify, via AUR now that paru exists.
# ---------------------------------------------------------------------------
log "Installing Google Chrome and Spotify (AUR)..."
aur_install google-chrome spotify

# ---------------------------------------------------------------------------
# 3b. Theme packages referenced by configs/hypr/hyprland.conf and Layer 5's
#     GTK settings.ini (adw-gtk3-dark, Bibata-Modern-Ice) but not installed
#     there since both are AUR-only and paru doesn't exist until this layer.
# ---------------------------------------------------------------------------
log "Installing theme and visual utility packages (wlogout, adw-gtk-theme, bibata-cursor-theme)..."
aur_install wlogout
aur_install adw-gtk-theme
aur_install bibata-cursor-theme

# ---------------------------------------------------------------------------
# 3d. Eww dashboard dependencies. eww-wayland is the Wayland-native build
#     variant (AUR-only); socat/jq/pamixer are runtime deps its widgets
#     call out to for IPC and volume control.
# ---------------------------------------------------------------------------
log "Installing Eww dashboard dependencies..."
aur_install eww-wayland
try_install socat jq pamixer

# ---------------------------------------------------------------------------
# 3c. Live wallpaper. mpvpaper is AUR-only, hence installed here rather
#     than alongside the static PNG in Layer 5. configs/wallpaper/
#     icarus-wallpaper.sh (installed in Layer 5) already falls back to the
#     static PNG via swaybg if mpvpaper isn't present — so if this
#     specific install fails, the desktop still gets a wallpaper, just not
#     the animated one.
# ---------------------------------------------------------------------------
log "Installing mpvpaper (live wallpaper) and the animated wallpaper file..."
aur_install mpvpaper
if [[ -f "${ICARUS_REPO_PATH}/configs/wallpaper/icarus-midnight-live.mp4" ]]; then
    install -d /usr/share/backgrounds/icarus
    install -m 0644 "${ICARUS_REPO_PATH}/configs/wallpaper/icarus-midnight-live.mp4" /usr/share/backgrounds/icarus/icarus-midnight-live.mp4
else
    warn "Missing configs/wallpaper/icarus-midnight-live.mp4 — will fall back to the static wallpaper even if mpvpaper installed fine."
fi
log "Note: mpvpaper decodes video continuously, which costs more battery than a static wallpaper. The 'mpvpaper-stop' companion tool (AUR) can pause it on idle/lock if that matters more than the motion — not installed by default."

# ---------------------------------------------------------------------------
# 4. Microsoft-adjacent needs — native/web-first, Wine only where nothing
#    else covers it.
# ---------------------------------------------------------------------------
log "Installing native Office-compatible suite (LibreOffice)..."
try_install libreoffice-fresh hunspell-en_us

log "Notes on the rest (not auto-installed — pick based on what you actually use):"
log "  - Office/Word/Excel/PowerPoint: office.com works fully in Chrome/Chromium — no install needed."
log "  - Teams: Microsoft dropped native Linux Teams. Use teams.microsoft.com in Chrome, or 'paru -S teams-for-linux' for an unofficial wrapper."
log "  - Edge (if you specifically want it over Chrome): 'paru -S microsoft-edge-stable-bin'."
log "  - VS Code: 'paru -S visual-studio-code-bin' for the MS-branded build."

# ---------------------------------------------------------------------------
# 5. First-Boot Onboarding Script
# ---------------------------------------------------------------------------
log "Installing icarus-welcome onboarding script..."
cat > /usr/local/bin/icarus-welcome << 'EOF'
#!/usr/bin/env bash
set -e

# Mark as done immediately so it doesn't loop if they close the terminal
mkdir -p "$HOME/.config/icarus"
touch "$HOME/.config/icarus/.welcome-done"

clear
gum style --border double --margin "1" --padding "1 2" --border-foreground 212 "Welcome to Icarus-ArchOS"

gum style "Let's get your engineering workstation ready."
echo ""

if ! ping -c 1 archlinux.org &>/dev/null; then
    if gum confirm "You appear to be offline. Open Wi-Fi settings?"; then
        kitty -e nmtui &
        gum spin --spinner dot --title "Waiting for connection..." -- sleep 5
    fi
fi

echo "Would you like to install optional engineering apps?"
APPS=$(gum choose --no-limit "VS Code" "Docker" "Teams" "Edge")

if [[ -n "$APPS" ]]; then
    echo "Installing selected apps..."
    [[ "$APPS" == *"VS Code"* ]] && paru -S --noconfirm visual-studio-code-bin
    [[ "$APPS" == *"Docker"* ]] && sudo pacman -S --noconfirm docker docker-compose && sudo systemctl enable --now docker && sudo usermod -aG docker $USER
    [[ "$APPS" == *"Teams"* ]] && paru -S --noconfirm teams-for-linux
    [[ "$APPS" == *"Edge"* ]] && paru -S --noconfirm microsoft-edge-stable-bin
    gum style --foreground 212 "Apps installed!"
fi

if [[ -d "/usr/share/archos/firefox-theme" ]]; then
    if gum confirm "Would you like to apply the macOS theme to Firefox?"; then
        echo "Launching Firefox briefly to initialize default profile..."
        firefox &
        FIREFOX_PID=$!
        sleep 4
        kill $FIREFOX_PID || true
        sleep 1
        echo "Installing Firefox Theme..."
        /usr/share/archos/firefox-theme/install.sh
        gum style --foreground 212 "Firefox theme applied!"
    fi
fi

gum style "All set! Press SUPER+Space for your launcher, or SUPER+W to cycle wallpapers."
echo "Press any key to exit."
read -n 1
EOF
chmod +x /usr/local/bin/icarus-welcome

mkdir -p "$ICARUS_LOG_DIR"
touch "$SENTINEL"
log "Layer 7 complete. Sentinel written: ${SENTINEL}"
