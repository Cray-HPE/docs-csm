#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

import sys
import json
import base64
import urllib3
import requests
from urllib3.util.retry import Retry
import argparse
from kubernetes import client, config

# Get rid of cert warning messages
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

#
# Debug convenience function
#
debug = False
def on_debug(debug=False, message=None):
    if debug:
        print("DEBUG: {}".format(message))


#
# Parse input args
#
parser = argparse.ArgumentParser(description="Configure Bifurcated CAN route")
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument("--route", dest="route", choices=["CAN", "CHN"],
    help="Set the Bifurcated CAN route to either the CAN or CHN",
)
group.add_argument("--check", action="store_true", dest="check", help="View current setting")
args = parser.parse_args()

on_debug(debug, "Command line arguments: {}".format(args))


#
# Convenience wrapper around remote calls
#
def remote_request(remote_type, remote_url, headers=None, data=None, verify=True, debug=False):
    remote_response = None

    retry_strategy = Retry(total=3, backoff_factor=0.1)
    adapter = requests.adapters.HTTPAdapter(max_retries=retry_strategy)
    http = requests.Session()
    http.mount("https://", adapter)
    http.mount("http://", adapter)

    while True:
        try:
            response = http.request(remote_type, url=remote_url, headers=headers, data=data, verify=verify,)
            on_debug(debug, "Request response: {}".format(response.text))
            response.raise_for_status()
            remote_response = json.dumps({})
            if response.text:
                remote_response = response.json()
            break
        except Exception as err:
            message = "Error calling {}: {}".format(remote_url, err)
            raise SystemExit(message)
    return remote_response


#
# Get the admin client secret from Kubernetes
#
secret = None
try:
    config.load_kube_config()
    v1 = client.CoreV1Api()
    secret_obj = v1.list_namespaced_secret("default", field_selector="metadata.name=admin-client-auth")
    secret_dict = secret_obj.to_dict()
    secret_base64_str = secret_dict["items"][0]["data"]["client-secret"]
    on_debug(debug, "base64 secret from Kubernetes is {}".format(secret_base64_str))
    secret = base64.b64decode(secret_base64_str.encode("utf-8"))
    on_debug(debug, "secret from Kubernetes is {}".format(secret))
except Exception as err:
    print("Error collecting secret from Kubernetes: {}".format(err))
    sys.exit(1)


#
# Get an auth token by using the secret
#
token = None
try:
    token_url = "https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token"
    token_data = {
        "grant_type": "client_credentials",
        "client_id": "admin-client",
        "client_secret": secret,
    }
    token_request = remote_request("POST", token_url, data=token_data, debug=debug)
    token = token_request["access_token"]
    on_debug(
        debug=debug,
        message="Auth Token from keycloak (first 50 char): {}".format(token[:50]),
    )
except Exception as err:
    print("Error obtaining keycloak token: {}".format(err))
    sys.exit(1)


#
# Get existing SLS BICAN network data
#
sls_data = None
sls_url = "https://api-gw-service-nmn.local/apis/sls/v1/networks/BICAN"
auth_headers = {"Authorization": "Bearer {}".format(token)}
try:
    sls_data = remote_request("GET", sls_url, headers=auth_headers, verify=False)
except Exception as err:
    print("Error requesting BICAN data from SLS: {}".format(err))
    sys.exit(1)
on_debug(debug=debug, message="SLS record: {}".format(sls_data))


# If SystemDefaultRoute doesn't exist in the retrieved BICAN data
# something has gone horribly wrong during CSM Install/Upgrade.
if "SystemDefaultRoute" not in sls_data["ExtraProperties"]:
    print("SystemDefaultRoute property not found, check SLS data was migrated successfully")
    sys.exit(1)

if args.check:
    print("Configured SystemDefaultRoute: {}".format(sls_data["ExtraProperties"]["SystemDefaultRoute"]))
    sys.exit(0)

# Don't update SystemDefaultRoute unless necessary.
if args.route:
    if sls_data["ExtraProperties"]["SystemDefaultRoute"] == args.route:
        print("SystemDefaultRoute already set to {}".format(args.route))
        sys.exit(0)

    sls_data["ExtraProperties"]["SystemDefaultRoute"] = args.route
    print("Setting SystemDefaultRoute to {}".format(args.route))
    on_debug(debug=debug, message="Updated SLS data: {}".format(sls_data))

    sls_request = None
    sls_url = "https://api-gw-service-nmn.local/apis/sls/v1/networks/BICAN"
    auth_headers = {"Authorization": "Bearer {}".format(token)}
    try:
        sls_request = remote_request(
            "PUT",
            sls_url,
            headers=auth_headers,
            data=json.dumps(sls_data),
            verify=False,
        )
    except Exception as err:
        print("Error requesting EthernetInterfaces from SLS: {}".format(err))
        sys.exit(1)
    on_debug(debug=debug, message="SLS records {}".format(sls_request))
