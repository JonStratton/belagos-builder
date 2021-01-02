#!/bin/sh

package_list="radvd nodejs build-essential python2.7"

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
echo $new_packages > ./new_packages_darknet.txt

# Build cjdns
wget -O cjdns.tar.gz https://github.com/cjdelisle/cjdns/archive/master.tar.gz
tar xzf cjdns.tar.gz
cd cjdns-master
./do
sudo mv cjdroute /usr/bin/
sudo mv contrib/systemd/cjdns.service /etc/systemd/system/
sudo systemctl enable cjdns
sudo systemctl start cjdns

# IP Tables; allow tap0 to talk to the outside via ethernet
sudo cp /etc/iptables/rules.v6 /etc/iptables/rules.v6_back
sudo ip6tables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
sudo ip6tables -A FORWARD -i tun0 -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo ip6tables -A FORWARD -i tap0 -o tun0 -j ACCEPT
sudo sh -c '( ip6tables-save > /etc/iptables/rules.v6 )'

sudo sh -c '( echo "net.ipv6.conf.all.forwarding=1
net.ipv6.ip_forward = 1" > /etc/sysctl.d/belagos-darknet-sysctl.conf )'

# Add "fdfc::1" address as static on tap0
sudo sh -c "( echo \"
iface tap0 inet6 static
   address fdfc::1
   netmask 64\" >> /etc/network/interfaces.d/tap0.iface )"

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

# Final step needed as radvd doesnt seem to work...
echo "Run the following on your plan 9 machine:"
echo "echo 'add :: 0:0:0:0:0:0:0:0 fdfc::1' >/net/iproute"
}

#############
# Uninstall #
#############
uninstall()
{
sudo mv /etc/iptables/rules.v6_back /etc/iptables/rules.v6

# Remove Packages
sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y `cat ./new_packages_darknet.txt`
rm ./new_packages.txt
sudo apt-get autoremove -y
sudo apt-get clean -y

sudo rm /etc/sysctl.d/belagos-darknet-sysctl.conf
sudo rm /etc/radvd.conf

# Final step needed as radvd doesnt seem to work...
echo "Run the following on your plan 9 machine:"
echo "echo 'delete :: 0:0:0:0:0:0:0:0' >/net/iproute"
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
