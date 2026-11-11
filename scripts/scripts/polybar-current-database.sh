#!/usr/bin/env bash
output=$(warp-cli vnet 2>/dev/null)
selected=$(awk '/^Currently selected:/ {print $3}' <<<"$output")

name=$(awk -v sel="$selected" '
/^  ID:/ { id=$2 }
/^  Name:/ { if (id == sel) { print $2; exit } }
' <<<"$output")
# 
case "$name" in
EU-FAT-vnet) echo "%{F#e06c2e}FAT%{F-}" ;;         # green
EU-Staging-vnet) echo "%{F#e02e49}STAG%{F-}" ;;    # red
EU-Production-vnet) echo "%{F#e02ea2}PROD%{F-}" ;; # yellow
*) echo "%{F#6e738d} %{F-}" ;;
esac
