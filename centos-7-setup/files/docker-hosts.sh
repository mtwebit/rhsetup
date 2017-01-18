#!/bin/bash
# Simple shell script to generate hosts entries for docker containers
# Created by Tamas Meszaros <meszaros@mit.bme.hu>

function show_help() {
cat << EOF
Usage: ${0##*/} [-hi] [CID]
List information about docker hosts
  -h	display this help and exit
  -i	display IP addresses
EOF
}

while getopts "hp:i:" opt; do
  case "$opt" in
    h) show_help
       exit 0
       ;;
    i) qformat='{{ .NetworkSettings.IPAddress }}'
       ;;
    i) image=$OPTARG
       ;;
    '?')
       echo "ERROR: Invalid or missing arguments. See -h for help."
       exit 3
       ;;
  esac
done

if [ ! -x /usr/bin/docker ]; then
  echo "ERROR: Docker is not installed."
  exit 2
fi

for i in "`docker ps -aq`"
do
echo $i `docker inspect --format $qformat $i`
done
exit 0
