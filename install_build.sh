#!/bin/sh
###########
# Install #
###########
install()
{
script_loc=`dirname $0`
. $script_loc/var/env.sh

# Create local belagos, the user that will run the vms
sudo useradd belagos -m -s /bin/false --groups vde2-net

# Add to belagos to KVM if needed.
if [ `cat /proc/cpuinfo | grep 'vmx\|svm' | wc -l` -ge 1 ]; then
   sudo usermod -a -G kvm belagos
fi

# Copy / Move stuff over.
sudo mkdir /opt/belagos/
sudo mkdir /opt/belagos/bin/
sudo cp bin/* /opt/belagos/bin/
sudo mkdir /opt/belagos/var/
sudo cp var/env.sh /opt/belagos/var/
sudo mkfifo -m 622 /opt/belagos/var/main_run_in
sudo mkfifo -m 644 /opt/belagos/var/main_run_out

if [ $type = 'grid' ]; then
   sudo mkfifo -m 622 /opt/belagos/var/authserve_run_in
   sudo mkfifo -m 644 /opt/belagos/var/authserve_run_out
   sudo mkfifo -m 622 /opt/belagos/var/cpuserve_run_in
   sudo mkfifo -m 644 /opt/belagos/var/cpuserve_run_out
fi

sudo mv var/9front_main.img /opt/belagos/var/

if [ -f var/9front_authserve.img ]; then
   sudo mv var/9front_authserve.img /opt/belagos/var/
fi

if [ -f var/9front_cpuserve.img ]; then
   sudo mv var/9front_cpuserve.img /opt/belagos/var/
fi

sudo chown -R belagos:belagos /opt/belagos/var/*

if [ $type = 'grid' ]; then
   sudo sh -c '( echo "[Unit]
Description=Belagos Service
After=network.target
[Service]
Type=forking
TimeoutStartSec=600
User=belagos
WorkingDirectory=/opt/belagos
ExecStart=/opt/belagos/bin/boot_wait.sh bin/main_run.sh bin/authserve_run.sh bin/cpuserve_run.sh
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos.service )'
else
   sudo sh -c '( echo "[Unit]
Description=Belagos Service
After=network.target
[Service]
Type=forking
TimeoutStartSec=600
User=belagos
WorkingDirectory=/opt/belagos
ExecStart=/opt/belagos/bin/boot_wait.sh bin/main_run.sh
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos.service )'
fi

sudo systemctl daemon-reload
sudo systemctl enable belagos.service
sudo systemctl start belagos.service
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
