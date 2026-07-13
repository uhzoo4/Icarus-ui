#!/usr/bin/env bash
# update.sh - Automates pulling the latest from GitHub and running the deployer.

set -euo pipefail

# Style helpers
c_reset='\033[0m'; c_bold='\033[1m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_blue='\033[1;34m'; c_red='\033[1;31m'
info()  { printf "    %s\n" "$1"; }
ok()    { printf "${c_green}[ok]${c_reset} %s\n" "$1"; }
warn()  { printf "${c_yellow}[warn]${c_reset} %s\n" "$1"; }
err()   { printf "${c_red}[error]${c_reset} %s\n" "$1"; }
step()  { printf "\n${c_blue}==>${c_reset} ${c_bold}%s${c_reset}\n" "$1"; }

REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -eq 0 ]]; then
    err "Do not run this script as root. Run it as your normal user. Sudo will be requested when needed."
    exit 1
fi

cd "$REPO_PATH" || { err "Failed to cd into $REPO_PATH"; exit 1; }

step "1. Fetching latest changes from GitHub"
info "Stashing local changes to prevent loss..."
git stash || warn "No local modifications to stash, proceeding."
info "Pulling latest master branch..."
git pull origin main || git pull origin master || { err "Failed to pull from GitHub."; exit 1; }
info "Re-applying stashed changes..."
git stash pop || warn "No stashed changes to apply."
ok "Repository is up to date."

step "2. Making scripts executable"
chmod +x "${REPO_PATH}/run.sh"
chmod +x "${REPO_PATH}/apply-extra.sh"
chmod +x "${REPO_PATH}/update.sh"
ok "Scripts are executable."

step "3. Executing deployment script"
bash "${REPO_PATH}/run.sh"

ok "Update complete!"
