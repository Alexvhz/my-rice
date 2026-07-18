#!/usr/bin/env bash
# Keybind cheatsheet — parses hyprland.conf and shows it grouped in Rofi.
set -euo pipefail
CONF="$HOME/.config/hypr/hyprland.conf"
gen() {
  local started=0
  while IFS= read -r line; do
    [[ "$line" == *"KEYBINDS"* ]] && { started=1; continue; }
    [ "$started" = 1 ] || continue
    if [[ "$line" =~ ^#[[:space:]]*-+[[:space:]]*(.*[^-[:space:]])[[:space:]]*-+[[:space:]]*$ ]]; then
      printf '\n  %s\n' "${BASH_REMATCH[1]}"; continue
    fi
    [[ "$line" =~ ^bind ]] || continue
    local body="${line#*=}" desc=""
    case "$body" in *"#"*) desc="${body#*#}";; esac
    body="${body%%#*}"
    local mods key disp args
    mods="$(echo "$body" | cut -d, -f1 | xargs)"
    key="$(echo  "$body" | cut -d, -f2 | xargs)"
    disp="$(echo "$body" | cut -d, -f3 | xargs)"
    args="$(echo "$body" | cut -d, -f4- | xargs)"
    [ -z "$key" ] && continue
    mods="${mods//\$mod/SUPER}"; mods="${mods// /+}"
    args="${args//\$term/terminal}"; args="${args//\$menu/app launcher}"; args="${args//\$categories/app launcher}"
    desc="$(echo "$desc" | xargs)"
    [ -z "$desc" ] && desc="$disp${args:+ $args}"
    printf '   %-20s  %s\n' "${mods:+$mods+}$key" "$desc"
  done < "$CONF"
}
gen | rofi -dmenu -i -p "Keybinds" \
  -theme "$HOME/.config/rofi/theme.rasi" \
  -theme-str 'window {width: 46em;} listview {lines: 22;} element-text {font: "JetBrainsMono Nerd Font 11";}' \
  >/dev/null 2>&1 || true
