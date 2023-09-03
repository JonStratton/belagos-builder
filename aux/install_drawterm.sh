#!/bin/sh

###########
# Install #
###########
install()
{
sudo apt-get install libx11-dev libxt-dev build-essential
wget https://github.com/9front/drawterm/archive/refs/heads/front.zip -P /tmp
sudo unzip /tmp/front.zip -d /opt
rm /tmp/front.zip
cd /opt/drawterm-front/
sudo CONF=unix make
sudo ln -s `pwd`/drawterm /usr/local/bin/drawterm
}

#############
# Uninstall #
#############
uninstall()
{
sudo rm /usr/local/bin/drawterm
sudo rm -rf /opt/drawterm-*
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
