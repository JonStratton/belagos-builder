#!/bin/sh
# This script will attempt to run a VM in the background (via “boot_pipe_menu.exp” and nohup) and report “Success” if it detects that its done booting.

proj_root=`dirname $0`'/..'
cd $proj_root

sleep='sleep 10'
lastline=''

for process in "$@"
do
   touch /tmp/boot_wait_$USER.txt
   chmod 600 /tmp/boot_wait_$USER.txt

   # Run Process in BG
   nohup ./bin/boot_pipe_menu.exp $process > /tmp/boot_wait_$USER.txt 2>&1 &

   success=0
   while [ $success -eq 0 ]; do
      if [ `grep "Final Status: Booted" /tmp/boot_wait_$USER.txt | wc -l` -ge 1 ]; then
         success=1
      else
         curline=`tail -n 1 /tmp/boot_wait_$USER.txt`
         if [ ! "$lastline" = "$curline"  ]; then
            lastline=$curline
            echo $lastline
         fi
         `$sleep`
      fi
   done

   rm /tmp/boot_wait_$USER.txt
done

echo "Success"
exit 0
