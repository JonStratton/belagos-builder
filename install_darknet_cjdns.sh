#!/bin/sh

package_list="nodejs build-essential python2.7"

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
echo $new_packages > ./install_darknet_cjdns_new_packages.txt

# Dont install if we already have a tun0. Just do everything around it.
if [ ! -f /sys/class/net/tun0 ]; then
   # Build cjdns
   wget -O cjdns.tar.gz https://github.com/cjdelisle/cjdns/archive/master.tar.gz
   tar xzf cjdns.tar.gz
   cd cjdns-master
   ./do
   sudo chown root:root cjdroute contrib/systemd/cjdns.service
   sudo mv cjdroute /usr/bin/
   sudo mv contrib/systemd/cjdns.service /etc/systemd/system/
   cd ..
   sudo rm -rf cjdns-master
   sudo systemctl enable cjdns
   sudo systemctl start cjdns
fi

# IP Tables; allow tap0 to talk to the outside via ethernet
sudo cp /etc/iptables/rules.v6 /etc/iptables/rules.v6_back
sudo ip6tables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
sudo ip6tables -A FORWARD -i tun0 -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo ip6tables -A FORWARD -i tap0 -o tun0 -j ACCEPT
sudo sh -c '( ip6tables-save > /etc/iptables/rules.v6 )'

sudo sh -c '( echo "net.ipv6.conf.all.forwarding=1
net.ipv6.ip_forward = 1" > /etc/sysctl.d/belagos-darknet-sysctl.conf )'
}

#############
# Uninstall #
#############
uninstall()
{
sudo mv /etc/iptables/rules.v6_back /etc/iptables/rules.v6

# Remove Packages
sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y `cat ./install_darknet_cjdns_new_packages.txt`
rm ./new_packages.txt
sudo apt-get autoremove -y
sudo apt-get clean -y

# Remove CJDNS
sudo systemctl stop cjdns
sudo systemctl disable cjdns
sudo rm /usr/bin/cjdroute
sudo rm /etc/systemd/system/cjdns.service

sudo rm /etc/sysctl.d/belagos-darknet-sysctl.conf
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
