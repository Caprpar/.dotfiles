#!/usr/bin/env bash
# Source this file to share the machine profile between shells and launchers.
# An explicitly set profile takes precedence over hostname detection.
if [[ -z "${MACHINE_PROFILE:-}" ]]; then
  case "$(uname -n)" in
  archikat) MACHINE_PROFILE=work ;;
  *) MACHINE_PROFILE=home ;;
  esac
fi

export MACHINE_PROFILE
