#!/bin/sh

if [ -f "/etc/iptables/rules.v4_back" ]; then
   sudo mv /etc/iptables/rules.v4_back /etc/iptables/rules.v4
fi

if [ -f "/etc/iptables/rules.v6_back" ]; then
   sudo mv /etc/iptables/rules.v6_back /etc/iptables/rules.v6
fi

sudo iptables-restore /etc/iptables/rules.v4
sudo ip6tables-restore /etc/iptables/rules.v6
