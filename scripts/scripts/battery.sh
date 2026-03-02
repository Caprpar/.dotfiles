#!/bin/bash
NOTIFIED=false

while :; do
  POWER=$(acpi -b | grep "Battery 1" | grep -oP '\d+(?=%)')

  if [[ -n $POWER ]]; then
    if [[ $POWER -le 20 ]]; then
      if [[ $NOTIFIED == false ]]; then
        notify-send "Battery power is lower than 20%! (Current: $POWER%)"
        NOTIFIED=true
      fi
    else
      NOTIFIED=false
    fi
  fi

  sleep 30
done
