#!/usr/bin/env bash

set -euo pipefail

exec xrandr \
  --output DisplayPort-0 --primary --mode 2560x1440 --rate 99.95 \
  --output HDMI-A-0 --mode 2560x1440 --rate 99.95 --right-of DisplayPort-0
