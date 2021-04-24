#!/bin/sh

max_counter=600
sleep='sleep 1'

counter=0
success=0

for process in "$@"
do
   touch /tmp/boot_wait.txt
   chmod 600 /tmp/boot_wait.txt

   # Run Process in BG
   echo $process
   nohup $process > /tmp/boot_wait.txt 2>&1 &

   success=0
   while [ $counter -lt $max_counter -a $success -eq 0 ]; do
      if [ `grep "\# " /tmp/boot_wait.txt | wc -l` -ge 1 ]; then
         success=1
      else
         `$sleep`
         counter=`expr $counter + 1`
      fi
   done

   rm /tmp/boot_wait.txt
done

if [ $success -eq 1 ]; then
   echo "Success"
   exit 0
fi

echo "Fail"
exit 1
