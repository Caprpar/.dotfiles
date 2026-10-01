#!/usr/bin/env bash
# Toggle screen recording (bound to $mod+plus in i3).
#   screenrec.sh          start/stop recording
#   screenrec.sh status   print polybar label (used by module/screenrec)

PIDFILE=/tmp/screenrec.pid
OUTDIR=/tmp/recordings

isRecording() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }
updateBar() { polybar-msg action screenrec hook 0 >/dev/null 2>&1; }

start() {
  mkdir -p "$OUTDIR"
  local word
  word="$(faker word 2>/dev/null | tr -cd '[:alpha:]' | tr '[:upper:]' '[:lower:]')"
  local file="$OUTDIR/$(date '+%Y-%m-%d_%H-%M-%S')_${word:-recording}.mkv"
  # Whole X screen (all monitors), e.g. 2880x1800
  local size
  size="$(xrandr | awk '/current/{print $8"x"$10}' | tr -d ,)"

  # Large thread queues + pulse input keep audio from being dropped
  # while x11grab/x264 is busy; ultrafast keeps encoding real-time
  setsid ffmpeg -nostdin -loglevel warning \
    -thread_queue_size 1024 -video_size "$size" -framerate 25 -f x11grab -i :0.0 \
    -thread_queue_size 4096 -f pulse -ac 1 -i default \
    -af "volume=4,aresample=async=1" \
    -c:v libx264 -preset ultrafast -crf 23 -c:a libopus -b:a 128k \
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

case $1 in
status)
  isRecording && echo "%{F#d4a0a8}● REC%{F-}" || echo ""
  ;;
*)
  if isRecording; then stop; else
    rm -f "$PIDFILE"
    start
  fi
  ;;
esac
