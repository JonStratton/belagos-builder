#!/bin/sh
script_loc=`dirname $0`

outbound()
{
   if [ ! -f "/usr/bin/tor" ]; then
      install
   fi

   if [ ! -f "/etc/iptables/rules.v4_back" ]; then
          sudo cp /etc/iptables/rules.v4 /etc/iptables/rules.v4_back
   fi

   # "Anonymizing Middlebox" from https://gitlab.torproject.org/legacy/trac/-/wikis/doc/TransparentProxy
   sudo sh -c "( echo \"
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 192.168.9.1:9040
DNSPort 192.168.9.1:5353\" >> /etc/tor/torrc )"

   sudo systemctl restart tor

   # IP Tables redirect dns to 5353 and everything else to tor
   sudo iptables -t nat -A PREROUTING -i tap0 -p udp --dport 53 -j REDIRECT --to-ports 5353
   sudo iptables -t nat -A PREROUTING -i tap0 -p udp --dport 5353 -j REDIRECT --to-ports 5353
   sudo iptables -t nat -A PREROUTING -i tap0 -p tcp --syn -j REDIRECT --to-ports 9040
   sudo sh -c '( iptables-save > /etc/iptables/rules.v4 )'
}

inbound()
{
   if [ ! -f "/usr/bin/tor" ]; then
      install
   fi

   . $script_loc/../var/env.sh
   sudo sh -c "( echo \"
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 564 $fsserve:564
HiddenServicePort 567 $authserve:567
HiddenServicePort 5356 $authserve:5356
HiddenServicePort 17019 $cpuserve:17019
HiddenServicePort 17020 $cpuserve:17020\" >> /etc/tor/torrc )"

   sudo systemctl restart tor
}

uninstall()
{
   sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y tor
}

install()
{
   sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tor
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
