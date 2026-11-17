#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'server: %s\n' "$*" >&2
  exit 1
}

root="$HOME/surikaterna"
[[ -d "$root" ]] || fail "Mappen $root finns inte."
root="$(cd "$root" && pwd -P)"
[[ "$(pwd -P)" == "$root" ]] || fail "Du måste befinna dig i $root/ innan du kör server."
[[ -n "${TMUX:-}" && -n "${TMUX_PANE:-}" ]] || fail "Du måste köra server inifrån en tmux-session."
command -v tmux >/dev/null || fail "tmux är inte installerat."
command -v tmux-servers >/dev/null || fail "tmux-servers är inte installerat."

if tmux-servers list >/dev/null 2>&1; then
  fail "En serverpanel finns redan. Använd Ctrl+s, v för att välja server."
fi

servers=(
  'lx-api-server|npm run dev'
  'lx-booking|npm run dev:https'
  'lx-react-client|npm run dev:vite'
  'lx-tenant-api|TENANTS='["pof"]' && npm run dev'
  'inventory-engine|npm start'
  'lx-pesos|npm run dev'
  'lx-import-service|npm start'
  'grandprix|npm run dev'
)

for server in "${servers[@]}"; do
  project="${server%%|*}"
  [[ -f "$root/$project/package.json" ]] || fail "Saknar $root/$project/package.json."
done

session="$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}')"
window_name=server-dev
if tmux list-windows -t "$session" -F '#{window_name}' | grep -Fxq "$window_name"; then
  fail "Fönstret $window_name finns redan i sessionen. Stäng det innan du startar igen."
fi

# Create all panes before starting the servers. The calling window is preserved.
first_project="${servers[0]%%|*}"
first_pane="$(tmux new-window -d -P -F '#{pane_id}' -t "$session:" -n "$window_name" -c "$root/$first_project")"
window="$(tmux display-message -p -t "$first_pane" '#{window_id}')"
panes=("$first_pane")

for ((index = 1; index < ${#servers[@]}; index++)); do
  project="${servers[$index]%%|*}"
  pane="$(tmux split-window -d -P -F '#{pane_id}' -t "$first_pane" -c "$root/$project")"
  panes+=("$pane")
  tmux select-layout -t "$window" tiled >/dev/null
done

for index in "${!servers[@]}"; do
  project="${servers[$index]%%|*}"
  command="${servers[$index]#*|}"
  tmux select-pane -t "${panes[$index]}" -T "${project##*/}"
  tmux send-keys -t "${panes[$index]}" -l "$command"
  tmux send-keys -t "${panes[$index]}" Enter
done

tmux-servers setup "$first_pane"
tmux select-window -t "$window"
tmux select-pane -t "$first_pane"
printf 'Startade %s utvecklingsservrar i panelen %s. Ctrl+s, v väljer server.\n' "${#servers[@]}" "$window_name"
