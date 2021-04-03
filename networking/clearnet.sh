#!/bin/sh

outbound()
{
   if [ ! -f "/etc/dnsmasq.d/belagos-dnsmasq.conf" ]; then
      install
   fi

   sudo cp networking/vde_find_internet.sh /usr/local/sbin/

   # Keep checking interfaces until one has an internet connection. Than plug it into vde
   sudo sh -c '( echo "[Unit]
Description=Belagos Find Internet Service
After=network.target mesh_micro.service
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/vde_find_internet.sh
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos_find_internet.service )'

   sudo systemctl enable belagos_find_internet.service
   sudo systemctl start belagos_find_internet.service
}

inbound()
{
   if [ ! -f "/etc/dnsmasq.d/belagos-dnsmasq.conf" ]; then
      install
   fi

   # iptables commands for direct connections?
   sudo sysctl -w net.ipv4.ip_forward=1
   sudo iptables -t nat -I PREROUTING -p tcp --dport 564 -j DNAT --to-destination 192.168.9.3:564
   sudo iptables -t nat -I PREROUTING -p tcp --dport 567 -j DNAT --to-destination 192.168.9.4:567
   sudo iptables -t nat -I PREROUTING -p tcp --dport 17019 -j DNAT --to-destination 192.168.9.5:17019
   sudo iptables -t nat -I PREROUTING -p tcp --dport 17020 -j DNAT --to-destination 192.168.9.5:17020
   sudo sh -c '( iptables-save > /etc/iptables/rules.v4 )'
}

uninstall()
{
   sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y dnsmasq
   sudo rm /usr/local/sbin/vde_find_internet.sh
   sudo rm /etc/systemd/system/belagos_find_internet.service
   sudo systemctl stop belagos_find_internet.service
   sudo systemctl disable belagos_find_internet.service
}

install()
{
   sudo DEBIAN_FRONTEND=noninteractive apt-get install -y dnsmasq

   # Create dnsmasq config for tap0
   sudo sh -c '( echo "interface=tap0
   expand-hosts" > /etc/dnsmasq.d/belagos-dnsmasq.conf )'
   sudo systemctl enable dnsmasq
   sudo systemctl restart dnsmasq
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
