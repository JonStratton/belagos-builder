#!/bin/sh

package_list="iptables-persistent qemu-system-x86 vde2 uml-utilities expect 9mount p7zip-full"

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

# Add our user to vde2-net, so we can use tap0
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
}

#############
# Uninstall #
#############
uninstall()
{
# Remove Packages
sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y `cat ./install_base_new_packages.txt`
rm ./new_packages.txt
sudo apt-get autoremove -y
sudo apt-get clean -y
sudo rm /etc/network/interfaces.d/tap0.iface
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
