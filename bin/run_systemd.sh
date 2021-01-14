#!/bin/sh

runner=$1
needed_ip=$2

# If we need a server before starting, wait on it
if [ ! -z $needed_ip ]; then
   cat ~/.belagos_pass | bin/9front_boot_wait.sh $needed_ip
   wait_code=$?
   if [ $wait_code -ne 0 ]; then
      >&2 echo "$needed_ip doesnt appear to be up. Giving up."
      exit $wait_code
   fi
fi

nohup $runner -nographic
