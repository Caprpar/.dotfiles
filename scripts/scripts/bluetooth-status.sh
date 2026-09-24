#!/usr/bin/env bash
# Shows one icon per connected bluetooth device (matching the device type),
# colored green/yellow/red to reflect that device's battery level.
#
# Queried straight over D-Bus instead of `bluetoothctl`: bluetoothctl's
# non-interactive commands (`devices Connected`, `info`) are unreliable -
# they can print stale/empty state even while a device is actually
# connected (verified against org.bluez.Device1.Connected directly).
#
# Icons are written as \u/\U escapes (not literal glyphs) so this file
# stays plain ASCII and survives editing tools that mangle private-use
# unicode ranges.

# Same catppuccin macchiato green/yellow/red already used in vpn-status.sh
battery_color() {
  local pct=$1
  if ((pct >= 60)); then
    echo "a6da95" # green
  elif ((pct >= 25)); then
    echo "eed49f" # yellow
  else
    echo "ed8796" # red
  fi
}

device_icon() {
  case "$1" in
  audio-headset | audio-headphones) printf '%b' '\U000f02cb' ;; # headphones
  audio-card) printf '%b' '\U000f04c3' ;;                       # speaker
  input-mouse) printf '%b' '\U000f037d' ;;                      # mouse
  input-keyboard) printf '%b' '\U000f030c' ;;                   # keyboard
  input-gaming | input-tablet) printf '%b' '\U000f0eb5' ;;      # gamepad
  phone) printf '%b' '\U000f011c' ;;                            # cellphone
  computer) printf '%b' '' ;;                                  # desktop
  printer) printf '%b' '\U000f02f6' ;;                          # printer
  *) printf '%b' '\U000f00af' ;;                                # bluetooth
  esac
}

devices=$(busctl --json=short call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null |
  jq -r '
        .data[0]
        | to_entries[]
        | select(.value["org.bluez.Device1"].Connected.data == true)
        | [
            (.value["org.bluez.Device1"].Icon.data // "unknown"),
            (.value["org.bluez.Device1"].Alias.data // .value["org.bluez.Device1"].Name.data // "Unknown device"),
            (.value["org.bluez.Battery1"].Percentage.data // "")
          ]
        | @tsv
    ')

output=""
notification=""
while IFS=$'\t' read -r icon_type name pct; do
  [[ -z $icon_type ]] && continue

  if [[ ${1-} == --notify ]]; then
    notification+="${notification:+$'\n'}${name}${pct:+ (${pct}%)}"
    continue
  fi

  icon=$(device_icon "$icon_type")
  if [[ -n $pct ]]; then
    icon="%{F#$(battery_color "$pct")}${icon}%{F-}"
  fi

  output+="${output:+ }${icon}"
done <<<"$devices"

if [[ ${1-} == --notify ]]; then
  notify-send "Bluetooth" "${notification:-No connected devices}"
else
  echo "$output"
fi
