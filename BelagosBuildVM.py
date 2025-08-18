#!/usr/bin/env python3
import os, platform, requests, re, subprocess, glob
import BelagosLib as bl
from configparser import ConfigParser

CONFIG_FILE = './BelagosService.conf'
DISK_MAIN = './9front_main.img'
DISK_AUTH = './9front_authserve.img'
DISK_CPU = './9front_cpuserve.img'
SCRIPTS_ISO = './plan9Scripts.iso'
TIMEZONE = 'US_Central'

def main():
   arch = platform.machine()
   iso_arch, qemu_arch = get_alt_arch(arch)

   # Read config, or create one if there isnt one.
   glenda_pass, disk_pass, disk_gb, config = get_specs_user(CONFIG_FILE, qemu_arch)

   # Download the iso if not installed
   local_iso = '9front.%s.iso' % (iso_arch)
   remote_iso_reg = re.compile('9front-\d+.%s.iso.gz' % (iso_arch)) # 9front-10522.amd64.iso.gz
   if not os.path.exists(local_iso):
      get_iso("http://9front.org/iso/", remote_iso_reg, local_iso)

   # Pull out boot ini and kern. Patch boot ini
   kern = process_iso(local_iso, iso_arch)

   # Create Disk Images
   subprocess.run(['qemu-img', 'create', '-f', 'qcow2', DISK_MAIN, "%sG" % (disk_gb)])

   # Do basic install by adding custom 
   command_install = "%s -drive if=none,id=vd1,file=%s -device scsi-cd,drive=vd1, -kernel %s -initrd plan9.ini -no-reboot" % (config.get('main_vm', 'command'), local_iso, kern)
   bl.base_install_vm(command_install, TIMEZONE, disk_pass)
   os.unlink(kern)
   os.unlink('./plan9.ini')

   # Package up plan9 scripts and make an ISO for the install process
   subprocess.run(['mkisofs', '-o', SCRIPTS_ISO, './plan9'])

   # Service Stuff
   bl.base_services_vm(config.get('main_vm', 'command'), SCRIPTS_ISO, glenda_pass, config.get('main', 'type'), disk_pass)
   os.unlink(SCRIPTS_ISO)

   if config.get('main', 'type') == 'grid':
      pexp_main = bl.boot_vm(config.get('main_vm', 'command'), glenda_pass, disk_pass)

      # Dont create AUTH and CPU disks if we are using disk encryption, as those contain cached glenda creds
      if not int(config.get('main', 'disk_encryption')):
         subprocess.run(['qemu-img', 'create', '-f', 'qcow2', DISK_AUTH, '1M'])
         bl.grid_nvram_vm(config.get('auth_vm', 'command'), glenda_pass)

      bl.grid_authserver_vm(config.get('auth_vm', 'command'), glenda_pass)

      # You only really need to do this step to create nvram. So no need to continue on if we are using disk encryption
      if not int(config.get('main', 'disk_encryption')):
         pexp_auth = bl.boot_vm(config.get('auth_vm', 'command'), glenda_pass, disk_pass)
         subprocess.run(['qemu-img', 'create', '-f', 'qcow2', DISK_CPU, '1M'])
         bl.grid_nvram_vm(config.get('cpu_vm', 'command'), glenda_pass)
         bl.halt_vm(pexp_auth)

      bl.halt_vm(pexp_main)

   return(0)

def get_alt_arch(arch):
   iso_arch = arch
   qemu_arch = arch
   if arch == 'x86_64':
      iso_arch = 'amd64'
   else:
      iso_arch = '386'
      qemu_arch = 'i386'
   return(iso_arch, qemu_arch)

# gunzip and pull out the plan9.ini file (and kern?) so we can patch it for serial ccoonnssoollee
def process_iso(local_iso, iso_arch):
   subprocess.run(['7z', 'e', local_iso, 'cfg/plan9.ini', '%s/9pc*' % (iso_arch), '-aoa'], stdout=subprocess.DEVNULL)
   with open("plan9.ini", "a") as plan9iniH:
      plan9iniH.write("console=0\n*acpi=1")

   kerns = glob.glob('9pc*')
   return(kerns[0])

def get_iso(url, remote_iso_reg, local_iso):
   # Download
   response = requests.get(url).text
   matches = remote_iso_reg.search(response)
   if matches:
      remote_iso = matches.group()
      remote_iso_url = "%s/%s" % (url, remote_iso)
      print('Downloading:', remote_iso_url)
      get_response = requests.get("%s/%s" % (url, remote_iso),stream=True)
      with open(remote_iso, 'wb') as f:
         for chunk in get_response.iter_content(chunk_size=1024):
            f.write(chunk)

      # gunzip and redirect
      with open(local_iso, "w") as outfile:
         subprocess.run(['gunzip', '--stdout', remote_iso], stdout=outfile)
      os.unlink(remote_iso)

   return('')

def get_specs_user(config_file, arch):
   config = ConfigParser()

   glenda_pass = input("Enter password for glenda: ")
   disk_gb = input("Disk for install(in GB. Should be 10 or greater, or the installer may stop): ")
   disk_pass = input("Enter optional disk encryption password. If entered, this password will be required to boot: ")

   disk_encryption = 0
   autostart = 1
   if disk_pass: # Turn off autostart as we need the disk_pass (and glenda pass) to boot now.
      disk_encryption = 1
      autostart = 0

   config = ConfigParser()
   if os.path.exists(config_file):
      config.read(config_file)
   else:
      web_pass = input("Enter password for the Web Control Service: ")
      installType = input("Install type(solo or grid): ")
      if installType == 'grid':
         main_core = input("RAM for fsserve(MB): ")
         authserve_core = input("RAM for authserve(MB): ")
         cpuserve_core = input("RAM for cpuserve(MB): ")
         config['main'] = {'order': 'main_vm auth_vm cpu_vm', 'autostart': autostart, 'disk_encryption': disk_encryption, 'type': installType, 'web_password': web_pass}
         config['main_vm'] = {'command': 'qemu-system-%s -m %s -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=%s -device scsi-hd,drive=vd0 -nographic' % (arch, main_core, DISK_MAIN)}
         if disk_encryption:
            config['auth_vm'] = {'command': 'qemu-system-%s -m %s -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -boot n -nographic' % (arch, authserve_core)}
            config['cpu_vm'] = {'command': 'qemu-system-%s -m %s -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -boot n -nographic' % (arch, cpuserve_core)}
         else:
            config['auth_vm'] = {'command': 'qemu-system-%s -m %s -net nic,macaddr=52:54:00:00:EE:04 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=%s -device scsi-hd,drive=vd0 -boot n -nographic' % (arch, authserve_core, DISK_AUTH)}
            config['cpu_vm'] = {'command': 'qemu-system-%s -m %s -net nic,macaddr=52:54:00:00:EE:05 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=%s -device scsi-hd,drive=vd0 -boot n -nographic' % (arch, cpuserve_core, DISK_CPU)}
      else:
         main_core = input("RAM for install(MB): ")
         config['main'] = {'order': 'main_vm', 'autostart': autostart, 'disk_encryption': disk_encryption, 'type': installType, 'web_password': web_pass}
         config['main_vm'] = {'command': 'qemu-system-%s -m %s -net nic,macaddr=52:54:00:00:EE:03 -net vde,sock=/var/run/vde2/tap0.ctl -device virtio-scsi-pci,id=scsi -drive if=none,id=vd0,file=%s -device scsi-hd,drive=vd0 -nographic' % (arch, main_core, DISK_MAIN)}
   
      # Write the configuration to a file
      with open(config_file, 'w') as config_fileH:
         config.write(config_fileH)

   return(glenda_pass, disk_pass, disk_gb, config)

if __name__ == '__main__':
   main()
