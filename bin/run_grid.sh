#!/bin/sh -x

bin/run_headless.exp bin/run_fsserve.sh > /dev/null 2>&1 &
sleep 10
cat .belagos_pass | bin/9front_boot_wait.sh 192.168.9.3

bin/run_headless.exp bin/run_authserve.sh > /dev/null 2>&1 &
sleep 10
cat .belagos_pass | bin/9front_boot_wait.sh 192.168.9.4

bin/run_headless.exp bin/run_cpuserve.sh > /dev/null 2>&1 &
