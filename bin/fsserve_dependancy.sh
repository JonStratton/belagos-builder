#!/bin/sh

# 1. Check image. If Missing,  do install.
if [ ! -f img/9front_fsserve.img ]; then
   # This should have been created by build_grid.sh.
   cp img/9front_base.img img/9front_fsserve.img

   # Set up networking and turn on PXE
   build_grid/9front_fsserve.exp bin/fsserve_run.sh
fi
 
# 2. Run with no hup
nohup bin/fsserve_run.sh -nographic &
