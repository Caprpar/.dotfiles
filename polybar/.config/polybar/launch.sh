#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Launch a bar on each monitor
for m in $(polybar --list-monitors | cut -d":" -f1); do
  case "$m" in
  DP-1) bar="caspar-dp1" ;;
  eDP-1) bar="caspar-edp1" ;;
  *) bar="caspar" ;;
  esac
  polybar "$bar" 2>&1 | tee -a /tmp/polybar-$m.log &
  disown
done

echo "Bars launched..."
