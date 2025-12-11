![BelaGOS Logo](bela_black.jpg?raw=true)

This project has moved. To get the latest version, pull from https://codeberg.org/JonStratton/belagos-builder

# belagos-builder
Turns a Debian install into BelaGOS. Currently this is some Python/Expect scripts to build some 9front VMs, and a Flask Service to optionally manage the VMs from inside of the VMs.

## BelaGOS - Black Emulated Grid Operating System
I’m creating this because I want a Cyberpunk Operating System that is more than just a cool GUI on GNU/Linux or BSD. Something to run on Cyberdecks or old junker ThinkPads pulled out of the trash. So I’m going to build a self contained Plan 9 grid, add an optional Mesh Networking (via Batman-adv) layer and a Darknet layer (via Yggrasil). So I can say things like "Meshing my Node into the Darknet Grid!" in front of a cool looking terminal.

### Current Status

This is a set of tools that creates a small self contained grid (or solo) of plan9 qemu VMs on a vde2 network. The machines it creates are:

	fsserve.localgrid / 192.168.9.3 / fdfc::5054:ff:fe00:ee03
	authserve.localgrid / 192.168.9.4 / fdfc::5054:ff:fe00:ee04
	cpuserve.localgrid / 192.168.9.5 / fdfc::5054:ff:fe00:ee05

This currently also has an option to route and expose services to TOR and Yggdrasil. And to join mesh networks with Batman-adv. And it also includes the ability to theme (currently only amber) via rio.themes and acme.themes.

### Future Plans

- The ability to spawn a shell on the host from inside the VMs.
- The ability to run native on ARM without falling back to emulating x86.

## How to Build VMs and Install

Prep System for install. This will create the internal VDE network (192.168.9.1/24) and install some other needed packages like qemu and some python packages.

	$ ./install/prep_system.sh install

This will add your running user to the “vde2-net”. You may need to log off and on again (or reboot) to continue to the next stage.

Run the "BelagosBuildVM.py" script below to build the VM(solo) or VMs(grid), and set the initial password(s). Disk Encryption is optional, but if enabled you have to use the web-service to enter both the Glenda password and the encryption password at boot.

	$ ./BelagosBuildVM.py
	Enter password for glenda: Password1!
	Disk for install(in GB. Should be 10 or greater, or the installer may stop): 10
	Enter optional disk encryption password. If entered, this password will be required to boot: Password1!
	Enter password for the Web Control Service: Password1!
	Install type(solo or grid): grid
	RAM for fsserve(MB): 128
	RAM for authserve(MB): 64
	RAM for cpuserve(MB): 1024
	....
	done halting

You can then run the VMs under your user account at this point. External networking will not be available yet (see "networking" to enable manually).

	$ ./BelagosService.py
	...
	init: starting /bin/rc
	cpuserve#...

Optionally if you are using Disk Encrption, you will need to store both the Disk Encryption and Glenda Passwords in RAM before booting. To do this, browse to the Webservice URL, login, enter BOTH Glenda and the Disk Encrption password, the click "Store". Once the page refreshes, you can then click "Boot".

	http://192.168.9.1:5000

At this point you should be able to connect to the host(s) with draw term. To Connect to a grid (via the CPU server), use something like:

	$ drawterm -h 192.168.9.5 -a 192.168.9.4 -u glenda

If you only created a "solo" host, use something like:

	$ drawterm -h 192.168.9.3 -a 192.168.9.3 -u glenda

If you are running at this point, you might need to type "rio" at the prompt to get a working environment.

	% rio

Optionally, if you wanted to install this as a service (so it would run on boot), you could do the following:

	$ ./install/migrate_vms_to_system.sh install

If you wanted to delete the install, just run with "uninstall".

	$ ./install/migrate_vms_to_system.sh uninstall

Finally, if you wanted to remove the dependancies for your system, you could with the following command:

	$ ./install/prep_system.sh uninstall

## Networking
Optionally you can enable networking to the hosts in the VDE network with the following scripts. These scripts have at least four modes:

- install - This will install the needed packages and prep the system for use the network / overlay feature.
- uninstall - This will uninstall the feature. WARNING; this will uninstall without checking to see if the software was previously installed. So, for instance, if you installed TOR seperatily, you should probably avoid using the "uninstall" mode as it will simply uninstall tor.
- inbound - This will expose the hosts in the VDE network to the larger network.
- outbound - This will force traffic leaving the VDE network via the network or overlay.

Here are the network and overlay features.

- optional/clearnet.sh - This will allow the hosts to connect to the internet for outbound connections. If enabled for "inbound" traffic, it will simply expose the ports of the hosts in the VDE network on the underlying hosts.
- optional/tor.sh - This will allow the hosts to connect to TOR for outbound connections. If enabled for "inbound" traffic, the host(s) will be exposed on TOR via hidden services.
- optional/yggdrasil.sh - This will allow the hosts to connect to Yggdrasil for outbound connections. If enabled for "inbound" traffic, the host(s) will be exposed on Yggdrasil. Yggdrasil will need additional configuration (to set the initial Peers).

So, for instance, if you wanted to install and allow your hosts to connect outbound to the internet, you could do the following:

	sudo ./optional/clearnet.sh install
	sudo ./optional/clearnet.sh outbound

If the VMs have been migrated to the system, you should also be able to switch the inbound and outbound traffic via the Web Interface from instide the VMs with the "Web Terminal":

	% webfs
	% mothra http://192.168.9.1:5000

The following additional scripts are also present:

- optional/restore.sh - This is used for clearing out IP Tables rules. This is useful, for instance, if you are removing the "clearnet" feature and switching to TOR. Run this to restore the IP tables rules before allowing, for instance, outbound TOR.
- optional/vde_find_internet.sh - This is a service enabled with "clearnet" is installed. Basically, in the default mode, it will attempt to connect to 8.8.8.8 on each interface on the underlying host. And when it finds a connection to the internet, it will set the IP tables rules to force outbound traffic in the VDE network down that interface.
- optional/mesh-micro.sh - This is a simple wrapper around Batman-adv. This allows the hosts in the VDE network to use Wireless Mesh Networking.

## GUI

There are some additional optional packages that can be installed at this point, mostly around themes. This includes:

- rio.themes - Rio with Themes
- acme-themes - Acme with Themes (taken from rio.themes).
- Many “amber” and dark versions of common apps.

To install these packages, connect the VMs to the internet and run the following:

	% ./plan9Scripts/packages.rc

## Useful links

- [9front](http://www.9front.org/)
- [Acme-themes](https://hjgit.org/jgstratt/acme-themes/HEAD/info.html)
- [Expanding your Grid](https://9p.io/wiki/plan9/Expanding_your_Grid/index.html)
- [Nicolas S. Montanaro - 9front guild](https://nicolasmontanaro.com/blog/9front-guide/)

