#!/usr/bin/env bash
set -euo pipefail
WALL_DIR="$HOME/.config/hypr/wallpapers"
THEME="$HOME/.config/rofi/wallpaper.rasi"
shopt -s nullglob nocaseglob
sel=$(
  for f in "$WALL_DIR"/*.{png,jpg,jpeg,webp}; do
    b=$(basename "$f")
    [ "$b" = "wall.png" ] && continue
    printf '%s\0icon\x1f%s\n' "$b" "$f"
  done | rofi -dmenu -i -p "Wallpaper" -theme "$THEME"
)
[ -z "${sel:-}" ] && exit 0
img="$WALL_DIR/$sel"
[ -f "$img" ] || exit 0
killall swaybg 2>/dev/null || true
setsid swaybg -i "$img" -m fill >/dev/null 2>&1 &
cp -f "$img" "$WALL_DIR/wall.png"
