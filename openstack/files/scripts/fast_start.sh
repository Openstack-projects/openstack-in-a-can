#!/bin/bash
set -ex
function fast_start() {
  local slow_start_command="${*}"
  local need_run="true"
  if [[ -f "/var/run/secrets/airshipit.org/faststart/${FAST_START_SERVICE}" ]]; then
    if [[ "${FAST_START}" == "true" ]]; then
      if [[ "$(cat "/var/run/secrets/airshipit.org/faststart/${FAST_START_SERVICE}")" == "${MY_IMAGE}" ]]; then
        need_run="false"
      fi
    fi
  fi

  if [[ "${need_run}" == "true" ]]; then
      ${slow_start_command}
      echo "${MY_IMAGE}" > "/var/run/secrets/airshipit.org/faststart/${FAST_START_SERVICE}"
  fi
}
fast_start "${@}"