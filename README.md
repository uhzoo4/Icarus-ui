<div align="center">

```text
  █████▒ ▒█████   ██▀███   ▄████▄   ██▀███   ▄████▄    ██████ 
▓██   ▒ ▒██▒  ██▒▓██ ▒ ██▒▒██▀ ▀█  ▓██ ░▄█ ▒▒██▀ ▀█  ▒██    ▒ 
▒████ ░ ▒██░  ██▒▓██ ░▄█ ▒▒▓█    ▄ ▓██ ░▄█ ▒▒▓█    ▄ ░ ▓██▄   
░▓█▒  ░ ▒██   ██░▒██▀▀█▄  ▒▓▓▄ ▄██▒▒██▀▀█▄  ▒▓▓▄ ▄██▒  ▒   ██▒
░▒█░    ░ ████▓▒░░██▓ ▒██▒▒ ▓███▀ ░░██▓ ▒██▒▒ ▓███▀ ░▒██████▒▒
 ▒ ░    ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░ ░▒ ▒  ░░ ▒▓ ░▒▓░░ ░▒ ▒  ░░ ▒▓▒ ▒ ░
 ░        ░ ▒ ▒░   ░▒ ░ ▒░  ░  ▒     ░▒ ░ ▒░  ░  ▒   ░ ░▒  ░ ░
 ░ ░    ░ ░ ░ ▒    ░░   ░ ░          ░░   ░ ░          ░  ░  
            ░ ░     ░     ░ ░         ░     ░ ░             ░
                          ░                 ░                
```

# ICARUS UI — SYSTEM RICE & CONFIGURATION SUITE
**The Premium Multi-Distro Desktop Customization for Fedora, CachyOS, and Arch Linux**

[![Fedora Linux](https://img.shields.io/badge/OS-Fedora_Linux-blue.svg?logo=fedora&logoColor=white&style=for-the-badge)](#)
[![CachyOS](https://img.shields.io/badge/OS-CachyOS-cyan.svg?logo=arch-linux&logoColor=white&style=for-the-badge)](#)
[![Arch Linux](https://img.shields.io/badge/OS-Vanilla_Arch-blue.svg?logo=arch-linux&logoColor=white&style=for-the-badge)](#)
[![Compositor](https://img.shields.io/badge/WM-Hyprland-orange.svg?style=for-the-badge)](#)
[![Desktop Preset](https://img.shields.io/badge/Variant-KDE_Plasma-green.svg?style=for-the-badge)](#)

*Icarus UI is an elite, multi-distro-safe desktop customization suite. It is designed to deploy premium GTK/icon assets, window decorations, dynamic video color generators, animations, panels, and custom-compiled tiling layouts seamlessly across Fedora, CachyOS, and Arch Linux systems.*

</div>

---

## ⚡ Main Highlights & Custom Features

### 🍏 macOS-Style Desktop Preset (`mac-style`)
A premium macOS-inspired workspace workflow consisting of:
- **Interactive Bottom Dock**: A floating, glassmorphic app dock built natively using Waybar. It features pinned quick-launchers (Finder, Safari, Terminal) and active task indicators that zoom and bounce dynamically using custom-tuned CSS scale transitions.
- **Fullscreen Launchpad**: An immersive application grid launcher styled within Rofi, mapped directly to `SUPER+A`.
- **Top Menu Bar**: A sleek, centered top bar layout with an Apple-style application menu, central calendar clock, and quick-access indicators.

### 🎛️ Eww Control Center Dashboard
A custom dashboard utility mapped to `SUPER+D` or toggled by clicking the Control Center button (``) on the top bar:
- Includes interactive volume and brightness scales.
- Quick network, Bluetooth, and notification toggles.
- Real-time CPU usage, RAM utilization, disk stats, and media playing controls.

### 🎥 Video Wallpaper & Material color Palette
- **Palette Generator**: When switching video or static wallpapers, `ffmpeg` and our Python engine analyze the background to dynamically generate a Material You color system (`colors.conf` and `colors.scss`) applied across Hyprland, Waybar, kitty, and Rofi instantly.
- **Pause Daemon**: A background service monitors battery states and fullscreen windows to automatically pause live wallpaper rendering to save resources.

### 🖥️ KDE Plasma Variant (Jux Preset Theme)
For users who prefer KDE Plasma, the codebase includes a complete alternative desktop theme suite under `configs/kde/`:
- **Mystical-Blue Theme**: Custom global colors (`JuxTheme.colors`), window frame decorations (`JuxDeco`), and Kvantum templates (`NoMansSkyJux`).
- **KWin Dynamic Tiling (Krohnkite)**: Bundled krohnkite tiling scripts to bring bspwm/dwm-like tiling into your KWin compositor.
- **Force Blur Compiler**: An automated script compiles and installs the KWin Force Blur plugin from source, adding glassmorphism to transparent window layers.

### 📦 Smart Wallpaper Bank Installer
To prevent repository bloat, we use a smart installer framework:
- A curated selection of **15 peak wallpapers** (under 15MB) is permanently stored in the repository.
- If the full wallpaper zip archive is present locally, the installer automatically copies the entire **780MB wallpaper bank** straight to `/usr/share/backgrounds/icarus/references/`.

---

## 🚀 How to Deploy on a Booted System

To apply this custom desktop configuration, wallpapers, panels, and widget styles to your running system:

```bash
# Clone the repository
git clone https://github.com/uhzoo4/Icarus-ui.git
cd Icarus-ui

# Run the master user configuration launcher
bash run.sh
```

### Component Selector:
You can choose to install specific modules (Hyprland, KDE, or GRUB bootloader) or deploy the entire workspace:
```bash
# Run the installer and choose your option from the menu:
bash run.sh
```

---

## 📊 Project Status & Recent Milestones

The Icarus UI project is **98% complete** and fully deployable as a stable visual suite.

### 🛠️ What We Worked On Recently:
1. **Unified Setup Flow**: Consolidated all component installations (Hyprland desktop, KDE Plasma variants, animated GRUB themes) into a single interactive chooser menu inside [run.sh](file:///d:/WebProjects/icarus-ui/run.sh).
2. **KDE Dynamic Color Scheme Engine**: Extended our Python dynamic palette switcher ([tools/icarus-palette.py](file:///d:/WebProjects/icarus-ui/tools/icarus-palette.py)) to construct and apply colors to KDE's `JuxTheme.colors` config folder dynamically whenever the desktop wallpaper changes.
3. **Animated Bootloader**: Extracted the custom animated **Retroboot** and **Pochita** GRUB themes from stolen repositories, added them to the tree, and built a distro-aware GRUB config builder script ([configs/bootloader/install.sh](file:///d:/WebProjects/icarus-ui/configs/bootloader/install.sh)).
4. **Clean Asset Directory Layout**: Moved fastfetch logos and GRUB template backdrops out of the desktop wallpaper path, and renamed all custom wallpaper assets to fit a strict sequential numbering scheme (`173.png` to `183.jpg`).

---

## 📂 Repository Folder Layout

```text
Icarus-ui/
├── apply-extra.sh                  # Distro-aware package and configuration installer
├── run.sh                          # Master setup orchestrator (interactive menu)
├── update.sh                       # Updates workspace files
├── configs/
│   ├── hypr/                       # Hyprland workflows (mac-style, gaming, etc.) and curves
│   ├── waybar/                     # Top panels and macOS bottom Dock layouts
│   ├── eww/                        # Control Center widgets and scripts
│   ├── kde/                        # KDE Plasma Jux Theme variant and install scripts
│   ├── bootloader/                 # GRUB theme configuration builder and updater
│   ├── rofi/                       # Launchpad and Spotlight launcher themes
│   ├── dunst/                      # Glassmorphic notifications
│   ├── fastfetch/                  # Boxed hardware logo layouts and png directories
│   ├── kitty/                      # Terminal settings with smart copy/paste binds
│   ├── cava/                       # Audio visualizer profiles
│   ├── yazi/                       # Yazi file manager configurations
│   └── wallpaper/                  # Wallpaper switchers and reference images
├── pkgs/
│   ├── themes/                     # Pre-packaged WhiteSur GTK and cursor themes
│   ├── sddm-themes/                # SDDM Astronaut and Silent login screen templates
│   ├── bootloader/                 # Compressed animated GRUB themes (Retroboot, Pochita)
│   └── kde/                        # Krohnkite & Force Blur source modules
└── tools/
    └── icarus-palette.py           # Color palette generator
```

---

<div align="center">
Optimized to the limits. Enjoy the flight.
</div>
