#!/bin/sh -x

~/bin/run_fsserve.sh -nographic > /dev/null 2>&1 &
sleep 20
cat ~/.belagos_pass | bin/9front_boot_wait.sh 192.168.9.3

~/bin/run_authserve.sh -nographic > /dev/null 2>&1 &
sleep 20
cat ~/.belagos_pass | bin/9front_boot_wait.sh 192.168.9.4

~/bin/run_cpuserve.sh -nographic > /dev/null 2>&1
