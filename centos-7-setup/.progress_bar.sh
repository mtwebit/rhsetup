#!/bin/bash

# Simple progress bar based on the work of
#
# Copyright © Abner Ballardo Urco
# http://www.modlost.net
#

#
# Cool Progress Indicator
#
function start_progress {
  chars=( "-" "\\" "|" "/" )
  interval=0.5
  count=0

  while true
  do
    pos=$(($count % 4))

    echo -en "\b${chars[$pos]}"

    count=$(($count + 1))
    sleep $interval
  done
}

#
# Stop progress indicator
#
function stop_progress {
  exec 2>/dev/null
  kill $1
  echo -en "\n"
}

# Thanks Stephen Concannon for sending this fix.
# If the main script is interrupted, this line takes care
# of stopping the progress indicator
trap "stop_progress $prpid; exit" INT TERM EXIT
