#!/bin/sh -x
###########
# Install #
###########
install()
{
# Create local glenda, the user that will run the vms
sudo useradd glenda -m --groups vde2-net

# Copy / Move stuff over.
sudo mkdir /home/glenda/bin/
sudo cp bin/* /home/glenda/bin/
sudo chown -R glenda:glenda /home/glenda/bin/
sudo mkdir /home/glenda/img/
sudo cp img/*img /home/glenda/img/
sudo chown -R glenda:glenda /home/glenda/img/

# Glenda's Password
sudo touch /home/glenda/.belagos_pass
sudo chown glenda:glenda /home/glenda/.belagos_pass
sudo chmod 600 /home/glenda/.belagos_pass
cat ~/.belagos_pass | sudo sh -c '( cat > /home/glenda/.belagos_pass )'

# Install fsserve service
sudo sh -c '( echo "[Unit]
Description=Belagos fsserve Service
After=network.target

[Service]
Type=simple
User=glenda
WorkingDirectory=/home/glenda
ExecStart=/home/glenda/bin/run_systemd.sh bin/run_fsserve.sh
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
ExecStart=/home/glenda/bin/run_systemd.sh bin/run_authserve.sh 192.168.9.3
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
ExecStart=/home/glenda/bin/run_systemd.sh bin/run_cpuserve.sh 192.168.9.4
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

sudo rm /home/glenda/.belagos_pass
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
