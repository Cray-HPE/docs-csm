#!/usr/bin/env python3
#  MIT License
#
#  (C) Copyright [2023] Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

import requests
import json
import sys
import os
import subprocess
import urllib3

urllib3.disable_warnings()

if len(sys.argv) < 2:
  print("ERROR: Usage: bss-update-ids-etags ims-post-import-file.json")
  sys.exit()


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

subfile = sys.argv[1]

print(subfile)

fsub = open(subfile,"r")

sub = json.loads(fsub.read())

BSS_URL="https://api-gw-service-nmn.local/apis/bss/boot/v1"
headers = {
  'cache-control': "no-cache",
  'Authorization': f'Bearer {token}'
}
url = BSS_URL + "/bootparameters"
ret = requests.request("GET", url, headers=headers, verify=False)
data = ret.json()

change = 0
nochange = 0
for i in data:
  oldi = str(i)
  for j in sub["id_maps"]["images"]:
    if "params" in i:
      i["params"] = i["params"].replace(j,sub["id_maps"]["images"][j])
    if "kernel" in i:
      i["kernel"] = i["kernel"].replace(j,sub["id_maps"]["images"][j])
    if "initrd" in i:
      i["initrd"] = i["initrd"].replace(j,sub["id_maps"]["images"][j])
  for j in sub["etag_map"]:
    if "params" in i:
      i["params"] = i["params"].replace(j,sub["etag_map"][j])
  if str(i) == oldi:
    nochange+=1
  else:
    change+=1
    BSS_URL="https://api-gw-service-nmn.local/apis/bss/boot/v1"
    headers = {
      'Content-Type': "application/json",
      'cache-control': "no-cache",
      'Authorization': f'Bearer {token}'
    }
    url = BSS_URL + "/bootparameters"
    payload = json.dumps(i)
    ret = requests.request("PUT", url, headers=headers, data=payload, verify=False)
    if ret.status_code != 200:
      print("ERROR: Return Code: " + str(ret.status_code))
      print(ret.json())

print(str(change) + " Changed")
print(str(nochange) + " Not Changed")
