#!/usr/bin/env bash

/usr/bin/feh --bg-fill ~/Pictures/wallhaven-jexkwm.jpg &
/usr/bin/setxkbmap se &
# /usr/local/bin/st &

# fading
# shadow
# in fade .05
# out fade .05
# --corner-radius 12
# picom -fc -I .05 -O .05 -CG -b
# picom -cfF -o 0.38 -O 200 -I 200 -t 0 -l 0 -r 3 -D2 -m 0.88
picom --config ~/.config/picom/picom.conf &
~/scripts/statusbar.sh &
