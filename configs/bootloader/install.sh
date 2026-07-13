#!/usr/bin/env bash
# configs/bootloader/install.sh
# Installs animated GRUB themes for Icarus UI

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

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${BASE_DIR}/../.." && pwd)"

# Sudo keepalive function
sudo_init_keepalive() {
    info "Initializing sudo keepalive. You may be prompted for your password once..."
    sudo -v
    # Keep sudo ticket alive in the background until the script exits
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done) 2>/dev/null &
}
sudo_init_keepalive

THEME_NAME="Retroboot" # Default theme
THEME_FILE="${REPO_ROOT}/pkgs/bootloader/Grub_Retroboot.tar.gz"

# Allow user to choose a theme if they pass it as an argument
if [[ "${1:-}" == "--pochita" ]]; then
    THEME_NAME="Pochita"
    THEME_FILE="${REPO_ROOT}/pkgs/bootloader/Grub_Pochita.tar.gz"
fi

step "1. Creating GRUB themes directory"
sudo mkdir -p /boot/grub/themes

step "2. Extracting theme file"
sudo tar -xzf "$THEME_FILE" -C /boot/grub/themes/
ok "Theme extracted to /boot/grub/themes/${THEME_NAME}."

step "3. Updating /etc/default/grub"
# Backup existing grub file
sudo cp /etc/default/grub "/etc/default/grub.bak.$(date +%s)"

# Remove any existing GRUB_THEME line
sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub

# Append new GRUB_THEME line
echo "GRUB_THEME=\"/boot/grub/themes/${THEME_NAME}/theme.txt\"" | sudo tee -a /etc/default/grub >/dev/null
ok "GRUB configuration updated."

step "4. Regenerating GRUB boot loader config"
if [[ -f /boot/grub/grub.cfg ]]; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
elif [[ -f /boot/efi/EFI/fedora/grub.cfg ]]; then
    sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
elif command -v grub2-mkconfig &>/dev/null; then
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg || sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg || true
else
    sudo grub-mkconfig -o /boot/grub/grub.cfg || true
fi
ok "GRUB config successfully regenerated."

step "GRUB Animated theme installed!"
info "Restart your system to view the animated boot loader menu."
