#!/usr/bin/env bash
# =============================================================================
#  Categorized app launcher for Rofi (with nested categories).
#
#  HOW IT WORKS
#  ------------
#  Everything is data. Each "menu" is a key in the MENU array whose value is a
#  list of entries, one per line. There are two kinds of entry:
#
#     Display Label::@SubmenuKey     -> opens another menu (nesting)
#     Display Label::shell command   -> launches the command
#
#  So to add nesting, point an entry at another MENU key. To add a leaf app,
#  give it a command. That's it — edit the arrays below to taste.
#
#  The Cybersecurity branch is filled in as a working example with sub-categories
#  (Recon, Web, Exploitation, Wireless). Tools that live in a terminal are
#  launched with `alacritty -e ...` so they get a window. Swap in whatever you
#  actually have installed.
# =============================================================================

set -euo pipefail

ROFI=(rofi -dmenu -i -theme "$HOME/.config/rofi/theme.rasi")
BACK="  Back"

declare -A MENU

# ------------------------------- TOP LEVEL -----------------------------------
MENU[main]="\
 Internet::@Internet
 Development::@Development
 Cybersecurity::@Cybersecurity
 Media::@Media
 Office::@Office
 System::@System"

# --------------------------------- BRANCHES ----------------------------------
MENU[Internet]="\
 Firefox::firefox
 Chromium::chromium
 Thunderbird::thunderbird
 qBittorrent::qbittorrent"

MENU[Development]="\
 VS Code::code
 Neovim::alacritty -e nvim
 Lazygit::alacritty -e lazygit
 Docker (lazydocker)::alacritty -e lazydocker
 DBeaver::dbeaver"

MENU[Media]="\
 mpv::mpv
 VLC::vlc
 Spotify::spotify
 OBS Studio::obs
 GIMP::gimp"

MENU[Office]="\
 LibreOffice::libreoffice
 Obsidian::obsidian
 Zathura (PDF)::zathura"

MENU[System]="\
 Files (Thunar)::thunar
 System Monitor (btop)::alacritty -e btop
 Audio (pavucontrol)::pavucontrol
 Bluetooth::blueman-manager
 Network::nm-connection-editor
 GTK Theme::nwg-look"

# ---------------------------- CYBERSECURITY ----------------------------------
# Nested example: category -> sub-category -> tools.
MENU[Cybersecurity]="\
 Recon::@Sec_Recon
 Web::@Sec_Web
 Exploitation::@Sec_Exploit
 Wireless::@Sec_Wireless
 Passwords::@Sec_Passwords"

MENU[Sec_Recon]="\
 nmap::alacritty -e bash -c 'nmap; exec bash'
 rustscan::alacritty -e bash -c 'rustscan; exec bash'
 masscan::alacritty -e bash -c 'sudo masscan; exec bash'
 amass::alacritty -e bash -c 'amass; exec bash'
 subfinder::alacritty -e bash -c 'subfinder; exec bash'"

MENU[Sec_Web]="\
 Burp Suite::burpsuite
 OWASP ZAP::zaproxy
 ffuf::alacritty -e bash -c 'ffuf; exec bash'
 gobuster::alacritty -e bash -c 'gobuster; exec bash'
 sqlmap::alacritty -e bash -c 'sqlmap; exec bash'
 nikto::alacritty -e bash -c 'nikto; exec bash'"

MENU[Sec_Exploit]="\
 Metasploit::alacritty -e msfconsole
 searchsploit::alacritty -e bash -c 'searchsploit; exec bash'
 msfvenom::alacritty -e bash -c 'msfvenom -h; exec bash'"

MENU[Sec_Wireless]="\
 airmon-ng::alacritty -e bash -c 'sudo airmon-ng; exec bash'
 airodump-ng::alacritty -e bash -c 'sudo airodump-ng; exec bash'
 aircrack-ng::alacritty -e bash -c 'aircrack-ng; exec bash'
 Wireshark::wireshark"

MENU[Sec_Passwords]="\
 hashcat::alacritty -e bash -c 'hashcat; exec bash'
 john::alacritty -e bash -c 'john; exec bash'
 hydra::alacritty -e bash -c 'hydra; exec bash'"

# =============================================================================
#  Engine — you shouldn't need to touch anything below this line.
# =============================================================================
show_menu() {
    local key="$1" prompt="$2"
    local entries="${MENU[$key]:-}"
    [[ -z "$entries" ]] && return 1

    # Build the visible list (labels only), plus a Back item for sub-menus.
    local list=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        list+="${line%%::*}"$'\n'
    done <<<"$entries"
    [[ "$key" != "main" ]] && list+="$BACK"

    printf '%s' "$list" | "${ROFI[@]}" -p "$prompt"
}

# Resolve a chosen label back to its target (submenu key or command).
resolve() {
    local key="$1" choice="$2"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "${line%%::*}" == "$choice" ]]; then
            printf '%s' "${line#*::}"
            return 0
        fi
    done <<<"${MENU[$key]}"
    return 1
}

# Navigation loop with a simple breadcrumb stack for "Back".
stack=("main")
prompts=("Apps")

while [[ ${#stack[@]} -gt 0 ]]; do
    cur="${stack[-1]}"
    prompt="${prompts[-1]}"

    choice="$(show_menu "$cur" "$prompt")" || exit 0   # Esc -> quit
    [[ -z "$choice" ]] && exit 0

    if [[ "$choice" == "$BACK" ]]; then
        unset 'stack[-1]' 'prompts[-1]'
        stack=("${stack[@]}"); prompts=("${prompts[@]}")   # reindex
        continue
    fi

    target="$(resolve "$cur" "$choice")" || exit 0

    if [[ "$target" == @* ]]; then          # submenu
        stack+=("${target#@}")
        prompts+=("${choice#* }")           # crumb = label without leading icon
    else                                     # launch
        setsid -f bash -c "$target" >/dev/null 2>&1
        exit 0
    fi
done
