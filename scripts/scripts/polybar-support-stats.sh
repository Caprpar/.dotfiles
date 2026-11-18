#!/usr/bin/env bash
# Show P&O Ferries support counts as colored text: open, closed today, assigned to me.
set -uo pipefail
umask 077

# Polybar may start without the interactive shell's PATH.
twg_bin=$(command -v twg || printf '%s' "$HOME/.local/bin/twg")

site="surikat.atlassian.net"
base='filter = "SURHD - P&O Ferries"'
team='assignee IN (membersOf("Mariteam"))'

count() {
  timeout --kill-after=2s 20s "$twg_bin" jira workitem query \
    --site "$site" \
    --jql "$1" \
    --fields key \
    --limit 100 \
    --output json \
    --output-summary none 2>/dev/null |
    jq -r '
      if .ok == false or .error != null or ((.errors // []) | length > 0) or (.data.issues | type) != "array" then
        "?"
      else
        .data.issues | length
      end
    ' 2>/dev/null || printf '?'
}

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT

count "$base AND statuscategory != Done AND $team" >"$tmp/open" &
count "$base AND resolutiondate >= startOfDay() AND $team" >"$tmp/team" &
count "$base AND statuscategory != Done AND assignee = currentUser()" >"$tmp/mine" &
wait

open=$(<"$tmp/open")
team_done=$(<"$tmp/team")
mine_open=$(<"$tmp/mine")

fg_primary='#c8bfe8'
fg_secondary='#9b8ec4'
alert='#d4a0a8'
good='#a8d4a0'
dim='#7a6fa0'

item() {
  printf '%%{F%s}%s %s%%{F-}' "$1" "$2" "$3"
}

open_color=$fg_secondary
[[ $open =~ ^[0-9]+$ ]] && ((open >= 40)) && open_color=$alert
[[ $open == '?' ]] && open_color=$dim

team_color=$dim
[[ $team_done =~ ^[0-9]+$ ]] && ((team_done > 0)) && team_color=$good

mine_color=$dim

printf '%s  %s  %s\n' \
  "$(item "$open_color" '󰈸' "$open")" \
  "$(item "$team_color" '󰄵' "$team_done")" \
  "$(item "$mine_color" '󰀄' "$mine_open")"
