#!/bin/sh

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
script_loc=`dirname $0`
# If argument use it if it exists
if [ $1 ]; then
   if [ -w "bin/../img/$1_in" ]; then
      in="$script_loc/../img/$1_in"
      out="$script_loc/../img/$1_out"
   else
      echo "Error, can not find named pipes under bin/../img/$1_*"
   fi
elif [ `ls -1 $script_loc/../img/*_in | wc -l` -eq 1 ]; then
   single_in=`ls -1 $script_loc/../img/*_in`
   base=`basename $single_in _in`
   in="$script_loc/../img/${base}_in"
   out="$script_loc/../img/${base}_out"
else
   for pipe_in in `ls -1 bin/../img/*_in`; do
      basename $pipe_in | sed 's/_in$//g'
   done
   exit 1
fi
}

args $1
main $2
exit 0
