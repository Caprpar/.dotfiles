#!/usr/bin/env bash
status=$(curl -s --max-time 5 https://www.githubstatus.com/api/v2/status.json)
indicator=$(jq -r '.status.indicator' <<<"$status")
description=$(jq -r '.status.description' <<<"$status")

case "$indicator" in
# none) echo "%{F#a6da95}   󰔓 %{F-}" ;;     # green, operational
# minor) echo "%{F#eed49f}    %{F-}" ;;    # yellow
# major) echo "%{F#f5a97f}   󰔑 %{F-}" ;;    # orange
# critical) echo "%{F#ed8796}    %{F-}" ;; # red
none) echo "%{F#a6da95}%{F-}" ;;     # green, operational
minor) echo "%{F#eed49f}%{F-}" ;;    # yellow
major) echo "%{F#f5a97f}%{F-}" ;;    # orange
critical) echo "%{F#ed8796}%{F-}" ;; # red
*) echo "%{F#6e738d} GitHub?%{F-}" ;; # unknown/curl fail
esac
