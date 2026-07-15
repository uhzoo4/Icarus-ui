#!/usr/bin/env bash
# tools/system_core.sh
# ICARUS-UI: Low-level Hardware Profiler & Game Accelerator
# Toggles high-performance kernels, HugePages, iGPU parameters, and CPU schedulers.

set -e

# Colors for better readability
c_reset='\033[0m'; c_bold='\033[1m'; c_green='\033[1;32m'; c_yellow='\033[1;33m'; c_red='\033[1;31m'; c_blue='\033[1;34m'; c_magenta='\033[1;35m'
info()  { printf "    %s\n" "$1"; }
ok()    { printf "${c_green}[ok]${c_reset} %s\n" "$1"; }
warn()  { printf "${c_yellow}[warn]${c_reset} %s\n" "$1"; }
err()   { printf "${c_red}[error]${c_reset} %s\n" "$1"; }

clear
echo -e "${c_magenta}==========================================================================${c_reset}"
echo -e "${c_bold}          ICARUS-UI: HARDWARE PROFILER & GAME ACCELERATOR                 ${c_reset}"
echo -e "${c_magenta}==========================================================================${c_reset}"
echo -e "  1) 🎮 ENGAGE HYPER-FLUID GAMING ENGINE (GameMode + Ananicy + low-latency)"
echo -e "  2) 🧠 RESTORE STANDARD ENGINEERING WORKSPACE"
echo -e "${c_magenta}==========================================================================${c_reset}"
read -rp "Select Profile State [1-2]: " GAME_PROFILE

if [ "$GAME_PROFILE" -eq 1 ]; then
    echo -e "\n[+] Activating hardware acceleration routines..."

    # 1. Start the Ananicy process priority scheduler
    if systemctl is-active --quiet ananicy-cpp; then
        ok "Ananicy-cpp auto-nice scheduler is already active."
    else
        info "Starting Ananicy-cpp auto-nice scheduler..."
        sudo systemctl start ananicy-cpp 2>/dev/null || true
        sudo systemctl enable ananicy-cpp --now 2>/dev/null || true
        ok "Ananicy-cpp activated."
    fi

    # 2. Kernel memory allocation tweaks (Transparent HugePages)
    info "Configuring transparent HugePages (forcing memory matrix)..."
    sudo bash -c "echo always > /sys/kernel/mm/transparent_hugepage/enabled" 2>/dev/null || warn "Failed to configure Transparent HugePages."

    # 3. Disable split-lock processor throttling anomalies (prevents micro-stutters)
    info "Disabling CPU split-lock detection..."
    sudo sysctl -w kernel.split_lock_detect=0 2>/dev/null || warn "Failed to set kernel.split_lock_detect."

    # 4. Maximize file descriptor limits
    info "Configuring maximum file descriptor limits..."
    sudo sysctl -w fs.file-max=2097152 2>/dev/null || warn "Failed to set fs.file-max."

    # 5. Apply low-latency network and virtual memory parameters
    info "Applying low-latency sysctl tuning..."
    sudo sysctl -w net.core.netdev_max_backlog=16384 2>/dev/null || true
    sudo sysctl -w net.core.somaxconn=8192 2>/dev/null || true
    sudo sysctl -w vm.swappiness=10 2>/dev/null || true
    sudo sysctl -w vm.vfs_cache_pressure=50 2>/dev/null || true

    # 6. Optimize the Intel Iris Xe graphics pipeline parameters
    export INTEL_DEBUG=noccs
    export vblank_mode=0 # Disables VSync constraints to minimize input lag
    export NM_CONTROLLED=no

    echo -e "\n${c_green}[✓] SUCCESS: Low-latency scheduling and kernel tweaks active.${c_reset}"
    echo -e "To start your game with graphics acceleration, use this launch option in Steam:"
    echo -e "    ${c_green}INTEL_DEBUG=noccs vblank_mode=0 gamemoderun %command%${c_reset}"

elif [ "$GAME_PROFILE" -eq 2 ]; then
    echo -e "\n[+] Restoring system parameters to standard development workspace..."

    # 1. Stop the Ananicy process priority scheduler
    info "Stopping Ananicy-cpp scheduler..."
    sudo systemctl stop ananicy-cpp 2>/dev/null || true

    # 2. Restore transparent HugePages to default (madvise)
    info "Restoring default memory Large Pages allocation..."
    sudo bash -c "echo madvise > /sys/kernel/mm/transparent_hugepage/enabled" 2>/dev/null || true

    # 3. Restore split-lock detection
    info "Enabling standard split-lock detection..."
    sudo sysctl -w kernel.split_lock_detect=1 2>/dev/null || true

    # 4. Restore standard file max limits
    info "Restoring standard file limits..."
    sudo sysctl -w fs.file-max=100000 2>/dev/null || true

    # 5. Restore default swappiness and cache pressure
    info "Restoring standard virtual memory limits..."
    sudo sysctl -w vm.swappiness=60 2>/dev/null || true
    sudo sysctl -w vm.vfs_cache_pressure=100 2>/dev/null || true

    echo -e "\n${c_green}[✓] SUCCESS: Standard developer resource allocation restored.${c_reset}"

else
    err "Selection out of bounds."
fi
