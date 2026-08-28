#!/usr/bin/env bash
output=$(warp-cli vnet 2>/dev/null)

names=$(awk '/^  Name:/ {print $2}' <<<"$output")
choice=$(printf '%s\n' "$names" | dmenu -p "Switch database:" -l 5)

[ -z "$choice" ] && exit 0

id=$(awk -v want="$choice" '
/^  ID:/ { id=$2 }
/^  Name:/ { if ($2 == want) { print id; exit } }
' <<<"$output")

[ -n "$id" ] && warp-cli vnet "$id"
