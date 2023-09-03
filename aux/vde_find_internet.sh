#!/bin/sh
# Takes an interface from a config file. If nothing, just try each of them

internet_interface=

# Exec config file if exists
if [ -f /etc/vde_find_internet.conf ]; then
   . /etc/vde_find_internet.conf
fi

# No internet interface. Try the ones we have.
while [ -z "$internet_interface" ]; do
   echo "No interface configured. Attempting..."
   for interface in `ls -1 /sys/class/net/ | sort -r | grep -v tun0 | grep -v tap0 | grep -v lo`; do
      echo "$interface"
      if [ `ping -c 1 -q 8.8.8.8 -I $interface 2>/dev/null | grep "1 received" | wc -l` -eq 1 ]; then
         internet_interface=$interface
         break
      fi
   done;
done;

# IP Tables; allow tap0 to talk to the outside via ethernet
if [ -n "$internet_interface" ]; then
   echo "Using $internet_interface"
   sudo sysctl -w net.ipv4.ip_forward=1
   sudo iptables -t nat -A POSTROUTING -o $internet_interface -j MASQUERADE
   sudo iptables -A FORWARD -i $internet_interface -o tap0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
   sudo iptables -A FORWARD -i tap0 -o $internet_interface -j ACCEPT
fi
