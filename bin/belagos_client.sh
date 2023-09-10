#!/bin/sh
# This script acts as a way to interact with the hosts on the backend, mostly around the boot process. Really, this process is only needed due to funkiness caused by using “secure mode” / disk encryption. This allows us, via named pipes, to get the encryption password into the boot process and not store it on disk (AKA the “secret zero” problem). If this is the client, “boot_pipe_menu.exp” is the service.

# Clean up the tail -f on exit
trap "kill 0" 1 2 3 6

in=""
out=""

main()
{
tail -f $out &

if [ $1 ]; then
   cat <<EOF > $in
$1
EOF
else
   echo "status" > $in
   while [ 1 ]; do
      read command_in
      cat <<EOF > $in
$command_in
EOF
   done
fi
}

args()
{
proj_root=`dirname $0`'/..'
cd $proj_root

# If argument use it if it exists
if [ $1 ]; then
   if [ -w "./grid/$1_in" ]; then
      in="./grid/$1_in"
      out="./grid/$1_out"
   else
      echo "Error, can not find named pipes under ./grid/$1_*"
   fi
elif [ `ls -1 ./grid/*_in | wc -l` -eq 1 ]; then
   single_in=`ls -1 ./grid/*_in`
   base=`basename $single_in _in`
   in="./grid/${base}_in"
   out="./grid/${base}_out"
else
   for pipe_in in `ls -1 ./grid/*_in`; do
      basename $pipe_in | sed 's/_in$//g'
   done
   exit 1
fi
}

args $1
main $2
exit 0
