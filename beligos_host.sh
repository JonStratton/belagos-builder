#!/bin/sh

package_list="dnsmasq iptables-persistent qemu-system-x86 vde2 uml-utilities kpcli"

###########
# Install #
###########
install()
{
# Install Deps
sudo apt-get update
new_packages=""
for package in $package_list; do
   if [ `sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $package | grep "is already the newest version" | wc -l` -eq 0 ]; then
      new_packages="$new_packages $package"
   fi
done
echo $new_packages > ./new_packages.txt

# Create tap0 interface for our VM Network
sudo usermod -a -G vde2-net $USER
sudo sh -c '( echo "auto tap0
iface tap0 inet static
   address 192.168.9.1
   netmask 255.255.255.0
   vde2-switch -t tap0" > /etc/network/interfaces.d/tap0.iface )'

# Create dnsmasq config for tap0 with some hard coded MACs to IP
sudo sh -c '( echo "interface=tap0
dhcp-option=3,192.168.9.1
dhcp-range=192.168.9.100,192.168.9.200,255.255.255.0,24h
dhcp-host=52:54:00:00:EE:03,192.168.9.3
dhcp-host=52:54:00:00:EE:04,192.168.9.4
local=/localgrid/
expand-hosts
address=/cpuserve.localgrid/192.168.9.3
address=/fsserve.localgrid/192.168.9.4" > /etc/dnsmasq.d/beligos-dnsmasq.conf )'

# IP Tables; allow tap0 to talk to the outside via ethernet
sudo cp /etc/iptables/rules.v4 /etc/iptables/rules.v4_back
sudo cp /etc/iptables/rules.v6 /etc/iptables/rules.v6_back
eth0=`ls -1 /sys/class/net/ | grep '^e' | head -n 1`
sudo iptables -t nat -A POSTROUTING -o $eth0 -j MASQUERADE
sudo iptables -A FORWARD -i $eth0 -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o $eth0 -j ACCEPT
sudo sh -c '( iptables-save > /etc/iptables/rules.v4 )'

sudo sh -c '( echo "net.ipv4.ip_forward = 1
net.ipv6.ip_forward = 1" > /etc/sysctl.d/beligos-sysctl.conf )'

# Create keepass db(beligos.kdbx) so we dont have to default passwords.
expect keepass.exp

# Prep the VMs
wget http://9front.org/iso/9front-8013.d9e940a768d1.amd64.iso.gz
gunzip 9front-8013.d9e940a768d1.amd64.iso.gz

# Creating base install image
expect 9front_install.exp 9front_base.img 512 9front-8013.d9e940a768d1.amd64.iso 10G
cp 9front_base.img 9front_cpuserve.img
cp 9front_base.img 9front_fsserve.img

# Give new name and MAC, and turn on CPU serve for remote connections
expect 9front_branch_and_cpu.exp 9front_cpuserve.img 512 cpuserve 52:54:00:00:EE:03 52540000ee03
expect 9front_branch_and_cpu.exp 9front_fsserve.img 512 cpuserve 52:54:00:00:EE:04 52540000ee04

# Runner scripts for our VDE network after reboot
echo "qemu-system-x86_64 -m 512 -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=9front_cpuserve.img -device scsi-hd,drive=vd0 -curses" > run_cpuserve.sh
chmod u+x run_cpuserve.sh

echo "qemu-system-x86_64 -m 512 -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=9front_fsserve.img -device scsi-hd,drive=vd0 -curses" > run_cpuserve.sh
chmod u+x run_fsserve.sh
}

#############
# Uninstall #
#############
uninstall()
{
sudo mv /etc/iptables/rules.v4_back /etc/iptables/rules.v4
sudo mv /etc/iptables/rules.v6_back /etc/iptables/rules.v6

sudo rm /etc/network/interfaces.d/tap0.iface
sudo rm /etc/dnsmasq.d/beligos-dnsmasq.conf
sudo rm /etc/sysctl.d/beligos-sysctl.conf

# Remove Packages
sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y `cat ./new_packages.txt`
rm ./new_packages.txt
sudo apt-get autoremove -y
sudo apt-get clean -y
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
