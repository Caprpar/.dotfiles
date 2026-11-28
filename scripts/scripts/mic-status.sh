#!/bin/bash
if [ "$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}')" = "yes" ]; then
  echo "%{F#666666}󰍭%{F-}"
else
  echo "%{F#c8bfe8}󰍬%{F-}"
fi
