![BelaGOS Logo](bela_black.png?raw=true)
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

	./install_base.sh
	sudo reboot
	./build_grid.sh

You will then be prompted for some information about the VMs to build, such as disk and memory size, and passwords. If you want to just build a single Plan 9 VM, run the above with “solo” as an argument:

	./install_base.sh
	newgrp vde2-net
	./build_grid.sh solo

You should then be able to boot the VMs with the bin/*_run.sh scripts. So to run our solo VM, execute the following:

	bin/solo_run.sh

If you want these VMs to run on system boot, run the following:

	./install_build.sh

If you entered a disk encryption password for the VMs, you can input it to the system by running “belagos_client.sh” and then typing “password”, return, and then the password followed by another return:

	/opt/belagos/bin/belagos_client.sh
	...
	password
	MyDiskPassword1!

You can connect to installed builds with drawterm:

	./install_drawterm.sh
	/opt/drawterm*/drawterm -h 192.168.9.3 -a 192.168.9.3 -u glenda

or

	/opt/drawterm*/drawterm -h 192.168.9.5 -a 192.168.9.4 -u glenda

### Uninstall

To remove the VMs from the system, run the following:

	./install_build.sh uninstall

To remove the software dependencies and attempt to return the system to its original state, run the following:

	./install_base.sh uninstall

## Networking

Optionally, you can also plug your vm network into TOR or Yggdrasil with one of the darknet(IPv6 overlay mesh network) scripts.

	networking/tor.sh install
	networking/tor.sh outbound

This will install TOR software. Route all outbound traffic threw TOR. If you are really cool, you can expose your inbound connections to TOR or Yggdrasil with the following:

	networking/tor.sh inbound

If it was plugged into Yggdrasil, and the needed ports were exposed; you can connect via drawterm:

	/opt/drawterm/drawterm -h 200:aaaa:bbbb:cccc:dddd:eeee:ffff:1111

## Useful links

[Expanding your Grid](https://9p.io/wiki/plan9/Expanding_your_Grid/index.html)
[Nicolas S. Montanaro - 9front guild](https://nicolasmontanaro.com/blog/9front-guide/)

