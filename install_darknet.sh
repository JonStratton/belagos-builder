#!/bin/sh

###########
# Install #
###########
install()
{
if [ ! -L /sys/class/net/tun0 ]; then
   # Add get and repo for yggdrasil
   gpg --fetch-keys https://neilalexander.s3.dualstack.eu-west-2.amazonaws.com/deb/key.txt
   gpg --export 569130E8CA20FBC4CB3FDE555898470A764B32C9 | sudo apt-key add -
   gpg --batch --delete-keys 569130E8CA20FBC4CB3FDE555898470A764B32C9
   sudo sh -c '( echo "deb http://neilalexander.s3.dualstack.eu-west-2.amazonaws.com/deb/ debian yggdrasil" > /etc/apt/sources.list.d/yggdrasil.list )'

   # Install Deps
   sudo apt-get update
   sudo DEBIAN_FRONTEND=noninteractive apt-get install -y yggdrasil
   sudo systemctl enable yggdrasil
   sudo systemctl start yggdrasil
fi

# IP Tables; allow tap0 to talk to the outside via ethernet
sudo cp /etc/iptables/rules.v6 /etc/iptables/rules.v6_back
sudo ip6tables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
sudo ip6tables -A FORWARD -i tun0 -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo ip6tables -A FORWARD -i tap0 -o tun0 -j ACCEPT
sudo sh -c '( ip6tables-save > /etc/iptables/rules.v6 )'

sudo sh -c '( echo "net.ipv6.conf.all.forwarding=1
net.ipv6.ip_forward = 1" > /etc/sysctl.d/belagos-darknet-sysctl.conf )'

################
# Danger Zone! #
################
	# Warning: must be at least this cool to progress -> 9

## fsserve - expose fs
#ip6tables -t nat -A PREROUTING -p tcp --dport 564 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee03]:564

## cpuserve - expose auth?
#ip6tables -t nat -A PREROUTING -p tcp --dport 17019 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee05]:17019
#ip6tables -t nat -A PREROUTING -p tcp --dport 17020 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee05]:17020
}

#############
# Uninstall #
#############
uninstall()
{
sudo mv /etc/iptables/rules.v6_back /etc/iptables/rules.v6

# Remove Packages
sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y yggdrasil
rm ./new_packages.txt
sudo apt-get autoremove -y
sudo apt-get clean -y

sudo rm /etc/apt/sources.list.d/yggdrasil.list
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
