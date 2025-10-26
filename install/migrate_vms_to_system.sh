#!/bin/sh
# This script takes a previous created grid or solo server (from build_vms.sh) and installs it generically on the system. It does this by coping the needed files to “/opt/”, created a “belagos” service user, and created a SystemD service to start on boot.

###########
# Install #
###########
install()
{
proj_root=`dirname $0`'/..'
cd $proj_root

# Create local belagos, the user that will run the vms
sudo useradd belagos -m -s /bin/false --groups vde2-net
sudo usermod -a -G kvm belagos

# Copy / Move stuff over.
sudo mkdir /opt/belagos/
sudo mkdir /opt/belagos/optional/
sudo mkdir /opt/belagos/templates/
sudo mkdir /opt/belagos/plugins/
sudo cp bela_black.jpg /opt/belagos/
sudo cp BelagosService.py /opt/belagos/
sudo cp BelagosLib.py /opt/belagos/
sudo cp optional/* /opt/belagos/optional/
sudo cp templates/* /opt/belagos/templates/
sudo cp plugins/* /opt/belagos/plugins/
sudo mv BelagosService.conf /opt/belagos/
sudo mv 9front_*.img /opt/belagos/

# Service root permissions
sudo chown -R root:belagos /opt/belagos/
sudo chmod 660 /opt/belagos/9front_*.img
sudo chmod 640 /opt/belagos/BelagosService.conf
sudo chmod 755 /opt/belagos/Belagos*.py
sudo chmod 755 /opt/belagos/optional/*

# sudo access
sudo sh -c '( echo "# Created by belagos
# Moved to /etc/sudoers.d/
Cmnd_Alias BELAGOS = /opt/belagos/optional/clearnet.sh *, /opt/belagos/optional/restore.sh *, /opt/belagos/optional/tor.sh *, /opt/belagos/optional/yggdrasil.sh *
%belagos ALL=NOPASSWD: BELAGOS" > /etc/sudoers.d/belagos-sudoers )'
sudo chmod 440 /etc/sudoers.d/belagos-sudoers

# Service
sudo sh -c '( echo "[Unit]
Description=Belagos Service
After=network.target
[Service]
TimeoutStartSec=600
User=belagos
WorkingDirectory=/opt/belagos
ExecStart=/opt/belagos/BelagosService.py
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos.service )'

sudo systemctl daemon-reload
sudo systemctl enable belagos.service
sudo systemctl start belagos.service &
}

#############
# Uninstall #
#############
uninstall()
{
# Stop Service and uninstall
sudo systemctl stop belagos.service
sudo systemctl disable belagos.service
sudo rm /etc/systemd/system/belagos.service
sudo rm -rf /opt/belagos
sudo rm /etc/sudoers.d/belagos-sudoers
sudo userdel -r belagos
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
