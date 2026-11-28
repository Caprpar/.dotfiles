#!/bin/bash
# Orange dot while any app is actively recording from a microphone.
n=$(pactl list source-outputs 2>/dev/null | awk '
  /^Source Output #/ {if (c=="no" && !skip) n++; c=""; skip=0}
  /Corked:/ {c=$2}
  /application.name = "(pavucontrol|PulseAudio Volume Control)"/ {skip=1}
  /media.name = "Peak detect"/ {skip=1}
  END {if (c=="no" && !skip) n++; print n+0}')
if [ "$n" -gt 0 ]; then echo "%{F#ff9f0a}●%{F-}"; else echo ""; fi
