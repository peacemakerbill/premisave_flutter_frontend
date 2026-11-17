#!/usr/bin/env bash
# Premisave launcher for Linux, macOS, WSL and Git Bash.
#
#   ./run.sh                       pick a platform, environment and mode from menus
#   ./run.sh --platform linux      skip the platform menu
#   ./run.sh --device emulator-5554 --env development.local --mode debug
#   ./run.sh --help                every option
#
# Needs only Flutter on the PATH. Works with bash 3.2 and newer.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || exit 1

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------
OPT_PLATFORM=""
OPT_DEVICE=""
OPT_ENV="${APP_ENV:-}"
OPT_MODE=""
OPT_PORT="${PORT:-3000}"
OPT_YES=0
OPT_QUICK="${PREMISAVE_QUICK:-0}"
OPT_ACTION=""
OPT_EXTRA=()

usage() {
  cat <<'EOF'
Premisave launcher

Usage: ./run.sh [options] [-- extra flutter run arguments]

  -p, --platform NAME   web, linux, windows, macos, android, ios or web-server
  -d, --device ID       a device id from `flutter devices`
  -e, --env NAME        a file in config/env, with or without .json
  -m, --mode MODE       debug, profile or release
      --port N          web port, default 3000 (the sign in callback uses 3000)
  -y, --yes             take the first choice for anything not given, ask nothing
      --devices         list the devices Flutter can see, then stop
      --doctor          run flutter doctor, then stop
      --quick           skip the animation
  -h, --help            this text

Anything after -- goes straight to `flutter run`.
APP_ENV is still read, so APP_ENV=staging ./run.sh keeps working.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--platform) OPT_PLATFORM="${2:-}"; shift 2 ;;
    --platform=*)  OPT_PLATFORM="${1#*=}"; shift ;;
    -d|--device)   OPT_DEVICE="${2:-}"; shift 2 ;;
    --device=*)    OPT_DEVICE="${1#*=}"; shift ;;
    -e|--env)      OPT_ENV="${2:-}"; shift 2 ;;
    --env=*)       OPT_ENV="${1#*=}"; shift ;;
    -m|--mode)     OPT_MODE="${2:-}"; shift 2 ;;
    --mode=*)      OPT_MODE="${1#*=}"; shift ;;
    --port)        OPT_PORT="${2:-}"; shift 2 ;;
    --port=*)      OPT_PORT="${1#*=}"; shift ;;
    -y|--yes)      OPT_YES=1; shift ;;
    --quick)       OPT_QUICK=1; shift ;;
    --devices)     OPT_ACTION="devices"; shift ;;
    --doctor)      OPT_ACTION="doctor"; shift ;;
    -h|--help)     usage; exit 0 ;;
    --)            shift; OPT_EXTRA=("$@"); break ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------------------
# Terminal capabilities
# ---------------------------------------------------------------------------
TTY=0; [ -t 0 ] && [ -t 1 ] && TTY=1
COLS="${COLUMNS:-0}"; ROWS="${LINES:-0}"
if [ "$TTY" = 1 ]; then
  if [ "$COLS" -le 0 ] 2>/dev/null; then COLS="$(tput cols 2>/dev/null || echo 80)"; fi
  if [ "$ROWS" -le 0 ] 2>/dev/null; then ROWS="$(tput lines 2>/dev/null || echo 24)"; fi
else
  COLS=80; ROWS=24
fi

COLOR=0
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
  case "${COLORTERM:-}" in
    truecolor|24bit) COLOR=2 ;;
    *) case "${TERM:-}" in
         *256color*|xterm*|screen*|tmux*|alacritty*|kitty*|foot*|rxvt*|vt100*|linux*) COLOR=1 ;;
       esac
       # Windows Terminal and VS Code speak truecolor but do not always say so
       if [ -n "${WT_SESSION:-}" ] || [ "${TERM_PROGRAM:-}" = "vscode" ] || [ "${TERM_PROGRAM:-}" = "iTerm.app" ]; then COLOR=2; fi ;;
  esac
fi

UNI=0
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) UNI=1 ;; esac

ANIM=1
if [ "$TTY" != 1 ] || [ "$COLOR" = 0 ] || [ "$OPT_QUICK" = 1 ] || [ "$OPT_YES" = 1 ]; then ANIM=0; fi

# rgb to an escape in $E, either truecolor or the nearest of the 256 colours.
# It assigns instead of printing so the animation never forks.
E=""
esc() { # $1 = 38 or 48, then r g b
  if [ "$COLOR" = 2 ]; then
    printf -v E '\033[%s;2;%s;%s;%sm' "$1" "$2" "$3" "$4"
  elif [ "$COLOR" = 1 ]; then
    printf -v E '\033[%s;5;%dm' "$1" $((16 + 36 * ($2 * 5 / 255) + 6 * ($3 * 5 / 255) + ($4 * 5 / 255)))
  else
    E=""
  fi
}

RST=""; BOLD=""; DIMTX=""; GOLD=""; VIO=""; OK=""; WARN=""; ERR=""; INK=""
C_ROOF=""; C_WALL=""; C_WON=""; C_WOFF=""
if [ "$COLOR" != 0 ]; then
  RST=$'\033[0m'; BOLD=$'\033[1m'
  esc 38 138 134 168; DIMTX=$E
  esc 38 245 182 66;  GOLD=$E
  esc 38 150 130 255; VIO=$E
  esc 38 80 220 150;  OK=$E
  esc 38 255 190 80;  WARN=$E
  esc 38 255 100 115; ERR=$E
  esc 38 24 20 52;    INK=$E
  esc 48 245 182 66;  C_ROOF=$E
  esc 48 74 63 219;   C_WALL=$E
  esc 38 255 214 120; C_WON="$C_WALL$E"
  esc 38 52 44 160;   C_WOFF="$C_WALL$E"
fi

if [ "$UNI" = 1 ]; then
  S_OK="✔"; S_ERR="✘"; S_PTR="❯"; S_DOT="•"; S_WIN="▪"; S_STAR="·"; S_BARL="─"
  SPIN_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
else
  S_OK="+"; S_ERR="x"; S_PTR=">"; S_DOT="*"; S_WIN="o"; S_STAR="."; S_BARL="-"
  SPIN_FRAMES=("|" "/" "-" "\\")
fi

# the cursor is hidden and line wrap is off while a menu is on screen, so a long
# line gets cut at the edge instead of pushing the redraw out of place
hide_cursor() { [ "$TTY" = 1 ] && printf '\033[?25l\033[?7l'; }
show_cursor() { [ "$TTY" = 1 ] && printf '\033[?25h\033[?7h'; }
cleanup() { show_cursor; printf '%s' "$RST"; [ -n "${SPIN_OUT:-}" ] && rm -f "$SPIN_OUT"; }
trap cleanup EXIT
trap 'cleanup; printf "\n%sStopped.%s\n" "$DIMTX" "$RST"; exit 130' INT TERM

say()  { printf '%s\n' "$*"; }
info() { printf '  %s%s%s %s\n' "$VIO" "$S_DOT" "$RST" "$*"; }
good() { printf '  %s%s%s %s\n' "$OK" "$S_OK" "$RST" "$*"; }
warn() { printf '  %s!%s %s\n' "$WARN" "$RST" "$*"; }
fail() { printf '  %s%s%s %s\n' "$ERR" "$S_ERR" "$RST" "$*" >&2; }
rule() { # a thin gradient-free rule, width capped
  local w=$(( COLS < 72 ? COLS - 2 : 70 )) line="" i
  for ((i = 0; i < w; i++)); do line+="$S_BARL"; done
  printf '  %s%s%s\n' "$DIMTX" "$line" "$RST"
}

# ---------------------------------------------------------------------------
# Splash: a skyline that rises, windows that light up, a gradient wordmark
# ---------------------------------------------------------------------------
LOGO=(
"██████╗ ██████╗ ███████╗███╗   ███╗██╗███████╗ █████╗ ██╗   ██╗███████╗"
"██╔══██╗██╔══██╗██╔════╝████╗ ████║██║██╔════╝██╔══██╗██║   ██║██╔════╝"
"██████╔╝██████╔╝█████╗  ██╔████╔██║██║███████╗███████║██║   ██║█████╗  "
"██╔═══╝ ██╔══██╗██╔══╝  ██║╚██╔╝██║██║╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  "
"██║     ██║  ██║███████╗██║ ╚═╝ ██║██║███████║██║  ██║ ╚████╔╝ ███████╗"
"╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝"
)
LOGO_W=71

# colour at position x of w: gold, then coral, then violet
grad() { # $1 x  $2 w  -> sets G_R G_G G_B
  local x=$1 w=$2 t seg
  t=$(( x * 200 / (w > 1 ? w - 1 : 1) ))
  if [ "$t" -lt 100 ]; then
    G_R=$(( 245 + (255 - 245) * t / 100 )); G_G=$(( 182 + (112 - 182) * t / 100 )); G_B=$(( 66 + (130 - 66) * t / 100 ))
  else
    seg=$(( t - 100 ))
    G_R=$(( 255 + (140 - 255) * seg / 100 )); G_G=$(( 112 + (110 - 112) * seg / 100 )); G_B=$(( 130 + (255 - 130) * seg / 100 ))
  fi
}

# the gradient painted over one string, one character at a time
paint_gradient() { # $1 text  -> prints
  local s=$1 n=${#1} i out=""
  if [ "$COLOR" = 0 ]; then printf '%s' "$s"; return; fi
  for ((i = 0; i < n; i++)); do
    grad "$i" "$n"; esc 38 "$G_R" "$G_G" "$G_B"
    out+="$E${s:i:1}"
  done
  printf '%s%s' "$out" "$RST"
}

SK_W=0; SK_H=7
SK_HEIGHT=(); SK_START=(); SK_END=(); SK_LIT=(); SK_STAR=()

build_city() {
  SK_W=$(( COLS < 72 ? COLS - 4 : LOGO_W ))
  local x=0 bw bh i
  SK_HEIGHT=(); SK_START=(); SK_END=(); SK_LIT=(); SK_STAR=()
  for ((i = 0; i < SK_W; i++)); do SK_HEIGHT[i]=0; SK_START[i]=0; SK_END[i]=0; done
  while [ "$x" -lt "$SK_W" ]; do
    bw=$(( 4 + RANDOM % 5 )); bh=$(( 2 + RANDOM % (SK_H - 1) ))
    [ $(( x + bw )) -gt "$SK_W" ] && bw=$(( SK_W - x ))
    for ((i = x; i < x + bw; i++)); do SK_HEIGHT[i]=$bh; SK_START[i]=$x; SK_END[i]=$(( x + bw - 1 )); done
    x=$(( x + bw + (RANDOM % 3 == 0 ? 1 : 0) ))
  done
  for ((i = 0; i < SK_W * SK_H; i++)); do
    SK_LIT[i]=$(( RANDOM % 100 < 42 ? 1 : 0 ))
    SK_STAR[i]=$(( RANDOM % 100 < 4 ? 1 : 0 ))
  done
}

# progress 0..100: how much of every tower is standing
draw_city() { # $1 progress
  local p=$1 r x vis idx h out="" cell rel
  for ((r = SK_H - 1; r >= 0; r--)); do
    out+="  "
    for ((x = 0; x < SK_W; x++)); do
      h=${SK_HEIGHT[x]}; vis=$(( (h * p + 99) / 100 )); idx=$(( r * SK_W + x ))
      if [ "$r" -lt "$vis" ]; then
        rel=$(( x - SK_START[x] ))
        if [ "$r" -eq $((h - 1)) ] && [ "$vis" -ge "$h" ]; then
          cell="$C_ROOF "
        elif [ $(( rel % 2 )) -eq 1 ] && [ $(( r % 2 )) -eq 1 ] && [ "$x" -lt "${SK_END[x]}" ] && [ "$r" -gt 0 ]; then
          if [ "${SK_LIT[idx]}" = 1 ]; then cell="$C_WON$S_WIN"; else cell="$C_WOFF$S_WIN"; fi
        else
          cell="$C_WALL "
        fi
        out+="${cell}${RST}"
      elif [ "${SK_STAR[idx]}" = 1 ] && [ "$r" -gt 2 ]; then
        out+="${DIMTX}${S_STAR}${RST}"
      else
        out+=" "
      fi
    done
    out+=$'\033[K\n'
  done
  printf '%s' "$out"
}

twinkle() { # flip a few windows
  local k n=$(( SK_W * SK_H / 9 )) i
  for ((k = 0; k < n; k++)); do i=$(( RANDOM % (SK_W * SK_H) )); SK_LIT[i]=$(( 1 - SK_LIT[i] )); done
}

LOGO_COL=()
prep_logo() {
  local x
  for ((x = 0; x < LOGO_W; x++)); do grad "$x" "$LOGO_W"; esc 38 "$G_R" "$G_G" "$G_B"; LOGO_COL[x]=$E; done
}

draw_logo() { # $1 visible columns
  local cols=$1 r x out="" line
  for ((r = 0; r < 6; r++)); do
    out+="  "
    line="${LOGO[r]}"
    for ((x = 0; x < cols && x < LOGO_W; x++)); do out+="${LOGO_COL[x]}${line:x:1}"; done
    out+="${RST}"$'\033[K\n'
  done
  printf '%s' "$out"
}

splash() {
  local host arch ver
  prep_logo
  host="$(uname -s 2>/dev/null || echo unknown)"; arch="$(uname -m 2>/dev/null || echo)"
  ver="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml 2>/dev/null | head -n1 | tr -d '\r')"

  if [ "$ANIM" = 1 ] && [ "$UNI" = 1 ] && [ "$COLS" -ge 76 ] && [ "$ROWS" -ge 26 ]; then
    hide_cursor
    build_city
    printf '\n'
    local p
    draw_city 0 >/dev/null
    for p in 0 14 28 42 56 70 84 100; do
      [ "$p" -gt 0 ] && printf '\033[%dA' "$SK_H"
      draw_city "$p"; sleep 0.045
    done
    for p in 1 2 3 4 5 6; do
      twinkle; printf '\033[%dA' "$SK_H"; draw_city 100; sleep 0.09
    done
    local c
    for ((c = 0; c <= LOGO_W; c += 5)); do
      [ "$c" -gt 0 ] && printf '\033[6A'
      draw_logo "$c"; sleep 0.02
    done
    printf '\033[6A'; draw_logo "$LOGO_W"
    show_cursor
  elif [ "$COLOR" != 0 ] && [ "$UNI" = 1 ] && [ "$COLS" -ge 76 ]; then
    printf '\n'; draw_logo "$LOGO_W"
  else
    printf '\n  '; paint_gradient "P R E M I S A V E"; printf '\n'
  fi

  local tag="Find it. Rent it. Pay for it. All in one app."
  printf '\n  %s%s%s\n' "$BOLD" "$tag" "$RST"
  printf '  %sFlutter app %s  %s %s  %s\n' "$DIMTX" "${ver:+v$ver}" "$host" "$arch" "$RST"
  printf '\n'
}

# ---------------------------------------------------------------------------
# Small helpers: spinner and menu
# ---------------------------------------------------------------------------
SPIN_OUT=""; SPIN_RC=0
spin() { # $1 message, then the command. Output lands in $SPIN_OUT.
  local msg=$1; shift
  [ -n "$SPIN_OUT" ] && rm -f "$SPIN_OUT"
  SPIN_OUT="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/premisave-run.$$")"
  if [ "$TTY" != 1 ]; then
    info "$msg"; "$@" >"$SPIN_OUT" 2>&1; SPIN_RC=$?; return
  fi
  "$@" >"$SPIN_OUT" 2>&1 &
  local pid=$! i=0
  hide_cursor
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r  %s%s%s %s\033[K' "$GOLD" "${SPIN_FRAMES[i % ${#SPIN_FRAMES[@]}]}" "$RST" "$msg"
    i=$(( i + 1 )); sleep 0.08
  done
  wait "$pid"; SPIN_RC=$?
  printf '\r\033[K'; show_cursor
}

# MENU_LABEL, MENU_HINT, MENU_ON (1 = can be chosen), MENU_HEAD (1 = section heading)
MENU_LABEL=(); MENU_HINT=(); MENU_ON=(); MENU_HEAD=(); MENU_PICK=0
menu_reset() { MENU_LABEL=(); MENU_HINT=(); MENU_ON=(); MENU_HEAD=(); }
menu_add()   { MENU_LABEL+=("$1"); MENU_HINT+=("${2:-}"); MENU_ON+=("${3:-1}"); MENU_HEAD+=(0); }
menu_head()  { MENU_LABEL+=("$1"); MENU_HINT+=(""); MENU_ON+=(0); MENU_HEAD+=(1); }

menu_draw() { # $1 current index
  local cur=$1 n=${#MENU_LABEL[@]} i num=0 out="" ptr line
  for ((i = 0; i < n; i++)); do
    if [ "${MENU_HEAD[i]}" = 1 ]; then
      out+="  ${DIMTX}${MENU_LABEL[i]}${RST}"$'\033[K\n'; continue
    fi
    if [ "${MENU_ON[i]}" = 1 ]; then
      num=$(( num + 1 ))
      local tag="  "; [ "$num" -le 9 ] && tag="$num "
      if [ "$i" -eq "$cur" ]; then
        line="  ${GOLD}${S_PTR}${RST} ${GOLD}${tag}${RST}${BOLD}${MENU_LABEL[i]}${RST}"
        [ -n "${MENU_HINT[i]}" ] && line+="  ${DIMTX}${MENU_HINT[i]}${RST}"
      else
        line="    ${DIMTX}${tag}${RST}${MENU_LABEL[i]}"
        [ -n "${MENU_HINT[i]}" ] && line+="  ${DIMTX}${MENU_HINT[i]}${RST}"
      fi
    else
      line="    ${DIMTX}  ${MENU_LABEL[i]}  ${MENU_HINT[i]}${RST}"
    fi
    out+="${line}"$'\033[K\n'
  done
  printf '%s' "$out"
}

menu_first() { local i; for ((i = 0; i < ${#MENU_LABEL[@]}; i++)); do [ "${MENU_ON[i]}" = 1 ] && { echo "$i"; return; }; done; echo 0; }

menu_step() { # $1 current, $2 direction -> echoes new index, wraps around
  local n=${#MENU_LABEL[@]} cur=$1 d=$2 k nxt=$1
  for ((k = 0; k < n; k++)); do
    nxt=$(( (nxt + d + n) % n ))
    [ "${MENU_ON[nxt]}" = 1 ] && { echo "$nxt"; return; }
  done
  echo "$cur"
}

menu_nth() { # $1 = nth selectable row, 1-based, echoes index or nothing
  local i c=0
  for ((i = 0; i < ${#MENU_LABEL[@]}; i++)); do
    if [ "${MENU_ON[i]}" = 1 ]; then c=$(( c + 1 )); [ "$c" -eq "$1" ] && { echo "$i"; return; }; fi
  done
}

# Asks the question and leaves the chosen index in MENU_PICK.
choose() { # $1 = title
  local title=$1 n=${#MENU_LABEL[@]} cur key rest hit
  cur="$(menu_first)"
  printf '  %s%s%s\n' "$BOLD" "$title" "$RST"

  if [ "$TTY" != 1 ] || [ $(( n + 4 )) -gt "$ROWS" ]; then
    # plain numbered list, also used when the window is too short for arrows
    local i num=0 ans
    for ((i = 0; i < n; i++)); do
      if [ "${MENU_HEAD[i]}" = 1 ]; then printf '      %s\n' "${MENU_LABEL[i]}"; continue; fi
      if [ "${MENU_ON[i]}" = 1 ]; then num=$(( num + 1 )); printf '    %2d  %s  %s\n' "$num" "${MENU_LABEL[i]}" "${MENU_HINT[i]}"
      else printf '        %s  %s\n' "${MENU_LABEL[i]}" "${MENU_HINT[i]}"; fi
    done
    while :; do
      printf '  Number (Enter for 1, q to quit): '
      read -r ans || { printf '\n'; exit 1; }
      case "$ans" in
        ''|1) MENU_PICK="$(menu_first)"; return ;;
        q|Q) printf '\n  %sSee you soon.%s\n' "$DIMTX" "$RST"; exit 0 ;;
        *[!0-9]*) ;;
        *) hit="$(menu_nth "$ans")"; [ -n "$hit" ] && { MENU_PICK=$hit; return; } ;;
      esac
    done
  fi

  hide_cursor
  menu_draw "$cur"
  printf '  %sup and down to move, Enter to pick, q to quit%s' "$DIMTX" "$RST"
  while :; do
    IFS= read -rsn1 key || { show_cursor; exit 1; }
    if [ "$key" = $'\033' ]; then rest=""; read -rsn2 -t 1 rest; key="$key$rest"; fi
    case "$key" in
      $'\033[A'|$'\033OA'|k|K) cur="$(menu_step "$cur" -1)" ;;
      $'\033[B'|$'\033OB'|j|J) cur="$(menu_step "$cur" 1)" ;;
      $'\033[H'|$'\033[1'|g)   cur="$(menu_first)" ;;
      '') break ;;
      q|Q) printf '\r\033[K\033[%dA\033[J' "$n"; show_cursor; printf '  %sSee you soon.%s\n' "$DIMTX" "$RST"; exit 0 ;;
      [1-9]) hit="$(menu_nth "$key")"; if [ -n "$hit" ]; then cur=$hit; break; fi ;;
    esac
    printf '\r\033[K\033[%dA' "$n"; menu_draw "$cur"
    printf '  %sup and down to move, Enter to pick, q to quit%s' "$DIMTX" "$RST"
  done
  # wipe the menu and the help line, plus the title above it
  printf '\r\033[K\033[%dA\033[J\033[1A\033[J' "$n"
  show_cursor
  MENU_PICK=$cur
}

# ---------------------------------------------------------------------------
# Host and tools
# ---------------------------------------------------------------------------
case "$(uname -s 2>/dev/null)" in
  Linux*)  HOST=linux ;;
  Darwin*) HOST=macos ;;
  MINGW*|MSYS*|CYGWIN*) HOST=windows ;;
  *) HOST=other ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

# Flutter only lists Chrome when it finds it. Chromium alone is common on Linux.
if [ -z "${CHROME_EXECUTABLE:-}" ] && ! have google-chrome && ! have google-chrome-stable && ! have chrome; then
  for b in chromium chromium-browser; do
    if have "$b"; then CHROME_EXECUTABLE="$(command -v "$b")"; export CHROME_EXECUTABLE; break; fi
  done
fi

plat_of() { # targetPlatform text to a short name
  case "$1" in
    android*) echo android ;; ios*) echo ios ;; darwin*|macos*) echo macos ;;
    linux*) echo linux ;; windows*) echo windows ;; web*) echo web ;; *) echo other ;;
  esac
}

DEV_ID=(); DEV_NAME=(); DEV_PLAT=(); DEV_EMU=()

load_devices() {
  DEV_ID=(); DEV_NAME=(); DEV_PLAT=(); DEV_EMU=()
  local rows id name plat emu
  spin "Looking for devices" flutter devices --machine
  rows=""
  if have python3; then
    rows="$(python3 -I - "$SPIN_OUT" 2>/dev/null <<'PY'
import json, sys
s = open(sys.argv[1], errors="replace").read()
i = s.find("[")
if i < 0:
    sys.exit(1)
data, _ = json.JSONDecoder().raw_decode(s[i:])
def plat(t):
    t = (t or "").lower()
    for k, v in (("android", "android"), ("ios", "ios"), ("darwin", "macos"), ("macos", "macos"),
                 ("linux", "linux"), ("windows", "windows"), ("web", "web")):
        if t.startswith(k):
            return v
    return "other"
for d in data:
    print("\t".join([d.get("id", ""), d.get("name", "").replace("\t", " "), plat(d.get("targetPlatform")), "1" if d.get("emulator") else "0"]))
PY
)"
  fi
  if [ -z "$rows" ]; then
    # no python, or an unexpected answer: read the plain table instead
    spin "Looking for devices" flutter devices
    rows="$(sed -e 's/ • /\t/g' -e 's/ \* /\t/g' "$SPIN_OUT" | awk -F'\t' 'NF >= 3 && $2 !~ /[[:space:]]/ {print $2 "\t" $1 "\t" $3 "\t" ($2 ~ /^emulator-/ ? 1 : 0)}')"
    local fixed="" line
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      id="${line%%$'\t'*}"; local r2="${line#*$'\t'}"; name="${r2%%$'\t'*}"; r2="${r2#*$'\t'}"
      plat="$(plat_of "${r2%%$'\t'*}")"; emu="${r2##*$'\t'}"
      fixed+="$id"$'\t'"$name"$'\t'"$plat"$'\t'"$emu"$'\n'
    done <<EOF
$rows
EOF
    rows="$fixed"
  fi
  while IFS=$'\t' read -r id name plat emu; do
    [ -z "$id" ] && continue
    DEV_ID+=("$id"); DEV_NAME+=("$name"); DEV_PLAT+=("$plat"); DEV_EMU+=("$emu")
  done <<EOF
$rows
EOF
}

# badge with the platform colour
badge() { # $1 platform, $2 emulator flag
  local label r g b
  case "$1" in
    web)     label=" WEB ";     r=66;  g=165; b=245 ;;
    linux)   label=" LINUX ";   r=250; g=204; b=21  ;;
    windows) label=" WINDOWS "; r=0;   g=164; b=239 ;;
    macos)   label=" MACOS ";   r=205; g=205; b=220 ;;
    android) label=" ANDROID "; r=61;  g=220; b=132 ;;
    ios)     label=" IOS ";     r=190; g=150; b=255 ;;
    *)       label=" OTHER ";   r=170; g=170; b=190 ;;
  esac
  [ "$2" = 1 ] && label=" EMULATOR " && { r=255; g=150; b=120; }
  if [ "$COLOR" = 0 ]; then printf '[%s]' "${label// /}"; return; fi
  esc 48 "$r" "$g" "$b"
  printf '%s%s%s%s%s' "$E" "$INK" "$BOLD" "$label" "$RST"
}

host_desktop_label() { case "$1" in linux) echo "Linux desktop";; windows) echo "Windows desktop";; macos) echo "macOS desktop";; esac; }

ORDER=()
build_order() { # phones, emulators, this computer's desktop, browsers
  ORDER=()
  local pass i rank
  for pass in 0 1 2 3 4; do
    for ((i = 0; i < ${#DEV_ID[@]}; i++)); do
      case "${DEV_PLAT[i]}" in
        android|ios) if [ "${DEV_EMU[i]}" = 1 ]; then rank=1; else rank=0; fi ;;
        linux|windows|macos) rank=2 ;;
        web) if [ "${DEV_ID[i]}" = "web-server" ]; then rank=4; else rank=3; fi ;;
        *) rank=4 ;;
      esac
      [ "$rank" -eq "$pass" ] && ORDER+=("$i")
    done
  done
}

pick_platform() {
  load_devices
  build_order
  local i
  while :; do
    menu_reset
    local MAP=() s_android=0 s_ios=0 s_linux=0 s_windows=0 s_macos=0 s_web=0
    if [ "${#ORDER[@]}" -gt 0 ]; then
      menu_head "Ready to run"
      for i in "${ORDER[@]}"; do
        menu_add "$(badge "${DEV_PLAT[i]}" "${DEV_EMU[i]}") ${DEV_NAME[i]}" "${DEV_ID[i]}"
        MAP+=("dev:$i")
        case "${DEV_PLAT[i]}" in
          android) s_android=1 ;; ios) s_ios=1 ;; linux) s_linux=1 ;;
          windows) s_windows=1 ;; macos) s_macos=1 ;; web) s_web=1 ;;
        esac
      done
    fi

    if [ $(( s_android + s_ios + s_linux + s_windows + s_macos + s_web )) -lt 6 ]; then
      menu_head "Not ready on this computer"
      if [ "$s_android" = 0 ]; then menu_add "$(badge android 0) Phone or emulator" "plug in a phone with USB debugging, or start an emulator below" 0; MAP+=("x"); fi
      if [ "$s_ios" = 0 ]; then
        if [ "$HOST" = macos ]; then menu_add "$(badge ios 0) iPhone or simulator" "plug in an iPhone, or start a simulator below" 0
        else menu_add "$(badge ios 0) iPhone or simulator" "needs a Mac" 0; fi; MAP+=("x")
      fi
      if [ "$s_macos" = 0 ]; then
        if [ "$HOST" = macos ]; then menu_add "$(badge macos 0) macOS desktop" "run: flutter config --enable-macos-desktop" 0
        else menu_add "$(badge macos 0) macOS desktop" "needs a Mac" 0; fi; MAP+=("x")
      fi
      if [ "$s_windows" = 0 ]; then
        if [ "$HOST" = windows ]; then menu_add "$(badge windows 0) Windows desktop" "run: flutter config --enable-windows-desktop" 0
        else menu_add "$(badge windows 0) Windows desktop" "needs a Windows PC, use run.bat there" 0; fi; MAP+=("x")
      fi
      if [ "$s_linux" = 0 ]; then
        if [ "$HOST" = linux ]; then menu_add "$(badge linux 0) Linux desktop" "run: flutter config --enable-linux-desktop" 0
        else menu_add "$(badge linux 0) Linux desktop" "needs a Linux PC" 0; fi; MAP+=("x")
      fi
      if [ "$s_web" = 0 ]; then menu_add "$(badge web 0) Browser" "run: flutter config --enable-web, and install Chrome or Chromium" 0; MAP+=("x"); fi
    fi

    menu_head "More"
    menu_add "Start an emulator or simulator" "" 1;      MAP+=("emu")
    menu_add "Look for devices again" "" 1;               MAP+=("refresh")
    menu_add "Check my setup with flutter doctor" "" 1;   MAP+=("doctor")
    menu_add "Quit" "" 1;                                 MAP+=("quit")

    # MAP holds one entry per row that is not a heading, in the same order
    choose "Where do you want to run Premisave?"
    local k=0 j target=""
    for ((j = 0; j < ${#MENU_LABEL[@]}; j++)); do
      [ "${MENU_HEAD[j]}" = 1 ] && continue
      if [ "$j" -eq "$MENU_PICK" ]; then target="${MAP[k]}"; break; fi
      k=$(( k + 1 ))
    done

    case "$target" in
      dev:*)
        local di="${target#dev:}"
        SEL_ID="${DEV_ID[di]}"; SEL_NAME="${DEV_NAME[di]}"; SEL_PLAT="${DEV_PLAT[di]}"; SEL_EMU="${DEV_EMU[di]}"
        return 0 ;;
      emu)     start_emulator; load_devices; build_order ;;
      refresh) load_devices; build_order ;;
      doctor)  printf '\n'; flutter doctor; printf '\n  %sPress Enter to go back.%s' "$DIMTX" "$RST"; read -r _; printf '\n' ;;
      quit)    printf '  %sSee you soon.%s\n' "$DIMTX" "$RST"; exit 0 ;;
    esac
  done
}

start_emulator() {
  spin "Listing emulators" flutter emulators
  local rows ids=() names=() line id name
  rows="$(sed -e 's/ • /\t/g' -e 's/ \* /\t/g' "$SPIN_OUT" | awk -F'\t' 'NF >= 3 && $1 != "Id" {print $1 "\t" $2}')"
  while IFS=$'\t' read -r id name; do
    [ -z "$id" ] && continue
    case "$id" in *[[:space:]]*) continue ;; esac
    ids+=("$id"); names+=("$name")
  done <<EOF
$rows
EOF
  if [ "${#ids[@]}" -eq 0 ]; then
    warn "No emulators or simulators are set up."
    say "    Android: open Android Studio, Device Manager, Create device."
    say "    iOS: install Xcode, then run: open -a Simulator"
    printf '\n  %sPress Enter to go back.%s' "$DIMTX" "$RST"; read -r _; printf '\n'
    return
  fi
  menu_reset
  local i
  for ((i = 0; i < ${#ids[@]}; i++)); do menu_add "${names[i]:-${ids[i]}}" "${ids[i]}" 1; done
  menu_add "Back" "" 1
  choose "Which one should start?"
  [ "$MENU_PICK" -ge "${#ids[@]}" ] && return
  local eid="${ids[MENU_PICK]}" before=${#DEV_ID[@]} tries=0
  spin "Starting ${names[MENU_PICK]:-$eid}" flutter emulators --launch "$eid"
  if [ "$SPIN_RC" -ne 0 ]; then fail "It would not start."; sed 's/^/    /' "$SPIN_OUT" | head -n 8; sleep 2; return; fi
  while [ "$tries" -lt 20 ]; do
    spin "Waiting for it to finish booting" sleep 3
    spin "Checking" flutter devices --machine
    local count
    count="$(grep -c '"id"' "$SPIN_OUT" 2>/dev/null || echo 0)"
    [ "${count:-0}" -gt "$before" ] && break
    tries=$(( tries + 1 ))
  done
}

# ---------------------------------------------------------------------------
# Environment and mode
# ---------------------------------------------------------------------------
ENV_DIR="config/env"
pick_env() {
  local files=() f name first=""
  # preferred first: the one asked for, then the private file, then the usual order
  local want
  for want in "$OPT_ENV" development.local development staging production; do
    [ -z "$want" ] && continue; want="${want%.json}"
    [ -f "$ENV_DIR/$want.json" ] || continue
    case " ${files[*]:-} " in *" $want "*) continue ;; esac
    files+=("$want")
  done
  for f in "$ENV_DIR"/*.json; do
    [ -f "$f" ] || continue
    name="$(basename "$f" .json)"
    case " ${files[*]:-} " in *" $name "*) continue ;; esac
    files+=("$name")
  done
  if [ "${#files[@]}" -eq 0 ]; then
    fail "No environment files found in $ENV_DIR."; exit 1
  fi

  if [ -n "$OPT_ENV" ]; then
    SEL_ENV="${OPT_ENV%.json}"
    if [ ! -f "$ENV_DIR/$SEL_ENV.json" ]; then
      fail "There is no $ENV_DIR/$SEL_ENV.json. Available: ${files[*]}"; exit 1
    fi
    return
  fi
  if [ "$OPT_YES" = 1 ] || [ "${#files[@]}" -eq 1 ]; then SEL_ENV="${files[0]}"; return; fi

  menu_reset
  local url hint
  for name in "${files[@]}"; do
    url="$(sed -n 's/.*"BASE_URL"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ENV_DIR/$name.json" | head -n1)"
    if [ -z "$url" ]; then hint="auth-service on this computer, port 8080"
    else
      case "$url" in *example*) hint="${WARN}placeholder address, put the real one in first${RST}${DIMTX}" ;; *) hint="$url" ;; esac
    fi
    case "$name" in *.local) hint="$hint   private, git ignores it" ;; esac
    menu_add "$name" "$hint" 1
  done
  choose "Which settings file?"
  SEL_ENV="${files[MENU_PICK]}"
}

pick_mode() {
  if [ -n "$OPT_MODE" ]; then SEL_MODE="$OPT_MODE"
  elif [ "$OPT_YES" = 1 ]; then SEL_MODE=debug
  else
    menu_reset
    menu_add "Debug" "hot reload, best for working on the app" 1
    menu_add "Profile" "close to real speed, with the performance tools" 1
    menu_add "Release" "the real thing, no hot reload" 1
    choose "How should it run?"
    case "$MENU_PICK" in 1) SEL_MODE=profile ;; 2) SEL_MODE=release ;; *) SEL_MODE=debug ;; esac
  fi
  case "$SEL_MODE" in debug|profile|release) ;; *) fail "Mode must be debug, profile or release."; exit 2 ;; esac
}

# ---------------------------------------------------------------------------
# Checks before launching
# ---------------------------------------------------------------------------
need_flutter() {
  if have flutter; then return; fi
  fail "Flutter is not on your PATH."
  say "    Install it from https://docs.flutter.dev/get-started/install, then open a new terminal."
  exit 1
}

check_linux_tools() {
  local missing=() t
  for t in cmake ninja clang pkg-config; do have "$t" || missing+=("$t"); done
  if have pkg-config && ! pkg-config --exists gtk+-3.0 2>/dev/null; then missing+=("libgtk-3-dev"); fi
  if [ "${#missing[@]}" -gt 0 ]; then
    fail "The Linux desktop build needs: ${missing[*]}"
    say "    Debian, Ubuntu, Kali:"
    say "      sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev"
    say "    Fedora:"
    say "      sudo dnf install clang cmake ninja-build pkgconf-pkg-config gtk3-devel libsecret-devel"
    exit 1
  fi
}

port_busy() { # bash can open a tcp connection by itself
  ( exec 3<>"/dev/tcp/127.0.0.1/$1" ) >/dev/null 2>&1
}

pub_get_if_needed() {
  local cfg=".dart_tool/package_config.json"
  local stale=0
  if [ ! -f "$cfg" ]; then stale=1
  elif [ pubspec.yaml -nt "$cfg" ]; then stale=1
  elif [ -f pubspec.lock ] && [ pubspec.lock -nt "$cfg" ]; then stale=1; fi
  if [ "$stale" = 1 ]; then
    spin "Fetching packages" flutter pub get
    if [ "$SPIN_RC" -ne 0 ]; then fail "flutter pub get failed:"; sed 's/^/    /' "$SPIN_OUT"; exit 1; fi
    good "Packages are up to date"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
need_flutter

if [ "$OPT_ACTION" = doctor ]; then flutter doctor; exit $?; fi
if [ "$OPT_ACTION" = devices ]; then flutter devices; exit $?; fi

splash

SEL_ID=""; SEL_NAME=""; SEL_PLAT=""; SEL_EMU=0; SEL_ENV=""; SEL_MODE=""

if [ -n "$OPT_DEVICE" ]; then
  SEL_ID="$OPT_DEVICE"; SEL_NAME="$OPT_DEVICE"
  case "$OPT_DEVICE" in chrome|edge|web-server) SEL_PLAT=web ;; linux|windows|macos) SEL_PLAT="$OPT_DEVICE" ;; *) SEL_PLAT=other ;; esac
  load_devices
  for ((i = 0; i < ${#DEV_ID[@]}; i++)); do
    if [ "${DEV_ID[i]}" = "$OPT_DEVICE" ]; then SEL_NAME="${DEV_NAME[i]}"; SEL_PLAT="${DEV_PLAT[i]}"; SEL_EMU="${DEV_EMU[i]}"; fi
  done
elif [ -n "$OPT_PLATFORM" ] || [ "$OPT_YES" = 1 ]; then
  load_devices
  want="$OPT_PLATFORM"
  [ "$want" = "browser" ] && want=web
  if [ -z "$want" ]; then
    case "$HOST" in linux|macos|windows) want="$HOST" ;; *) want="" ;; esac
  fi
  for ((i = 0; i < ${#DEV_ID[@]}; i++)); do
    if [ -z "$want" ] || [ "${DEV_PLAT[i]}" = "$want" ] || [ "${DEV_ID[i]}" = "$want" ]; then
      SEL_ID="${DEV_ID[i]}"; SEL_NAME="${DEV_NAME[i]}"; SEL_PLAT="${DEV_PLAT[i]}"; SEL_EMU="${DEV_EMU[i]}"; break
    fi
  done
  if [ -z "$SEL_ID" ] && [ -z "$OPT_PLATFORM" ] && [ "$OPT_YES" = 1 ] && [ "${#DEV_ID[@]}" -gt 0 ]; then
    SEL_ID="${DEV_ID[0]}"; SEL_NAME="${DEV_NAME[0]}"; SEL_PLAT="${DEV_PLAT[0]}"; SEL_EMU="${DEV_EMU[0]}"
  fi
  if [ -z "$SEL_ID" ]; then
    fail "No ${want:-usable} device found. Run ./run.sh --devices to see what Flutter can use."; exit 1
  fi
else
  pick_platform
fi
good "Platform  $(badge "$SEL_PLAT" "$SEL_EMU") $SEL_NAME"

pick_env
good "Settings  $SEL_ENV"

pick_mode
good "Mode      $SEL_MODE"

printf '\n'
[ "$SEL_PLAT" = linux ] && check_linux_tools
pub_get_if_needed

CMD=(flutter run -d "$SEL_ID" "--dart-define-from-file=$ENV_DIR/$SEL_ENV.json")
URL=""
if [ "$SEL_PLAT" = web ]; then
  if port_busy "$OPT_PORT"; then
    warn "Port $OPT_PORT is already in use. Sign in with GitHub, Google or Facebook sends you back to port 3000,"
    say  "    so stop whatever uses it, or pick another with --port and expect those callbacks to miss."
    if [ "$OPT_YES" != 1 ] && [ "$TTY" = 1 ]; then
      printf '  Continue on port %s anyway? [y/N] ' "$OPT_PORT"; read -r ans
      case "$ans" in y|Y|yes) ;; *) exit 1 ;; esac
    fi
  fi
  CMD+=("--web-port=$OPT_PORT"); URL="http://localhost:$OPT_PORT"
fi
case "$SEL_MODE" in profile) CMD+=(--profile) ;; release) CMD+=(--release) ;; esac
[ "${#OPT_EXTRA[@]}" -gt 0 ] && CMD+=("${OPT_EXTRA[@]}")

if grep '"BASE_URL"' "$ENV_DIR/$SEL_ENV.json" 2>/dev/null | grep -q example; then
  warn "$SEL_ENV.json still has a placeholder address, so the app may not reach your server."
fi

rule
printf '  %sLaunching%s  %s\n' "$GOLD" "$RST" "$SEL_NAME"
[ -n "$URL" ] && printf '  %sOpens at%s   %s%s%s\n' "$GOLD" "$RST" "$BOLD" "$URL" "$RST"
printf '  %sCommand%s    %s%s%s\n' "$GOLD" "$RST" "$DIMTX" "${CMD[*]}" "$RST"
printf '  %sKeys%s       r hot reload, R hot restart, q quit\n' "$GOLD" "$RST"
rule
printf '\n'

START=$(date +%s)
"${CMD[@]}"
RC=$?
END=$(date +%s)
DUR=$(( END - START ))

printf '\n'
rule
if [ "$RC" -eq 0 ]; then
  good "Done after $(( DUR / 60 ))m $(( DUR % 60 ))s"
else
  fail "Flutter stopped with code $RC after $(( DUR / 60 ))m $(( DUR % 60 ))s"
  say  "    Try ./run.sh --doctor to check your setup, or run again and pick another device."
fi
exit "$RC"
