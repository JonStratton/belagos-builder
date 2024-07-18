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
sudo cp BelagosService.py /opt/belagos/
sudo cp BelagosLib.py /opt/belagos/
sudo mv BelagosService.conf /opt/belagos/
sudo mv 9front_*.img /opt/belagos/

sudo chown -R belagos:belagos /opt/belagos/*
sudo chmod 640 /opt/belagos/*.img
sudo chmod 640 /opt/belagos/*.conf

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
