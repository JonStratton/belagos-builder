#!/bin/sh
# boot_wait.sh is back from the grave. undead undead undead

sleep='sleep 10'

for process in "$@"
do
   touch /tmp/boot_wait.txt
   chmod 600 /tmp/boot_wait.txt

   # Run Process in BG
   echo bin/boot_pipe_menu.exp $process
   nohup bin/boot_pipe_menu.exp $process > /tmp/boot_wait.txt 2>&1 &

   success=0
   while [ $success -eq 0 ]; do
      if [ `grep "Final Status: Booted" /tmp/boot_wait.txt | wc -l` -ge 1 ]; then
         success=1
      else
         tail -n 1 /tmp/boot_wait.txt
         echo
         `$sleep`
      fi
   done

   rm /tmp/boot_wait.txt
done

echo "Success"
exit 0
