#!/usr/bin/env bash
# Show open P1/P2 support tickets for P&O Ferries; prints nothing when there are none.
set -euo pipefail
umask 077

cache_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/polybar"
monitor="${MONITOR:-default}"
url_file="$cache_dir/p1p2-${monitor//[^a-zA-Z0-9_.-]/_}.url"

if [[ ${1-} == --open ]]; then
  [[ -r "$url_file" ]] || exit 0
  IFS= read -r ticket_url <"$url_file" || exit 0
  [[ $ticket_url =~ ^https://[^[:space:]]+$ ]] || exit 0
  exec xdg-open "$ticket_url" >/dev/null 2>&1
fi

mkdir -p -- "$cache_dir"

# Polybar may start without the interactive shell's PATH.
twg_bin=$(command -v twg || printf '%s' "$HOME/.local/bin/twg")

purple='#b48ef0'
icon=$'\uf1e2'

if ! result=$(
  timeout --kill-after=2s 20s "$twg_bin" jira workitem query \
    --site surikat.atlassian.net \
    --jql 'filter = "SURHD - P&O Ferries" AND priority in (P1, P2) AND statuscategory != Done ORDER BY priority ASC, created DESC' \
    --fields priority \
    --limit 50 \
    --output json \
    --output-summary none 2>/dev/null |
    jq -r '
      if .ok == false or .error != null or ((.errors // []) | length > 0) or (.data.issues | type) != "array" then
        error("Jira query failed")
      else
        .data.issues as $i
        | if ($i | length) == 0 then empty
          elif ($i[0].url | test("^https://[^[:space:]]+$")) then
            [$i[0].url, ($i[0].key | gsub("[^A-Za-z0-9-]"; "")), ($i | length | tostring), ($i[0].priority.name // "")] | join("\t")
          else
            error("Invalid ticket URL")
          end
      end
    ' 2>/dev/null
); then
  : >"$url_file"
  exit 0
fi

if [[ -z $result ]]; then
  : >"$url_file"
  exit 0
fi

IFS=$'\t' read -r ticket_url key count prio <<<"$result"
printf '%s\n' "$ticket_url" >"$url_file"

label="$prio $key"
((count > 1)) && label+=" +$((count - 1))"
printf '%%{F%s}%s %s%%{F-}\n' "$purple" "$icon" "$label"
