#!/bin/sh

package_list="dnsmasq iptables-persistent qemu-system-x86 vde2 radvd uml-utilities expect 9mount"

# Add KVM if possible
if [ `cat /proc/cpuinfo | grep 'vmx\|svm' | wc -l` -ge 1 ]; then
   package_list="$package_list qemu-kvm"
fi

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
echo $new_packages > ./install_base_new_packages.txt

# Create local glenda user and add her to the vde2-net group. This may eventually be our systemd running user on boot.
sudo usermod -a -G vde2-net $USER

# Create tap0 interface for our VM Network
sudo sh -c '( echo "auto tap0
iface tap0 inet static
   address 192.168.9.1
   netmask 255.255.255.0
   vde2-switch -t tap0
iface tap0 inet6 static
   address fdfc::1
   netmask 64" > /etc/network/interfaces.d/tap0.iface )'

# Create non perssistent tap0 using /var/run/vde2/ so we dont have to reboot to continue
sudo mkdir -p /var/run/vde2
sudo chown vde2-net:vde2-net /var/run/vde2/
sudo chmod 2770 /var/run/vde2/
sudo vde_switch -tap tap0 -s /var/run/vde2/tap0.ctl -m 660 -g vde2-net -M /var/run/vde2/tap0.mgmt --mgmtmode 660 -d
sudo ip link set dev tap0 down
sudo ip addr add 192.168.9.1/24 dev tap0
sudo ip addr add fdfc::1/64 dev tap0
sudo ip link set dev tap0 up

# Create dnsmasq config for tap0 with some hard coded MACs to IP
sudo sh -c '( echo "interface=tap0
domain=localgrid
local=/localgrid/
expand-hosts
dhcp-option=3,192.168.9.1
dhcp-range=192.168.9.100,192.168.9.200,255.255.255.0,24h
dhcp-boot=386/9bootpxe,fsserve,192.168.9.3
dhcp-host=52:54:00:00:EE:03,fsserve,192.168.9.3
dhcp-host=52:54:00:00:EE:04,authserve,192.168.9.4
dhcp-host=52:54:00:00:EE:05,cpuserve,192.168.9.5
address=/host.localgrid/192.168.9.1
address=/fsserve.localgrid/192.168.9.3
address=/authserve.localgrid/192.168.9.4
address=/cpuserve.localgrid/192.168.9.5" > /etc/dnsmasq.d/belagos-dnsmasq.conf )'
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

# Prompt for iface if we have a couple. Like on a laptop with eth and wlan
ipv4iface=''
if [ `ls -1 /sys/class/net/ | grep -v tun0 | grep -v tap0 | grep -v lo | wc -l` -eq 1 ]; then
   ipv4iface=`ls -1 /sys/class/net/ | grep -v tun0 | grep -v tap0 | grep -v lo`
else
   ifaces=`ls -1 /sys/class/net/ | grep -v tun0 | grep -v tap0 | grep -v lo`
   read -p "Enter IPv4 interface that has an internet connection($ifaces): " ipv4iface
fi

# IP Tables; allow tap0 to talk to the outside via ethernet
sudo cp /etc/iptables/rules.v4 /etc/iptables/rules.v4_back
sudo iptables -t nat -A POSTROUTING -o $ipv4iface -j MASQUERADE
sudo iptables -A FORWARD -i $ipv4iface -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o $ipv4iface -j ACCEPT
sudo sh -c '( iptables-save > /etc/iptables/rules.v4 )'

sudo sh -c '( echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/belagos-sysctl.conf )'

# radvd, but it doesnt seem like it works in plan 9. But it does on OpenBSD.
sudo sh -c "( echo \"
interface tap0
{
   AdvSendAdvert on;
   prefix fdfc::1/64 {
      AdvRouterAddr on;
   };
};\" > /etc/radvd.conf )"
sudo systemctl enable radvd
sudo systemctl restart radvd
}

#############
# Uninstall #
#############
uninstall()
{
sudo mv /etc/iptables/rules.v4_back /etc/iptables/rules.v4

sudo rm /etc/network/interfaces.d/tap0.iface
sudo rm /etc/dnsmasq.d/belagos-dnsmasq.conf
sudo rm /etc/sysctl.d/belagos-sysctl.conf
sudo rm /etc/radvd.conf

# Remove Packages
sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y `cat ./install_base_new_packages.txt`
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
