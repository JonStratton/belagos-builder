#!/bin/sh
# This script exposes the grid inside of the vde network to tor hidden services. This will allow people online to connect to your grid with tor.

proj_root=`dirname $0`'/..'
type=`grep type $proj_root/BelagosService.conf | cut -d' ' -f3`

outbound()
{
   if [ ! -f "/usr/bin/tor" ]; then
      install
   fi

   if [ ! -f "/etc/iptables/rules.v4_back" ]; then
          sudo cp /etc/iptables/rules.v4 /etc/iptables/rules.v4_back
   fi

   if [ ! -f "/etc/tor/torrc_prebelagos" ]; then
      sudo cp /etc/tor/torrc /etc/tor/torrc_prebelagos
   fi

   # Be careful around appending more than once, we may break tor
   if [ `grep "TransPort 192.168.9.1:9040" /etc/tor/torrc | wc -l` -eq 0 ]; then
      # "Anonymizing Middlebox" from https://gitlab.torproject.org/legacy/trac/-/wikis/doc/TransparentProxy
      sudo sh -c "( echo \"
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
TransPort 192.168.9.1:9040
DNSPort 192.168.9.1:5353\" >> /etc/tor/torrc )"
   fi

   sudo systemctl restart tor

   # Bypass rules(?) for internal network, so we can like hit our Webservice?
   sudo iptables -t nat -I PREROUTING -i tap0 -p tcp -d 192.168.0.0/16 -j RETURN

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

   if [ ! -f "/etc/tor/torrc_prebelagos" ]; then
      sudo cp /etc/tor/torrc /etc/tor/torrc_prebelagos
   fi

   # Be careful around appending more than once, we may break tor
   if [ `grep "HiddenServicePort 564 192.168.9.3:564" /etc/tor/torrc | wc -l` -eq 0 ]; then
      if [ $type = 'grid' ]; then
         sudo sh -c "( echo \"
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 564 192.168.9.3:564
HiddenServicePort 567 192.168.9.4:567
HiddenServicePort 5356 192.168.9.4:5356
HiddenServicePort 17019 192.168.9.5:17019
HiddenServicePort 17020 192.168.9.5:17020\" >> /etc/tor/torrc )"
      else
         sudo sh -c "( echo \"
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 564 192.168.9.3:564
HiddenServicePort 567 192.168.9.3:567
HiddenServicePort 5356 192.168.9.3:5356
HiddenServicePort 17019 192.168.9.3:17019
HiddenServicePort 17020 192.168.9.3:17020\" >> /etc/tor/torrc )"
      fi
   fi

   sudo systemctl restart tor
}

uninstall()
{
   sudo mv /etc/tor/torrc_prebelagos /etc/tor/torrc
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
