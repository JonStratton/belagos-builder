#!/usr/bin/env python3
import os, threading, subprocess, sys
import BelagosLib as bl
from flask import Flask, request, render_template, send_from_directory, redirect, url_for
from configparser import ConfigParser
import uuid
import importlib
sys.path.append('plugins')

CONFIG = ConfigParser()
CONFIG.read('BelagosService.conf')
VM_ORDER = CONFIG.get('main', 'order').split()
WEB_PASSWORD = CONFIG.get('main', 'web_password')
AUTOSTART = int(CONFIG.get('main', 'autostart'))
DISK_ENCRYPTION = int(CONFIG.get('main', 'disk_encryption'))
PLUGINS = CONFIG.get('main', 'plugins').split()
CANSUDO = False
PLUGIN_SCRIPTS = {"internet":"optional/clearnet.sh","tor":"optional/tor.sh","yggdrasil":"optional/yggdrasil.sh","mesh":"optional/mesh-micro.sh"}
PLUGIN_CHECK_SERVICE = {"internet":"belagos_find_internet","tor":"tor","yggdrasil":"yggdrasil","mesh":"mesh_micro"}
PLUGIN_STATE = {}

# Globals
app = Flask(__name__)
VM_TO_EXP = {}
STATUS = 'preboot'
DISK_PASSWORD = ''
GLENDA_PASSWORD = ''
UUID = uuid.uuid1()

for plugin in PLUGINS:
   module = importlib.import_module(plugin, package=None)

def boot():
   global STATUS
   for vm in VM_ORDER:
      command = CONFIG.get(vm, 'command')
      VM_TO_EXP[vm] = bl.boot_vm(command, GLENDA_PASSWORD, DISK_PASSWORD)
   STATUS = 'booted';
   return 0

def halt():
   global STATUS
   for vm in reversed(VM_ORDER):
      if VM_TO_EXP[vm].isalive():
         bl.halt_vm(VM_TO_EXP[vm])
   STATUS = 'halted';
   return 0

@app.route("/", methods=['GET'])
def root_http():
   return render_template('login.html')

@app.route('/static/bela_black.jpg')
def static_bela():
   return send_from_directory('', 'bela_black.jpg')

@app.route("/login", methods=['POST'])
def login_http():
   if (request.values.get('password') and (request.values.get('password') == WEB_PASSWORD)):
      return redirect(url_for('admin_http'))
   return 'Unauthorized', 401

@app.route("/%s" % UUID)
def admin_http():
   pluginsEnabled = {}
   for plugin in PLUGIN_CHECK_SERVICE.keys():
      commandReturn = subprocess.run(['systemctl', 'status', PLUGIN_CHECK_SERVICE.get(plugin)], capture_output=True, text=True).stdout
      if (subprocess.run(['systemctl', 'status', PLUGIN_CHECK_SERVICE.get(plugin)], capture_output=True, text=True).stdout):
         pluginsEnabled[plugin] = 1
   return render_template('admin.html', uuid=UUID, status=STATUS, disk_encryption=DISK_ENCRYPTION, cansudo=CANSUDO, pluginsEnabled=pluginsEnabled, plugins=PLUGINS, pluginState=PLUGIN_STATE)

@app.route("/%s/status" % UUID)
def status_http():
   return STATUS

@app.route("/%s/network" % UUID, methods=['GET', 'POST'])
def network_http():
   subprocess.run(["sudo", 'optional/restore.sh'], capture_output=True, text=True).stdout

   inbound = request.values.get('inbound')
   if (inbound != 'default'):
      inboundCmd = PLUGIN_SCRIPTS.get(inbound)
      subprocess.run(["sudo", inboundCmd, 'inbound'], capture_output=True, text=True).stdout

   outbound = request.values.get('outbound')
   if (outbound != 'default'):
      outboundCmd = PLUGIN_SCRIPTS.get(outbound)
      subprocess.run(["sudo", outboundCmd, 'outbound'], capture_output=True, text=True).stdout

   return redirect(url_for('admin_http'))

@app.route("/%s/password" % UUID, methods=['POST'])
def disk_password_http():
   global DISK_PASSWORD, GLENDA_PASSWORD
   DISK_PASSWORD = request.values.get('disk_password')
   GLENDA_PASSWORD = request.values.get('glenda_password')
   return redirect(url_for('admin_http'))

@app.route("/%s/boot" % UUID)
def boot_http():
   boot()
   return redirect(url_for('admin_http'))

@app.route("/%s/halt" % UUID)
def halt_http():
   halt()
   return redirect(url_for('admin_http'))

if __name__ == '__main__':
   commandReturn = subprocess.run(["sudo", "-ln"], capture_output=True, text=True).stdout
   if 'optional/restore.sh' in commandReturn:
      CANSUDO = True

   if AUTOSTART:
      boot_thread = threading.Thread(target=boot, args=())
      boot_thread.start()

   app.run(host='192.168.9.1', port=5000)

