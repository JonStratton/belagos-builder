#!/bin/sh

runner=$1
ip=$2

nohup $runner -nographic > /dev/null 2>&1 &

if [ ! -z $ip ]; then
   sleep 20
   cat ~/.belagos_pass | bin/9front_boot_wait.sh $ip > /tmp/boot_wait2.txt
fi
