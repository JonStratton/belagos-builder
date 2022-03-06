#!/bin/sh


script_loc=`dirname $0`
in="$script_loc/../img/$1_in"
out="$script_loc/../img/$1_out"

# If no arguments, print out connections and exit.
if [ ! $1 ]; then
   for pipe_in in `ls -1 bin/../img/*_in`; do 
      basename $pipe_in | sed 's/_in$//g'
   done
   exit 1
fi

# If argument, check pipe if exists. If not, exit

main()
{
tail -f $out &
echo "status" > $in
while [ 1 ]; do
   read command_in
   cat <<EOF > $in
$command_in
EOF
done
}

main
exit 0
