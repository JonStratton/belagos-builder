#!/bin/sh

# 1. Check Dep IP Addresses. If up, move on.
bin/boot_wait.sh 192.168.9.3:17019 192.168.9.4:17019
wait_code=$?
if [ $wait_code -ne 0 ]; then
   >&2 echo "192.168.9.3:17019 and 192.168.9.4:17019 doesnt appear to be up. Giving up."
   exit $wait_code
fi

# 2. Check image. If Missing,  do install.
if [ ! -f img/9front_cpuserve.img ]; then
   qemu-img create -f qcow2 img/9front_cpuserve.img 1M
   build_grid/9front_cpuserve.exp bin/cpuserve_run.sh
fi

# 3. Run with no hup
if [ $1 = '-d' ]; then
   nohup bin/cpuserve_run.sh -nographic &
else
   bin/cpuserve_run.sh -nographic
fi
