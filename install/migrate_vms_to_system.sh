#!/bin/sh
###########
# Install #
###########
install()
{
script_loc=`dirname $0`
. $script_loc/../grid/env.sh

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
sudo mkdir /opt/belagos/grid/
sudo cp grid/env.sh /opt/belagos/grid/
sudo mkfifo -m 622 /opt/belagos/grid/main_in
sudo mkfifo -m 644 /opt/belagos/grid/main_out

if [ $type = 'grid' ]; then
   sudo mkfifo -m 622 /opt/belagos/grid/auth_in
   sudo mkfifo -m 644 /opt/belagos/grid/auth_out
   sudo mkfifo -m 622 /opt/belagos/grid/cpu_in
   sudo mkfifo -m 644 /opt/belagos/grid/cpu_out
fi

sudo mv grid/9front_main.img /opt/belagos/grid/

if [ -f grid/9front_authserve.img ]; then
   sudo mv grid/9front_authserve.img /opt/belagos/grid/
fi

if [ -f grid/9front_cpuserve.img ]; then
   sudo mv grid/9front_cpuserve.img /opt/belagos/grid/
fi

sudo chown -R belagos:belagos /opt/belagos/grid/*

if [ $type = 'grid' ]; then
   sudo sh -c '( echo "[Unit]
Description=Belagos Service
After=network.target
[Service]
Type=forking
TimeoutStartSec=600
User=belagos
WorkingDirectory=/opt/belagos
ExecStart=/opt/belagos/bin/boot_wait.sh main auth cpu
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
ExecStart=/opt/belagos/bin/boot_wait.sh main
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
