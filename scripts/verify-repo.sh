#!/usr/bin/env bash
#
# Fast, host-safe validation for the Icarus installer repository. This does
# not attempt to install Arch packages or mutate a target system; that remains
# the job of burn-in-checklist.md on real hardware.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
    echo "verify-repo: ERROR: $*" >&2
    exit 1
}

require_file() {
    [[ -f "$1" ]] || fail "missing required file: $1"
}

echo "==> Validating manifest"
manifest_lines=0
while IFS=':' read -r name context failure_mode script extra; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    manifest_lines=$((manifest_lines + 1))

    [[ -z "${extra:-}" ]] || fail "manifest entry '$name' has too many fields"
    [[ "$name" =~ ^layer-[0-9]+[a-z]?-[a-z0-9-]+$ ]] || fail "invalid layer name: $name"
    [[ "$context" == "host" || "$context" == "chroot" ]] || fail "invalid context for $name: $context"
    [[ "$failure_mode" == "fatal" || "$failure_mode" == "soft" ]] || fail "invalid failure mode for $name: $failure_mode"
    [[ "$script" != */* && "$script" == *.sh ]] || fail "invalid layer script for $name: $script"
    require_file "layers/$script"

    grep -Fq 'SENTINEL="${ICARUS_LOG_DIR}/'"$name"'.done"' "layers/$script" \
        || fail "$name does not define its expected sentinel"
done < layers/MANIFEST
(( manifest_lines > 0 )) || fail "layers/MANIFEST has no layer entries"

echo "==> Checking shell and Python syntax"
mapfile -d '' shell_files < <(find layers configs scripts -type f -name '*.sh' -print0)
(( ${#shell_files[@]} > 0 )) || fail "no shell scripts found"
bash -n "${shell_files[@]}"

python_bin="python3"
command -v "$python_bin" >/dev/null 2>&1 || python_bin="python"
command -v "$python_bin" >/dev/null 2>&1 || fail "Python 3 is required to validate tools/icarus-palette.py"
"$python_bin" -m py_compile tools/icarus-palette.py

if command -v shellcheck >/dev/null 2>&1; then
    echo "==> Running ShellCheck"
    shellcheck --shell=bash --severity=error --exclude=SC1091 "${shell_files[@]}"
else
    echo "==> ShellCheck not installed locally; syntax validation completed"
fi

echo "==> Checking dynamic-theme contract"
while IFS=':' read -r file token; do
    grep -Fq "$token" "$file" || fail "$file is missing required theme token $token"
done <<'TOKENS'
configs/theme/colors.conf:$bgElevated
configs/theme/colors.conf:$accentWarm
configs/theme/colors.css:@define-color bgElevated
configs/theme/colors.css:@define-color accentWarm
configs/theme/colors.sh:ICARUS_BG_ELEVATED
configs/theme/colors.sh:ICARUS_ACCENT_WARM
configs/theme/colors.rasi:bg-elevated:
configs/theme/colors.rasi:accent-warm:
configs/theme/colors.scss:$bgElevated:
configs/theme/colors.scss:$accentWarm:
tools/icarus-palette.py:$bgElevated
tools/icarus-palette.py:$accentWarm
configs/eww/eww.scss:$bgElevated
configs/eww/eww.scss:$accentWarm:
configs/kitty/kitty.conf:include colors.conf
configs/kitty/colors.conf:background #050505
TOKENS

echo "==> Checking dashboard and power controls"
for package in network-manager-applet bluez bluez-utils blueman curl jq; do
    grep -Fq "$package" layers/05-ui-winhybrid.sh || fail "Layer 5 is missing dashboard dependency: $package"
done
grep -Fq 'systemctl enable bluetooth.service' layers/05-ui-winhybrid.sh \
    || fail "Layer 5 does not enable Bluetooth"
grep -Fq 'icarus-powermenu-entries.sh" /usr/local/bin/icarus-powermenu-entries' layers/05-ui-winhybrid.sh \
    || fail "Layer 5 does not install the Rofi power-menu script"
grep -Fq 'configs/kitty/colors.conf' layers/05-ui-winhybrid.sh \
    && grep -Fq 'skel/.config/kitty/colors.conf' layers/05-ui-winhybrid.sh \
    || fail "Layer 5 does not install Kitty's palette fallback"
grep -Fq 'dunstctl is-paused' configs/eww/dashboard.yuck \
    || fail "Eww notification control must use the installed Dunst daemon"
! grep -qi '"label"[[:space:]]*:[[:space:]]*"hibernate"' configs/wlogout/layout \
    || fail "wlogout exposes hibernate even though this project has no disk-backed swap"

echo "==> Checking wallpaper pairings"
while IFS= read -r -d '' live_file; do
    directory="$(dirname "$live_file")"
    name="$(basename "$live_file")"
    still_stem="${name%-live.*}"
    if [[ ! -f "$directory/$still_stem.png" && ! -f "$directory/$still_stem.jpg" && ! -f "$directory/$still_stem.jpeg" ]]; then
        fail "live wallpaper has no static companion: $live_file"
    fi
done < <(find configs/wallpaper/references -type f \( -name 'icarus-*-live.gif' -o -name 'icarus-*-live.mp4' -o -name 'icarus-*-live.webm' -o -name 'icarus-*-live.mkv' \) -print0)

echo "==> Checking untracked-source protection"
if git rev-parse --is-inside-work-tree &>/dev/null; then
    git check-ignore -q -- STEAL/.icarus-ignore-probe \
        || fail "STEAL/ must stay ignored so source archives cannot be committed accidentally"
else
    echo "Skipping git-ignore check (not inside a git worktree)"
fi

echo "verify-repo: all checks passed"
