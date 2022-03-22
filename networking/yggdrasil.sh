#!/bin/sh
script_loc=`dirname $0`

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

   # fs: 564, auth: 567, cpu: 17019 and 17029
   . $script_loc/../var/env.sh
   sudo ip6tables -t nat -A PREROUTING -p tcp --dport 564 -j DNAT --to-destination [$fsserve6]:564
   sudo ip6tables -t nat -A PREROUTING -p tcp --dport 567 -j DNAT --to-destination [$authserve6]:567
   sudo ip6tables -t nat -A PREROUTING -p tcp --dport 17019 -j DNAT --to-destination [$cpuserve6]:17019
   sudo ip6tables -t nat -A PREROUTING -p tcp --dport 17020 -j DNAT --to-destination [$cpuserve6]:17020
   sudo sh -c '( ip6tables-save > /etc/iptables/rules.v6 )'
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

if [ $1 -a $1 = 'outbound' ]; then
   outbound
elif [ $1 -a $1 = 'inbound' ]; then
   inbound
elif [ $1 -a $1 = 'uninstall' ]; then
   uninstall
elif [ $1 -a $1 = 'install' ]; then
   install
else
   echo "$0 install|uninstall|inbound|outbound"
fi
