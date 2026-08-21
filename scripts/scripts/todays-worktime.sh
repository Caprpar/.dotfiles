#!/usr/bin/env bash
# Shows today's total Watson work time, excluding the "break" project,
# including the currently running frame, for polybar.

seconds=0
while IFS=$'\t' read -r start stop; do
  s=$(date -d "$start" +%s)
  e=$(date -d "$stop" +%s)
  seconds=$((seconds + e - s))
done < <(watson log --day -c --ignore-project break --json 2>/dev/null | jq -r '.[] | [.start, .stop] | @tsv')

h=$((seconds / 3600))
m=$(((seconds % 3600) / 60))
s=$((seconds % 60))

if ((h > 0)); then
  elapsed=$(printf "%dh %02dm" "$h" "$m")
else
  elapsed=$(printf "%dm %02ds" "$m" "$s")
fi

echo "󰥔 ${elapsed}"
