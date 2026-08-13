#!/usr/bin/env bash
# Shows the currently active Watson project + elapsed time for polybar.

status=$(watson status -p 2>/dev/null)

if [[ -z "$status" || "$status" == "No project started." ]]; then
  echo "󰥔 No project"
  exit 0
fi

elapsed=$(watson status -e 2>/dev/null)

echo " ${status} · ${elapsed}"
