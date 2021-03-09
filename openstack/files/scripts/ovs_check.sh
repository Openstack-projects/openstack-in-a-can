#!/bin/bash
set -ex

: ${OVS_SOCKET:="/run/openvswitch/db.sock"}

t=0
while [ ! -e "${OVS_SOCKET}" ] ; do
    echo "waiting for ovs socket $sock"
    sleep 1
    t=$(($t+1))
    if [ $t -ge 600 ] ; then
        echo "no ovs socket, giving up"
        exit 1
    fi
done
ovs-vsctl --db=unix:${OVS_SOCKET} --no-wait show