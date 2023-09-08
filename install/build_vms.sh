#!/bin/sh
# This script attempts to build a 9front grid or solo server. It gets some VM sizing information from the user, creates some disk images, and will run some Expect scripts first against the 9front installer, and then against the VMs. Some funking things this script does:
# It will pull some files out of the plan9 ISO so it can patch the init process used by the 9front ISO for console mode. This is done because using qemu in text mode creates issues with terminal control characters breaking the Expect scripts.
# It packages up some RC scripts in an ISO for copying to the 9front system after the install. 
# In cases where a grid is built, it will run VMs in the background as, for example, the auth server needs the fsserver to be running as it net boots off of it.

proj_root=`dirname $0`'/..'
cd $proj_root

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
mainserve_core_default=`expr \( \( $core_free_mb \* 25 \) / 100 \) + 64`
cpuserve_core_default=`expr \( \( $core_free_mb \* 75 \) / 100 \) + 64`
authserve_core_default=64

# Overwrite defaults if above 2gb for 32 bit VMs.
[ $arch = 'i686' ] && [ $mainserve_core_default -gt 2000 ] && mainserve_core_default=2000
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

   read -p "RAM in MB for fsserve(default $mainserve_core_default): " main_core
   [ -z $main_core ] && main_core=$mainserve_core_default
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
mainserve_ip='192.168.9.3'
mainserve_ip6='fdfc::5054:ff:fe00:ee03'
authserve_ip='192.168.9.4'
authserve_ip6='fdfc::5054:ff:fe00:ee04'
cpuserve_ip='192.168.9.5'
cpuserve_ip6='fdfc::5054:ff:fe00:ee05'"> grid/env.sh
else
   echo "type='solo'
mainserve_ip='192.168.9.3'
mainserve_ip6='fdfc::5054:ff:fe00:ee03'
authserve_ip='192.168.9.3'
authserve_ip6='fdfc::5054:ff:fe00:ee03'
cpuserve_ip='192.168.9.3'
cpuserve_ip6='fdfc::5054:ff:fe00:ee03'"> grid/env.sh
fi

echo "qemu_arch='$qemu_arch'
secure_boot=$secure_boot
install_disk='grid/9front_install.img'
mainserve_MAC='52:54:00:00:EE:03'
mainserve_ram='$main_core'
mainserve_disk='grid/9front_main.img'
mainserve_cores='1'
authserve_MAC='52:54:00:00:EE:04'
authserve_ram='$authserve_core'
authserve_cores='1'
cpuserve_MAC='52:54:00:00:EE:05'
cpuserve_ram='$cpuserve_core'
cpuserve_cores='4'
" >> grid/env.sh

if [ $secure_boot ]; then
   echo "authserve_disk=''" >> grid/env.sh
   echo "cpuserve_disk=''" >> grid/env.sh
else
   echo "authserve_disk='grid/9front_authserve.img'" >> grid/env.sh
   echo "cpuserve_disk='grid/9front_cpuserve.img'" >> grid/env.sh
fi

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
   install/9front_installer.exp $local_iso

   rm ./plan9.ini
   rm ./9pc*
fi

###########
# Install #
###########
   # For solo servers with services exposed, or a file server in a grid

rm grid/*_in
rm grid/*_out

# Package scripts in an ISO
mkisofs -o grid/plan9Scripts.iso ./plan9

mkfifo -m 622 grid/main_in
mkfifo -m 644 grid/main_out

if [ ! -f grid/9front_main.img ]; then
   cp grid/9front_install.img grid/9front_main.img

   # Expose the services
   install/9front_services.exp $type
fi

###################
# PXE Booted Grid #
###################

if [ $type = 'grid' ]; then
   bin/boot_wait.sh main

   # AUTHSERVE
   mkfifo -m 622 grid/auth_in
   mkfifo -m 644 grid/auth_out

   if [ ! $secure_boot ]; then
      qemu-img create -f qcow2 grid/9front_authserve.img 1M
      install/9front_grid_pxe_client_nvram.exp auth
   fi
   install/9front_authserver_changeuser.exp

   # Need the auth serve to create the CPU Server
   bin/boot_wait.sh auth

   # CPUSERVE
   mkfifo -m 622 grid/cpu_in
   mkfifo -m 644 grid/cpu_out
   if [ ! $secure_boot ]; then
      qemu-img create -f qcow2 grid/9front_cpuserve.img 1M
      install/9front_grid_pxe_client_nvram.exp cpu
   fi
fi

########################
# Turn down everything #
########################

if [ $type = 'grid' ]; then
   bin/belagos_client.sh auth halt
   sleep 1
   bin/belagos_client.sh main halt
fi
