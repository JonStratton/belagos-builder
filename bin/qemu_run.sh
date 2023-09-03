#!/bin/sh

kvm=''
qemu_arch=''
mac=''
ram=''
disk=''
cores=1
iso=''
boot=''

. grid/env.sh

case $1 in
   install)
      mac=$install_MAC
      ram=$install_ram
      disk=$install_disk
      cores=$instal_cores
      boot='-kernel 9pc* -initrd plan9.ini -no-reboot'
      ;;
   solo)
      mac=$fsserve_MAC
      ram=$fsserve_ram
      disk=$fsserve_disk
      cores=$fsserve_cores
      ;;
   fs)
      mac=$fsserve_MAC
      ram=$fsserve_ram
      disk=$fsserve_disk
      cores=$fsserve_cores
      ;;
   auth)
      mac=$authserve_MAC
      ram=$authserve_ram
      disk=$authserve_disk
      cores=$authserve_cores
      boot='-boot n'
      ;;
   cpu)
      mac=$cpuserve_MAC
      ram=$cpuserve_ram
      disk=$cpuserve_disk
      cores=$cpuserve_cores
      boot='-boot n'
      ;;
   *)
      echo "$0 install|fs|auth|cpu (iso)"
      exit 1;
      ;;
esac

qemu_iso=''
if [ -n "$2" -a -f $2 ]; then
   qemu_iso="-drive if=none,id=vd1,file=$2 -device scsi-cd,drive=vd1,"
fi

qemu_disk=''
if [ -n "$disk" ]; then
   qemu_disk="-drive if=none,id=vd0,file=$disk -device scsi-hd,drive=vd0"
fi

# Check for KVM at run time. 
qemu_kvm=''
if [ `cat /proc/cpuinfo | grep 'vmx\|svm' | wc -l` -ge 1 ]; then
   qemu_kvm='-cpu host -enable-kvm'
fi

echo "qemu-system-$qemu_arch $qemu_kvm -m $ram -net nic,macaddr=$mac -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi $qemu_disk $qemu_iso $boot -nographic"
qemu-system-$qemu_arch $qemu_kvm -m $ram -net nic,macaddr=$mac -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi $qemu_disk $qemu_iso $boot -nographic
