#!/bin/sh
###########
# Install #
###########
install()
{
# Create local glenda, the user that will run the vms
sudo useradd glenda -m --groups vde2-net

# Add to glenda to KVM if needed.
if [ `cat /proc/cpuinfo | grep 'vmx\|svm' | wc -l` -ge 1 ]; then
   sudo usermod -a -G kvm glenda
fi

# Copy / Move stuff over.
sudo mkdir /home/glenda/bin/
sudo cp bin/* /home/glenda/bin/
sudo mkdir /home/glenda/img/
sudo chown -R glenda:glenda /home/glenda/bin/

# Install solo service
if [ -f img/9front_solo.img ]; then
   sudo mv img/9front_solo.img /home/glenda/img/
   sudo chown -R glenda:glenda /home/glenda/img/
   sudo sh -c '( echo "[Unit]
Description=Belagos Solo Service
After=network.target
[Service]
Type=forking
TimeoutStartSec=600
User=glenda
WorkingDirectory=/home/glenda
ExecStart=/home/glenda/bin/boot_wait.sh bin/solo_run.sh
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos_solo.service )'

   sudo systemctl daemon-reload
   sudo systemctl enable belagos_solo.service
   sudo systemctl start belagos_solo.service
fi

# Install fsserve service
if [ -f img/9front_fsserve.img ]; then
   sudo mv img/9front_fsserve.img /home/glenda/img/
   sudo mv img/9front_authserve.img /home/glenda/img/
   sudo mv img/9front_cpuserve.img /home/glenda/img/
   sudo chown -R glenda:glenda /home/glenda/img/
   sudo sh -c '( echo "[Unit]
Description=Belagos Grid Service
After=network.target
[Service]
Type=forking
TimeoutStartSec=600
User=glenda
WorkingDirectory=/home/glenda
ExecStart=/home/glenda/bin/boot_wait.sh bin/fsserve_run.sh bin/authserve_run.sh bin/cpuserve_run.sh
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos_grid.service )'

   sudo systemctl daemon-reload
   sudo systemctl enable belagos_grid.service
   sudo systemctl start belagos_grid.service
fi


}

#############
# Uninstall #
#############
uninstall()
{
# Stop Service and uninstall
sudo systemctl stop belagos_grid.service
sudo systemctl stop belagos_solo.service
sudo systemctl disable belagos_grid.service
sudo systemctl disable belagos_solo.service
sudo rm /etc/systemd/system/belagos_grid.service
sudo rm /etc/systemd/system/belagos_solo.service

sudo rm -rf /home/glenda/bin/
sudo rm -rf /home/glenda/img/

sudo userdel -r glenda
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
