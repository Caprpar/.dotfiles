# Polybar: hemma och jobb

`MACHINE_PROFILE` är en exporterad miljövariabel med värdet `home` eller `work`.
Den sätts i `~/scripts/machine-profile.sh`, som läses av både
`~/.bashrc_custom` och Polybars `launch.sh`. Därmed fungerar valet även när
i3 startar Polybar utan en interaktiv terminal.

- `archikat` → `work` (jobbdatorn).
- Övriga hostnames → `home`. Lägg till fler hostname-regler i scriptet vid behov.
- En redan satt `MACHINE_PROFILE` går före det automatiska valet.

## Välj vad som visas

Ändra `modules-left`, `modules-center` och `modules-right` i `config.ini`:

- `[bar/home]`: hemmadatorns layout.
- `[bar/work]`: jobbdatorns layout.
- `[bar/base]`: gemensamt utseende, färger, typsnitt och avstånd.

Båda profilerna börjar med samma layout. Modulerna definieras längre ned i
filen och kan användas i båda profilerna. Lämna en modullista tom för att
dölja den delen av baren.

Launchern startar den valda profilen på varje ansluten skärm. HDMI-A-0 och
DisplayPort-0 behåller sin tidigare skalning på 80 DPI via ärvda barsektioner;
övriga skärmar använder Polybars automatiska DPI.

## Ladda om eller välj profil manuellt

```bash
# Automatisk profil, eller den profil som redan är exporterad:
~/.config/polybar/launch.sh

# Tillfälligt val för denna start:
MACHINE_PROFILE=home ~/.config/polybar/launch.sh
MACHINE_PROFILE=work ~/.config/polybar/launch.sh

# Läs in variabeln i en redan öppen terminal:
source ~/scripts/machine-profile.sh
echo "$MACHINE_PROFILE"
```

För ett permanent manuellt val i hela inloggningssessionen kan du exportera
`MACHINE_PROFILE=home` eller `MACHINE_PROFILE=work` i sessionens startmiljö.
Vill du återgå till automatisk identifiering i en terminal, kör
`unset MACHINE_PROFILE` och läs sedan in `machine-profile.sh` igen.
