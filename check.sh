#!/bin/bash
set -ex
while true; do
  date
  time helm template ./openstack --debug > debug1.log
  time helm template ./openstack --debug > debug2.log
  if [[ $(diff debug1.log debug2.log) ]]; then
      echo "diff found"
      exit 1
  else
      echo "no diff found"
  fi
done
