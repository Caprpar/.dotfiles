#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Launch a bar on each monitor
for m in $(polybar --list-monitors | cut -d":" -f1); do
  MONITOR=$m polybar caspar 2>&1 | tee -a /tmp/polybar-$m.log &
  disown
done

echo "Bars launched..."
