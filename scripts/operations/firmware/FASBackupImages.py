#!/usr/bin/env python3
# MIT License
#
# (C) Copyright [2024] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

import json
import sys
import os
import requests
import urllib3
from pathlib import Path

urllib3.disable_warnings()

if len(sys.argv) < 2:
  print("ERROR: Usage: backupFASImages.py backupdir")
  sys.exit(2)

token = os.environ.get('TOKEN')
if token is None or token == "":
  print("Error environment variable TOKEN was not set")
  print('Run the following to set the TOKEN:')
  print('''export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \\
    -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \\
    -o jsonpath='{.data.client-secret}' | base64 -d` \\
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \\
    | jq -r '.access_token')
    ''')
  sys.exit(1)

backupdir = sys.argv[1]
Path(backupdir).mkdir(parents=True, exist_ok=True)

headers = {
  'Content-Type': "application/json",
  'cache-control': "no-cache",
  'Authorization': f'Bearer {token}'
}

errors = 0
url = "https://api-gw-service-nmn.local/apis/fas/v1/images"
ret = requests.request("GET", url, headers=headers, verify=False)
if ret.status_code != 200:
  print("ERROR: Return Status Code: " + str(ret.status_code))
  print(ret.json())
  sys.exit(1)

images = ret.json()

for image in images["images"]:
  if "s3URL" in image:
    s3URL=image["s3URL"]
    file = ""
    bucket = "fw-update"
    o = os.path.split(s3URL)
    image["fileName"] = o[1]
    while o[1] != bucket:
      if len(file) > 0:
        file = o[1] + "/" + file
      else:
        file = o[1]
      o = os.path.split(o[0])
    if len(backupdir) > 0:
      localfile = backupdir + "/" + file
    localdir = os.path.split(localfile)[0]
    print(file)
    if not os.path.exists(localfile):
      command = "cray artifacts get " + bucket + " " + file + " " + localfile
      Path(localdir).mkdir(parents=True, exist_ok=True)
      print(command)
      os.system(command)
      if "imageID" in image: image.pop("imageID")
      if "createTime" in image: image.pop("createTime")
      if "s3URL" in image: image.pop("s3URL")
      if "target" in image:
        image["targets"] = [ image.pop("target") ]
      with open(localfile + ".json", "w") as f:
        out = json.dumps(image, indent=2)
        f.write(out)
      f.close()
    else:
      f = open(localfile + ".json")
      nimage = json.load(f)
      f.close()
      nimage["targets"].append(image["target"])
      with open(localfile + ".json", "w") as f:
        out = json.dumps(nimage, indent=2)
        f.write(out)
      f.close()