#!/usr/bin/env bash
set -euo pipefail
options="  Lock
󰗽  Logout
⏾  Suspend
  Reboot
⏻  Shutdown"
chosen=$(printf '%s\n' "$options" | rofi -dmenu -i -p "Power" -theme "$HOME/.config/rofi/theme.rasi")
case "$chosen" in
  *Lock*)     hyprlock ;;
  *Logout*)   hyprctl dispatch exit ;;
  *Suspend*)  systemctl suspend ;;
  *Reboot*)   systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
esac
