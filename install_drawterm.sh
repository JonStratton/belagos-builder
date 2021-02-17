#!/bin/sh

###########
# Install #
###########
install()
{
sudo apt-get install libx11-dev libxt-dev build-essential
wget https://code.9front.org/hg/drawterm/archive/tip.tar.gz -P /tmp
sudo tar xzf /tmp/tip.tar.gz -C /opt
cd /opt/drawterm-*/
sudo CONF=unix make
sudo ln -s `pwd`/drawterm /usr/local/bin/drawterm
}

#############
# Uninstall #
#############
uninstall()
{
rm /usr/local/bin/drawterm
rm -rf /opt/drawterm-*
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
