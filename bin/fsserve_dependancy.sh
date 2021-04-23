#!/bin/sh

# 2. Run with no hup
if [ $1 = '-d' ]; then
   nohup bin/fsserve_run.sh -nographic &
else
   bin/fsserve_run.sh -nographic
fi
