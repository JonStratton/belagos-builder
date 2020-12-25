#!/bin/sh

package_list="dnsmasq iptables-persistent qemu-system-x86 vde2 uml-utilities kpcli expect build-essential libx11-dev libxt-dev"

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
domain=localgrid
local=/localgrid/
expand-hosts
dhcp-option=3,192.168.9.1
dhcp-range=192.168.9.100,192.168.9.200,255.255.255.0,24h
dhcp-host=52:54:00:00:EE:03,fsserve,192.168.9.3
dhcp-host=52:54:00:00:EE:04,authserve,192.168.9.4
dhcp-host=52:54:00:00:EE:05,cpuserve,192.168.9.5
address=/host.localgrid/192.168.9.1
address=/fsserve.localgrid/192.168.9.3
address=/authserve.localgrid/192.168.9.4
address=/cpuserve.localgrid/192.168.9.5" > /etc/dnsmasq.d/belagos-dnsmasq.conf )'

# IP Tables; allow tap0 to talk to the outside via ethernet
sudo cp /etc/iptables/rules.v4 /etc/iptables/rules.v4_back
sudo cp /etc/iptables/rules.v6 /etc/iptables/rules.v6_back
eth0=`ls -1 /sys/class/net/ | grep '^e' | head -n 1`
sudo iptables -t nat -A POSTROUTING -o $eth0 -j MASQUERADE
sudo iptables -A FORWARD -i $eth0 -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o $eth0 -j ACCEPT
sudo sh -c '( iptables-save > /etc/iptables/rules.v4 )'

sudo sh -c '( echo "net.ipv4.ip_forward = 1
net.ipv6.ip_forward = 1" > /etc/sysctl.d/belagos-sysctl.conf )'

# You have to use 9front's Drawterm to connect to 9front it seems
s
cd /opt/
sudo wget https://code.9front.org/hg/drawterm/archive/tip.tar.gz
sudo tar xzf tip.tar.gz
sudo rm tip.tar.gz
sudo mv drawterm-* drawterm
cd drawterm
sudo CONF=unix make
}

#############
# Uninstall #
#############
uninstall()
{
sudo rm -rf /opt/drawterm

sudo mv /etc/iptables/rules.v4_back /etc/iptables/rules.v4
sudo mv /etc/iptables/rules.v6_back /etc/iptables/rules.v6

sudo rm /etc/network/interfaces.d/tap0.iface
sudo rm /etc/dnsmasq.d/belagos-dnsmasq.conf
sudo rm /etc/sysctl.d/belagos-sysctl.conf

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
