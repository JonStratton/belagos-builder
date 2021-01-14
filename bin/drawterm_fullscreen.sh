#!/bin/sh

res=`xdpyinfo 2> /dev/null | awk '/dimensions/ {print $2}'`
geo='-G' # No gui
if [ $res ]; then
   geo="-g $res"
fi

/opt/drawterm/drawterm -h 192.168.9.5 -a 192.168.9.4 -u glenda $geo
