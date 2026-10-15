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

projects=(lx-api-server lx-booking/apps/lx-booking-api lx-booking/apps/lx-booking-web lx-react-client lx-tenant-api)
commands=('npm run dev' 'npm run dev' 'npm run dev' 'npm run dev:vite' 'npm run dev')

for project in "${projects[@]}"; do
  [[ -f "$root/$project/package.json" ]] || fail "Saknar $root/$project/package.json."
done

session="$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}')"
window_name=server-dev
if tmux list-windows -t "$session" -F '#{window_name}' | grep -Fxq "$window_name"; then
  fail "Fönstret $window_name finns redan i sessionen. Stäng det innan du startar igen."
fi

# Create all panes before starting the servers. The calling window is preserved.
first_pane="$(tmux new-window -d -P -F '#{pane_id}' -t "$session:" -n "$window_name" -c "$root/${projects[0]}")"
window="$(tmux display-message -p -t "$first_pane" '#{window_id}')"
panes=("$first_pane")

for ((index = 1; index < ${#projects[@]}; index++)); do
  pane="$(tmux split-window -d -P -F '#{pane_id}' -t "$first_pane" -c "$root/${projects[$index]}")"
  panes+=("$pane")
  tmux select-layout -t "$window" tiled >/dev/null
done

for index in "${!projects[@]}"; do
  tmux select-pane -t "${panes[$index]}" -T "${projects[$index]##*/}"
  tmux send-keys -t "${panes[$index]}" -l "${commands[$index]}"
  tmux send-keys -t "${panes[$index]}" Enter
done

tmux select-window -t "$window"
tmux select-pane -t "$first_pane"
printf 'Startade %s utvecklingsservrar i tmux-fönstret %s.\n' "${#projects[@]}" "$window_name"
