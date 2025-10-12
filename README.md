![BelaGOS Logo](bela_black.jpg?raw=true)
# belagos-builder
Turns a Debian install into BelagOS. Currently this is some shell and Expect scripts to build some 9front VMs.

## BelaGOS - Black Emulated Grid Operating System
I’m creating this because I want a Cyberpunk Operating System thats more than just a cool GUI on GNU/Linux or BSD. Something to run on Cyberdecks or old junker laptops. So I’m going to build a self contained Plan 9 grid, add an optional Mesh Networking (via Batman-adv) layer and a Darknet layer (via Yggrasil). So I can say things like "Meshing my Node into the Darknet Grid!" in front of a cool looking terminal.

### Current Status

This is a set of tools that creates a small self contained grid of plan9 qemu VMs on a vde2 network. The machines it creates are:

	fsserve.localgrid / 192.168.9.3 / fdfc::5054:ff:fe00:ee03
	authserve.localgrid / 192.168.9.4 / fdfc::5054:ff:fe00:ee04
	cpuserve.localgrid / 192.168.9.5 / fdfc::5054:ff:fe00:ee05

## How to Install

To build a grid, run the following:

	install/prep_system.sh
	sudo reboot
	./BelagosBuildVM.py

You will then be prompted for some information about the VMs to build, such as disk and memory size, and passwords. You may be able to get around rebooting between running the prep_system.sh script and the Build VM Script by running "newgrp vde2-net" instead. You should then be able to boot the VMs by running "./BelagosService.py".

If you want these VMs to run on system boot, run the following:

	install/migrate_vms_to_system.sh

You can connect to installed builds with drawterm(solo):

	sudo apt-get install drawterm-9front
	drawterm -h 192.168.9.3 -a 192.168.9.3 -u glenda

or, to connect to your grid:

	drawterm -h 192.168.9.5 -a 192.168.9.4 -u glenda

### Uninstall

To remove the VMs from the system, run the following:

	install/migrate_vms_to_system.sh uninstall

To remove the software dependencies and attempt to return the system to its original state, run the following:

	install/prep_system.sh uninstall

## Networking

Optionally, you can also plug your vm network into TOR or Yggdrasil with one of the darknet(IPv6 overlay mesh network) scripts.

	aux/tor.sh install
	aux/tor.sh outbound

This will install TOR software. Route all outbound traffic threw TOR. If you are really cool, you can expose your inbound connections to TOR or Yggdrasil with the following:

	aux/tor.sh inbound

If it was plugged into Yggdrasil, and the needed ports were exposed; you can connect via drawterm:

	drawterm -h 200:aaaa:bbbb:cccc:dddd:eeee:ffff:1111

## Scripts
### Install
These scripts prepare the system and build the grid.
 - BelagosBuildVM.py - This script attempts to build a 9front grid or solo server.
 - BelagosService.py - This script controls the VMs via a web service.
 - install/migrate_vms_to_system.sh - This script takes a previous created grid or solo server (from build_vms.sh) and installs it generically on the system.
 - install/prep_system.sh - This script installs some needed packages for the project, as well as creates the vde network to be used by the grid or solo server. 

### Plan 9 Scripts
These are script that will be run on the grid, mostly as part of the install process.
 - plan9/nvram.rc - This rc script just formats the nvram. 
 - plan9/packages.rc - This rc script just installs some optional packages. 
 - plan9/pxe.rc - This rc script just sets some networking configs and enables pxe.
 - plan9/solo.rc - This rc script just sets some networking configs for a solo host.

### Optional Features
These are optional features. Mostly around plugging the grid into different networks. 
 - optional/mesh-micro.sh - This script is a wrapper around batctl for optional wireless mesh networking.
 - optional/clearnet.sh - This script exposes the internal vde network ports on the host.
 - optional/restore.sh - This script attempts to clear the funky network rules after using clearnet.sh, tor.sh, or yggdrasil.sh. 
 - optional/tor.sh - This script exposes the grid inside of the vde network to tor hidden services. 
 - optional/yggdrasil.sh - This script exposes the grid inside of the vde network to yggdrasil; an overlay mesh network. 
 - optional/vde_find_internet.sh – This script attempts to find a path to the internet, and uses IP tables to allow the vde network to connect to it.

## Useful links

[Expanding your Grid](https://9p.io/wiki/plan9/Expanding_your_Grid/index.html)
[Nicolas S. Montanaro - 9front guild](https://nicolasmontanaro.com/blog/9front-guide/)

