#!/usr/bin/python3
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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
#
import argparse
import os
import sys
import requests
import json
import urllib3

def globalErrorHandler(error):
    print(e)
    sys.exit("something went wrong")

urllib3.disable_warnings()

parser = argparse.ArgumentParser(description='utility script to configure keycloak for cray-nls')

session = requests.Session()
session.verify = False

kc_url="https://" + os.environ.get('KC_URL')
argo_url="https://" + os.environ.get('ARGO_URL')
kc_client_id=os.environ.get('KC_CLIENT_ID')
kc_username=os.environ.get('KC_USERNAME')
kc_password=os.environ.get('KC_PASSWORD')

try:
    # Get TOKEN
    data = {
            "grant_type":"password",
            "client_id": kc_client_id,
            "username": kc_username,
            "password": kc_password
            }
    token_response = session.post(kc_url + '/keycloak/realms/master/protocol/openid-connect/token', data=data)
    token_json = token_response.json()
    token = token_json['access_token']
    if token is None:
        raise ValueError("Can't get keycloak access token")
    session.headers["Authorization"] = 'Bearer {}'.format(token)
    session.headers["Content-Type"]="application/json"

    # Get keycloak clients and find oauth2-proxy-customer-management client
    clients_response = session.get(kc_url + '/keycloak/admin/realms/shasta/clients')
    clients_json = clients_response.json()
    customerManagementClient = None
    for client in clients_json:
        if client['clientId'] == "oauth2-proxy-customer-management":
            customerManagementClientRes=session.get(kc_url + '/keycloak/admin/realms/shasta/clients/'+client['id'])
            customerManagementClient=customerManagementClientRes.json()
            break
    if customerManagementClient is None:
        raise ValueError("Failed to find customer management client")

    needConfigure=False
    # Configure webOrigins
    argoWebOrigin=argo_url
    if not argoWebOrigin in customerManagementClient['webOrigins']:
        customerManagementClient['webOrigins'].append(argoWebOrigin)
        needConfigure=True
    # Configure redirectUris
    argoRedirectUri=argo_url + "/oauth/callback"
    if not argoRedirectUri in customerManagementClient['redirectUris']:
        customerManagementClient['redirectUris'].append(argoRedirectUri)
        needConfigure=True

    if needConfigure:
        patch_response=session.put(
            kc_url + '/keycloak/admin/realms/shasta/clients/'+customerManagementClient['id'],
            data=json.dumps(customerManagementClient),
        )
        if patch_response.status_code != 204:
            print(patch_response)
            raise ValueError("Failed to patch keycloak configuration for argo")
    print("Keycloak has been configured for argo")
except Exception as e:
    globalErrorHandler(e)
