# belagos-builder
Turns a Debian install into BelagOS. Currently this is some shell and Expect scripts to build some 9front VMs.

## BelaGOS - Black Emulated Grid Operating System
I’m creating this because:
1. Its a pun on Bell Labs(the creators of Plan 9), and Bela Lugosi, who’s last pseudo role was in Plan 9 from Outer Space. This pun is so good, I basically have to make something that justifies this name.
1. Its basically a living Operating System Fanfic. In an alternate 1990s, what would have happened if Bell Labs was in Microsofts place? And RMS launched his campaign from inside Bell Labs somehow!
1. I want a Cyberpunk Operating System thats more than just a cool GUI on GNU/Linux or BSD. So I’m going to add an optional Mesh Networking (via Batman-adv) layer and a Darknet layer (via CJDNS or Yggrisil). So I can say things like "Meshing my Node into the Darknet Grid!" in front of a cool looking terminal.
1. I think it would be funny to have script kiddies port scan a Darknet node, see a Plan 9 machine, and think "What the hell?!".

### Short Term:
1. Host machine also mounts the 9p File Server for easy transfers.
1. Rio's Dark theme, so it looks all Cyberpunk.

### Long Term Goals:
1. Different qemu CPU servers for different CPU Archetectures.
1. Boots into Drawterm fullscreen, or Qemu fullscreen with a 9front Terminal.
1. SSH and a Plan 9 X server autoconfiged to the host, maybe with a devoted user account on the host. So the 9front Grid can run X11 apps on the host instead of via like a VM in 9front.

### Current Status

This is a set of tools that creates a small self contained grid of plan9 qemu VMs on a vde2 network. The machines it creates are:

	fsserve.localgrid / 192.168.9.3
	authserve.localgrid / 192.168.9.4
	cpuserve.localgrid / 192.168.9.5

## How to Install

Run the base installer.

	./install_base.sh

This will do the following:
1. Install needed packages if they are not installed (like qemu, expect, etc).
1. Add the running user to the "vde2-net" group and create a "tap0" interface for our VM network.
1. Configure dnsmasq for a 192.168.9.X network and set static IPs/Names for some of our VM MAC addresses and also set up PXE.
1. Set up IP Tables on IPv4, so our VMs can talk to the internet. This may not be needed if you are connecting to a Darknet instead.
1. Download and Build 9fronts version of drawterm. 

Your running user should now be in the vde2-net group. First, reboot or run the newgrp command. Then run the script that starts making the VMs.

	newgrp vde2-net
	./build_grid.sh

This will:
1. Make a keepass file to store Glenda's password. 
1. Download 9front for the CPU architecture. You can also pass in an ISO as a filename alternatively.
1. Attempts to make the file server (fsserve) based in the ISO with qemu and expect. Turns on PXE.
1. Boots the authserve from the fsserve via PXE. Creates the nvram in the authserve and reset glenda's password.
1. Boots the cpuserve from the fsserve via PXE and creates nvram.
1. Shuts everything down.

Optionally, you can also plug your grid into a darknet with one of the darknet(IPv6 overlay mesh network) scripts.

	./make_darknet_yggdrasil.sh

This will:
1. Install the software. 
1. Create IPv6 iptables rules to forward IPv6 connections between out vde2 network and the darknet.

If you want, you can now test by running the FSServe alone:

	bin/fsserve_run.sh -curses

If it looks good, you can now install it on the built grid onto the system:

	./install_build.sh

1. Create a new “glenda” user.
1. Copy the images and runners into glenda’s home directory.
1. Create service files than run the Vms on boot (as glenda).

You should now be able to connect to the grid with the terminal VM:

	bin/termserve_run.sh
