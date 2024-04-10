#!/usr/bin/env python3
#  MIT License
#
#  (C) Copyright [2024] Hewlett Packard Enterprise Development LP
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

import json
import sys
import os
import requests
import urllib3

urllib3.disable_warnings()

if len(sys.argv) < 2:
  print("ERROR: Usage: updateroles rolesfile.json")
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
  sys.exit(1)

rolesfile = sys.argv[1]

with open(rolesfile,"r") as froles:
  data = json.loads(froles.read())

headers = {
  'Content-Type': "application/json",
  'cache-control': "no-cache",
  'Authorization': f'Bearer {token}'
}

errors = 0
url = "https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components"

for i in data["Components"]:
  xname = i["ID"]
  role = ""
  subrole = ""
  payload_dict = {}
  if "Role" in i:
    role = i["Role"]
    payload_dict.update({"Role": role})
  if "SubRole" in i:
    subrole = i["SubRole"]
    payload_dict.update({"SubRole": subrole})

  if len(payload_dict) > 0:
    payload = json.dumps(payload_dict)
    print(xname + " " + payload)
    url_role = url + "/" + xname + "/Role"
    ret = requests.request("PATCH", url_role, data=payload, headers=headers, verify=False)
    if ret.status_code != 204:
      print("ERROR: Return Status Code: " + str(ret.status_code))
      print(ret.json())
