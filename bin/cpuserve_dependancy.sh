#!/bin/sh

# 1. Check Dep IP Addresses. If up, move on.
bin/boot_wait.sh 192.168.9.3:564 192.168.9.4:567
wait_code=$?
if [ $wait_code -ne 0 ]; then
   >&2 echo "192.168.9.3:564 and 192.168.9.4:567 doesnt appear to be up. Giving up."
   exit $wait_code
fi

# 3. Run with no hup
if [ $1 = '-d' ]; then
   nohup bin/cpuserve_run.sh -nographic &
else
   bin/cpuserve_run.sh -nographic
fi
