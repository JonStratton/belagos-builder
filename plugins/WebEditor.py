#!/usr/bin/env python3
import os, threading, subprocess
from flask import Flask, request, redirect, url_for

# If Called directly, stub out app. Otherwise, import from caller
if __name__ == '__main__':
   app = Flask(__name__)
else:
   from __main__ import app, UUID, PLUGIN_STATE

PLUGIN_STATE['WebEditor'] = {}
PLUGIN_STATE['WebEditor']['File'] = '';
PLUGIN_STATE['WebEditor']['Contents'] = '';

@app.route("/%s/editor" % UUID, methods=['GET', 'POST'])
def plugins_editorLoad():
   read = request.values.get('read')
   write = request.values.get('write')
   infile = request.values.get('infile')
   savetext = request.values.get('savetext')

   PLUGIN_STATE['WebEditor']['File'] = infile
   PLUGIN_STATE['WebEditor']['Contents'] = savetext

   if ((read) and (infile) and (os.path.isfile(infile))):
      file = open(infile, "r")
      PLUGIN_STATE['WebEditor']['Contents'] = file.read()
      file.close()

   if ((write) and (infile) and (savetext)):
      file = open(infile, "w")
      file.write(savetext)
      file.close()
      
   return redirect(url_for('admin_http'))

if __name__ == '__main__':
   print("Called as Script\n")
