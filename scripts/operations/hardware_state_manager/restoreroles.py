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

import json
import sys
import os
import requests
import urllib3

urllib3.disable_warnings()

def checkKeyMatch(ID, i, j, key):
  if key in i:
    if key in j:
      if set(str(i[key])) != set(str(j[key])):
        print("ERROR:" + key + " Mismatch: " + ID + " - " + str(i[key]) + " != " + str(j[key]))
        return(1)
      else:
        print(key + " Match: " + ID + " - " + str(i[key]))
        return(0)
    else:
      print("ERROR:" + key + " Mismatch: " + ID)
      return(1)
  else:
    if key in i:
      print("ERROR:" + key + " Mismatch: " + ID)
      return(1)
  return(0)


if len(sys.argv) < 2:
  print("ERROR: Usage: verifyroles rolesfile.json")
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
ret = requests.request("GET", url, headers=headers, verify=False)
if ret.status_code != 200:
  print("ERROR: Return Status Code: " + str(ret.status_code))
  print(ret.json())
  sys.exit(1)

current = ret.json()

for i in data["Components"]:
  ID = i["ID"]
  found = False
  for j in current["Components"]:
    currentID = j["ID"]
    if ID == currentID:
      found = True
      checkKeyMatch(ID, i, j, "Type")
      checkKeyMatch(ID, i, j, "Role")
      checkKeyMatch(ID, i, j, "SubRole")
      checkKeyMatch(ID, i, j, "NID")
      checkKeyMatch(ID, i, j, "NetType")
      checkKeyMatch(ID, i, j, "Arch")
      checkKeyMatch(ID, i, j, "Class")
  if not found:
    print("ERROR: " + ID + " not found in current HSM membership list")
    errors = errors + 1

for i in current["Components"]:
  ID = i["ID"]
  found = False
  for j in data["Components"]:
    currentID = j["ID"]
    if ID == currentID:
      found = True
  if not found:
    print("ERROR: " + ID + " not found in provided HSM membership file")
    errors = errors + 1

print(str(errors) + " errors found")
sys.exit(errors)
