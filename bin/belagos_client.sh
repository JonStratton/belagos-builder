#!/bin/sh


script_loc=`dirname $0`
in="$script_loc/../img/belagos_in"
out="$script_loc/../img/belagos_out"
safe_owner="belagos"

main()
{
check_pipes

tail -f $out &
echo "status" > $in
while [ 1 ]; do
   read command_in
   check_pipes
   cat <<EOF > $in
$command_in
EOF
done
}

# Check Pipes in case someone is spying on us!
check_pipes()
{
pipe_error=""
in_user=`stat -c %U $in`
out_user=`stat -c %U $out`
in_perm=`stat -c %A $in`
out_perm=`stat -c %A $out`

#if [ "$in_user" != "$safe_user" -a "$in_user" != `whoami` ]; then
#   pipe_error="Unsafe owner($in_user) on $in, $pipe_error"
#fi
if [ "$in_perm" != "prw--w--w-" ]; then
   pipe_error="Unsafe permissions($in_perm) on $in, $pipe_error"
fi
#if [ "$out_user" != "$safe_user" -a "$out_user" != `whoami` ]; then
#   pipe_error="Unsafe owner($out_user) on $out, $pipe_error"
#fi
if [ "$out_perm" != "prw-r--r--" ]; then
   pipe_error="Unsafe permissions($out_perm) on $out, $pipe_error"
fi

if [ "$pipe_error" ]; then
   error_bad $pipe_error
fi
}

error_bad()
{
echo $@
echo "exiting"
exit 1
}

main
exit 0
