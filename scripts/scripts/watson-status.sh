#!/usr/bin/env bash
# Shows the currently active Watson project + today's total time
# (completed frames + the still-running one) for polybar.

status=$(watson status -p 2>/dev/null)

if [[ -z "$status" || "$status" == "No project started." ]]; then
  echo "󰥔 No project"
  exit 0
fi

seconds=$(watson report --day -c --project "$status" --json 2>/dev/null | jq '.time')
seconds=${seconds%.*}

h=$((seconds / 3600))
m=$(((seconds % 3600) / 60))
s=$((seconds % 60))

if ((h > 0)); then
  elapsed=$(printf "%dh %02dm" "$h" "$m")
else
  elapsed=$(printf "%dm %02ds" "$m" "$s")
fi

echo " ${status} · ${elapsed}"
