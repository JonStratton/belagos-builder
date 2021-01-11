#!/bin/sh

ip=$1
max_counter=40
sleep="sleep 5"

counter=0
success=0

# Start with ping
while [ $counter -lt $max_counter -a $success -eq 0 ]
do
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

# Once server is pingable, try drawterm
success=0
while [ $counter -lt $max_counter -a $success -eq 0 ]
do
   drawterm="/opt/drawterm/drawterm -h $ip -a $ip -u glenda -G -c 'uptime'"
   echo $drawterm
   if [ `cat .belagos_pass | $drawterm | grep days | wc -l` -ge 1 ]; then
      success=1
   else
      echo $sleep
      `$sleep`
      counter=`expr $counter + 1`
   fi
done

if [ $success -eq 1 ]; then
   echo "Success"
else
   echo "Fail"
fi
