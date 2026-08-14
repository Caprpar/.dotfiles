#!/bin/bash
BASE_DIR="$HOME/surikat"

declare -A CMDS=(
  ["lx-booking"]="npm run dev"
  ["lx-react-client"]="npm run dev:vite"
  ["lx-tenant-api"]="npm run dev"
  ["lx-api-server"]="npm run dev"
  # ["lx-import-service"]="export TENANTS='pof' && npm start"
  # ["lx-report-service"]="export TENANTS=pof && npm run dev"
)

# Vim-sessioner
for session in lx-booking lx-react-client lx-tenant-api lx-api-server lynx3; do
  path="$BASE_DIR/$session"
  tmux new-session -d -s "$session" -c "$path"
  tmux send-keys -t "$session:0" "v ." C-m
done

# Server-sessioner
for session in lx-booking lx-react-client lx-tenant-api lx-api-server; do
  path="$BASE_DIR/$session"
  cmd="${CMDS[$session]}"
  tmux new-session -d -s "$session-server" -c "$path"
  tmux send-keys -t "$session-server:0" "$cmd" C-m
done

# Docker stack: kör start-only-lynx, sedan lazydocker
tmux new-session -d -s "docker-stack" -c "$BASE_DIR/lx-docker-stack"
tmux send-keys -t "docker-stack" "./start-only-lynx.sh && lazydocker" C-m

# tmux new-session -d -s "util-scripts" -c "$BASE_DIR/lx-util-scripts-ts"
# tmux send-keys -t "lx-util-scripts-ts" "v ."

echo "done"
