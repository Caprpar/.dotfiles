# i3 + polybar — miljöinstallation

Paketlista framtagen genom att läsa igenom `i3/.config/i3/config`,
`polybar/.config/polybar/config.ini`, `polybar/.config/polybar/launch.sh`
och alla scripts de anropar (`scripts/scripts/*`, `bin/.local/bin/*`).
Kör hela blocket nedan med `yay` (paketen finns både i officiella repon
och AUR, `yay` löser båda).

## Engångsinstallation

```bash
yay -S --needed \
  i3-wm polybar picom dmenu dex xss-lock feh i3lock \
  xorg-xset xorg-setxkbmap xorg-xprop xorg-xdpyinfo xsel xclip \
  networkmanager network-manager-applet \
  kitty neovim flameshot slack-desktop firefox-developer-edition \
  playerctl brightnessctl libpulse \
  pastel gpick \
  python-i3ipc \
  dunst libnotify \
  ttf-cascadia-code-nerd \
  acpi jq bluez bluez-utils pavucontrol \
  bc
```

Glöm inte att aktivera/starta NetworkManager och Bluetooth-daemonen om de
inte redan körs:

```bash
sudo systemctl enable --now NetworkManager bluetooth
```

## Vad varje paket används till

### Kärna (fönsterhanterare / bar / compositor)
| Paket | Används av |
|---|---|
| `i3-wm` | Fönsterhanteraren själv (inkl. `i3lock`-nagbar-dialogen på `$mod+Shift+e`) |
| `polybar` | Statusbaren, startas via `polybar/.config/polybar/launch.sh` |
| `picom` | `exec_always picom --config ~/.config/picom/picom.conf` i i3-config |
| `dmenu` | `$mod+d`, samt `dmenu-calc` och `dmenu-claude` |
| `dex` | `exec --no-startup-id dex --autostart --environment i3` (XDG autostart) |
| `xss-lock` | Skärmlås-trigger vid suspend, kör `i3lock` |
| `feh` | Sätter bakgrundsbild (`feh --bg-scale ~/wallpapers/cow-field.jpg`) |
| `i3lock` | `$mod+x`, `$mod+Ctrl+l` |

### X-verktyg
| Paket | Används av |
|---|---|
| `xorg-xset` | `xset r rate 200 35` (tangentbordsrepetition) |
| `xorg-setxkbmap` | Layout-växling (`setxkbmap se -option ctrl:nocaps`) |
| `xorg-xprop` | `$mod+t` (kopierar WM_CLASS till urklipp) |
| `xorg-xdpyinfo` | `scripts/scripts/record` (skärminspelning, bonusscript) |
| `xsel` | `$mod+p` (färgväljare), `$mod+t` |
| `xclip` | `dmenu-calc` |

### Nätverk / session
| Paket | Används av |
|---|---|
| `networkmanager` + `network-manager-applet` | `exec --no-startup-id nm-applet` |

### Program bundna till binds
| Paket | Används av |
|---|---|
| `kitty` | `$mod+Return`, `$mod+n`, `$mod+m` |
| `neovim` | Öppnas via kitty i `$mod+n` och `bin/.local/bin/scratch` |
| `flameshot` | `$mod+y`, `$mod+shift+y`, `$mod+u`, `$mod+Ctrl+l` |
| `slack-desktop` | `$mod+s` |
| `firefox-developer-edition` | `$mod+b` |

### Media / volym / ljusstyrka
| Paket | Används av |
|---|---|
| `playerctl` | `XF86AudioPlay/Next/Prev` |
| `brightnessctl` | `XF86MonBrightness{Up,Down}` |
| `libpulse` (ger `pactl`) | Volym-binds samt polybars `pulseaudio`-modul |

### Färgverktyg
| Paket | Används av |
|---|---|
| `pastel` | `$mod+p` (formatterar färg som hex) |
| `gpick` | `$mod+p` (själva färgväljar-GUI:t) |

### Python
| Paket | Används av |
|---|---|
| `python-i3ipc` | `i3/.config/i3/new_humbug_json.py` och `scripts/scripts/alternating_layouts.py` (autostartat) |

### Notifikationer
| Paket | Används av |
|---|---|
| `dunst` | Notifikationsdaemon (redan konfigurerad i `dunst/.config/dunst/dunstrc`) — behövs för alla `notify-send`-anrop |
| `libnotify` | Ger `notify-send`-kommandot |

### Typsnitt
| Paket | Används av |
|---|---|
| `ttf-cascadia-code-nerd` | `font pango:CaskaydiaCove Nerd Font` i i3, `font-0` i polybar, samt alla Nerd Font-ikoner i modulerna |

### Polybar-moduler (scripts under `scripts/scripts/`)
| Paket | Används av |
|---|---|
| `acpi` | `battery.sh` (batterivarning) |
| `jq` | `bluetooth-status.sh` (parsar D-Bus/`busctl`-JSON) |
| `bluez` + `bluez-utils` | Bluetooth-status samt `bluetoothctl` i `click-left` på bluetooth-modulen |
| `pavucontrol` | `click-right` på pulseaudio-modulen |

### Övrigt
| Paket | Används av |
|---|---|
| `bc` | `dmenu-calc` (beräkningar) |

## Kända luckor — inte lösta av paket

Dessa hittades vid genomläsningen men går inte att åtgärda med `yay`:

- **`i3/.config/i3/config:41`** pekar på `~/.config/i3/setup-monitors.sh`
  och **`i3/.config/i3/config:85`** på `~/scripts/watson-dmenu-start.sh` —
  ingendera finns i dotfiles-repot eller på filsystemet just nu. Måste
  skapas/kopieras manuellt innan i3 startar felfritt.
- **`polybar/.config/polybar/config.ini:78`** — `modules-right` listar
  `github-status`, `current-database` och `todays-worktime`, men inga
  `[module/...]`-block med dessa namn finns i filen. Polybar kommer
  varna/ignorera dem tills de definieras eller tas bort ur listan.
- **`bin/.local/bin/dmenu-claude`** kräver Claude Code-CLI:t (`claude`)
  installerat separat — det är inget pacman/AUR-paket.
- Nerd Font-glyferna i configen (t.ex. `` i `apple-icon`-modulen)
  förutsätter att `ttf-cascadia-code-nerd` faktiskt innehåller de
  Private-Use-Area-koderna som används — verifiera med `fc-list | grep -i cascadia`
  om ikoner saknas.
