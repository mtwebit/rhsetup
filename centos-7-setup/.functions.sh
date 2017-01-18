#!/bin/bash
#
# CentOS/Fedora post install customization utility
#   created by Tamas Meszaros <meszaros@mit.bme.hu>
#
# Version 20141113
#
# This script can be freely distributed and modified under GPLv2.
# See http://www.gnu.org/licenses/gpl-2.0.html

function killme() {
  # Remove the status file (TODO) and exit on interrupt
  [ "$TODO" != "" ] && [ -f $TODO ] && /bin/rm $TODO
  exit $?
}

# Execute and log a command and its outout
function x() {
  trap "stop_progress $prpid; exit" TERM EXIT
  trap killme SIGINT
  start_progress &
  prpid=$!
  echo "" >> $LOG
  echo "# $*" >> $LOG
  # Remove the status file (TODO) and exit on error
  bash -c "$* 2>&1" >> $LOG || { echo "ERROR: command "$*" failed. See the log for details."; stop_progress $prpid; killme; }
  sleep 1
  stop_progress $prpid
  # bash -x -c "$*" >> $LOG
}

# Append the argument line to the post-install todo list
function todo() {
  echo "$*" >> $TODO
}

# Append several argument lines from stdin to the post-install todo list
function todos() {
  cat - >> $TODO
}

# set and remember a variable
function remember() {
  if [ "${2}" == "" ]; then
    echo "Internal error: invalid variable value"
    exit
  fi
  eval ${1}=${2}
  echo "${1}=${2}" >> $VARS
}

# Ask a question, remember the answer (and provide a default answer)
# ARGS: 1:varname to set 2:question text 3:default value if varname is not set
function ask() {
  # the default answer is $varname or $3 or ""
  tmpans=`eval echo \\$$1`
  [ "$3" != "" ] && tmpans="$3"
  echo -n "${2} [$tmpans] "
  read pp
  # use the default answer
  [ "$pp" == "" ] && pp=$tmpans
  if [ "$pp" == "" ]; then
    eval ${1}=$3
  else
    eval ${1}=$pp
  fi
  # remember variables except yes/no questions ($ypp)
  [ "$1" != "ypp" ] && remember $1 $pp || eval ${1}=${pp}
}

# asks for a password and store it in a variable
# ARGS: 1: variable name 2: question text
# This part is based on http://stackoverflow.com/questions/4316730/linux-scripting-hiding-user-input-on-terminal/4316755#4316755
function askpw() {
  echo -n "${2} [ENTER=generate] "
  unset ypp
  while IFS= read -r -s -n1 pwc; do
    if [[ -z $pwc ]]; then
       echo
       break
    else
       echo -n '*'
       ypp+=$pwc
    fi
  done
  [ "$ypp" == "" ] && ypp=`/usr/bin/mkpasswd -l 8 -d 1 -s 0`
  eval ${1}=${ypp}
}

# Ask a yes/no question, returns true on answering y
# 1:question 2:default answer
function askif() {
  ask ypp "$1" "$2"
  [ "${ypp}" == "y" ]
}

# Append firewall rules to the custom rules file
function addfwrule() {
  [ ! -x /usr/bin/firewall-cmd ] && echo "Firewall will not be set as it is not installed." && return
  fwzone=$1
  shift
  echo -n "Firewall zone from where requests will be allowed: [$fwzone] "
  read pp
  if [ "$pp" != "" ]; then
    fwzone=$pp
  fi
  x firewall-cmd --permanent --zone=$fwzone $*
  if [ $? -eq 0 ]; then
    echo $* added to $fwzone zone
    x firewall-cmd --reload
    x firewall-cmd --zone=$fwzone --list-all
    # Store the rule
    echo "--zone=$fwzone $*" >> ${FWRULESDIR}/$rhscript
  else
    # dump the error
    firewall-cmd --permanent --zone=$fwzone $*
  fi
}
