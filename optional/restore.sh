#!/bin/sh
# This script attempts to clear the funky network rules after using clearnet.sh, tor.sh, or yggdrasil.sh. It does this by restoring and clearing IP tables.

if [ -f "/etc/iptables/rules.v4_back" ]; then
   sudo mv /etc/iptables/rules.v4_back /etc/iptables/rules.v4
fi

if [ -f "/etc/iptables/rules.v6_back" ]; then
   sudo mv /etc/iptables/rules.v6_back /etc/iptables/rules.v6
fi

sudo iptables-restore /etc/iptables/rules.v4
sudo ip6tables-restore /etc/iptables/rules.v6

sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X

sudo ip6tables -P INPUT ACCEPT
sudo ip6tables -P FORWARD ACCEPT
sudo ip6tables -P OUTPUT ACCEPT
sudo ip6tables -t nat -F
sudo ip6tables -t mangle -F
sudo ip6tables -F
sudo ip6tables -X
