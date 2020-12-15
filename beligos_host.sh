#!/bin/sh

package_list="dnsmasq iptables-persistent diod qemu-system-x86"

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
sudo groupadd beligos
sudo usermod -a -G beligos $USER
sudo sh -c '( echo "auto tap0
iface tap0 inet static
   address 192.168.9.1
   netmask 255.255.255.0
   pre-up ip tuntap add dev tap0 mode tap group beligos
   pre-up ip link set tap0 up
   post-down ip link set tap0 down
   post-down ip tuntap del dev tap0 mode tap
iface tap0 inet6 manual" > /etc/network/interfaces.d/tap0.iface )'

# Create dnsmasq config for tap0 with some hard coded MACs to IP
sudo sh -c '( echo "interface=tap0
dhcp-option=3,192.168.9.1
dhcp-range=192.168.9.100,192.168.9.200,255.255.255.0,24h
dhcp-host=52:54:00:00:EE:03,192.168.9.3" > /etc/dnsmasq.d/beligos-dnsmasq.conf )'

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

# Diod, for file sharing between VMs. Only listen on tap0, or we might have a problem.
sudo sh -c '( cat /etc/default/diod | sed "s/DIOD_ENABLE=false/DIOD_ENABLE=true/g" > /etc/default/diod2 )'
sudo mv /etc/default/diod2 /etc/default/diod
sudo sh -c '( echo "listen = { \"192.168.9.1:564\" }
exports = {
   { path=\"/tmp/TODO/\", opts=\"ro,noauth\" }
}" > /etc/diod.conf )'

# Prep the VMs
mkdir qemu; cd qemu
wget http://9front.org/iso/9front-8013.d9e940a768d1.amd64.iso.gz
gunzip 9front-8013.d9e940a768d1.amd64.iso.gz

# Creating with "-net user" so we can do it before reboot. Just make sure to keep the MAC addresses the same
echo "qemu-img create -f qcow2 9front_test1.qcow2.img 10G
qemu-system-x86_64 -m 512 -net nic,model=virtio,macaddr=52:54:00:00:EE:03 -net user -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=9front_test1.qcow2.img -device scsi-hd,drive=vd0 -drive if=none,id=vd1,file=9front-8013.d9e940a768d1.amd64.iso -device scsi-cd,drive=vd1,bootindex=0 -curses" > install_9front_test1.sh
chmod u+x install_9front_test1.sh
echo "qemu-system-x86_64 -m 512 -netdev tap,id=eth,ifname=tap0,script=no,downscript=no -device e1000,netdev=eth,mac=52:54:00:00:EE:03 -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=9front_test1.qcow2.img -device scsi-hd,drive=vd0 -vga std" > run_test1.sh
chmod u+x run_test1.sh
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
