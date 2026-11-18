#!/usr/bin/env bash
# Show the latest assigned Jira ticket with the exact "In Progress" status.
set -euo pipefail
umask 077

cache_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/polybar"
monitor="${MONITOR:-default}"
url_file="$cache_dir/current-ticket-${monitor//[^a-zA-Z0-9_.-]/_}.url"

if [[ ${1-} == --open ]]; then
  [[ -r "$url_file" ]] || exit 0
  IFS= read -r ticket_url <"$url_file" || exit 0
  [[ $ticket_url =~ ^https://[^[:space:]]+$ ]] || exit 0
  exec xdg-open "$ticket_url" >/dev/null 2>&1
fi

mkdir -p -- "$cache_dir"

# Polybar may start without the interactive shell's PATH.
twg_bin=$(command -v twg || printf '%s' "$HOME/.local/bin/twg")

if ! ticket=$(
  timeout --kill-after=2s 20s "$twg_bin" jira workitem query \
    --jql 'assignee = currentUser() AND status = "In Progress" ORDER BY updated DESC' \
    --fields summary,status \
    --limit 1 \
    --output json \
    --output-summary none 2>/dev/null |
    jq -r '
      if .ok == false or .error != null or ((.errors // []) | length > 0) then
        error("Jira query failed")
      elif (.data.issues | type) != "array" then
        error("Invalid Jira response")
      else
        .data.issues[0] // empty
        | if (.url | test("^https://[^[:space:]]+$")) then
            [
              .url,
              (
                "[\(.key)]"
                # Keep the key on one line and prevent Polybar formatting tags.
                | gsub("[[:cntrl:]]"; " ")
                | gsub("%\\{"; "% {")
              )
            ] | join("\t")
          else
            error("Invalid ticket URL")
          end
      end
    ' 2>/dev/null
); then
  : >"$url_file"
  printf '%s\n' 'Jira?'
  exit 0
fi

ticket_url=""
ticket_label=""
if [[ -n "$ticket" ]]; then
  IFS=$'\t' read -r ticket_url ticket_label <<<"$ticket"
fi

# Cache this monitor's displayed URL so clicking does not run a new Jira query.
printf '%s\n' "$ticket_url" >"$url_file"
# Empty results hide the module instead of leaving a stale ticket visible.
printf '%s\n' "$ticket_label"
