#!/usr/bin/env bash
# =============================================================================
#  install.sh — Atom OneDark Hyprland rice
#
#  What it does:
#    1. Installs an AUR helper (yay) if you don't have one.
#    2. Installs every package listed in packages.txt (+ Powerlevel10k from AUR).
#    3. Backs up any configs you already have, then symlinks this repo's configs
#       into ~/.config (so editing them here == editing your live setup).
#    4. Sets zsh as your login shell and enables the needed services.
#
#  Usage:
#    ./install.sh                # full install
#    ./install.sh --no-packages  # only link dotfiles (skip pacman/yay)
#    ./install.sh --dry-run      # show what would happen, change nothing
#
#  Safe to re-run. Existing files are backed up to <file>.rice-backup.
# =============================================================================

set -euo pipefail

# --------------------------------- setup -------------------------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
DRY_RUN=false
DO_PACKAGES=true

for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY_RUN=true ;;
        --no-packages) DO_PACKAGES=false ;;
        -h|--help)     grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -n 22; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# --------------------------------- colours -----------------------------------
c_blue=$'\033[38;5;39m'; c_grn=$'\033[38;5;76m'; c_red=$'\033[38;5;196m'
c_yel=$'\033[38;5;178m'; c_dim=$'\033[90m';      c_rst=$'\033[0m'

info()  { printf '%s==>%s %s\n'  "$c_blue" "$c_rst" "$*"; }
ok()    { printf '%s  ✓%s %s\n'  "$c_grn"  "$c_rst" "$*"; }
warn()  { printf '%s  !%s %s\n'  "$c_yel"  "$c_rst" "$*"; }
err()   { printf '%s  ✗%s %s\n'  "$c_red"  "$c_rst" "$*" >&2; }
run()   { if $DRY_RUN; then printf '%s   (dry-run)%s %s\n' "$c_dim" "$c_rst" "$*"; else eval "$@"; fi; }

# ------------------------------ sanity checks --------------------------------
if [[ $EUID -eq 0 ]]; then
    err "Don't run this as root. Run it as your normal user; it will sudo when needed."
    exit 1
fi
if ! command -v pacman >/dev/null 2>&1; then
    err "pacman not found — this script is for Arch Linux (or an Arch-based distro)."
    exit 1
fi

printf '\n%s╔══════════════════════════════════════════╗%s\n' "$c_blue" "$c_rst"
printf   '%s║   Atom OneDark · Hyprland rice installer  ║%s\n' "$c_blue" "$c_rst"
printf   '%s╚══════════════════════════════════════════╝%s\n\n' "$c_blue" "$c_rst"
$DRY_RUN && warn "DRY RUN — nothing will actually change."

# ============================================================================
#  1. AUR helper
# ============================================================================
install_yay() {
    if command -v yay >/dev/null 2>&1; then ok "yay already installed"; return; fi
    info "Installing yay (AUR helper)…"
    run "sudo pacman -S --needed --noconfirm git base-devel"
    local tmp; tmp="$(mktemp -d)"
    run "git clone https://aur.archlinux.org/yay.git '$tmp/yay'"
    run "cd '$tmp/yay' && makepkg -si --noconfirm"
    run "rm -rf '$tmp'"
    ok "yay installed"
}

# ============================================================================
#  2. Packages
# ============================================================================
install_packages() {
    info "Reading package list…"
    # Strip comments + blank lines from packages.txt.
    local pkgs
    pkgs=$(sed 's/#.*$//' "$REPO_DIR/packages.txt" | tr -s ' \t' '\n' | grep -v '^$' | sort -u)
    local count; count=$(printf '%s\n' "$pkgs" | grep -c . || true)
    info "Installing $count packages (this can take a while)…"
    # shellcheck disable=SC2086
    run "yay -S --needed --noconfirm $(printf '%s ' $pkgs)"
    ok "Base packages installed"

    info "Installing Powerlevel10k (AUR)…"
    run "yay -S --needed --noconfirm powerlevel10k"
    ok "Powerlevel10k installed"
}

# ============================================================================
#  3. Symlink dotfiles
# ============================================================================
BACKUP_SUFFIX=".rice-backup"

link() {
    local src="$1" dest="$2"
    if [[ ! -e "$src" ]]; then warn "missing source: $src (skipped)"; return; fi
    # Already the right symlink? nothing to do.
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        ok "linked: ${dest/#$HOME/\~}"; return
    fi
    # Back up anything real that's in the way.
    if [[ -e "$dest" || -L "$dest" ]]; then
        run "mv -f '$dest' '${dest}${BACKUP_SUFFIX}'"
        warn "backed up existing ${dest/#$HOME/\~} -> ${dest/#$HOME/\~}${BACKUP_SUFFIX}"
    fi
    run "mkdir -p '$(dirname "$dest")'"
    run "ln -s '$src' '$dest'"
    ok "linked: ${dest/#$HOME/\~} -> ${src/#$HOME/\~}"
}

link_dotfiles() {
    info "Linking configs into ~/.config …"
    run "mkdir -p '$HOME/.config'"

    for name in hypr waybar rofi alacritty fastfetch swaync wlogout; do
        link "$CONFIG_SRC/$name" "$HOME/.config/$name"
    done

    link "$REPO_DIR/zsh/zshrc"    "$HOME/.zshrc"
    link "$REPO_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"

    # Make the helper scripts executable.
    run "chmod +x '$CONFIG_SRC/waybar/scripts/gpu.sh' '$CONFIG_SRC/rofi/scripts/categories.sh'"

    # Create the git-ignored per-machine override files so Hyprland's `source`
    # lines never point at a missing file.
    run "touch '$CONFIG_SRC/hypr/local.conf' '$CONFIG_SRC/hypr/monitors.conf'"
    ok "Configs linked"

    guard_lua_shadow

    # Wallpaper check.
    if [[ ! -f "$CONFIG_SRC/hypr/wallpapers/wall.png" ]] && ! $DRY_RUN; then
        warn "No wallpaper at config/hypr/wallpapers/wall.png"
        warn "Drop an image there named wall.png (hyprpaper + hyprlock use it)."
    fi
}

# Since Hyprland 0.55, a hyprland.lua (if present) is loaded INSTEAD of
# hyprland.conf. A fresh Hyprland boot auto-generates one, which then silently
# shadows this rice. This makes sure our plain-text hyprland.conf is the config
# Hyprland actually loads.
guard_lua_shadow() {
    local lua="$HOME/.config/hypr/hyprland.lua"
    local conf="$HOME/.config/hypr/hyprland.conf"

    if [[ -e "$lua" || -L "$lua" ]]; then
        run "mv -f '$lua' '${lua}${BACKUP_SUFFIX}'"
        warn "Found a hyprland.lua that would override this rice — moved it to"
        warn "  ${lua/#$HOME/\~}${BACKUP_SUFFIX}. Hyprland will now load hyprland.conf."
    fi

    if $DRY_RUN; then return; fi
    if [[ -e "$conf" ]]; then
        ok "Active Hyprland config: hyprland.conf (no .lua shadow)"
    else
        warn "hyprland.conf not found at ~/.config/hypr — did the hypr link fail above?"
    fi
}

# ============================================================================
#  4. Shell + services
# ============================================================================
set_shell() {
    local zsh_path; zsh_path="$(command -v zsh || echo /usr/bin/zsh)"
    if [[ "${SHELL:-}" == "$zsh_path" ]]; then ok "zsh already default shell"; return; fi
    info "Setting zsh as your login shell…"
    run "chsh -s '$zsh_path'"
    ok "Default shell -> zsh (takes effect on next login)"
}

enable_services() {
    info "Enabling system services…"
    run "sudo systemctl enable --now NetworkManager.service" || warn "NetworkManager: skipped"
    run "sudo systemctl enable --now bluetooth.service"      || warn "bluetooth: skipped"
    info "Enabling PipeWire (user)…"
    run "systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service" \
        || warn "PipeWire user services: enable after first graphical login if this failed"
    ok "Services configured"
}

# ============================================================================
#  Run
# ============================================================================
if $DO_PACKAGES; then
    install_yay
    install_packages
else
    warn "--no-packages: skipping package installation"
fi

link_dotfiles
set_shell
$DO_PACKAGES && enable_services || true

printf '\n%s┌─────────────────────────────────────────────┐%s\n' "$c_grn" "$c_rst"
printf   '%s│  Done!  Next steps:                          │%s\n' "$c_grn" "$c_rst"
printf   '%s└─────────────────────────────────────────────┘%s\n' "$c_grn" "$c_rst"
cat <<EOF
  1. Add a wallpaper:  cp yourimage.png "$CONFIG_SRC/hypr/wallpapers/wall.png"
  2. Log out completely, then pick "Hyprland" from your login manager
     (or run 'Hyprland' from a TTY).
  3. Once inside:  SUPER+Return = terminal · SUPER+Space = launcher
     SUPER+A = categorized app menu · SUPER+Shift+E = power menu
  4. Fonts/icons look wrong? Log out/in so the new Nerd Fonts are picked up.

  Tip: your live setup is symlinked to this repo, so 'git commit' here
       versions any tweak you make. Machine-specific bits go in
       ~/.config/hypr/local.conf and ~/.config/hypr/monitors.conf (git-ignored).
EOF
