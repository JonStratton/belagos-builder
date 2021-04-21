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
sudo chown -R glenda:glenda /home/glenda/bin/
sudo mkdir /home/glenda/img/
sudo mv img/*serve.img /home/glenda/img/
sudo chown -R glenda:glenda /home/glenda/img/

# Install fsserve service
sudo sh -c '( echo "[Unit]
Description=Belagos fsserve Service
After=network.target
[Service]
Type=simple
User=glenda
WorkingDirectory=/home/glenda
ExecStart=/home/glenda/bin/fsserve_dependancy.sh
Restart=on-failure
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos_fsserve.service )'

# Install authserve service
sudo sh -c '( echo "[Unit]
Description=Belagos authserve Service
After=network.target belagos_fsserve.service
[Service]
Type=simple
User=glenda
WorkingDirectory=/home/glenda
ExecStart=/home/glenda/bin/authserve_dependancy.sh
Restart=on-failure
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos_authserve.service )'

# Install cpuserve service
sudo sh -c '( echo "[Unit]
Description=Belagos cpuserve Service
After=network.target belagos_fsserve.service belagos_authserve.service
[Service]
Type=simple
User=glenda
WorkingDirectory=/home/glenda
ExecStart=/home/glenda/bin/cpuserve_dependancy.sh
Restart=on-failure
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos_cpuserve.service )'

sudo systemctl daemon-reload
sudo systemctl enable belagos_fsserve.service
sudo systemctl enable belagos_authserve.service
sudo systemctl enable belagos_cpuserve.service
sudo systemctl start belagos_fsserve.service
sudo systemctl start belagos_authserve.service
sudo systemctl start belagos_cpuserve.service
}

#############
# Uninstall #
#############
uninstall()
{
# Stop Service and uninstall
sudo systemctl stop belagos_fsserve.service
sudo systemctl stop belagos_authserve.service
sudo systemctl stop belagos_cpuserve.service
sudo systemctl disable belagos_fsserve.service
sudo systemctl disable belagos_authserve.service
sudo systemctl disable belagos_cpuserve.service
sudo rm /etc/systemd/system/belagos_fsserve.service
sudo rm /etc/systemd/system/belagos_authserve.service
sudo rm /etc/systemd/system/belagos_cpuserve.service

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
