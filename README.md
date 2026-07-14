# Atom OneDark — Hyprland Rice

A clean, reproducible [Hyprland](https://hyprland.org) rice for Arch Linux, themed
in **Atom OneDark** with a **blue accent** throughout. One-command install, fully
version-controlled dotfiles.

```
 ┌──────────────────────────────────────────────────────────┐
 │  ⌂ 1 2 3 4 5    arch          12:34  Mon 14 Jul       │
 │                                                          │
 │   frosted alacritty + zsh + p10k + fastfetch greeting    │
 │   blue rofi launcher (with nested categories)            │
 └──────────────────────────────────────────────────────────┘
```

## What's in it

| Piece | Tool | Notes |
|-------|------|-------|
| Compositor | **Hyprland** | rounded corners, blur, frosted windows, workspaces 1–5 |
| Bar | **Waybar** | single frosted pill across the top, blue accents |
| Launcher | **Rofi** (wayland) | blue theme + a nested-category menu script |
| Terminal | **Alacritty** | frosted, Atom OneDark, JetBrainsMono Nerd Font |
| Shell | **Zsh + Powerlevel10k** | minimal "lean" prompt |
| Greeting | **Fastfetch** | Arch logo + specs on every new shell |
| Notifications | **swaync** | blue notification center (bell in the bar) |
| Power menu | **wlogout** | `SUPER+Shift+E` |
| Lock | **hyprlock** + **hypridle** | auto-lock after 5 min |

### The bar layout

- **Left** — workspace pills (1–5, active one is blue) + Arch logo (click = app menu)
- **Center** — time + date
- **Right** — CPU · RAM · GPU · WiFi · Bluetooth · Battery · Notifications · Power

## Install

On a fresh Arch install (with an internet connection):

```bash
git clone https://github.com/<you>/arch-hyprland-rice.git ~/.dotfiles/arch-hyprland-rice
cd ~/.dotfiles/arch-hyprland-rice
chmod +x install.sh
./install.sh
```

The installer will:

1. install **yay** (if needed), then every package in `packages.txt` + Powerlevel10k;
2. **back up** any configs you already have (to `*.rice-backup`) and **symlink** this
   repo's configs into `~/.config`;
3. set **zsh** as your login shell and enable NetworkManager / Bluetooth / PipeWire.

Then add a wallpaper and log into Hyprland:

```bash
cp your-wallpaper.png config/hypr/wallpapers/wall.png
# log out → choose "Hyprland" at the login screen (or run `Hyprland` from a TTY)
```

### Install options

```bash
./install.sh --dry-run      # print what it would do, change nothing
./install.sh --no-packages  # only (re)link the dotfiles
```

Because the configs are **symlinked**, any change you make to your live setup is a
change to this repo — just `git commit` to version it.

## Keybinds (cheat sheet)

`SUPER` is the modifier.

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `Return` | terminal | `Space` | app launcher (drun) |
| `A` | categorized app menu | `E` | file manager |
| `Q` | close window | `F` | fullscreen |
| `V` | float toggle | `T` | split toggle |
| `X` | lock screen | `Shift+E` | power menu |
| `1`–`5` | switch workspace | `Shift`+`1`–`5` | move window to workspace |
| `H/J/K` / arrows | focus | `Shift`+arrows | move window |
| `C` | clipboard history | `N` | toggle notifications |
| `Print` | screenshot → clipboard | `SUPER+Print` | region screenshot |

Media, volume and brightness keys work out of the box.

## Customizing

- **Colors** live inline in each config; the accent is `#61afef` everywhere.
- **The app-menu categories** are just data at the top of
  `config/rofi/scripts/categories.sh`. Add categories, nest them, or drop in your
  cybersecurity tools — there's a worked Cybersecurity → Recon/Web/Exploitation/
  Wireless example already there.
- **Per-machine settings** (monitors, one-off tweaks) go in
  `~/.config/hypr/monitors.conf` and `~/.config/hypr/local.conf`, which are
  git-ignored so the repo stays portable across machines.
- **Prompt**: prefer the wizard? Run `p10k configure` (it overwrites `~/.p10k.zsh`).

## Repo layout

```
arch-hyprland-rice/
├── install.sh              # the installer
├── packages.txt            # everything to install (commented)
├── config/
│   ├── hypr/               # hyprland, hyprpaper, hypridle, hyprlock, wallpapers/
│   ├── waybar/             # config.jsonc, style.css, scripts/gpu.sh
│   ├── rofi/               # config, blue theme, scripts/categories.sh
│   ├── alacritty/          # alacritty.toml
│   ├── fastfetch/          # config.jsonc (the greeting)
│   ├── swaync/             # notification center
│   └── wlogout/            # power menu
└── zsh/                    # zshrc + p10k.zsh (linked to ~/.zshrc, ~/.p10k.zsh)
```

## Credits

Palette: [Atom One Dark](https://github.com/atom/atom). Built to be a clean,
re-usable base — fork it and make it yours.
