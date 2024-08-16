#!/usr/bin/env python3
import os, threading, subprocess
import BelagosLib as bl
from flask import Flask, request, session, render_template, send_from_directory, redirect, url_for
from configparser import ConfigParser

CONFIG = ConfigParser()
CONFIG.read('BelagosService.conf')
VM_ORDER = CONFIG.get('main', 'order').split()
WEB_PASSWORD = CONFIG.get('main', 'web_password')
AUTOSTART = int(CONFIG.get('main', 'autostart'))
DISK_ENCRYPTION = int(CONFIG.get('main', 'disk_encryption'))
OVERLAY_CANSUDO = False
OVERLAY_SCRIPTS = {"clear":"optional/clearnet.sh","tor":"optional/tor.sh","yggdrasil":"optional/yggdrasil.sh","restore":"optional/restore.sh"}
OVERLAY_ACTIONS = ("install", "uninstall", "inbound", "outbound", " ")

# Globals
app = Flask(__name__)
VM_TO_EXP = {};
STATUS = 'preboot';
DISK_PASSWORD = '';
GLENDA_PASSWORD = '';

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
   return render_template('root.html', status=STATUS, disk_encryption=DISK_ENCRYPTION, overlay_cansudo=OVERLAY_CANSUDO)

@app.route('/static/bela_black.png')
def static_bela():
   return send_from_directory('', 'bela_black.png')

@app.route("/login", methods=['POST'])
def login_http():
   if (request.values.get('password') and (request.values.get('password') == WEB_PASSWORD)):
      session['logged_in'] = True
      return redirect(url_for('root_http'))
   return 'Unauthorized', 401

@app.route("/logout")
def logout_http():
   session['logged_in'] = False
   return redirect(url_for('root_http'))

@app.route("/status")
def status_http():
   if not session.get('logged_in'):
      return 'Unauthorized', 401
   return STATUS

@app.route("/network", methods=['GET', 'POST'])
def network_http():
   if not session.get('logged_in'):
      return 'Unauthorized', 401
   overlay = request.values.get('overlay')
   action = request.values.get('action')
   if overlay not in OVERLAY_SCRIPTS:
      return 'Bad Request', 400
   if action not in OVERLAY_ACTIONS:
      return 'Bad Request', 400
   command = OVERLAY_SCRIPTS.get(overlay)
   commandReturn = subprocess.run(["sudo", command, action], capture_output=True, text=True).stdout
   return redirect(url_for('root_http'))

@app.route("/password", methods=['POST'])
def disk_password_http():
   if not session.get('logged_in'):
      return 'Unauthorized', 401
   global DISK_PASSWORD, GLENDA_PASSWORD
   DISK_PASSWORD = request.values.get('disk_password')
   GLENDA_PASSWORD = request.values.get('glenda_password')
   return redirect(url_for('root_http'))

@app.route("/boot")
def boot_http():
   if not session.get('logged_in'):
      return 'Unauthorized', 401
   boot()
   return redirect(url_for('root_http'))

@app.route("/halt")
def halt_http():
   if not session.get('logged_in'):
      return 'Unauthorized', 401
   halt()
   return redirect(url_for('root_http'))

if __name__ == '__main__':
   commandReturn = subprocess.run(["sudo", "-ln"], capture_output=True, text=True).stdout
   if 'optional/restore.sh' in commandReturn:
      OVERLAY_CANSUDO = True

   if AUTOSTART:
      boot_thread = threading.Thread(target=boot, args=())
      boot_thread.start()

   app.secret_key = os.urandom(12)
   app.run(host='192.168.9.1', port=5000)

