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

if len(sys.argv) < 2:
  fcuser = input("Enter Foxconn BMC User : ")
else:
  fcuser = sys.argv[1]
if len(sys.argv) < 3:
  pword = input("Enter Foxconn BMC Password for user : " + fcuser + " : ")
else:
  pword = sys.argv[2]

headers = {
  'Content-Type': "application/json",
  'cache-control': "no-cache",
  'Authorization': f'Bearer {token}'
}

url = "https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/RedfishEndpoints"
hsmret = requests.request("GET", url, headers=headers, verify=False)
if hsmret.status_code != 200:
  print("ERROR: Return Status Code: " + str(hsmret.status_code))
  print(hsmret.json())
  sys.exit(1)

endpoints = hsmret.json()

for ep in endpoints["RedfishEndpoints"]:
  discoverStatus = ep["DiscoveryInfo"]["LastDiscoveryStatus"]
  if discoverStatus != "DiscoverOK":
    xname = ep["ID"]
    print("------------------------------------------------------------")
    print("Found " + xname + " with discovery status " + discoverStatus)
    url = "https://"+xname+"/redfish/v1/"
    try:
      ret = requests.request("GET", url, verify=False)
    except requests.exceptions.RequestException as e:
      print("ERROR: could not communicate with " + xname)
      print(e)
      continue
    if ret.status_code != 200:
      print("ERROR: Return Status Code: " + str(ret.status_code))
      print(ret.json())
      continue
    redfish = ret.json()
    if "Vendor" in redfish:
      vendor = redfish["Vendor"]
      if vendor == "Foxconn":
        print("UPDATE VAULT AUTHINCATION")
        url = "https://api-gw-service-nmn.local/apis/smd/hsm/v2/Inventory/RedfishEndpoints/" + xname
        headers = {
          'Content-Type': "application/json",
          'cache-control': "no-cache",
          'Authorization': f'Bearer {token}'
        }
        auth_payload = {
          "ID":xname,
          "User":fcuser,
          "Password":pword
        }
        payload = json.dumps(auth_payload)
        hsmret = requests.request("PATCH", url, data=payload, headers=headers, verify=False)
        if hsmret.status_code != 200:
          print("ERROR: Return Status Code: " + str(hsmret.status_code))
          print(hsmret.json())
    else:
      print("Vendor not Foxconn, continuing")
