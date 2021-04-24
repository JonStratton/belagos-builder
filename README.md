![BelaGOS Logo](bela_black.png?raw=true)
# belagos-builder
Turns a Debian install into BelagOS. Currently this is some shell and Expect scripts to build some 9front VMs.

## BelaGOS - Black Emulated Grid Operating System
I’m creating this because I want a Cyberpunk Operating System thats more than just a cool GUI on GNU/Linux or BSD. Something to run on Cyberdecks or old junker laptops. So I’m going to build a self contained Plan 9 grid, add an optional Mesh Networking (via Batman-adv) layer and a Darknet layer (via Yggrasil). So I can say things like "Meshing my Node into the Darknet Grid!" in front of a cool looking terminal.

### Long Term Goals:
1. Different qemu CPU servers for different CPU Archetectures.
1. SSH and a Plan 9 X server autoconfiged to the host, maybe with a devoted user account on the host. So the 9front Grid can run X11 apps on the host instead of via like a VM in 9front.

### Current Status

This is a set of tools that creates a small self contained grid of plan9 qemu VMs on a vde2 network. The machines it creates are:

	fsserve.localgrid / 192.168.9.3 / fdfc::5054:ff:fe00:ee03
	authserve.localgrid / 192.168.9.4 / fdfc::5054:ff:fe00:ee04
	cpuserve.localgrid / 192.168.9.5 / fdfc::5054:ff:fe00:ee05
	termserve.localgrid / 192.168.9.6 / fdfc::5054:ff:fe00:ee06

## How to Install

Run the base installer.

	./install_base.sh

This will do the following:
1. Install needed packages if they are not installed (like qemu, expect, etc).
1. Add the running user to the "vde2-net" group and create a "tap0" interface for our VM network.
1. Configure dnsmasq for a 192.168.9.X network and set static IPs/Names for some of our VM MAC addresses and also set up PXE.
1. Set up IP Tables on IPv4, so our VMs can talk to the internet. This may not be needed if you are connecting to a Darknet instead.

Your running user should now be in the vde2-net group. First, reboot or run the newgrp command. Then run the script that starts making the VMs.

	newgrp vde2-net
	./build_grid.sh

This will:
1. Download 9front for the CPU architecture. You can also pass in an ISO as a filename alternatively.
1. Attempts to make the file server (fsserve) based in the ISO with qemu and expect. Turns on PXE.
1. Boots the authserve from the fsserve via PXE. Creates the nvram in the authserve and reset glenda's password.
1. Boots the cpuserve from the fsserve via PXE and creates nvram.
1. Shuts everything down.

If you just one vm (to use in a larger darknet grid!), run the above script with the server type as an argument.

	newgrp vde2-net
	./build_grid.sh cpu

Optionally, you can also plug your vm network into TOR or Yggdrasil with one of the darknet(IPv6 overlay mesh network) scripts.

	networking/tor.sh install
	networking/tor.sh outbound

This will:
1. Install TOR software.
1. Route all outbound traffic threw TOR.

If you are really cool, you can expose your inbound connections to TOR or Yggdrasil with the following:

	networking/tor.sh inbound

If you want, you can now test by running the FSServe alone in a terminal:

	bin/fsserve_run.sh -nographic

If it looks good, you can now install it on the built grid onto the system:

	./install_build.sh

1. Create a new “glenda” user.
1. Copy the images and runners into glenda’s home directory.
1. Create service files than run the Vms on boot (as glenda).

You should now be able to connect to the grid with the terminal VM:

	bin/termserve_run.sh

If it was plugged into Yggdrasil, and the needed ports were exposed; you can connect via drawterm:

	/opt/drawterm/drawterm -h 200:aaaa:bbbb:cccc:dddd:eeee:ffff:1111

##Useful links

[Expanding your Grid](https://9p.io/wiki/plan9/Expanding_your_Grid/index.html)
[Nicolas S. Montanaro - 9front guild](https://nicolasmontanaro.com/blog/9front-guide/)

