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
local_iso="iso/9front.$iso_arch.iso"

[ ! -d img ] && mkdir img
[ ! -d bin ] && mkdir bin

###################
# Glenda Password #
###################

if [ ! -f ~/.belagos_pass ]; then
   belagos_pass_default=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
   echo "Passord will be stored in ~/.belagos_pass"
   read -p "Enter password for glenda(default $belagos_pass_default): " belagos_pass
   [ -z $belagos_pass ] && belagos_pass=$belagos_pass_default
   touch ~/.belagos_pass
   chmod 600 ~/.belagos_pass
   echo $belagos_pass > ~/.belagos_pass
fi

################
# Download ISO #
################

if [ $1 ]; then
   local_iso=$1
   echo "using $local_iso"
elif [ ! -f $local_iso ]; then
   # TODO, replace with torrent to avoid angering 9front
   mkdir iso
   remote_iso=`wget -O - http://9front.org/iso/ 2>/dev/null | grep ".$iso_arch.iso.gz<" | cut -d'"' -f4`
   wget -O $local_iso.gz http://9front.org/iso/$remote_iso
   gunzip $local_iso.gz
fi

###########
# FSSERVE #
###########

echo "qemu-system-$qemu_arch $kvm -m 256 -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_fsserve.img -device scsi-hd,drive=vd0 \$*" > bin/run_fsserve.sh
chmod u+x bin/run_fsserve.sh

# This can be large, as all other VMs will boot off of this disk
if [ ! -f img/9front_fsserve.img ]; then
   qemu-img create -f qcow2 img/9front_fsserve.img 10G
   # Creating base install image
   build_grid/9front_install.exp bin/run_fsserve.sh $local_iso
fi

# Back it up as expect is unrelyable with curses
[ ! -f img/9front_fsserve.img_back ] && cp img/9front_fsserve.img img/9front_fsserve.img_back

# Set up networking and turn on PXE
cat ~/.belagos_pass | build_grid/9front_fsserve.exp bin/run_fsserve.sh

# Boot fsserve in the background and wait until its up
build_grid/run_headless.exp bin/run_fsserve.sh > /dev/null 2>&1 &
sleep 10
bin/9front_boot_wait.sh 192.168.9.3

# Run installer via drawterm
cat ~/.belagos_pass | build_grid/9front_fsserve_net_and_pxe.exp

# Boot fsserve in the background and wait until its up
build_grid/run_headless.exp bin/run_fsserve.sh > /dev/null 2>&1 &
sleep 10
bin/9front_boot_wait.sh 192.168.9.3

#############
# AUTHSERVE #
#############
# fsserve needs to be done first, as authserve netboots from it

echo "qemu-system-$qemu_arch $kvm -m 256 -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_authserve.img -device scsi-hd,drive=vd0 -boot n \$*" > bin/run_authserve.sh
chmod u+x bin/run_authserve.sh

qemu-img create -f qcow2 img/9front_authserve.img 1M
cat ~/.belagos_pass | build_grid/9front_authserve.exp bin/run_authserve.sh

# Run it in the BG as we need it for cpuserve creation
build_grid/run_headless.exp bin/run_authserve.sh > /dev/null 2>&1 &
sleep 10
bin/9front_boot_wait.sh 192.168.9.4

############
# CPUSERVE #
############

echo "qemu-system-$qemu_arch $kvm -smp 4 -m 256 -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_cpuserve.img -device scsi-hd,drive=vd0 -boot n \$*" > bin/run_cpuserve.sh
chmod u+x bin/run_cpuserve.sh

qemu-img create -f qcow2 img/9front_cpuserve.img 1M
cat ~/.belagos_pass | build_grid/9front_cpuserve.exp bin/run_cpuserve.sh

########################
# Turn down everything #
########################

cat ~/.belagos_pass | /opt/drawterm/drawterm -h 192.168.9.4 -a 192.168.9.4 -u glenda -G -c "fshalt"
cat ~/.belagos_pass | /opt/drawterm/drawterm -h 192.168.9.3 -a 192.168.9.3 -u glenda -G -c "fshalt"
