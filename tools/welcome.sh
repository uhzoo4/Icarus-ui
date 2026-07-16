#!/usr/bin/env bash
# tools/welcome.sh
# ICARUS-UI Master Greeting & CLI Dashboard Panel
# Deploys interactive control hooks for launchers, style managers, and accelerators.

set -e

# Theme colors
c_reset='\033[0m'
c_bold='\033[1m'
c_green='\033[1;32m'
c_yellow='\033[1;33m'
c_red='\033[1;31m'
c_blue='\033[1;34m'
c_magenta='\033[1;35m'
c_cyan='\033[1;36m'
c_white='\033[1;37m'

show_banner() {
    clear
    echo -e "${c_magenta}========================================================================${c_reset}"
    echo -e "${c_cyan}${c_bold}"
    echo -e "    ___                               _    _ ___ "
    echo -e "   |_ _| ___ __ _ _ __ _   _ ___     | |  | |_ _|"
    echo -e "    | | / __/ _\` | '__| | | / __|    | |  | || | "
    echo -e "    | || (_| (_| | |  | |_| \__ \\    | |__| || | "
    echo -e "   |___|\\___\\__,_|_|   \\__,_|___/     \\____/|___|"
    echo -e "${c_reset}"
    echo -e "            ${c_white}${c_bold}Welcome to your Hyper-Optimized KDE Desktop!${c_reset}"
    echo -e "${c_magenta}========================================================================${c_reset}"
}

show_system_info() {
    # Detect GPU
    GPU_INFO=$(lspci | grep -i -E "vga|3d" | head -n 1 | sed 's/.*: //')
    # Detect CPU
    CPU_INFO=$(grep -m 1 'model name' /proc/cpuinfo | sed 's/model name[[:space:]]*:[[:space:]]*//')
    # Detect RAM
    MEM_TOTAL=$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
    # Check HugePages status
    HP_STATUS=$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null | grep -o "\[.*\]" | tr -d '[]' || echo "unknown")
    # Check split-lock detection
    SL_STATUS=$(sysctl -n kernel.split_lock_detect 2>/dev/null || echo "1")

    echo -e "${c_bold}  💻 SYSTEM RESOURCE MATRIX:${c_reset}"
    echo -e "     ${c_cyan}OS / Core:${c_reset} EndeavourOS Linux (KDE Plasma 6 + Hyprland)"
    echo -e "     ${c_cyan}Processor:${c_reset} ${CPU_INFO:-Generic CPU}"
    echo -e "     ${c_cyan}Graphics :${c_reset} ${GPU_INFO:-Intel Iris Xe Graphics}"
    echo -e "     ${c_cyan}Memory   :${c_reset} ${MEM_TOTAL} RAM"
    echo -e ""
    echo -e "${c_bold}  ⚡ ENGINE METRICS:${c_reset}"
    echo -e "     ${c_cyan}Transparent HugePages    :${c_reset} $([[ "$HP_STATUS" == "always" ]] && echo -e "${c_green}Enabled${c_reset}" || echo -e "${c_yellow}Standard ($HP_STATUS)${c_reset}")"
    echo -e "     ${c_cyan}Split-Lock Protection    :${c_reset} $([[ "$SL_STATUS" == "0" ]] && echo -e "${c_green}Mitigated (Game Mode)${c_reset}" || echo -e "${c_yellow}Active (Workspace Mode)${c_reset}")"
    echo -e "     ${c_cyan}Ananicy Priority Daemon  :${c_reset} $(systemctl is-active --quiet ananicy-cpp && echo -e "${c_green}Running${c_reset}" || echo -e "${c_yellow}Inactive${c_reset}")"
    echo -e "     ${c_cyan}Wallpaper Adaptation     :${c_reset} $(systemctl --user is-active --quiet kde-material-you-colors && echo -e "${c_green}Running${c_reset}" || echo -e "${c_yellow}Inactive${c_reset}")"
    echo -e "${c_magenta}========================================================================${c_reset}"
}

main_menu() {
    show_banner
    show_system_info
    echo -e "  ${c_bold}CHOOSE DESKTOP INTERFACE ROUTINES:${c_reset}"
    echo -e "    ${c_cyan}1)${c_reset} 🎮 Engage Hyper-Fluid Game Mode (HugePages, split-lock, real-time)"
    echo -e "    ${c_cyan}2)${c_reset} 🧠 Restore Standard Workspace (resource-saving mode)"
    echo -e "    ${c_cyan}3)${c_reset} 🎨 Switch Desktop Style Profile (Sweet, Catppuccin, Katerial)"
    echo -e "    ${c_cyan}4)${c_reset} 🖼️ Switch Desktop Scenes / Wallpapers (live/static picker)"
    echo -e "    ${c_cyan}5)${c_reset} 🎵 Launch CAVA Audio Visualizer (with custom style selector)"
    echo -e "    ${c_cyan}6)${c_reset} 🔄 Restore/Manage Konsave Layout Snapshots"
    echo -e "    ${c_cyan}0)${c_reset} 🚪 Exit"
    echo -e "${c_magenta}========================================================================${c_reset}"
    read -rp "  Select Option: " OPTION

    case $OPTION in
        1)
            bash "$(dirname "$0")/system_core.sh"
            echo -e "\nPress Enter to return to menu..."; read -r
            main_menu
            ;;
        2)
            # Engage normal workspace mode
            # system_core option 2 restores default variables
            if [[ -f "$(dirname "$0")/system_core.sh" ]]; then
                echo "2" | bash "$(dirname "$0")/system_core.sh"
            fi
            echo -e "\nPress Enter to return to menu..."; read -r
            main_menu
            ;;
        3)
            # Run KDE theme profile installer
            if [[ -f "$(dirname "$0")/../configs/kde/install.sh" ]]; then
                bash "$(dirname "$0")/../configs/kde/install.sh"
            fi
            echo -e "\nPress Enter to return to menu..."; read -r
            main_menu
            ;;
        4)
            # Run wallpaper switcher
            if command -v icarus-wallpaper-switch &>/dev/null; then
                icarus-wallpaper-switch
            elif [[ -f "$(dirname "$0")/../configs/wallpaper/switcher.sh" ]]; then
                bash "$(dirname "$0")/../configs/wallpaper/switcher.sh"
            else
                echo -e "${c_red}Wallpaper switcher script not found!${c_reset}"
            fi
            echo -e "\nPress Enter to return to menu..."; read -r
            main_menu
            ;;
        5)
            # Run CAVA custom loader
            if [[ -f "${HOME}/.local/bin/cava-theme-loader.sh" ]]; then
                bash "${HOME}/.local/bin/cava-theme-loader.sh"
            elif [[ -f "$(dirname "$0")/../configs/cava/cava-theme-loader.sh" ]]; then
                bash "$(dirname "$0")/../configs/cava/cava-theme-loader.sh"
            else
                echo -e "${c_red}CAVA theme loader not found! Running standard CAVA...${c_reset}"
                cava || true
            fi
            echo -e "\nPress Enter to return to menu..."; read -r
            main_menu
            ;;
        6)
            if command -v konsave &>/dev/null; then
                echo -e "\nActive Konsave profiles:"
                konsave -l
                echo ""
                read -rp "Enter profile name to activate (or press Enter to cancel): " PROFILE_NAME
                if [[ -n "$PROFILE_NAME" ]]; then
                    konsave -a "$PROFILE_NAME" && echo -e "${c_green}Profile applied successfully!${c_reset}"
                fi
            else
                echo -e "${c_red}Konsave utility is not installed!${c_reset}"
            fi
            echo -e "\nPress Enter to return to menu..."; read -r
            main_menu
            ;;
        0)
            echo -e "\nGoodbye! Keep ricing! 🚀\n"
            exit 0
            ;;
        *)
            main_menu
            ;;
    esac
}

main_menu
