#!/bin/bash

for iface in tun0 wg0 nordlynx proton0; do
  if ip link show "$iface" &>/dev/null 2>&1; then
    echo "󰦝"
    exit 0
  fi
done

echo ""
