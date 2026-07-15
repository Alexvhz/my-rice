#!/usr/bin/env bash
set -euo pipefail
ROFI=(rofi -dmenu -i -theme "$HOME/.config/rofi/theme.rasi")
BACK="  Back"
DRUN="rofi -show drun -theme $HOME/.config/rofi/theme.rasi"
declare -A MENU
MENU[main]="\
󰀻  All Applications::$DRUN
  System / Settings::@System
  Internet::@Internet
  Development::@Development
  Cybersecurity::@Cybersecurity
  Media::@Media
  Office::@Office"
MENU[System]="\
  All Settings / apps::$DRUN
  Files (Thunar)::thunar
  Network::nm-connection-editor
  Bluetooth::blueman-manager
  Audio::pavucontrol
  Appearance (GTK)::nwg-look
  System Monitor::alacritty -e btop"
MENU[Internet]="\
  Firefox::firefox
  Chromium::chromium
  Thunderbird::thunderbird"
MENU[Development]="\
  VS Code::code
  Neovim::alacritty -e nvim
  Lazygit::alacritty -e lazygit"
MENU[Media]="\
  mpv::mpv
  VLC::vlc
  Spotify::spotify
  GIMP::gimp"
MENU[Office]="\
  LibreOffice::libreoffice
  Obsidian::obsidian"
MENU[Cybersecurity]="\
  Recon::@Sec_Recon
  Web::@Sec_Web
  Exploitation::@Sec_Exploit
  Wireless::@Sec_Wireless
  Passwords::@Sec_Passwords"
MENU[Sec_Recon]="\
  nmap::alacritty -e bash -c 'nmap; exec bash'
  rustscan::alacritty -e bash -c 'rustscan; exec bash'
  subfinder::alacritty -e bash -c 'subfinder; exec bash'"
MENU[Sec_Web]="\
  Burp Suite::burpsuite
  ffuf::alacritty -e bash -c 'ffuf; exec bash'
  sqlmap::alacritty -e bash -c 'sqlmap; exec bash'"
MENU[Sec_Exploit]="\
  Metasploit::alacritty -e msfconsole
  searchsploit::alacritty -e bash -c 'searchsploit; exec bash'"
MENU[Sec_Wireless]="\
  aircrack-ng::alacritty -e bash -c 'aircrack-ng; exec bash'
  Wireshark::wireshark"
MENU[Sec_Passwords]="\
  hashcat::alacritty -e bash -c 'hashcat; exec bash'
  john::alacritty -e bash -c 'john; exec bash'
  hydra::alacritty -e bash -c 'hydra; exec bash'"
show_menu() {
    local key="$1" prompt="$2" entries="${MENU[$1]:-}" list=""
    [[ -z "$entries" ]] && return 1
    while IFS= read -r line; do [[ -z "$line" ]] && continue; list+="${line%%::*}"$'\n'; done <<<"$entries"
    [[ "$key" != "main" ]] && list+="$BACK"
    printf '%s' "$list" | "${ROFI[@]}" -p "$prompt"
}
resolve() {
    while IFS= read -r line; do [[ -z "$line" ]] && continue
        [[ "${line%%::*}" == "$2" ]] && { printf '%s' "${line#*::}"; return 0; }
    done <<<"${MENU[$1]}"; return 1
}
stack=("main"); prompts=("Apps")
while [[ ${#stack[@]} -gt 0 ]]; do
    cur="${stack[-1]}"; prompt="${prompts[-1]}"
    choice="$(show_menu "$cur" "$prompt")" || exit 0
    [[ -z "$choice" ]] && exit 0
    if [[ "$choice" == "$BACK" ]]; then
        unset 'stack[-1]' 'prompts[-1]'; stack=("${stack[@]}"); prompts=("${prompts[@]}"); continue
    fi
    target="$(resolve "$cur" "$choice")" || exit 0
    if [[ "$target" == @* ]]; then stack+=("${target#@}"); prompts+=("${choice#* }")
    else setsid -f bash -c "$target" >/dev/null 2>&1; exit 0; fi
done
