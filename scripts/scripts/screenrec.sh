#!/usr/bin/env bash
# Toggle screen recording (bound to $mod+plus in i3).
#   screenrec.sh             start/stop video-only recording
#   screenrec.sh --mic | -m   start with microphone audio, or stop recording
#   screenrec.sh status      print polybar label (used by module/screenrec)

PIDFILE=/tmp/screenrec.pid
OUTDIR=/tmp/recordings
LOCKDIR=/tmp/screenrec.lock.d

# Audio tuning (safe defaults; tweak these).
MIC_GAIN=1.4
MIC_MIX_GAIN=1.3
SYSTEM_MIX_GAIN=1
COMPRESSOR_THRESHOLD_DB=-18
COMPRESSOR_RATIO=3
MIX_COMPRESSOR_RATIO=2.5
LIMITER_LIMIT=0.95

isRecording() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }
updateBar() { polybar-msg action screenrec hook 0 >/dev/null 2>&1; }

acquire_lock() {
  # Avoid concurrent start/stop toggles from key-repeat.
  if ! mkdir "$LOCKDIR" 2>/dev/null; then
    return 1
  fi
  trap 'rmdir "$LOCKDIR" 2>/dev/null || true' EXIT
}

get_monitor_source() {
  local sink
  sink="$(pactl get-default-sink 2>/dev/null)" || return 1
  [ -n "$sink" ] || return 1
  printf '%s.monitor\n' "$sink"
}

# A Bluetooth headset mic that is not in headset mode never delivers samples,
# which makes ffmpeg block forever. Fall back to a built-in mic in that case.
get_mic_source() {
  local src
  src="$(pactl get-default-source 2>/dev/null)"
  if [ -z "$src" ] || [[ $src == bluez_* ]]; then
    src="$(pactl list short sources 2>/dev/null | awk '$2 ~ /^alsa_input/ {print $2}' | sort | head -1)"
    local mic1
    mic1="$(pactl list short sources 2>/dev/null | awk '$2 ~ /^alsa_input.*Mic1/ {print $2; exit}')"
    [ -n "$mic1" ] && src="$mic1"
  fi
  printf '%s\n' "${src:-default}"
}

pick_audio_mode() {
  local choice
  if command -v rofi >/dev/null 2>&1; then
    choice="$(printf '%s\n' quiet mic 'computer sound' 'mic + computer sound' | rofi -dmenu -i -p "Record audio")"
  elif command -v dmenu >/dev/null 2>&1; then
    choice="$(printf '%s\n' quiet mic 'computer sound' 'mic + computer sound' | dmenu -i -l 4 -p "Record audio")"
  else
    # No menu tool installed; fall back to quiet recording.
    printf 'quiet\n'
    return 0
  fi

  case "$choice" in
  quiet | mic | "computer sound" | "mic + computer sound")
    printf '%s\n' "$choice"
    ;;
  *)
    # Cancel/escape defaults to quiet so the keybind still works.
    printf 'quiet\n'
    ;;
  esac
}

start() {
  # Capture the monitor under the pointer when recording is initiated.
  local mouse_x mouse_y size offset
  if ! read -r mouse_x mouse_y < <(
    xdotool getmouselocation --shell 2>/dev/null |
      awk -F= '/^X=/ {x=$2} /^Y=/ {if (x != "") print x, $2}'
  ); then
    notify-send -u critical "Recording failed" "Could not locate mouse pointer."
    return 1
  fi
  if ! read -r size offset < <(
    xrandr --listmonitors | awk -v x="$mouse_x" -v y="$mouse_y" '
      NR > 1 {
        geometry = $3
        gsub(/\/[0-9]+/, "", geometry)
        gsub(/[+-]/, " &", geometry)
        split(geometry, rect, /[x ]/)
        if (x >= rect[3] && x < rect[3] + rect[1] &&
            y >= rect[4] && y < rect[4] + rect[2]) {
          printf "%sx%s %d,%d\n", rect[1], rect[2], rect[3], rect[4]
          exit
        }
      }'
  ); then
    notify-send -u critical "Recording failed" "Could not determine monitor under pointer."
    return 1
  fi

  mkdir -p "$OUTDIR"
  local word
  word="$(faker word 2>/dev/null | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]')"
  local file="$OUTDIR/$(date '+%Y-%m-%d_%H-%M-%S')_${word:-recording}.mkv"

  local mode monitor mic
  mode="${1:-quiet}"
  mic="$(get_mic_source)"

  local -a audio_input_args=()
  local -a audio_output_args=(-an)
  case "$mode" in
  quiet)
    ;;
  mic)
    audio_input_args=(-thread_queue_size 4096 -f pulse -ac 1 -i "$mic")
    audio_output_args=(-af "highpass=f=80,volume=${MIC_GAIN},acompressor=threshold=${COMPRESSOR_THRESHOLD_DB}dB:ratio=${COMPRESSOR_RATIO}:attack=5:release=100,alimiter=limit=${LIMITER_LIMIT},aresample=async=1" -c:a libopus -b:a 128k)
    ;;
  "computer sound")
    if ! monitor="$(get_monitor_source)"; then
      notify-send -u critical "Recording failed" "Could not determine PulseAudio monitor source."
      return 1
    fi
    audio_input_args=(-thread_queue_size 4096 -f pulse -ac 2 -i "$monitor")
    audio_output_args=(-af "alimiter=limit=${LIMITER_LIMIT},aresample=async=1" -c:a libopus -b:a 128k)
    ;;
  "mic + computer sound")
    if ! monitor="$(get_monitor_source)"; then
      notify-send -u critical "Recording failed" "Could not determine PulseAudio monitor source."
      return 1
    fi
    audio_input_args=(
      -thread_queue_size 4096 -f pulse -ac 1 -i "$mic"
      -thread_queue_size 4096 -f pulse -ac 2 -i "$monitor"
    )
    audio_output_args=(
      -filter_complex "[1:a]highpass=f=80,volume=${MIC_GAIN},acompressor=threshold=${COMPRESSOR_THRESHOLD_DB}dB:ratio=${COMPRESSOR_RATIO}:attack=5:release=100,alimiter=limit=${LIMITER_LIMIT},aresample=async=1[mic];[2:a]volume=${SYSTEM_MIX_GAIN},alimiter=limit=${LIMITER_LIMIT},aresample=async=1[sys]"
      -map 0:v -map "[mic]" -map "[sys]"
      -c:a libopus -b:a 128k
      -metadata:s:a:0 title=Mic -metadata:s:a:1 title="Computer sound"
    )
    ;;
  *)
    notify-send -u critical "Recording failed" "Unknown audio mode: $mode"
    return 1
    ;;
  esac

  # Large video queue + ultrafast keep encoding real-time.
  setsid ffmpeg -nostdin -loglevel warning \
    -thread_queue_size 1024 -video_size "$size" -framerate 25 -f x11grab -i "${DISPLAY:-:0.0}+$offset" \
    "${audio_input_args[@]}" \
    -c:v libx264 -preset ultrafast -crf 23 -pix_fmt yuv420p \
    "${audio_output_args[@]}" \
    "$file" >/tmp/screenrec.log 2>&1 &
  echo $! >"$PIDFILE"
  echo "$file" >/tmp/screenrec.file

  # If ffmpeg crashes immediately, clean up stale state right away.
  sleep 0.2
  if ! kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    rm -f "$PIDFILE" /tmp/screenrec.file
    updateBar
    notify-send -u critical "Recording failed" "ffmpeg exited on start. Check /tmp/screenrec.log"
    return 1
  fi

  updateBar
  notify-send -u low "Recording started" "$(basename "$file")"
}

stop() {
  local pid file
  pid="$(cat "$PIDFILE")"
  file="$(cat /tmp/screenrec.file 2>/dev/null)"

  # Try graceful stop first (best chance for playable file), then escalate.
  if kill -0 "$pid" 2>/dev/null; then
    local i
    kill -INT "$pid" 2>/dev/null || true
    for ((i = 0; i < 50; i++)); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done

    if kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
      for ((i = 0; i < 20; i++)); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
      done
    fi

    if kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid" 2>/dev/null || true
      notify-send -u normal "Recording stopped (forced)" "Process was unresponsive; output may be incomplete."
    fi
  fi
  rm -f "$PIDFILE" /tmp/screenrec.file

  updateBar
  notify-send -u low "Recording saved" "$file"
}

case "${1:-}" in
status)
  isRecording && echo "%{F#d4a0a8}● REC%{F-}" || echo ""
  ;;
"" | --mic | -m)
  acquire_lock || exit 0
  if isRecording; then stop; else
    rm -f "$PIDFILE"
    if [[ ${1:-} == --mic || ${1:-} == -m ]]; then
      start "mic"
    else
      start "$(pick_audio_mode)"
    fi
  fi
  ;;
*)
  printf 'Usage: %s [--mic|-m|status]\n' "${0##*/}" >&2
  exit 1
  ;;
esac
