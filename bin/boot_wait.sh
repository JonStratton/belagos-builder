#!/bin/sh

max_counter=40
sleep='sleep 5'

counter=0
success=0

for var in "$@"
do
   ip=`echo "$var" | cut -d':' -f1`
   port=`echo "$var" | cut -d':' -f2`

   # Ping IP
   success=0
   while [ $counter -lt $max_counter -a $success -eq 0 ]; do
      ping="ping -c 1 -q $ip"
      echo $ping
      if [ `$ping | grep "1 received" | wc -l` -ge 1 ]; then
         success=1
      else
         echo $sleep
         `$sleep`
         counter=`expr $counter + 1`
      fi
   done

   # NC port
   if [ $port ]; then
      success=0
      while [ $counter -lt $max_counter -a $success -eq 0 ]; do
         nc="nc -vz $ip $port"
         echo $nc
         if [ `$nc 2>&1 | grep "open" | wc -l` -ge 1 ]; then
            success=1
         else
            echo $sleep
            `$sleep`
            counter=`expr $counter + 1`
         fi
      done
   fi
done

if [ $success -eq 1 ]; then
   echo "Success"
   exit 0
fi

echo "Fail"
exit 1
