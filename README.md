# beligos-builder
Turns a Debian install into BeligOS. Currently this is some shell and Expect scripts to build some 9front VMs.

## BelaGOS - Black Emulated Grid Operating System
I’m creating this because:
1. Its a pun on Bell Labs(the creators of Plan 9), and Bela Lugosi, who’s last pseudo role was in Plan 9 from Outer Space. This pun is so good, I basically have to make something that justifies this name.
1. Its basically a living Operating System Fanfic. In an alternate 1990s, what would have happened if Bell Labs was in Microsofts place? And RMS launched his campaign from inside Bell Labs somehow!
1. I want a Cyberpunk Operating System thats more than just a cool GUI on GNU/Linux or BSD. So I’m going to add an optional Mesh Networking (via Batman-adv) layer and a Darknet layer (via CJDNS or Yggrisil). So I can say things like "Meshing my Node into the Darknet Grid!" in front of a cool looking terminal.
1. I think it would be funny to have script kiddies port scan a Darknet node, see a Plan 9 machine, and think "What the hell?!".

###Short Term:
1. A Qemu 9front grid containing at least a File Server and an Auth/CPU Server.
1. Host machine also mounts the 9p File Server for easy transfers.
1. IPv6 in the 9front grid either through autoconfig or maybe dnsmasq. This will help plug it into the Darknet.
1. IP Table rules that allow this grid to connect to both a wireless mesh network and a Darknet.
1. Rio's Dark theme, so it looks all Cyberpunk.

###Long Term Goals:
1. The 9front Auth Server, CPU Server(s), and Terminal Servers boot from the 9front File Server.
1. Different qemu CPU servers for different CPU Archetectures.
1. Boots into Drawterm fullscreen, or Qemu fullscreen with a 9front Terminal.
1. SSH and a Plan 9 X server autoconfiged to the host, maybe with a devoted user account on the host. So the 9front Grid can run X11 apps on the host instead of via like a VM in 9front.
