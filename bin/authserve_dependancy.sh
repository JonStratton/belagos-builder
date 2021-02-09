#!/bin/sh

# 1. Check Dep IP Addresses. If up, move on.
bin/boot_wait.sh 192.168.9.3:564
wait_code=$?
if [ $wait_code -ne 0 ]; then
   >&2 echo "192.168.9.3:564 doesnt appear to be up. Giving up."
   exit $wait_code
fi

# 2. Check image. If Missing,  do install.
if [ ! -f img/9front_authserve.img ]; then
   qemu-img create -f qcow2 img/9front_authserve.img 1M
   build_grid/9front_authserve.exp bin/authserve_run.sh
fi

# 3. Run with no hup
if [ $1 = '-d' ]; then
   nohup bin/authserve_run.sh -nographic &
else
   bin/authserve_run.sh -nographic
fi
