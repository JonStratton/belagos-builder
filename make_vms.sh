#!/bin/sh
# This should be done after out tap0 dev is up

# Create keepass db(belagos.kdbx) so we dont have to default passwords.
expect expect/keepass.exp

# Prep the VMs
wget -O iso/9front.amd64.iso.gz http://9front.org/iso/9front-8013.d9e940a768d1.amd64.iso.gz
gunzip iso/9front.amd64.iso.gz

# FSSERVE
# Creating base install image
expect expect/fsserve_install.exp img/9front_fsserve.img 256 iso/9front.amd64.iso 10G
# Back it up as expect is unrelyable with curses
cp img/9front_fsserve.img img/9front_fsserve.img_back
# Set up networking and turn on PXE
expect expect/fsserve_configure.exp img/9front_fsserve.img 256
# Runner scripts for our VDE network after reboot
echo "qemu-system-x86_64 -m 256 -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_fsserve.img -device scsi-hd,drive=vd0 -curses" > bin/run_fsserve.sh
chmod u+x bin/run_fsserve.sh

# AUTHSERVE
# authserve and cpuserve should be PXE bootable at this point
qemu-img create -f qcow2 img/9front_authserve.img 1M
expect expect/authserve_configure.exp img/9front_authserve.img 256
echo "qemu-system-x86_64 -m 256 -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=img/9front_authserve.img -device scsi-hd,drive=vd0 -boot n -curses" > bin/run_authserve.sh
chmod u+x bin/run_authserve.sh

# CPUSERVE
echo "qemu-system-x86_64 -smp 4 -m 256 -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -curses" > bin/run_cpuserve.sh
chmod u+x bin/run_cpuserve.sh
