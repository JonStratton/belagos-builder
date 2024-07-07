#!/usr/bin/env python3
import pexpect, os
import BelagosLib as bl
from flask import Flask, request, session
from configparser import ConfigParser

CONFIG = ConfigParser()
CONFIG.read('BelagosService.conf')
VM_ORDER = CONFIG.get('main', 'order').split()
WEB_PASSWORD = CONFIG.get('main', 'web_password')
AUTOSTART = CONFIG.get('main', 'autostart')

# Globals
app = Flask(__name__)
VM_TO_EXP = {};
STATUS = 'preboot';
DISK_PASSWORD = '';

@app.route("/login", methods=['GET', 'POST'])
def login_http():
   if (request.values.get('password') and (request.values.get('password') == WEB_PASSWORD)):
      session['logged_in'] = True
      return "SUCCESS"
   return "FAILED"

@app.route("/logout")
def logout_http():
   session['logged_in'] = False
   return "LOGOUT"

@app.route("/status")
def status_http():
   #if not session.get('logged_in'):
   #   return 'Unauthorized', 401
   return STATUS

# TODO, when encrypted, both disk and glenda passwords are needed
@app.route("/password", methods=['GET', 'POST'])
def password_http():
   global DISK_PASSWORD
   #if not session.get('logged_in'):
   #   return 'Unauthorized', 401
   DISK_PASSWORD = request.values.get('password')
   return "SUCCESS"

@app.route("/boot")
def boot_http():
   global STATUS, VM_TO_EXP
   #if not session.get('logged_in'):
   #   return 'Unauthorized', 401
   for vm in VM_ORDER:
      command = CONFIG.get(vm, 'command')
      VM_TO_EXP[vm] = bl.boot_vm(command)
   STATUS = 'booted';
   return STATUS

@app.route("/halt")
def halt_http():
   global STATUS
   #if not session.get('logged_in'):
   #   return 'Unauthorized', 401
   for vm in reversed(VM_ORDER):
      if VM_TO_EXP[vm].isalive():
         bl.halt_vm(VM_TO_EXP[vm])
   STATUS = 'halted';
   return STATUS

if __name__ == '__main__':
   if AUTOSTART:
      for vm in VM_ORDER:
         command = CONFIG.get(vm, 'command')
         VM_TO_EXP[vm] = bl.boot_vm(command)
      STATUS = 'booted';

   app.secret_key = os.urandom(12)
   app.run()

