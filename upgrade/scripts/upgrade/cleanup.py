#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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

import json
import os
import sys

import requests

# This script is idempotent; it can be run multiple times without consequence.
def main():
    token = os.getenv("TOKEN")
    if not token:
        print("ERROR Missing keycloak token. Is TOKEN environment variable set?", file=sys.stderr)
        sys.exit(1)

    headers = { "Authorization": f"Bearer {token}" }
    bss_url = "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters"
    response = requests.get(bss_url, headers=headers)

    response = response.json()

    nodes = []
    for node in response:
        metadata = node.get("cloud-init", {}).get("meta-data", {})
        # Some meta-data fields are null.
        if metadata is not None:
            hostname = metadata.get("local-hostname")
            # Some local-hostname fields are null.
            if hostname is not None:
                # We only care about master and worker nodes.
                if hostname.startswith("ncn-m") or hostname.startswith("ncn-w"):
                    nodes.append(node)

    for node in nodes:
        runcmd = node.get("cloud-init", {}).get("user-data", {}).get("runcmd")
        hostname = node.get("cloud-init").get("meta-data").get("local-hostname")

        if runcmd is not None:
            print(f"Patching BSS runcmd for node: {hostname}.")

            # Delete the lines we added in upgrade.sh.
            runcmd = [x for x in runcmd if x != "touch /etc/cray/kubernetes/upgrade" and x != "mkdir -p /etc/cray/kubernetes"]
            node["cloud-init"]["user-data"]["runcmd"] = runcmd

            response = requests.put(bss_url, headers=headers, json=node)
            if response.status_code != 200:
                print(f"ERROR Unable to patch BSS runcmd for node: {hostname}.", file=sys.stderr)
                print(response.text)

                sys.exit(1)


if __name__=='__main__':
    main()
