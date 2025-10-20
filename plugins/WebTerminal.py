#!/usr/bin/env python3
import os, threading, subprocess
from flask import Flask, request, redirect, url_for

# If Called directly, stub out app. Otherwise, import from caller
if __name__ == '__main__':
   app = Flask(__name__)
else:
   from __main__ import app, UUID, PLUGIN_STATE

PLUGIN_STATE['WebTerminal'] = ''

@app.route("/%s/terminal" % UUID, methods=['GET', 'POST'])
def plugins_terminal():
   if (request.values.get('cmd')):
      cmd = request.values.get('cmd')
      if (cmd == 'clear'):
         PLUGIN_STATE['WebTerminal'] = ''
      else:
         try:
            stdout, stderr  = subprocess.Popen(cmd.split(), stderr=subprocess.PIPE, stdout=subprocess.PIPE).communicate()
            PLUGIN_STATE['WebTerminal'] = PLUGIN_STATE['WebTerminal'] + ("> %s\n" % cmd)
            if stdout:
               PLUGIN_STATE['WebTerminal'] = PLUGIN_STATE['WebTerminal'] + stdout.decode('utf-8')
            if stderr:
               PLUGIN_STATE['WebTerminal'] = PLUGIN_STATE['WebTerminal'] + stderr.decode('utf-8')
         except OSError as e:
            PLUGIN_STATE['WebTerminal'] = PLUGIN_STATE['WebTerminal'] + ("> %s\n" % cmd)
            PLUGIN_STATE['WebTerminal'] = PLUGIN_STATE['WebTerminal'] + str(e) + "\n"
   return redirect(url_for('admin_http'))

if __name__ == '__main__':
   print("Called as Script\n")
