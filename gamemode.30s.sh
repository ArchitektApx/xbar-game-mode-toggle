#!/usr/bin/env bash
# <xbar.title>Game Mode Toggle</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>ArchitektApx</xbar.author>
# <xbar.author.github>ArchitektApx</xbar.author.github>
# <xbar.desc>Shows and switches the macOS Game Mode policy (auto/on/off) via Apple's gamepolicyctl.</xbar.desc>
# <xbar.dependencies>Xcode (provides gamepolicyctl)</xbar.dependencies>
# <xbar.image>https://raw.githubusercontent.com/ArchitektApx/xbar-game-mode-toggle/master/docs/demo.gif</xbar.image>
# <xbar.abouturl>https://github.com/ArchitektApx/xbar-game-mode-toggle</xbar.abouturl>

set -u

find_gamepolicyctl() {
  local p
  p=$(xcrun -f gamepolicyctl 2>/dev/null) && [ -x "$p" ] && { echo "$p"; return 0; }
  for p in /Applications/Xcode*.app/Contents/Developer/usr/bin/gamepolicyctl; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

GPC=$(find_gamepolicyctl) || {
  echo "🎮 ?"
  echo "---"
  echo "gamepolicyctl not found (install Xcode) | color=red"
  exit 0
}

# Menu actions call this script again with: set <auto|off|on>
if [ "${1:-}" = "set" ]; then
  "$GPC" game-mode set "$2" >/dev/null 2>&1
  exit 0
fi

status=$("$GPC" game-mode status 2>&1 | sed $'s/\x1b\\[[0-9;]*m//g')
active=$(printf '%s\n' "$status" | sed -nE 's/^Game mode is ([a-z]+)\..*/\1/p' | head -1)
# After leaving "forced on", macOS keeps Game Mode on for ~15s before turning it off
printf '%s\n' "$status" | grep -q "will soon turn off" && active="$active (turning off soon)"
# "currently automatic" or "currently disabled. Game mode is forced always on|off."
policy=$(printf '%s\n' "$status" | sed -nE 's/.*forced always (on|off).*/\1/p' | head -1)
[ -z "$policy" ] && printf '%s\n' "$status" | grep -q "policy is currently automatic" && policy="auto"

case "$policy" in
  off)  title="🎮✕";   label="off (forced)" ;;
  auto) title="🎮";    label="auto (macOS default)" ;;
  on)   title="🎮✓";   label="on (forced)" ;;
  *)    title="🎮 ?";  label="unknown" ;;
esac
self="$0"
echo "$title"
echo "---"
echo "Policy: $label"
echo "Game Mode right now: ${active:-unknown}"
echo "---"
[ "$policy" != "on" ]   && echo "Force on | shell=\"$self\" param1=set param2=on terminal=false refresh=true"
[ "$policy" != "off" ]  && echo "Force off | shell=\"$self\" param1=set param2=off terminal=false refresh=true"
[ "$policy" != "auto" ] && echo "Set to auto (macOS default) | shell=\"$self\" param1=set param2=auto terminal=false refresh=true"
echo "---"
echo "Refresh | refresh=true"
