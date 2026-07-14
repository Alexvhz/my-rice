# Wallpapers

Drop your wallpaper here and name it **`wall.png`** — that's the filename
`hyprpaper.conf` and `hyprlock.conf` point to.

```
cp ~/Downloads/my-cool-wallpaper.png ./wall.png
```

Want a different filename or multiple monitors? Edit `../hyprpaper.conf`.

By default `.gitignore` still lets you commit images here (the wallpaper
ignore rules are commented out) so your rice is fully reproducible. If you'd
rather keep large images out of git, uncomment the `wallpapers/*` lines in
`.gitignore` at the repo root.
