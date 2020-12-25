#!/bin/sh
# This should be done after out tap0 dev is up

# Create keepass db(belagos.kdbx) so we dont have to default passwords.
expect keepass.exp

# Prep the VMs
wget http://9front.org/iso/9front-8013.d9e940a768d1.amd64.iso.gz
gunzip 9front-8013.d9e940a768d1.amd64.iso.gz

# FSSERVE
# Creating base install image
expect 9front_fsserve_install.exp 9front_fsserve.img 256 9front-8013.d9e940a768d1.amd64.iso 10G
# Back it up as expect is unrelyable with curses
cp 9front_fsserve.img 9front_fsserve.img_back
# Set up networking and turn on PXE
expect 9front_fsserve_configure.exp 9front_fsserve.img 256
# Runner scripts for our VDE network after reboot
echo "qemu-system-x86_64 -m 256 -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=9front_fsserve.img -device scsi-hd,drive=vd0 -curses" > run_fsserve.sh
chmod u+x run_fsserve.sh

# AUTHSERVE
# authserve and cpuserve should be PXE bootable at this point
qemu-img create -f qcow2 9front_authserve.img 1M
expect 9front_authserve_configure.exp 9front_authserve.img 256
echo "qemu-system-x86_64 -m 256 -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=9front_authserve.img -device scsi-hd,drive=vd0 -boot n -curses" > run_authserve.sh
chmod u+x run_authserve.sh

# CPUSERVE
echo "qemu-system-x86_64 -smp 4 -m 256 -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -curses" > run_cpuserve.sh
chmod u+x run_cpuserve.sh
