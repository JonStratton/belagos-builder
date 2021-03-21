#!/bin/sh

outbound()
{
   if [ ! -f "/usr/bin/tor" ]; then
      install
   fi

   #sudo cp networking/vde_find_internet.sh /usr/local/sbin/

   # Keep checking interfaces until one has an internet connection. Than plug it into vde
   #sudo sh -c '( echo "[Unit]
#Description=Belagos Find Internet Service
#After=network.target mesh_micro.service
#[Service]
#Type=oneshot
#ExecStart=/usr/local/sbin/vde_find_internet.sh
#RemainAfterExit=yes
#[Install]
#WantedBy=multi-user.target" > /etc/systemd/system/belagos_find_internet.service )'

   #sudo systemctl enable belagos_find_internet.service
   #sudo systemctl start belagos_find_internet.service   
}

inbound()
{
   if [ ! -f "/usr/bin/tor" ]; then
      install
   fi

   # iptables commands for direct connections?
}

uninstall()
{
   #sudo rm /usr/local/sbin/vde_find_internet.sh
   #sudo rm /etc/systemd/system/belagos_find_internet.service
   #sudo systemctl stop belagos_find_internet.service
   #sudo systemctl disable belagos_find_internet.service
}

install()
{
   echo "install"
}

if [ $1 -a $1 = 'outbound' ]; then
   outbound
elif [ $1 -a $1 = 'inbound' ]; then
   inbound
elif [ $1 -a $1 = 'uninstall' ]; then
   uninstall
elif [ $1 ]; then
   echo "$0 install|uninstall|inbound|outbound"
else
   install
fi
