#!/usr/bin/env python3
import os, threading
import BelagosLib as bl
from flask import Flask, request, session, render_template, send_from_directory, redirect, url_for
from configparser import ConfigParser

CONFIG = ConfigParser()
CONFIG.read('BelagosService.conf')
VM_ORDER = CONFIG.get('main', 'order').split()
WEB_PASSWORD = CONFIG.get('main', 'web_password')
AUTOSTART = int(CONFIG.get('main', 'autostart'))
DISK_ENCRYPTION = int(CONFIG.get('main', 'disk_encryption'))

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
   return render_template('root.html', status=STATUS, disk_encryption=DISK_ENCRYPTION)

@app.route('/static/bela_black.png')
def static_bela():
   return send_from_directory('', 'bela_black.png')

@app.route("/login", methods=['GET', 'POST'])
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

@app.route("/password", methods=['GET', 'POST'])
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
   global STATUS, VM_TO_EXP
   boot()
   return redirect(url_for('root_http'))

@app.route("/halt")
def halt_http():
   if not session.get('logged_in'):
      return 'Unauthorized', 401
   halt()
   return redirect(url_for('root_http'))

if __name__ == '__main__':
   if AUTOSTART:
      boot_thread = threading.Thread(target=boot, args=())
      boot_thread.start()

   app.secret_key = os.urandom(12)
   app.run()

