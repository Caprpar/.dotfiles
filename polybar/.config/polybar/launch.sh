#!/usr/bin/env bash
# Only allow one reload at a time. Close the lock fd in launched children.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/polybar-launch-${UID}.lock"
flock -n 9 || exit 0

# IPC can hang when a bar is frozen. Stop bars directly and bound the wait.
pkill -u "$UID" -x polybar || true
for ((attempt = 0; attempt < 30; attempt++)); do
  pgrep -u "$UID" -x polybar >/dev/null || break
  sleep 0.1
done
if pgrep -u "$UID" -x polybar >/dev/null; then
  pkill -KILL -u "$UID" -x polybar || true
fi
# Launch a bar on each monitor
for m in $(polybar --list-monitors | cut -d":" -f1); do
  case "$m" in
  HDMI-A-0) bar="caspar-hdmi" ;;
  DisplayPort-0) bar="caspar-dp" ;;
  DP-1) bar="caspar-dp1" ;;
  eDP-1) bar="caspar-edp1" ;;
  *) bar="caspar" ;;
  esac
  MONITOR="$m" polybar "$bar" >>"/tmp/polybar-$m.log" 2>&1 9>&- &
  disown
done
echo "Bars launched..."
