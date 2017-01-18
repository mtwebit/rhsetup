#!/bin/bash
# Simple shell script to check an RBD mapping using sysfs.
# Created by Tamas Meszaros <meszaros@mit.bme.hu>
# See https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-bus-rbd

function show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-p POOL] [-i IMAGE]
Check an rbd device identified by an image name.
  -h        display this help and exit
  -p POOL   Ceph pool name
  -i IMAGE  Ceph image name
EOF
}

while getopts "hp:i:" opt; do
  case "$opt" in
    h) show_help
       exit 0
       ;;
    p) pool=$OPTARG
       ;;
    i) image=$OPTARG
       ;;
    '?')
       echo "UNKNOWN - Plugin error: invalid or missing arguments. See -h for help."
       exit 3
       ;;
  esac
done

if [ ! -d /sys/bus/rbd/devices ]; then
  echo "CRITICAL - Kernel module missing."
  exit 2
fi

devid=$(cd /sys/bus/rbd/devices/; dirname `/usr/bin/egrep --files-with-match "^${image}$" */name 2>/dev/null` 2>/dev/null)

if [ "$devid" == "" ]; then
  echo "CRITICAL - RBD device $image not mapped."
  exit 2
fi

devname=$(cat /sys/bus/rbd/devices/${devid}/name)
devpool=$(cat /sys/bus/rbd/devices/${devid}/pool)

if [ "$pool" != "$devpool" ]; then
  echo "CRITICAL - RBD device '$image' from pool '$pool' not mapped. (Found in '$devpool' pool.)"
  exit 2
fi

echo "OK - ${image} in pool ${devpool} mapped."
exit 0
