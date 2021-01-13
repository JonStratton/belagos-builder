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
cat .belagos_pass > /home/glenda/.belagos_pass

# Install service
sudo sh -c '( echo "[Unit]
Description=Belagos Service
After=network.target

[Service]
Type=simple
User=glenda
WorkingDirectory=/home/glenda
ExecStart=/home/glenda/bin/run_grid.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/belagos.service )'

sudo systemctl daemon-reload
sudo systemctl start belagos.service
sudo systemctl enable belagos.service
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

sudo rm -rf /home/glenda/bin/
sudo rm -rf /home/glenda/img/

userdel -r glenda
}

########
# Main #
########

if [ $1 -a $1 = 'uninstall' ]; then
   uninstall
else
   install
fi
