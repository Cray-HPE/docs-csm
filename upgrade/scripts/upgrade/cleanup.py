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
