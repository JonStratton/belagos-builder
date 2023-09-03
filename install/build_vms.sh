#!/bin/sh

# Arch for ISO and qemu
iso_arch='386'
qemu_arch='i386'
arch=`uname -m`
if [ $arch = 'x86_64' ]; then
   iso_arch='amd64'
   qemu_arch=$arch
fi
local_iso="9front.$iso_arch.iso"

# grid, solo/cpu, auth, fs
type='grid'
if [ $1 ]; then
   type=$1
fi

[ ! -d grid ] && mkdir grid

# Toggle on will prompt for passwords on boot
secure_boot=$2

#######################
# Disk and RAM Sizing #
#######################

# 512 for base debian gui, 64 for each plan9vm. Split the rest between the fsserve and the cpuserve(most)
total_core=`cat /proc/meminfo | grep "^MemTotal:" | awk '{print $2}'`
core_free_mb=`expr \( $total_core / 1024 \) - 512 - \( 64 \* 3 \)`
fsserve_core_default=`expr \( \( $core_free_mb \* 25 \) / 100 \) + 64`
cpuserve_core_default=`expr \( \( $core_free_mb \* 75 \) / 100 \) + 64`
authserve_core_default=64

# Overwrite defaults if above 2gb for 32 bit VMs.
[ $arch = 'i686' ] && [ $fsserve_core_default -gt 2000 ] && fsserve_core_default=2000
[ $arch = 'i686' ] && [ $cpuserve_core_default -gt 2000 ] && cpuserve_core_default=2000

# 75% of the free disk for fsserve
free_disk=`df -k 2>/dev/null | grep '/home/$' | awk '{print $4}'`
if [ ! $free_disk ]; then
   free_disk=`df -k 2>/dev/null | grep ' /$' | awk '{print $4}'`
fi
free_mb=`expr $free_disk / 1024`
main_disk_gb_default=`expr \( \( $free_mb \* 75 \) / 100 \) / 1024`G
# Warn on RAM and Disk.
[ $free_mb -lt 10240 ] && echo "Warning, you seem to have less than 10G free. Installer may not work(???)."

# Prompt for values
if [ $type = 'grid' ]; then
   [ $core_free_mb -lt 704 ] && echo "Warning, you seem to have less RAM than can run your base OS plus 3 VMs"

   read -p "RAM in MB for fsserve(default $fsserve_core_default): " main_core
   [ -z $main_core ] && main_core=$fsserve_core_default
   read -p "RAM in MB for cpuserve(default $cpuserve_core_default): " cpuserve_core
   [ -z $cpuserve_core ] && cpuserve_core=$cpuserve_core_default
   read -p "RAM in MB for authserve(default $authserve_core_default): " authserve_core
   [ -z $authserve_core ] && authserve_core=$authserve_core_default
else
   read -p "RAM in MB for install(default $cpuserve_core_default): " main_core
   [ -z $main_core ] && main_core=$cpuserve_core_default
fi
read -p "Disk for install(default $main_disk_gb_default): " main_disk_gb
[ -z $main_disk_gb ] && main_disk_gb=$main_disk_gb_default


############
# Password #
############
   # Use Glenda's password for the install

# Disk encryption
if [ $secure_boot ]; then
   if [ ! $DISK_PASS ]; then
      default=""
      read -p "Enter optional disk encryption password. If entered, this password will be required to boot: " DISK_PASS
      [ -z $DISK_PASS ] && DISK_PASS=$default
      export DISK_PASS
   fi
fi

if [ ! $GLENDA_PASS ]; then
   default=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
   read -p "Enter password for glenda(default $default): " GLENDA_PASS
   [ -z $GLENDA_PASS ] && GLENDA_PASS=$default
   export GLENDA_PASS
fi

################
# Download ISO #
################

if [ ! -f $local_iso ]; then
   remote_iso=`wget -O - http://9front.org/iso/ 2>/dev/null | grep ".$iso_arch.iso.gz<" | cut -d'"' -f4`
   wget -O $local_iso.gz http://9front.org/iso/$remote_iso
   gunzip $local_iso.gz
fi

###############
# Make env.sh #
###############
	# For use with qemu_run.sh

if [ $type = 'grid' ]; then
   echo "type='grid'
install_ip='192.168.9.3'
install_ip6='fdfc::5054:ff:fe00:ee0'
fsserve_ip='192.168.9.3'
fsserve_ip6='fdfc::5054:ff:fe00:ee03'
authserve_ip='192.168.9.4'
authserve_ip6='fdfc::5054:ff:fe00:ee04'
cpuserve_ip='192.168.9.5'
cpuserve_ip6='fdfc::5054:ff:fe00:ee05'"> grid/env.sh
else
   echo "type='solo'
install_ip='192.168.9.3'
install_ip6='fdfc::5054:ff:fe00:ee0'
fsserve_ip='192.168.9.3'
fsserve_ip6='fdfc::5054:ff:fe00:ee03'
authserve_ip='192.168.9.3'
authserve_ip6='fdfc::5054:ff:fe00:ee03'
cpuserve_ip='192.168.9.3'
cpuserve_ip6='fdfc::5054:ff:fe00:ee03'"> grid/env.sh
fi

echo "qemu_arch='$qemu_arch'
secure_boot=$secure_boot
install_MAC='52:54:00:00:EE:03'
install_ram='$main_core'
install_disk='grid/9front_install.img'
install_cores='1'
fsserve_MAC='52:54:00:00:EE:03'
fsserve_ram='$main_core'
fsserve_disk='grid/9front_main.img'
fsserve_cores='1'
authserve_MAC='52:54:00:00:EE:04'
authserve_ram='$authserve_core'
authserve_disk='grid/9front_authserve.img'
authserve_cores='1'
cpuserve_MAC='52:54:00:00:EE:05'
cpuserve_ram='$cpuserve_core'
cpuserve_disk='grid/9front_cpuserve.img'
cpuserve_cores='4'
" >> grid/env.sh

chmod 755 grid/env.sh

################
# Base Install #
################
   # This will be converted to our fsserve

# Run base installer directly
if [ ! -f grid/9front_install.img ]; then
   # Pull the kern and init out, so we can boot in console mode
   7z e $local_iso cfg/plan9.ini -aoa
   7z e $local_iso $iso_arch/9pc* -aoa

   chmod 644 ./plan9.ini
   echo "console=0\n*acpi=1" >> ./plan9.ini

   qemu-img create -f qcow2 grid/9front_install.img $main_disk_gb
   echo "install/9front_base.exp ./qemu_run.sh install $local_iso"
   #install/9front_base.exp ./qemu_run.sh install $local_iso

   #rm ./plan9.ini
   #rm ./9pc*
fi
exit 0;

########
# Main #
########
   # For solo servers with services exposed, or a file server in a grid

rm grid/*_run_in
rm grid/*_run_out

# Package scripts in an ISO
mkisofs -o grid/plan9Scripts.iso ./plan9

mkfifo -m 622 grid/main_run_in
mkfifo -m 644 grid/main_run_out

if [ ! -f grid/9front_main.img ]; then
   cp grid/9front_install.img grid/9front_main.img

   # Expose the services
   install/9front_services.exp "./qemu_run.sh fs" $type
fi

###################
# PXE Booted Grid #
###################

if [ $type = 'grid' ]; then
   bin/boot_wait.sh bin/main_run.sh

   # AUTHSERVE
   mkfifo -m 622 grid/authserve_run_in
   mkfifo -m 644 grid/authserve_run_out
   mk_run_sh "bin/authserve_run.sh"
   if [ ! $secure_boot ]; then
      echo "qemu-system-$qemu_arch \$kvm -m $authserve_core -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=grid/9front_authserve.img -device scsi-hd,drive=vd0 -boot n -nographic \$*" >> bin/authserve_run.sh
   else
      echo "qemu-system-$qemu_arch \$kvm -m $authserve_core -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -boot n -nographic \$*" >> bin/authserve_run.sh
   fi

   if [ ! $secure_boot ]; then
      qemu-img create -f qcow2 grid/9front_authserve.img 1M
      install/9front_grid_pxe_client_nvram.exp bin/authserve_run.sh
   fi
   install/9front_authserver_changeuser.exp bin/authserve_run.sh

   bin/boot_wait.sh bin/authserve_run.sh

   # CPUSERVE
   mkfifo -m 622 grid/cpuserve_run_in
   mkfifo -m 644 grid/cpuserve_run_out
   mk_run_sh "bin/cpuserve_run.sh"
   if [ ! $secure_boot ]; then
      echo "qemu-system-$qemu_arch \$kvm -smp 4 -m $cpuserve_core -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=grid/9front_cpuserve.img -device scsi-hd,drive=vd0 -boot n -nographic \$*" >> bin/cpuserve_run.sh
      qemu-img create -f qcow2 grid/9front_cpuserve.img 1M
      install/9front_grid_pxe_client_nvram.exp bin/cpuserve_run.sh
   else
      echo "qemu-system-$qemu_arch \$kvm -smp 4 -m $cpuserve_core -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -boot n -nographic \$*" >> bin/cpuserve_run.sh
   fi
fi

########################
# Turn down everything #
########################

if [ $type = 'grid' ]; then
   bin/belagos_client.sh authserve_run halt
   sleep 1
   bin/belagos_client.sh main_run halt
fi
