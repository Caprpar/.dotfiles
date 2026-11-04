# Sökbar serverpanel i tmux

**Ctrl+s, v** öppnar en sökbar lista med loggförhandsvisning. Skriv en del av
servernamnet, välj med piltangenterna och tryck **Enter**. **Esc** avbryter och
**Ctrl+r** uppdaterar förhandsvisningen.

Den valda serverns riktiga pane visas i den fasta serverpanelen. Övriga panes
parkeras i tmux-sessionen `_servers`. Processer och befintlig scrollback följer
med vid bytet; inget startas om. Snabbknappen fungerar även från andra sessioner
och tar bara den anropande klienten till serverpanelen.

Detta är en sökbar växlare, inte en flikrad inuti en pane. Panelens överkant visar
vilken server som är vald. `_servers` kan synas i tmux sessionslista, men behöver
inte vara ansluten. **Stäng inte den sessionen om servrarna ska fortsätta köra.**

## Kommandon

```sh
tmux-servers                    # öppna samma väljare
tmux-servers list               # pane-id, servernamn och terminalprocess
tmux-servers show inventory     # välj ett entydigt delnamn
tmux-servers unpack             # visa alla server-panes tillsammans, i rutnät
```

`unpack` stoppar inga processer. Det återställer panelens tidigare kantinställningar,
men inte den ursprungliga fördelningen av pane-storlekar.

För att samla befintliga server-panes: stå i den pane som ska vara synlig och kör
`tmux-servers setup`. **Alla panes i just det fönstret räknas som servrar**; använd
ett separat serverfönster, inte ett blandat editor-/serverfönster. Övriga fönster
lämnas orörda. En extra editor-pane som läggs till efter setup flyttas inte av väljaren.

Det befintliga `server`-kommandot i `~/surikaterna` använder panelen automatiskt
vid nya starter och avböjer att starta en dubblett när en panel redan finns.
Dess projektlista och startkommandon är oförändrade.

## Filer och tester

- `bin/.local/bin/tmux-servers` – växlare och pane-hantering.
- `tmux.conf/.tmux.conf` – snabbknappen.
- `scripts/scripts/server.sh` – start av nya servrar.

Från `~/.dotfiles`:

```sh
python3 -B -m unittest discover -s tests -p test_tmux_servers.py -v
```

Testerna använder egna tmux-sockets under `/tmp/opencode`, aldrig de riktiga sessionerna.
