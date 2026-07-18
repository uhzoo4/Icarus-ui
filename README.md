<div align="center">

```
  ██╗ ██████╗ █████╗ ██████╗ ██╗   ██╗███████╗      ██╗   ██╗██╗
  ██║██╔════╝██╔══██╗██╔══██╗██║   ██║██╔════╝      ██║   ██║██║
  ██║██║     ███████║██████╔╝██║   ██║███████╗█████╗██║   ██║██║
  ██║██║     ██╔══██║██╔══██╗██║   ██║╚════██║╚════╝██║   ██║██║
  ██║╚██████╗██║  ██║██║  ██║╚██████╔╝███████║      ╚██████╔╝██║
  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝       ╚═════╝ ╚═╝
```

<h1>⚡ ICARUS-UI: THE ULTIMATE DESKTOP EXPERIENCE ⚡</h1>

<h3><em>Elite, Adaptive, Keyboard-Driven Desktop Customization for KDE Plasma & Hyprland</em></h3>

<br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge&logo=open-source-initiative)](LICENSE)
[![OS: EndeavourOS](https://img.shields.io/badge/OS-EndeavourOS-7B2FBE?style=for-the-badge&logo=arch-linux&logoColor=white)](https://endeavouros.com/)
[![OS: Fedora](https://img.shields.io/badge/OS-Fedora_Linux-294172?style=for-the-badge&logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![KDE: Plasma 6](https://img.shields.io/badge/KDE-Plasma_6-1D99F3?style=for-the-badge&logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)
[![WM: Hyprland](https://img.shields.io/badge/WM-Hyprland-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)](https://hyprland.org/)

<br/>

[![Theme: Sweet](https://img.shields.io/badge/Theme-Sweet--KDE-E040FB?style=for-the-badge)](https://github.com/EliverLara/Sweet)
[![Theme: Catppuccin](https://img.shields.io/badge/Theme-Catppuccin-CBA6F7?style=for-the-badge)](https://github.com/catppuccin)
[![Theme: Katerial](https://img.shields.io/badge/Theme-Katerial-F44336?style=for-the-badge)](https://github.com/yeyushengfan258/Katerial-kde)
[![Style: Darkly](https://img.shields.io/badge/Style-Darkly-1A1A2E?style=for-the-badge)](https://github.com/Bali10050/Darkly)
[![Blur: Better Blur DX](https://img.shields.io/badge/Blur-Better_Blur_DX-00B4D8?style=for-the-badge)](https://github.com/xarblu/kwin-effects-better-blur-dx)

<br/>

> *Icarus-UI is a premium full-stack desktop suite — not just dotfiles. It is a complete, automated installation system that deploys a curated collection of themes, blur effects, dynamic color engines, tiling window managers, animated wallpapers, custom panels, and performance tuning tools in a single command. Whether you use KDE Plasma or Hyprland, Icarus-UI transforms your desktop from a blank canvas into a breathing, adaptive, ultra-premium workstation.*

<br/>

</div>

---

## 📸 Gallery

<table>
  <tr>
    <td width="50%" align="center">
      <b>🌸 CHERRY BLOSSOM</b><br/>
      <img src="https://raw.githubusercontent.com/ComplexPlatform/KDE-dotfiles/master/previews/cherryblossom.png" width="100%" alt="Cherry Blossom Theme"/><br/>
      <i>Soft pink pastel accents, glassmorphic panels & animated wallpapers</i>
    </td>
    <td width="50%" align="center">
      <b>☕ COFFEE GRIND</b><br/>
      <img src="https://raw.githubusercontent.com/ComplexPlatform/KDE-dotfiles/master/previews/coffee.png" width="100%" alt="Coffee Theme"/><br/>
      <i>Warm sepia tones, glassmorphic containers & frosted sidebar</i>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <b>🏙️ URBAN MIDNIGHT</b><br/>
      <img src="https://raw.githubusercontent.com/ComplexPlatform/KDE-dotfiles/master/previews/urban.png" width="100%" alt="Urban Theme"/><br/>
      <i>Sleek neon purple and blue grids with sharp contrast</i>
    </td>
    <td width="50%" align="center">
      <b>🏔️ FOGGY MOUNTAIN</b><br/>
      <img src="https://raw.githubusercontent.com/ComplexPlatform/KDE-dotfiles/master/previews/foggy-mountain.png" width="100%" alt="Foggy Mountain Theme"/><br/>
      <i>Muted forest greens and deep misty greys</i>
    </td>
  </tr>
</table>

---

## 🧠 What is Icarus-UI?

Icarus-UI is **not** just another `~/.config` dump. It is a **fully automated deployment system** built around a layered architecture that:

- **Auto-detects** your Desktop Environment (KDE or Hyprland) and only installs what you need
- **Compiles nothing** unnecessary — all heavy components come from pre-built AUR/COPR packages
- **Backs up** your existing configs before overwriting them (`~/.config/hypr.bak.timestamp`)
- **Provides an uninstaller** (`uninstall.sh`) that safely undoes everything without touching your system packages
- **Works on EndeavourOS AND Fedora** with distro-aware package mapping built into every script

---

## ✨ Feature Overview

### 🖥️ KDE Plasma Suite

The KDE Plasma path is the flagship. It's the most feature-rich path, deploying a complete KDE customization stack.

| Feature | Package / Tool | Description |
|---|---|---|
| **Application Style** | [Darkly](https://github.com/Bali10050/Darkly) | Modern fork of Lightly — polished Qt widget style with transparency and refined geometry |
| **Blur Effect** | [Better Blur DX](https://github.com/xarblu/kwin-effects-better-blur-dx) | Advanced KWin blur with force-blur, corner radius, saturation, brightness & refraction |
| **Color Engine** | [KDE Material You Colors](https://github.com/luisbocanegra/kde-material-you-colors) | Wallpaper-adaptive color system using Google's Material Color Utilities algorithm |
| **Color Scheme** | Sweet / Catppuccin / Katerial | 3 major scheme families + 6 GTK sub-variants via ComplexPlatform dotfiles |
| **Window Decoration** | JuxDeco / CatppuccinMocha-Modern / Katerial Aurorae | Hand-picked Aurorae decorations matched per theme |
| **Plasma Theme** | Sweet / Katerial | Full Plasma shell themes (taskbars, systray, panels) |
| **GTK Themes** | Cherry Blossom, Coffee, Flowers, Foggy Mountain, Neutral, Urban | 6 ComplexPlatform GTK3/4 themes for a consistent cross-framework look |
| **Icon Theme** | Archos / WhiteSur | macOS-inspired and custom icon sets |
| **Cursor Theme** | Archos Cursors / WhiteSur Cursors / Aura Mew | Premium cursor packs |
| **Tiling Engine** | [Bismuth](https://github.com/Bismuth-Forge/bismuth) / [Krohnkite](https://github.com/esjeon/krohnkite) | KWin scripted tiling — auto-selects Bismuth (Plasma 5) or Krohnkite (Plasma 6) |
| **Shell Panel** | [Caelestia Shell](https://github.com/caelestia-dots/shell) (Quickshell) | Custom QML-based panel with C++ KWin bridge shims |
| **Dock** | [Latte Dock](https://github.com/KDE/latte-dock) | macOS-style application dock with bounce animations |
| **Kvantum Themes** | Katerial / NoMansSkyJux | Material Design Qt style engine overlays |
| **SDDM Login** | WhiteSur / Katerial | Custom login screen themes |
| **Color Sync** | plasma2telegram | Auto-syncs system accent colors to Telegram Desktop themes |
| **Profiles** | [Konsave](https://github.com/Prayag2/konsave) | Full desktop profile snapshot & restore system |
| **Font** | JetBrains Mono Nerd + Noto Fonts | Terminal and UI fonts |
| **Terminal** | Kitty | GPU-accelerated terminal with custom color profile |
| **Shell Prompt** | Starship | Cross-shell prompt with git, language, and system context |
| **System Info** | Fastfetch | KDE-optimized system info with magenta Icarus branding, cursor, display & theme modules |

---

### 🌿 Hyprland Suite

The Hyprland path delivers a pure Wayland compositor experience with a full-featured tiling workflow.

| Feature | Package / Tool | Description |
|---|---|---|
| **Compositor** | [Hyprland](https://hyprland.org/) | GPU-accelerated tiling Wayland compositor |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | Highly configurable system status bar with dynamic workspaces |
| **Launcher** | [Rofi (Wayland)](https://github.com/lbonn/rofi) | Application launcher with custom Icarus skin |
| **Notifications** | [Dunst](https://dunst-project.org/) | Lightweight, scriptable notification daemon |
| **Wallpaper** | mpvpaper / swaybg + icarus-wallpaper daemon | Live video wallpaper support with fullscreen-app auto-pause |
| **Widgets** | [EWW](https://github.com/elkowar/eww) | Elkowar's Wacky Widgets for custom desktop overlays |
| **Lock Screen** | [Hyprlock](https://github.com/hyprwm/hyprlock) | GPU-accelerated blur lock screen |
| **Idle Manager** | [Hypridle](https://github.com/hyprwm/hypridle) | Auto-dim, auto-lock, and auto-suspend on inactivity |
| **Power Menu** | Wlogout | Full-screen session management menu |
| **Color Engine** | icarus-palette.py | Material You wallpaper color extractor for Hyprland/Waybar |
| **OSD** | swayosd | On-screen display for volume, brightness, caps-lock |
| **Clipboard** | cliphist + wl-clipboard | Persistent Wayland clipboard history |
| **Night Mode** | wlsunset | Blue light filter / color temperature scheduler |

---

### 🔧 Shared Components (Both DEs)

These tools are installed regardless of DE choice:

| Tool | Description |
|---|---|
| **CAVA** | Real-time terminal audio spectrum visualizer with DE-matched gradient themes |
| **Neovim** | Pre-configured code editor with Icarus colorscheme |
| **Yazi** | Terminal file manager with image previews |
| **eza / bat / zoxide / fzf / ripgrep** | Modern CLI replacements for ls, cat, cd, find, grep |
| **Starship** | Cross-shell prompt |
| **Kitty** | GPU-accelerated terminal |
| **Fastfetch** | System information tool with custom Icarus logo |
| **Wallpaper Library** | 100+ curated static and live wallpapers in `/usr/share/backgrounds/icarus/` |
| **WhiteSur Wallpapers** | macOS-styled wallpaper sets (1080p, 2K, 4K) |
| **GTK3/4 Preferences** | Auto-written `settings.ini` for consistent GTK theming |
| **Archos Themes** | GTK + Icons + Cursors (full suite) |
| **WhiteSur Themes** | GTK + Icons + Cursors (full suite) |

---

### 🎬 Animated Boot & Wallpapers

| Component | Description |
|---|---|
| **Retroboot GRUB Theme** | Retro pixel-art animated GRUB boot menu |
| **Pochita GRUB Theme** | Chainsaw Man (Pochita) animated GRUB boot menu |
| **Live Video Wallpaper** | `.mp4`, `.webm`, `.gif` wallpapers via mpvpaper/icarus-wallpaper-daemon |
| **Auto-Pause Daemon** | Wallpaper video automatically pauses when a fullscreen app is detected |
| **Dynamic Switcher** | `icarus-wallpaper-switch` CLI tool to cycle between wallpapers |

---

## 🚀 Installation

### Prerequisites

- **EndeavourOS** (Arch-based) with `yay` or `paru` AUR helper, **OR**
- **Fedora Linux** 41+ with `dnf`
- **Git** installed
- A working internet connection

### Fresh Install

```bash
# Clone the repository
git clone https://github.com/uhzoo4/Icarus-ui.git
cd Icarus-ui

# Run the interactive setup
bash run.sh
```

The installer will:
1. Auto-detect if you're running **KDE Plasma** or **Hyprland**
2. Present a menu to confirm or change the target DE
3. Install all required packages (no compiling from source — uses AUR/COPR)
4. Deploy configs, themes, wallpapers, and fonts
5. Enable background services
6. Hot-reload your compositor/plasma session
7. Show a full deployment summary report

### Menu Options

```
1) Hyprland Preset Suite       — Tiling Wayland compositor + Waybar + Rofi
2) KDE Plasma Variant Theme    — Sweet/Catppuccin/Katerial + Material You
3) Animated GRUB (Retroboot)   — Retro-styled animated boot screen
4) Animated GRUB (Pochita)     — Pochita animated boot screen
5) Deploy Full Suite           — All of the above
```

---

## 🧹 Uninstalling / Fresh Start

If you need to wipe a previous installation and start clean, use the included uninstaller. It is designed to be **safe for EndeavourOS** — it only removes things Icarus added, not your system packages.

```bash
bash uninstall.sh
```

This will:
- Remove Icarus dotfiles (`~/.config/hypr`, `waybar`, `rofi`, etc.)
- Remove Icarus themes, icons, cursors from `~/.themes` and `~/.local/share/`
- Stop and remove Icarus systemd user services
- Remove custom scripts from `~/.local/bin` and `/usr/local/bin`
- Clean Icarus hooks from `~/.bashrc`
- Uninstall Icarus add-on packages (`darkly`, `kwin-effects-better-blur-dx`, `eww-wayland`, etc.)
- Reset KDE to Breeze defaults

> **Note:** Your EndeavourOS base packages (`dolphin`, `kitty`, `fastfetch`, etc.) will **not** be removed.

For a complete nuclear wipe (removes shared tools too):

```bash
bash uninstall.sh --full
```

---

## 🔄 Updating

Pull the latest changes and redeploy:

```bash
bash update.sh
```

---

## 🗂️ Repository Structure

```
Icarus-ui/
│
├── run.sh                    # 🚀 Master installer — start here
├── uninstall.sh              # 🧹 Safe uninstaller (EndeavourOS-aware)
├── update.sh                 # 🔄 Pull latest & redeploy
├── apply-extra.sh            # 🎨 Shared assets installer (themes, wallpapers, configs)
│
├── configs/                  # All user-facing configuration files
│   ├── hypr/                 # Hyprland compositor config + scripts
│   ├── waybar/               # Waybar status bar config & styles
│   ├── rofi/                 # Rofi launcher themes
│   ├── kitty/                # Kitty terminal colorscheme
│   ├── dunst/                # Notification daemon styling
│   ├── cava/                 # Audio visualizer gradient profiles
│   ├── eww/                  # EWW widget definitions & scripts
│   ├── nvim/                 # Neovim configuration
│   ├── yazi/                 # Terminal file manager config
│   ├── fastfetch/            # System info display (custom Icarus logo)
│   ├── wlogout/              # Power menu styles
│   ├── wallpaper/            # Wallpaper daemon scripts & references
│   ├── fonts/                # Custom local fonts
│   ├── themes/               # GTK theme files
│   ├── icons/                # Icon theme files
│   ├── cursors/              # Cursor theme files
│   ├── sddm/                 # SDDM login screen themes
│   ├── kde/                  # KDE-specific configs
│   │   └── install.sh        # 750-line KDE Plasma installer
│   └── bootloader/           # GRUB theme installer
│
├── pkgs/                     # Packaged source assets
│   ├── kde/                  # KDE-specific packages
│   │   ├── kde-material-you-colors/   # Material You plasmoid bundled
│   │   └── caelestia-src/            # Caelestia KWin bridge source
│   ├── themes/               # GTK/Icon/Cursor theme sources
│   │   ├── Archos-gtk-theme/
│   │   ├── Archos-icon-theme/
│   │   ├── Archos-cursors/
│   │   ├── WhiteSur-gtk-theme/
│   │   ├── WhiteSur-icon-theme/
│   │   ├── WhiteSur-cursors/
│   │   ├── WhiteSur-wallpapers/
│   │   └── Aura-Mew-Cursor/
│   └── bootloader/           # GRUB theme zips
│
├── tools/                    # Utility scripts
│   ├── icarus-palette.py     # Wallpaper color extractor (Material You)
│   ├── welcome.sh            # Interactive CLI dashboard
│   ├── random_image.sh       # Terminal visual greeting
│   ├── system_core.sh        # Gaming/performance mode toggle
│   └── alist-handler         # Media stream handler
│
└── layers/                   # Layer manifest (architecture reference)
    └── MANIFEST
```

---

## ⚙️ How It Works (Architecture)

```
bash run.sh
     │
     ├─ Auto-detects DE (KDE / Hyprland)
     │
     ├─ [KDE Plasma Path]
     │   ├─ apply-extra.sh --kde
     │   │   ├─ Install: kitty, fastfetch, cava, starship, eza, bat...  (shared tools)
     │   │   ├─ Compile: Archos GTK + Icon + Cursor themes
     │   │   ├─ Deploy: Wallpaper library → /usr/share/backgrounds/icarus/
     │   │   └─ Deploy: User configs → ~/.config/ (kitty, cava, nvim, yazi, fastfetch)
     │   │
     │   └─ configs/kde/install.sh
     │       ├─ AUR: darkly + kwin-effects-better-blur-dx + kde-material-you-colors
     │       ├─ Deploy: Sweet, Catppuccin, Katerial themes → ~/.local/share/
     │       ├─ Deploy: 6 ComplexPlatform GTK themes → ~/.themes/
     │       ├─ Deploy: Kvantum themes → ~/.config/Kvantum/
     │       ├─ Install: Bismuth / Krohnkite tiling (auto-selected)
     │       ├─ Configure: Caelestia Shell + KWin bridge
     │       ├─ Configure: Konsave safety snapshot
     │       └─ Apply: kwriteconfig6 (theme, style, blur, tiling) → KWin reconfigure
     │
     └─ [Hyprland Path]
         └─ apply-extra.sh --hyprland
             ├─ Install: hyprland, waybar, rofi-wayland, eww-wayland, wlogout...
             ├─ Deploy: Hyprland + Waybar + Rofi + Dunst + EWW configs
             ├─ Generate: Material You color palette from default wallpaper
             ├─ Hot-reload: hyprctl reload + waybar restart
             └─ Launch: icarus-wallpaper daemon
```

---

## 🎨 Theme Deep-Dive

### Sweet-KDE

A deep purple-pink gradient theme built by [EliverLara](https://github.com/EliverLara). Includes a full Plasma shell theme, Aurorae window decorations (JuxDeco), and integrated Konsole color profile. Paired with the **Darkly** application style for refined widget rendering.

### Catppuccin (4 Flavors)

The [Catppuccin](https://github.com/catppuccin) project's KDE port, deployed in all four flavors: **Mocha** (default), **Macchiato**, **Frappé**, and **Latte**. Each flavor includes a color scheme, Aurorae window decoration, and LookAndFeel profile for one-click switching.

### Katerial

A flat Google Material Design inspired theme by [yeyushengfan258](https://github.com/yeyushengfan258). Deploys a full suite: Kvantum application style (`Katerial_Light_RedPink`), Plasma shell theme, Aurorae decorations, and a matching SDDM login screen.

### Darkly (Application Style)

[Darkly](https://github.com/Bali10050/Darkly) is a fork of the **Lightly** Qt application style, featuring a refined dark aesthetic with subtle transparency and modern geometry. It is installed via AUR (`yay -S darkly`) and applied globally as the KDE widget style — replacing the old Kvantum-only approach. Works seamlessly across all Icarus theme profiles.

### KDE Material You Colors

[KDE Material You Colors](https://github.com/luisbocanegra/kde-material-you-colors) by luisbocanegra is a wallpaper-adaptive color engine. It reads your current wallpaper, extracts dominant colors using Google's **Material Color Utilities** algorithm, and dynamically updates your entire KDE color scheme — accent colors, window borders, taskbar highlights — in real-time whenever you change your wallpaper. Installed via AUR and auto-started as a background daemon.

### Better Blur DX

[Better Blur DX](https://github.com/xarblu/kwin-effects-better-blur-dx) is the modern continuation of the popular **kwin-effects-forceblur** project. It provides:
- **Force blur** for any window class
- Adjustable blur **brightness, contrast, and saturation**
- Custom **corner radius** on blurred regions
- **Refraction** effects
- Bug fixes for blur disappearing during animations

Installed via AUR (`yay -S kwin-effects-better-blur-dx`) and automatically enabled in KWin, with the default blur effect disabled to avoid conflicts.

---

## 🎵 CAVA Audio Visualizer

CAVA (Console-based Audio Visualizer for Alsa) is pre-configured with **gradient profiles that dynamically match each KDE theme**:

| Profile | Colors |
|---|---|
| Sweet | Purple → Pink gradient |
| Catppuccin Mocha | Mauve → Lavender gradient |
| Katerial | Red → Pink Material gradient |
| Default | Magenta → Cyan (Icarus branding) |

Launches automatically in terminal sessions and syncs with theme changes.

---

## 🖼️ Fastfetch (System Info)

A custom fastfetch configuration is deployed to `~/.config/fastfetch/config.jsonc` featuring:

- **Custom Icarus ASCII logo** (`logo.txt`)
- **Magenta color scheme** matching Icarus-UI branding
- **Premium `━` separator bars** between sections
- **KDE-specific modules**: DE, WM, WM Theme, App Style, Icons, Cursor, Display resolution
- **Hardware modules**: CPU, GPU, RAM (`used / total (%)` format), Disk, Battery
- **Color palette swatch** at the bottom

```
██              ██
████            ████       yoozhaa@icarus-pc
...                        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ICARUS-OS                 OS  EndeavourOS
   by yoozhaa              󰟀 Host  ...
                             Kernel  6.x.x-zen
                            󰅐 Uptime  2h 13m
                            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            󰍹 DE     KDE Plasma 6.x
                             WM     KWin
                            󰏘 WM Theme  JuxDeco
                            󰉼 Theme   Sweet [Plasma], Darkly [Qt]
```

---

## 🛠️ Utility Scripts

### `icarus-welcome` — Interactive CLI Dashboard
An interactive terminal dashboard for controlling Icarus-UI features:
- Toggle gaming/performance mode
- Launch color scheme switcher
- Select wallpapers
- Restore Konsave layout backups

### `random_image.sh` — Terminal Visual Greeting
Integrated with the Kitty terminal. On every new shell, displays a randomly selected wallpaper preview alongside system information for a dynamic terminal opener.

### `cava-theme-loader.sh` — Audio Visualizer Theme Picker
Dynamically swaps CAVA's gradient configuration to match the currently active Icarus desktop theme.

### `system_core.sh` — Gaming Performance Mode
Toggles `gamemode` (CPU governor, GPU performance bias, process priority), `ananicy-cpp` (process scheduler rules), and `sched_ext` scheduler tuning for peak gaming and compute workloads.

### `icarus-palette.py` — Wallpaper Color Extractor
The core Hyprland color engine. Reads any wallpaper image and extracts Material You accent colors, writing them as shell variables sourced by Hyprland, Waybar, and Rofi configs. Gives Hyprland the same dynamic wallpaper-adaptive theming that KDE gets from Material You Colors.

### `plasma2telegram` — Telegram Theme Sync
A background daemon that watches for KDE color scheme changes and automatically updates Telegram Desktop's theme to match the current system accent color.

---

## 📋 Tips & Keybinds

### KDE Plasma

| Action | Command / Location |
|---|---|
| Change wallpaper | Right-click desktop → Configure Desktop |
| Auto-adapt colors | Material You Colors daemon runs in background |
| Restore backup | `konsave -a icarus-default` |
| List profiles | `konsave -l` |
| Gaming mode | `bash tools/system_core.sh` |
| CLI Dashboard | `icarus-welcome` |

### Hyprland

| Keybind | Action |
|---|---|
| `SUPER + D` | Open Rofi app launcher |
| `SUPER + W` | Open wallpaper selector |
| `SUPER + RETURN` | Open Kitty terminal |
| `SUPER + Q` | Close active window |
| `SUPER + Arrow` | Move focus between windows |
| `SUPER + SHIFT + Arrow` | Move window in grid |

### System

| Command | Description |
|---|---|
| `fastfetch` | Display system info with Icarus logo |
| `icarus-wallpaper` | Launch wallpaper daemon |
| `icarus-palette /path/to/wallpaper.png` | Regenerate color palette |
| `icarus-wallpaper-switch` | Cycle to next wallpaper |
| `konsave -s my-profile` | Save current KDE profile |
| `konsave -a my-profile` | Apply a saved KDE profile |

---

## 🏗️ Architecture Notes

Icarus-UI is built on a **layered architecture**:

| Layer | Responsibility |
|---|---|
| Layer 1 | Disk partitioning, Btrfs subvolumes, flash-wear tuning |
| Layer 2 | Base system bootstrap |
| Layer 3a | Guaranteed-bootable kernel + systemd-boot |
| Layer 3b | Custom kernel build (non-fatal) |
| Layers 3c–4 | Daemons, graphics stack, GPU generation detection |
| Layer 5 | Desktop environment (Hyprland / KDE Plasma) — this suite |
| Layer 6 | iGPU compute (OpenVINO/PyTorch-XPU), sched_ext, memory tuning |
| Layer 7 | Native browser, Office, AUR helper bootstrap |
| Layer 8 | Plymouth silent boot |
| Layer 9 | Opt-in curated application profiles |

---

## 🐛 Resolved Engineering Challenges

| Challenge | Resolution |
|---|---|
| **6+ hour install times** | Replaced all manual C++/Python compilations with pre-built AUR packages (`darkly`, `kwin-effects-better-blur-dx`, `kde-material-you-colors`) — install time dropped to ~5–10 minutes |
| **PEP 668 pip lockout** | Python packages redirected to `~/.local/lib/python-icarus` with dynamic `PYTHONPATH` injection |
| **Material You entrypoint** | Created `__main__.py` entry for automated `python3 -m kde_material_you_colors` execution on boot |
| **Qt6 Bismuth compilation** | Automated CMake compilation scripts with seamless Krohnkite fallback for Plasma 6 |
| **C++ DBus screenshot helper** | CMake scripts configured against Qt6 DBus for desktop portal API integration |
| **EndeavourOS safety** | `uninstall.sh` rewritten to detect and skip system packages — only removes Icarus additions |
| **bash `set -euo pipefail` crashes** | Non-critical asset operations guarded with `|| true`, critical ones allowed to fail loudly |
| **AUR build failures** | `base-devel` + kernel headers enforced before any AUR helper bootstrapping |
| **CAVA config parse errors** | Stripped invalid string quotes from INI-style hex color values |
| **Hyprland running during uninstall** | `HYPRLAND_INSTANCE_SIGNATURE` check prevents removing Hyprland packages from active session |

---

## 🤝 Third-Party Credits

Icarus-UI integrates and automates the installation of work from many talented creators:

| Project | Author | License |
|---|---|---|
| [Sweet KDE](https://github.com/EliverLara/Sweet) | EliverLara | GPL-3.0 |
| [Catppuccin KDE](https://github.com/catppuccin/kde) | Catppuccin Org | MIT |
| [Katerial KDE](https://github.com/yeyushengfan258/Katerial-kde) | yeyushengfan258 | GPL-3.0 |
| [Darkly](https://github.com/Bali10050/Darkly) | Bali10050 | GPL-2.0 |
| [Better Blur DX](https://github.com/xarblu/kwin-effects-better-blur-dx) | xarblu | MIT |
| [KDE Material You Colors](https://github.com/luisbocanegra/kde-material-you-colors) | luisbocanegra | GPL-3.0 |
| [Caelestia Shell](https://github.com/caelestia-dots/shell) | Caelestia | GPL-3.0 |
| [ComplexPlatform Dotfiles](https://github.com/ComplexPlatform/KDE-dotfiles) | ComplexPlatform | MIT |
| [WhiteSur GTK Theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) | vinceliuice | GPL-3.0 |
| [WhiteSur Icon Theme](https://github.com/vinceliuice/WhiteSur-icon-theme) | vinceliuice | GPL-3.0 |
| [WhiteSur Wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) | vinceliuice | CC-BY-SA-4.0 |
| [Catppuccin](https://github.com/catppuccin) | Catppuccin Org | MIT |
| [CAVA](https://github.com/karlstav/cava) | karlstav | MIT |
| [Fastfetch](https://github.com/fastfetch-cli/fastfetch) | fastfetch-cli | MIT |
| [Starship](https://starship.rs/) | Starship Devs | ISC |
| [Konsave](https://github.com/Prayag2/konsave) | Prayag2 | GPL-3.0 |
| [Bismuth](https://github.com/Bismuth-Forge/bismuth) | Bismuth-Forge | GPL-3.0 |
| [Krohnkite](https://github.com/esjeon/krohnkite) | esjeon | MIT |

Full third-party license text is available in [THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md).

---

## ⚖️ License

This project is open-source software licensed under the [MIT License](LICENSE).

---

<div align="center">

```
  ██╗ ██████╗ █████╗ ██████╗ ██╗   ██╗███████╗      ██╗   ██╗██╗
  ██║██╔════╝██╔══██╗██╔══██╗██║   ██║██╔════╝      ██║   ██║██║
  ██║██║     ███████║██████╔╝██║   ██║███████╗      ██║   ██║██║
  ██║██║     ██╔══██║██╔══██╗██║   ██║╚════██║      ██║   ██║██║
  ██║╚██████╗██║  ██║██║  ██║╚██████╔╝███████║      ╚██████╔╝██║
  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝       ╚═════╝ ╚═╝
```

**Icarus-UI Configuration Suite** • *Optimized to the limits. Enjoy the flight.* ⚡

*Built with obsession. Deployed with a single command.*

</div>
