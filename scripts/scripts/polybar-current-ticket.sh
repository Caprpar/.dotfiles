#!/usr/bin/env bash
# Show the latest assigned Jira ticket with the exact "In Progress" status.
set -euo pipefail
umask 077

cache_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/polybar"
monitor="${MONITOR:-default}"
url_file="$cache_dir/current-ticket-${monitor//[^a-zA-Z0-9_.-]/_}.url"

if [[ ${1-} == --open ]]; then
  [[ -r "$url_file" ]] || exit 0
  opened=0
  while IFS= read -r ticket_url; do
    [[ $ticket_url =~ ^https://[^[:space:]]+$ ]] || continue
    xdg-open "$ticket_url" >/dev/null 2>&1 &
    opened=1
  done <"$url_file"
  ((opened)) || exit 0
  exit 0
fi

mkdir -p -- "$cache_dir"

# Polybar may start without the interactive shell's PATH.
twg_bin=$(command -v twg || printf '%s' "$HOME/.local/bin/twg")

if ! ticket_data=$(
  timeout --kill-after=2s 20s "$twg_bin" jira workitem query \
    --jql 'assignee = currentUser() AND status = "In Progress" ORDER BY updated DESC' \
    --fields summary,status \
    --limit 50 \
    --output json \
    --output-summary none 2>/dev/null |
    jq -r '
      if .ok == false or .error != null or ((.errors // []) | length > 0) then
        error("Jira query failed")
      elif (.data.issues | type) != "array" then
        error("Invalid Jira response")
      else
        (.data.issues) as $issues
        | (
            ($issues[0] // empty)
            | if (.url // "" | test("^https://[^[:space:]]+$")) then
                "[\(.key)]"
                # Keep the key on one line and prevent Polybar formatting tags.
                | gsub("[[:cntrl:]]"; " ")
                | gsub("%\\{"; "% {")
              else
                ""
              end
          ) as $label
        | (
            $issues
            | map(.url // empty)
            | map(select(test("^https://[^[:space:]]+$")))
            | unique
          ) as $urls
        | $label,
          ($urls[]?)
      end
    ' 2>/dev/null
); then
  : >"$url_file"
  printf '%s\n' 'Jira?'
  exit 0
fi

ticket_label=""
if [[ -n "$ticket_data" ]]; then
  mapfile -t ticket_lines <<<"$ticket_data"
  ticket_label="${ticket_lines[0]-}"
  if ((${#ticket_lines[@]} > 1)); then
    printf '%s\n' "${ticket_lines[@]:1}" >"$url_file"
  else
    : >"$url_file"
  fi
else
  : >"$url_file"
fi

# Empty results hide the module instead of leaving a stale ticket visible.
printf '%s\n' "$ticket_label"
