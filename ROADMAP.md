# Icarus-ArchOS — Roadmap & Extension Guide

This exists so future customization has somewhere to go instead of turning
into ad-hoc edits scattered across scripts. Read this before adding
anything new.

## Current state (as of this writing)

**Solid / done:**
- Partitioning, Btrfs subvolumes, flash-wear tuning (Layer 1)
- Base bootstrap (Layer 2)
- Guaranteed-bootable stock kernel + systemd-boot (Layer 3a)
- Custom kernel build, non-fatal by design (Layer 3b)
- Daemons, graphics stack, GPU-generation detection (Layers 3c–4)
- Hyprland desktop, Waybar, Rofi, greetd login, Wine-Wayland, lock screen
  (hyprlock), idle management (hypridle), styled notifications (dunst),
  power menu (wlogout), system info (fastfetch), audio visualizer (cava),
  Eww dashboard, wallpaper-driven dynamic accent-color system
  (`icarus-palette.py`) (Layer 5)
- iGPU compute stack (OpenVINO/PyTorch-XPU), sched_ext scheduler,
  memory/thermal tuning, dev tooling (Layer 6)
- Native browser/Office layer + AUR helper bootstrap (Layer 7)
- Plymouth silent boot, systemd-boot only (Layer 8)
- Opt-in curated application profiles sourced from Awesome Linux Software
  discovery (Layer 9)
- Bluetooth service and the Blueman dashboard control (Layer 5)
- Manifest-driven conductor (`layers/MANIFEST`) — see "Adding a new layer" below
- `burn-in-checklist.md` for post-install validation
- Repository contract checks and GitHub Actions validation (`scripts/verify-repo.sh`)

**Open / in progress:**
- `pkgs/linux-icarus/PKGBUILD` targets `7.2-rc1` via git+tag — verify the
  PGP signature check actually passes once built for real, on real network
  access (see the PKGBUILD's own header comments)
- No custom kernel patches yet — `pkgs/linux-icarus/` currently has none;
  see "Adding a kernel patch" below for where they'd go
- Layer 7's AUR bootstrap (`paru`) hasn't been tested against a real
  network — if it fails, Chromium/LibreOffice from earlier in the same
  layer are unaffected, but Chrome/Teams/Edge/VS Code/eww-wayland/theme
  packages won't install until it's fixed
- Specific engineering/CAD software (MATLAB, SolidWorks, etc.) isn't
  mapped yet — Wine compatibility varies wildly per app; needs a
  per-app decision (native/web/Wine/VM) once the actual list is known
- No proper hibernate support — this system has zero disk-backed swap
  (ZRAM only), so hibernation cannot work as-is; the wlogout "Hibernate"
  option was removed rather than shipped broken. Real implementation
  needs a Btrfs-aware swapfile (NOCOW, sized ≥ RAM) plus `resume=` /
  `resume_offset=` kernel parameters on both boot entries — see the
  backlog below.
- No firewall — the desktop Bluetooth stack is installed, but inbound-network
  policy remains an intentional open item
- CI now checks shell/Python syntax plus manifest, theme, dashboard,
  wallpaper, and safety contracts. A complete install and the hardware
  burn-in checklist are still required before trusting a release.


## The rule for anything new

**Every layer must survive being interrupted and re-run.** That means:
idempotent operations where possible (checks before creates/deletes),
a sentinel written only on total success, and a clear decision — made
explicitly in `layers/MANIFEST`, not left implicit — about whether a
failure here should stop the whole install (`fatal`) or just get logged
and skipped (`soft`). When in doubt, anything touching boot configuration
is `fatal`; anything that's a nice-to-have on top of an already-bootable
system is a candidate for `soft`.

## Adding a new layer

1. Copy `layers/TEMPLATE.sh` to `layers/NN-your-name.sh` (pick a number
   that reflects where it belongs in the sequence — gaps are fine, e.g.
   `06-`, `07-`, or `04b-` if it needs to slot between existing ones).
2. Fill in the sentinel names, previous-layer dependency, and the actual
   work.
3. Add one line to `layers/MANIFEST`. `icarus-assemble.sh` does not need
   to change — it reads the manifest at runtime.
4. If it needs a new global flag (like `--force-xe`), add it to
   `icarus-assemble.sh`'s arg parser and export it alongside the existing
   `ICARUS_*` variables — every layer already receives the full set via
   environment, so no per-layer plumbing is needed beyond that one export.
5. Test standalone first: layers can be run directly with `--target`
   (and whichever other flags they need) without going through the full
   conductor, as long as the previous layer's sentinel already exists.

## Adding a kernel patch

Drop `.patch` files into `pkgs/linux-icarus/patches/` (create the
directory) and add an `applypatch()` loop to the PKGBUILD's `prepare()`,
after `make defconfig` and before the `scripts/config` calls — patches
against a stock tree, config changes on top of that. Update
`sha256sums`/the source array if a patch changes what needs verifying.
Re-run the burn-in checklist after any kernel patch, not just after a
kernel version bump — patches are exactly the kind of change that can
silently break a driver defconfig doesn't cover.

## Backlog — ideas that don't have a home yet

Rough categories, not commitments. Move an item into an actual layer (or
a new one) when you're ready to build it, rather than half-implementing it
inline somewhere it doesn't belong.

**Hardware / kernel**
- Per-laptop-model config fragments (if this ever targets more than one
  machine) — would live as additional files under `pkgs/linux-icarus/`,
  selected via a new conductor flag, not as branches inside the PKGBUILD.
- ~~Thermal/fan control tuning~~ — done via `thermald` in Layer 6.
- GTT (iGPU shared-memory) size tuning for AI workloads on 8GB total RAM
  — not addressed yet; worth investigating once real OpenVINO/llama.cpp
  workloads reveal whether the default carveout is actually a constraint.
- **Proper hibernate support.** Needs: a Btrfs-aware swapfile (NOCOW via
  `chattr +C`, sized ≥ total RAM, allocated with `fallocate` not sparse),
  the physical offset computed for `resume_offset=`, and `resume=UUID=...
  resume_offset=...` added to both `icarus-fallback.conf` and
  `icarus-custom.conf`. The wlogout "Hibernate" button was removed rather
  than shipped against a swap setup (ZRAM-only) that can't actually
  survive a full power-off. This touches Layer 1 (swapfile), 3a, and 3b
  (boot params) — do it as its own focused pass, not bundled into
  unrelated changes.
- A firewall (`ufw` or `firewalld`) — this system currently has none.

**Desktop / UX**
- Additional Waybar modules (media player controls, weather, etc.)
- A proper macOS-style dock (e.g. `nwg-dock-hyprland`) instead of relying
  on Waybar alone for app switching
- Per-app Hyprland window rules beyond the current Wine defaults

**Windows compatibility**
- Per-application Bottles presets checked into the repo (exported Bottles
  configs, not the runtime prefixes themselves) so a fresh install doesn't
  start from zero on app-specific tweaks
- GPU passthrough / DXVK-specific tuning if gaming performance becomes a
  priority beyond general app compatibility
- Specific engineering/CAD software mapping (see "Open / in progress"
  above) — this is the actual next step once the app list is known,
  probably a `layers/09-engineering-apps.sh` (Layer 8 is now Plymouth
  silent boot) or a QEMU/KVM Windows VM for anything Wine genuinely
  can't handle

**Operational**
- A `snapshot` layer using Btrfs snapshots of `@` before risky changes
  (kernel upgrades especially), with a rollback script — this is probably
  the single highest-value addition given everything else already assumes
  Btrfs
- Add a bootable VM smoke test once a reproducible Arch image pipeline exists;
  the current CI validates repository contracts but intentionally cannot test
  firmware, graphics, or a real disk install

## Versioning this repo

Given `.git` is already in use: tag a commit right after a successful
full install + a clean `burn-in-checklist.md` pass, before starting the
next round of customization. That gives you a known-good point to diff
against and revert to if a future change regresses something that used to
work — cheap insurance for exactly the kind of "heavy, complex" iteration
this roadmap exists to support.
