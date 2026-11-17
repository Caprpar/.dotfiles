#!/usr/bin/env bash
# Toggle screen recording (bound to $mod+plus in i3).
#   screenrec.sh             start/stop video-only recording
#   screenrec.sh --mic | -m   start with microphone audio, or stop recording
#   screenrec.sh status      print polybar label (used by module/screenrec)

PIDFILE=/tmp/screenrec.pid
OUTDIR=/tmp/recordings

isRecording() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }
updateBar() { polybar-msg action screenrec hook 0 >/dev/null 2>&1; }

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

  local -a audio_args=(-an)
  if [[ ${1:-} == --mic || ${1:-} == -m ]]; then
    # Keep microphone audio from being dropped while x11grab/x264 is busy.
    audio_args=(
      -thread_queue_size 4096 -f pulse -ac 1 -i default
      -af "volume=2,aresample=async=1" -c:a libopus -b:a 128k
    )
  fi

  # Large video queue + ultrafast keep encoding real-time.
  setsid ffmpeg -nostdin -loglevel warning \
    -thread_queue_size 1024 -video_size "$size" -framerate 25 -f x11grab -i "${DISPLAY:-:0.0}+$offset" \
    "${audio_args[@]}" \
    -c:v libx264 -preset ultrafast -crf 23 \
    "$file" >/tmp/screenrec.log 2>&1 &
  echo $! >"$PIDFILE"
  echo "$file" >/tmp/screenrec.file

  updateBar
  notify-send -u low "Recording started" "$(basename "$file")"
}

stop() {
  local pid file
  pid="$(cat "$PIDFILE")"
  file="$(cat /tmp/screenrec.file 2>/dev/null)"

  # SIGINT lets ffmpeg finalize the mkv properly
  kill -INT "$pid"
  while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
  rm -f "$PIDFILE" /tmp/screenrec.file

  updateBar
  notify-send -u low "Recording saved" "$file"
}

case "${1:-}" in
status)
  isRecording && echo "%{F#d4a0a8}● REC%{F-}" || echo ""
  ;;
""|--mic|-m)
  if isRecording; then stop; else
    rm -f "$PIDFILE"
    start "${1:-}"
  fi
  ;;
*)
  printf 'Usage: %s [--mic|-m|status]\n' "${0##*/}" >&2
  exit 1
  ;;
esac
