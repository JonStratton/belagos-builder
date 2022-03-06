#!/bin/sh
###########
# Install #
###########
install()
{
# Create local belagos, the user that will run the vms
sudo useradd belagos -s /bin/false --groups vde2-net

# Add to belagos to KVM if needed.
if [ `cat /proc/cpuinfo | grep 'vmx\|svm' | wc -l` -ge 1 ]; then
   sudo usermod -a -G kvm belagos
fi

# Copy / Move stuff over.
sudo mkdir /opt/belagos/
sudo mkdir /opt/belagos/bin/
sudo cp bin/* /opt/belagos/bin/
sudo mkdir /opt/belagos/img/


# Install solo service
if [ -f img/9front_solo.img ]; then
   sudo mkfifo -m 622 /opt/belagos/img/solo_run_in
   sudo mkfifo -m 644 /opt/belagos/img/solo_run_out
   sudo mv img/9front_solo.img /opt/belagos/img/
   sudo chown -R belagos:belagos /opt/belagos/img/*
   sudo sh -c '( echo "[Unit]
Description=Belagos Solo Service
After=network.target
[Service]
Type=forking
TimeoutStartSec=600
User=belagos
WorkingDirectory=/opt/belagos
ExecStart=/opt/belagos/bin/boot_wait.exp bin/solo_run.sh
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos_solo.service )'

   sudo systemctl daemon-reload
   sudo systemctl enable belagos_solo.service
   sudo systemctl start belagos_solo.service
fi

# Install fsserve service
if [ -f img/9front_fsserve.img ]; then
   sudo mkfifo -m 622 /opt/belagos/img/fsserve_run_in
   sudo mkfifo -m 644 /opt/belagos/img/fsserve_run_out
   sudo mkfifo -m 622 /opt/belagos/img/authserve_run_in
   sudo mkfifo -m 644 /opt/belagos/img/authserve_run_out
   sudo mkfifo -m 622 /opt/belagos/img/cpuserve_run_in
   sudo mkfifo -m 644 /opt/belagos/img/cpuserve_run_out
   sudo mv img/9front_fsserve.img /opt/belagos/img/
   sudo mv img/9front_authserve.img /opt/belagos/img/
   sudo mv img/9front_cpuserve.img /opt/belagos/img/
   sudo chown belagos:belagos /opt/belagos/img/*
   sudo sh -c '( echo "[Unit]
Description=Belagos Grid Service
After=network.target
[Service]
Type=forking
TimeoutStartSec=600
User=belagos
WorkingDirectory=/opt/belagos
ExecStart=/opt/belagos/bin/boot_wait.exp bin/fsserve_run.sh bin/authserve_run.sh bin/cpuserve_run.sh
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
