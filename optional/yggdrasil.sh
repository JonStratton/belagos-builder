#!/bin/sh
# This script exposes the grid inside of the vde network to yggdrasil; an overlay mesh network. This will allow people online to connect to your grid with yggdrasil.

proj_root=`dirname $0`'/..'
type=`grep type $proj_root/BelagosService.conf | cut -d' ' -f3`

outbound()
{
   if [ ! -f "/usr/bin/yggdrasil" ]; then
      install
   fi

   if [ ! -f "/etc/iptables/rules.v6_back" ]; then
      sudo cp /etc/iptables/rules.v6 /etc/iptables/rules.v6_back
   fi

   sudo ip6tables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
   sudo ip6tables -A FORWARD -i tun0 -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
   sudo ip6tables -A FORWARD -i tap0 -o tun0 -j ACCEPT
   sudo sh -c '( ip6tables-save > /etc/iptables/rules.v6 )'

   sudo sysctl -w net.ipv6.conf.all.forwarding=1
   sudo sh -c '( echo "net.ipv6.conf.all.forwarding=1
   net.ipv6.ip_forward = 1" > /etc/sysctl.d/belagos-darknet-sysctl.conf )'
}

inbound()
{
   if [ ! -f "/usr/bin/yggdrasil" ]; then
      install
   fi

   if [ ! -f "/etc/iptables/rules.v6_back" ]; then
      sudo cp /etc/iptables/rules.v6 /etc/iptables/rules.v6_back
   fi

   sudo sysctl -w net.ipv6.conf.all.forwarding=1

   # fs: 564, auth: 567, cpu: 17019 and 17029
   if [ $type = 'grid' ]; then
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 564 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee03]:564
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 567 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee04]:567
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 17019 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee05]:17019
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 17020 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee05]:17020
   else
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 564 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee03]:564
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 567 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee03]:567
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 17019 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee03]:17019
      sudo ip6tables -t nat -A PREROUTING -p tcp --dport 17020 -j DNAT --to-destination [fdfc::5054:ff:fe00:ee03]:17020
   fi
   sudo sh -c '( ip6tables-save > /etc/iptables/rules.v6 )'
   sudo sh -c '( echo "net.ipv6.conf.all.forwarding=1" > /etc/sysctl.d/belagos-darknet-sysctl.conf )'
}

uninstall()
{
   sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y yggdrasil radvd
   sudo rm /etc/apt/sources.list.d/yggdrasil.list
   sudo rm /etc/sysctl.d/belagos-darknet-sysctl.conf
}

install()
{
   # Only install it if not installed, in case its already installed and configured
   if [ ! -L /sys/class/net/tun0 ]; then
      # Install Deps
      sudo apt-get update
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y yggdrasil
      sudo systemctl enable yggdrasil
      sudo systemctl start yggdrasil
   fi

   # radvd
   sudo DEBIAN_FRONTEND=noninteractive apt-get install -y radvd
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

manage()
{
   setfacl -m g:belagos:rwx /etc/yggdrasil
   setfacl -m g:belagos:rw /etc/yggdrasil/yggdrasil.conf
}

unmanage()
{
   setfacl -x g:belagos /etc/yggdrasil/yggdrasil.conf
   setfacl -x g:belagos /etc/yggdrasil
}

if [ $1 -a $1 = 'outbound' ]; then
/etc/yggdrasil/yggdrasil.conf   outbound
elif [ $1 -a $1 = 'inbound' ]; then
   inbound
elif [ $1 -a $1 = 'uninstall' ]; then
   uninstall
elif [ $1 -a $1 = 'install' ]; then
   install
elif [ $1 -a $1 = 'manage' ]; then
   manage
elif [ $1 -a $1 = 'unmanage' ]; then
   unmanage
else
   echo "$0 install|uninstall|inbound|outbound"
fi
