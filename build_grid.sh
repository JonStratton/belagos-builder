#!/bin/sh

# If KVM is available, check so we can add it to our runners
kvm=''
if [ `cat /proc/cpuinfo | grep 'vmx\|svm' | wc -l` -ge 1 ]; then
   kvm='-cpu host -enable-kvm'
fi

# Arch for ISO and qemu
iso_arch='386'
qemu_arch='i386'
arch=`uname -m`
if [ $arch = 'x86_64' ]; then
   iso_arch='amd64'
   qemu_arch=$arch
fi
local_iso="9front.$iso_arch.iso"

[ ! -d img ] && mkdir img
[ ! -d bin ] && mkdir bin

#######################
# Disk and RAM Sizing #
#######################
   # Just gobble up most. TODO, confirm with prompts

# 512 for base debian gui, 64 for each plan9vm. Split the rest between the fsserve and the cpuserve(most)
total_core=`cat /proc/meminfo | grep "^MemTotal:" | awk '{print $2}'`
core_free_mb=`expr \( $total_core / 1024 \) - 512 - \( 64 \* 3 \)`
fsserve_core=`expr \( \( $core_free_mb \* 25 \) / 100 \) + 64`
cpuserve_core=`expr \( \( $core_free_mb \* 75 \) / 100 \) + 64`
authserve_core=64

# 75% of the free disk for fsserve
free_disk=`df -k | grep '/home/$' | awk '{print $4}'`
if [ ! $free_disk ]; then
   free_disk=`df -k | grep ' /$' | awk '{print $4}'`
fi
free_mb=`expr $free_disk / 1024`
fsserve_disk_gb=`expr \( \( $free_mb \* 75 \) / 100 \) / 1024`G

############
# Password #
############
   # Use Glenda's password for the install

if [ ! $GLENDA_PASS ]; then
   default=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
   read -p "Enter password for glenda(default $default): " GLENDA_PASS
   [ -z $GLENDA_PASS ] && GLENDA_PASS=$default
   export GLENDA_PASS
fi

if [ ! $USER_PASS ]; then
   default=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
   read -p "Enter password for user(default $default): " USER_PASS
   [ -z $USER_PASS ] && USER_PASS=$default
   export USER_PASS
fi

################
# Download ISO #
################
   # TODO, replace with torrent to avoid angering 9front

if [ $1 ]; then
   local_iso=$1
   echo "using $local_iso"
elif [ ! -f $local_iso ]; then
   remote_iso=`wget -O - http://9front.org/iso/ 2>/dev/null | grep ".$iso_arch.iso.gz<" | cut -d'"' -f4`
   wget -O $local_iso.gz http://9front.org/iso/$remote_iso
   gunzip $local_iso.gz
fi

################
# Base Install #
################
   # This will be converted to our fsserve

echo "qemu-system-$qemu_arch $kvm -m $fsserve_core -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_base.img -device scsi-hd,drive=vd0 \$*" > bin/base_run.sh
chmod u+x bin/base_run.sh

# Run base installer directly
if [ ! -f img/9front_base.img ]; then
   qemu-img create -f qcow2 img/9front_base.img $fsserve_disk_gb
   build_grid/9front_base.exp bin/base_run.sh 9front.iso
fi

###########
# FSSERVE #
###########

echo "qemu-system-$qemu_arch $kvm -m $fsserve_core -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_fsserve.img -device scsi-hd,drive=vd0 \$*" > bin/fsserve_run.sh
chmod u+x bin/fsserve_run.sh

bin/fsserve_dependancy.sh

#############
# AUTHSERVE #
#############

echo "qemu-system-$qemu_arch $kvm -m $authserve_core -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_authserve.img -device scsi-hd,drive=vd0 -boot n \$*" > bin/authserve_run.sh
chmod u+x bin/authserve_run.sh

bin/authserve_dependancy.sh

############
# CPUSERVE #
############

echo "qemu-system-$qemu_arch $kvm -smp 4 -m $cpuserve_core -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_cpuserve.img -device scsi-hd,drive=vd0 -boot n \$*" > bin/cpuserve_run.sh
chmod u+x bin/cpuserve_run.sh

bin/cpuserve_dependancy.sh

########################
# Turn down everything #
########################

echo "qemu-system-$qemu_arch $kvm -m 64 -net nic,macaddr=52:54:00:00:EE:06 -net vde,sock=/var/run/vde2/tap0.ctl -boot n \$*" > bin/termserve_run.sh
chmod u+x bin/termserve_run.sh
pkill qemu
