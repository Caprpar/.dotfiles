#!/usr/bin/env bash
set -euo pipefail

config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HOME/scripts/machine-profile.sh"

case "$MACHINE_PROFILE" in
home | work) ;;
*)
  printf 'Invalid MACHINE_PROFILE: %s (expected home or work)\n' "$MACHINE_PROFILE" >&2
  exit 1
  ;;
esac

# Only allow one reload at a time. Close the lock fd in launched children.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/polybar-launch-${UID}.lock"
flock -n 9 || exit 0

# Check monitors before stopping the currently running bars.
monitors="$(polybar --list-monitors)"
if [[ -z "$monitors" ]]; then
  printf 'No monitors found; leaving existing bars running.\n' >&2
  exit 1
fi

# IPC can hang when a bar is frozen. Stop bars directly and bound the wait.
pkill -u "$UID" -x polybar || true
for ((attempt = 0; attempt < 30; attempt++)); do
  pgrep -u "$UID" -x polybar >/dev/null || break
  sleep 0.1
done
if pgrep -u "$UID" -x polybar >/dev/null; then
  pkill -KILL -u "$UID" -x polybar || true
fi

# Use the selected machine layout on every connected monitor.
while IFS=: read -r monitor _; do
  [[ -n "$monitor" ]] || continue
  case "$monitor" in
  HDMI-A-0 | DisplayPort-0) bar="$MACHINE_PROFILE-scaled" ;;
  *) bar="$MACHINE_PROFILE" ;;
  esac
  MONITOR="$monitor" polybar --config="$config_dir/config.ini" "$bar" >>"/tmp/polybar-$monitor.log" 2>&1 9>&- &
  disown
done <<<"$monitors"

printf 'Bars launched (MACHINE_PROFILE=%s).\n' "$MACHINE_PROFILE"
