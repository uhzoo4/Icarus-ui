#!/usr/bin/env bash
# ~/.config/hypr/scripts/welcome.sh
# Icarus terminal greeting — decode-reveal wing assembly, wallpaper-driven
# gradient (wing accent -> wax gold), a sweeping flare of light through the
# wings, time-of-day flavor, two rare procedural events (a fall, and a rarer
# sun-reach), then handoff to fastfetch.
#
# Color: reads $accent from the wallpaper-driven theme
#   (~/.config/icarus/theme/colors.conf), as rgb(r,g,b) or hex rgb(RRGGBB).
#   Second gradient stop is wax gold, unless $sun / $accent2 is also defined.
#   The gradient also gets a subtle bias from the time of day (see below).
# NO_COLOR (see no-color.org): if set to anything, disables all color output.
#
# Modes — auto-detected (first shell of the login session gets the full
# cinematic, every terminal after gets the quick reveal), or force one:
#   ICARUS_WELCOME_MODE=full|quick|off   env var
#   welcome.sh --full|--quick|--off      flag, wins over env + auto-detect
#
# Rare events (full mode only): a fall (wax gives out) is uncommon; a
# sun-reach (wax somehow holds) is rarer still. Force either for preview:
#   ICARUS_FORCE_EVENT=fall|sun          env var
#
# Debug: `ICARUS_TEST_NO_MAIN=1 source welcome.sh` loads every function
# without running main, for poking at pieces from an interactive shell.

set -u

# Bash's string indexing/length ($..., ${#...}) is locale-dependent: under a
# C/POSIX locale it counts bytes, which corrupts every multi-byte glyph this
# script slices (██, the decode noise, the sun rays). Fixing it here (not
# exported) makes indexing character-correct for this process only — child
# processes like fastfetch/neofetch still inherit whatever locale you have.
LC_ALL=C.UTF-8

# ---------------------------------------------------------------- palette --
c_reset='\033[0m'
c_bold='\033[1m'
c_dim='\033[38;2;110;110;120m'

NO_COLOR_SET=0
[[ -n "${NO_COLOR:-}" ]] && NO_COLOR_SET=1
(( NO_COLOR_SET )) && { c_reset=''; c_bold=''; c_dim=''; }

TRUECOLOR=0
case "${COLORTERM:-}" in
    truecolor|24bit) TRUECOLOR=1 ;;
esac

FORCE_EVENT="${ICARUS_FORCE_EVENT:-}"

# wing (cool, dynamic accent) -> sun (warm, wax gold) gradient stops
WING_R=74  WING_G=109 WING_B=140   # steel-blue fallback
SUN_R=230  SUN_G=176 SUN_B=68      # wax gold
WARN_R=196 WARN_G=48  WARN_B=66    # crimson
OK_R=110   OK_G=200  OK_B=150

THEME_FILE="${HOME}/.config/icarus/theme/colors.conf"

clamp255() { local v=$1; (( v < 0 )) && v=0; (( v > 255 )) && v=255; printf '%d' "$v"; }

read_theme_color() {
    # $1 = variable name in colors.conf. echoes "r g b" on success.
    local var="$1" raw
    [[ -f "$THEME_FILE" ]] || return 1
    raw=$(grep -oP "^\\\$${var}\s*=\s*rgba?\(\K[^)]*" "$THEME_FILE" 2>/dev/null | head -n1)
    [[ -z "$raw" ]] && return 1
    raw="${raw//,/ }"
    if [[ "$raw" =~ ^[0-9a-fA-F]{6}$ ]]; then
        printf '%d %d %d' "$((16#${raw:0:2}))" "$((16#${raw:2:2}))" "$((16#${raw:4:2}))"
        return 0
    fi
    set -- $raw
    if [[ ${1:-} =~ ^[0-9]+$ && ${2:-} =~ ^[0-9]+$ && ${3:-} =~ ^[0-9]+$ ]]; then
        printf '%d %d %d' "$1" "$2" "$3"
        return 0
    fi
    return 1
}

if col=$(read_theme_color accent); then read -r WING_R WING_G WING_B <<< "$col"; fi
if col=$(read_theme_color sun); then
    read -r SUN_R SUN_G SUN_B <<< "$col"
elif col=$(read_theme_color accent2); then
    read -r SUN_R SUN_G SUN_B <<< "$col"
fi
WING_R=$(clamp255 "$WING_R"); WING_G=$(clamp255 "$WING_G"); WING_B=$(clamp255 "$WING_B")
SUN_R=$(clamp255 "$SUN_R");   SUN_G=$(clamp255 "$SUN_G");   SUN_B=$(clamp255 "$SUN_B")

# ---------------------------------------------------------- time of day --
# The flight has a clock. Dawn runs cool, dusk warms early, night pulls the
# whole gradient toward indigo. Subtle — the wax gold still reads as gold.
PERIOD=""
FLAVOR=""
set_time_flavor() {
    local h=$(( 10#$(date +%H 2>/dev/null || echo 12) ))
    if   (( h >= 5  && h < 8  )); then PERIOD="dawn";  FLAVOR="dawn ascent — the wax is still cool"
    elif (( h >= 8  && h < 17 )); then PERIOD="day";   FLAVOR="high flight — hold your bearing"
    elif (( h >= 17 && h < 20 )); then PERIOD="dusk";  FLAVOR="dusk descent — the wax remembers the sun"
    else                                PERIOD="night"; FLAVOR="night vigil — no sun to chase"
    fi
}
set_time_flavor

case "$PERIOD" in
    night) SUN_R=$(( SUN_R*70/100 ));  SUN_G=$(( SUN_G*70/100 ));  SUN_B=$(( SUN_B*130/100 )) ;;
    dawn)  WING_R=$(( WING_R*115/100 )); SUN_G=$(( SUN_G*105/100 )) ;;
    dusk)  SUN_R=$(( SUN_R*118/100 )); WING_B=$(( WING_B*90/100 )) ;;
esac
WING_R=$(clamp255 "$WING_R"); WING_G=$(clamp255 "$WING_G"); WING_B=$(clamp255 "$WING_B")
SUN_R=$(clamp255 "$SUN_R");   SUN_G=$(clamp255 "$SUN_G");   SUN_B=$(clamp255 "$SUN_B")

rgb() { # r g b [bold] -> escape code on stdout
    (( NO_COLOR_SET )) && return 0
    local r=$1 g=$2 b=$3 bold="${4:-0}" pre=""
    (( bold )) && pre='\033[1m'
    if (( TRUECOLOR )); then
        printf '%b\033[38;2;%d;%d;%dm' "$pre" "$r" "$g" "$b"
    else
        local rr=$(( r * 5 / 255 )) gg=$(( g * 5 / 255 )) bb=$(( b * 5 / 255 ))
        printf '%b\033[38;5;%dm' "$pre" $(( 16 + 36*rr + 6*gg + bb ))
    fi
}

lerp() { printf '%d' $(( $1 + ( ($2 - $1) * $3 ) / 100 )); }

gradient_color() { # index total [bold] -> escape code, WING -> SUN
    local i=$1 total=$2 bold="${3:-0}" t r g b
    (( total <= 1 )) && t=100 || t=$(( i * 100 / (total - 1) ))
    r=$(lerp "$WING_R" "$SUN_R" "$t"); g=$(lerp "$WING_G" "$SUN_G" "$t"); b=$(lerp "$WING_B" "$SUN_B" "$t")
    rgb "$r" "$g" "$b" "$bold"
}

# ------------------------------------------------------------------ modes --
INTERACTIVE=1
[[ -t 1 ]] || INTERACTIVE=0
COLS=$(tput cols 2>/dev/null || echo 80)

BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null | tr -d '-')
SESSION_ID="${XDG_SESSION_ID:-${BOOT_ID:-default}}"
SESSION_MARK="${XDG_RUNTIME_DIR:-/tmp}/.icarus-welcomed-${SESSION_ID}"

MODE="auto"
for arg in "$@"; do
    case "$arg" in
        --full) MODE="full" ;;
        --quick) MODE="quick" ;;
        --off) MODE="off" ;;
    esac
done
[[ "$MODE" == "auto" ]] && MODE="${ICARUS_WELCOME_MODE:-auto}"
if [[ "$MODE" == "auto" ]]; then
    # User requested full animations on EVERY terminal launch
    MODE="full"
fi
(( INTERACTIVE == 0 )) && MODE="off"

# ------------------------------------------------------------------- logo --
logo=(
""
"         ██                          ██"
"        ████                        ████"
"       ██  ██                      ██  ██"
"      ██    ██                    ██    ██"
"     ██      ██                  ██      ██"
"    ██        ██                ██        ██"
"   ██          ██    ██████    ██          ██"
"  ██            ██  ████████  ██            ██"
"  ██              ████████████████              ██"
" ██                ██████████████                ██"
"  ██              ████  ██  ████              ██"
"   ██            ██      ██      ██            ██"
"    ██          ██      ████      ██          ██"
"     ██        ██      ██████      ██        ██"
"      ██      ██        ████        ██      ██"
"       ██    ██          ██          ██    ██"
"        ██  ██                      ██  ██"
"         ████   I C A R U S - O S    ████"
"          ██      by  yoozhaa         ██"
""
)

render_line_final() { # index total [bold]
    local i=$1 total=$2 bold="${3:-0}" line="${logo[$i]}"
    [[ -z "$line" ]] && { printf ' '; return; }
    local color; color=$(gradient_color "$i" "$total" "$bold")
    printf '%b%s%b' "$color" "$line" "$c_reset"
}

noise_line() {
    local width=$1 glyphs='▓▒░╳╱╲#%@*+~' glen s='' n gi
    glen=${#glyphs}
    for (( n=0; n<width; n++ )); do
        gi=$(( RANDOM % glen ))
        s+="${glyphs:gi:1}"
    done
    printf '%s' "$s"
}

draw_logo_quick() {
    local total=${#logo[@]} i
    for (( i=0; i<total; i++ )); do
        render_line_final "$i" "$total"
        printf '\n'
        sleep 0.01
    done
}

draw_logo_full() {
    local total=${#logo[@]} i pass passes=4
    local -a resolved
    for (( i=0; i<total; i++ )); do resolved[i]=0; done
    for (( i=0; i<total; i++ )); do printf '\n'; done
    printf '\033[%dA' "$total"
    for (( pass=1; pass<=passes; pass++ )); do
        local target=$(( total * pass / passes )) resolved_count=0
        for (( i=0; i<total; i++ )); do (( resolved[i] )) && (( resolved_count++ )); done
        while (( resolved_count < target )); do
            local pick=$(( RANDOM % total ))
            if (( ! resolved[pick] )); then
                resolved[pick]=1
                (( resolved_count++ ))
            fi
        done
        for (( i=0; i<total; i++ )); do
            printf '\033[K'
            if (( resolved[i] )) || [[ -z "${logo[$i]}" ]]; then
                render_line_final "$i" "$total"
            else
                printf '%b%s%b' "$c_dim" "$(noise_line "${#logo[$i]}")" "$c_reset"
            fi
            printf '\n'
        done
        (( pass < passes )) && printf '\033[%dA' "$total"
        sleep 0.07
    done
    # a flare of light sweeps wingtip to wingtip — a nod to the wing-flap
    # shader in the Icarus Papers, now with actual motion instead of a flash
    wing_flare
}

wing_flare() {
    local total=${#logo[@]} i f width=0
    for (( i=0; i<total; i++ )); do
        local len=${#logo[$i]}
        (( len > width )) && width=$len
    done
    local band=7
    local frames=$(( (width + band*2) / 3 ))
    (( frames < 6 ))  && frames=6
    (( frames > 22 )) && frames=22
    local flash; flash=$(rgb 255 255 250 1)

    printf '\033[%dA' "$total"
    for (( f=0; f<frames; f++ )); do
        local wave_col=$(( (f * (width + band*2)) / (frames - 1) - band ))
        for (( i=0; i<total; i++ )); do
            local line="${logo[$i]}"
            printf '\033[K'
            if [[ -z "$line" ]]; then
                printf '\n'
                continue
            fi
            local base; base=$(gradient_color "$i" "$total")
            local hlen=${#line}
            if (( wave_col + band < 0 || wave_col > hlen )); then
                printf '%b%s%b\n' "$base" "$line" "$c_reset"
            else
                local s=$wave_col; (( s < 0 )) && s=0
                local e=$(( wave_col + band )); (( e > hlen )) && e=$hlen
                local pre="${line:0:s}" mid="${line:s:e-s}" post="${line:e}"
                printf '%b%s%b%b%s%b%b%s%b\n' \
                    "$base" "$pre" "$c_reset" \
                    "$flash" "$mid" "$c_reset" \
                    "$base" "$post" "$c_reset"
            fi
        done
        (( f < frames-1 )) && printf '\033[%dA' "$total"
        sleep 0.02
    done
}

fall_sequence() {
    local height=6 particles=16 width=$COLS
    (( width > 60 )) && width=60
    (( width < 20 )) && return 0
    local -a pcol pph
    local i
    for (( i=0; i<particles; i++ )); do
        pcol[i]=$(( RANDOM % width ))
        pph[i]=$(( RANDOM % height ))
    done
    local glyphs='·˙°∘⋆'
    local glen=${#glyphs}
    local blank; printf -v blank '%*s' "$width" ""
    local f frames=14
    for (( i=0; i<height; i++ )); do printf '\n'; done
    printf '\033[%dA' "$height"
    for (( f=0; f<frames; f++ )); do
        local r
        for (( r=0; r<height; r++ )); do
            local line="$blank"
            for (( i=0; i<particles; i++ )); do
                if (( (f + pph[i]) % height == r )); then
                    local gi=$(( RANDOM % glen ))
                    local g="${glyphs:gi:1}"
                    line="${line:0:pcol[i]}${g}${line:pcol[i]+1}"
                fi
            done
            local col; col=$(gradient_color "$r" "$height")
            printf '\033[K%b%s%b\n' "$col" "$line" "$c_reset"
        done
        (( f < frames-1 )) && printf '\033[%dA' "$height"
        sleep 0.045
    done
    local -a lines=(
        "the wax does not last forever"
        "Icarus remembers the warning, briefly"
        "gravity collects on every debt"
        "the sea keeps no records"
    )
    printf '  %b%s%b\n\n' "$c_dim" "${lines[RANDOM % ${#lines[@]}]}" "$c_reset"
}

sun_reach_sequence() {
    # ultra-rare counterpart to fall_sequence: the flight that doesn't end
    # in the sea. A small radiant sun grows rays outward, flares, and clears.
    local rows=9 half_h=4 half_w=10
    local width=$(( half_w*2 + 1 ))
    local frames=5 f i

    for (( i=0; i<rows; i++ )); do printf '\n'; done
    printf '\033[%dA' "$rows"

    for (( f=0; f<frames; f++ )); do
        local ray_len=$(( f + 1 ))
        local t=$(( f * 100 / (frames - 1) ))
        local r g b col row
        r=$(lerp "$SUN_R" 255 "$t"); g=$(lerp "$SUN_G" 255 "$t"); b=$(lerp "$SUN_B" 235 "$t")
        col=$(rgb "$r" "$g" "$b" 1)
        for (( row=0; row<rows; row++ )); do
            local dy=$(( row - half_h ))
            local ady=$(( dy < 0 ? -dy : dy ))
            local line="" cidx
            for (( cidx=0; cidx<width; cidx++ )); do
                local dx=$(( cidx - half_w ))
                local adx=$(( dx < 0 ? -dx : dx ))
                local ch=' '
                if (( dx == 0 && dy == 0 )); then
                    ch='◉'
                elif (( dx == 0 && ady > 0 && ady <= ray_len )); then
                    ch='│'
                elif (( dy == 0 && adx > 0 && adx <= ray_len*2 )); then
                    ch='─'
                elif (( ady > 0 && ady <= ray_len && adx == ady*2 )); then
                    if (( (dx>0) == (dy>0) )); then ch='╲'; else ch='╱'; fi
                fi
                line+="$ch"
            done
            printf '\033[K%b%s%b\n' "$col" "$line" "$c_reset"
        done
        (( f < frames-1 )) && printf '\033[%dA' "$rows"
        sleep 0.09
    done

    sleep 0.1
    local flashcol; flashcol=$(rgb 255 250 235 1)
    local flashline="" fc
    for (( fc=0; fc<width; fc++ )); do flashline+='·'; done
    printf '\033[%dA' "$rows"
    for (( row=0; row<rows; row++ )); do
        printf '\033[K%b%s%b\n' "$flashcol" "$flashline" "$c_reset"
    done
    sleep 0.07

    printf '\033[%dA' "$rows"
    for (( row=0; row<rows; row++ )); do printf '\033[K\n'; done

    local -a msgs=(
        "for one moment, the wax held"
        "higher than Daedalus ever warned against"
        "the sun did not feel like an ending"
        "you were closer than the myth allows"
    )
    printf '  %b%s%b\n\n' "$(rgb 255 214 130 1)" "${msgs[RANDOM % ${#msgs[@]}]}" "$c_reset"
}

# --------------------------------------------------------------- boot log --
BOOT_LINES=(
    "wax bond integrity ....... nominal"
    "wingspan calibration ..... locked"
    "thermal margin ........... within tolerance"
    "feather alignment ........ 100%"
    "solar bearing ............ tracking"
    "altitude discipline ...... your call"
)

boot_sequence() {
    local l tag color
    for l in "${BOOT_LINES[@]}"; do
        if (( RANDOM % 8 == 0 )); then
            tag="WARN"; color=$(rgb "$WARN_R" "$WARN_G" "$WARN_B")
        else
            tag="OK  "; color=$(rgb "$OK_R" "$OK_G" "$OK_B")
        fi
        printf ' %b[%s]%b %s\n' "$color" "$tag" "$c_reset" "$l"
        sleep 0.05
    done
    printf ' %b›%b %s\n' "$c_dim" "$c_reset" "$FLAVOR"
    sleep 0.1
}

# --------------------------------------------------------------- waveform --
waveform() {
    local bars=28 i h maxh=8
    local -a heights
    local -a blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
    for (( i=0; i<bars; i++ )); do heights[i]=$(( (RANDOM % maxh) + 1 )); done
    local frames=1
    [[ "$MODE" == "full" ]] && frames=5
    local f line col bi
    for (( f=0; f<frames; f++ )); do
        line=""
        for (( i=0; i<bars; i++ )); do
            if (( f > 0 )); then
                heights[i]=$(( heights[i] + (RANDOM % 3 - 1) ))
                (( heights[i] < 1 )) && heights[i]=1
                (( heights[i] > maxh )) && heights[i]=maxh
            fi
            h=${heights[i]}
            bi=$(( h * (${#blocks[@]}-1) / maxh ))
            line+="${blocks[bi]}"
        done
        col=$(gradient_color $(( bars/2 )) "$bars")
        printf '\033[K %b%s%b\n' "$col" "$line" "$c_reset"
        if (( f < frames-1 )); then
            sleep 0.09
            printf '\033[1A'
        fi
    done
}

# ------------------------------------------------------------------ fetch --
fallback_fetch() {
    local shell_name="${SHELL:-bash}"; shell_name="${shell_name##*/}"
    local rows=(
        "OS       -> $(uname -o 2>/dev/null || uname -s)"
        "Kernel   -> $(uname -r)"
        "Shell    -> ${shell_name}"
        "Uptime   -> $(uptime -p 2>/dev/null | sed 's/^up //')"
        "Term     -> ${TERM:-unknown}"
    )
    local i col
    for i in "${!rows[@]}"; do
        col=$(gradient_color "$i" "${#rows[@]}")
        printf ' %b%s%b\n' "$col" "${rows[$i]}" "$c_reset"
    done
}

run_fetch() {
    if command -v fastfetch &>/dev/null; then
        fastfetch
    elif command -v neofetch &>/dev/null; then
        neofetch
    else
        fallback_fetch
    fi
}

# -------------------------------------------------------------------- run --
main() {
    if [[ "$MODE" == "off" ]]; then
        run_fetch
        return
    fi
    if [[ "$MODE" == "full" ]]; then
        boot_sequence
        draw_logo_full
        if [[ "$FORCE_EVENT" == "sun" ]]; then
            sun_reach_sequence
        elif [[ "$FORCE_EVENT" == "fall" ]]; then
            fall_sequence
        elif (( RANDOM % 150 == 0 )); then
            sun_reach_sequence
        elif (( RANDOM % 40 == 0 )); then
            fall_sequence
        fi
    else
        draw_logo_quick
    fi
    waveform
    printf '\n'
    run_fetch
}

if [[ "${ICARUS_TEST_NO_MAIN:-0}" != "1" ]]; then
    main
fi