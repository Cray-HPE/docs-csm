#! /usr/bin/env python3
# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
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

import argparse
import re
import os
import requests
import sys
import urllib3

def is_2xx(http_status):
    return http_status // 200 == 1

def get_bmc_creds(api_token, scsd_url, target_bmc):
    # Setup requests sessions to include our token
    with requests.Session() as session:
        session.verify = False
        if api_token is not None:
            session.headers.update({'Authorization': f'Bearer {api_token}'})
        session.headers.update({'Content-Type': 'application/json'})

        # Retrieve BMC credentials from SCSD
        print(f"Retrieving BMC ({target_bmc}) credentials from SCSD")
        r = session.get(f'{scsd_url}/bmc/creds', params={"targets":[target_bmc]})
        if r.status_code != 200:
            print(f'Unexpected status {r.status_code} from SCSD, expected 200')
            return None

        scsd_response = r.json()
        print(scsd_response)
        if scsd_response["Targets"] is None:
            print(f'Unexpected number of credentials returned from SCSD found 0, excepted 1')
            return None
        elif len(scsd_response["Targets"]) != 1:
            print(f'Unexpected number of credentials returned from SCSD found {len(scsd_response["Targets"])}, excepted 1')
            return None

        return scsd_response["Targets"][0]


def clear_bmc_subscriptions(username, password, target_bmc):
    with requests.Session() as session:
        session.verify = False
        session.auth = requests.auth.HTTPBasicAuth(username, password)
 
        # Retrieve subscriptions from the BMC
        url = f'https://{target_bmc}/redfish/v1/EventService/Subscriptions'
        print(f"Retrieving Redfish Event subscriptions from the BMC: {url}")
        r = session.get(url)
        if r.status_code != 200:
            print(f'Unexpected status {r.status_code}, expected 200')
            return None

        # For each subscription delete it
        subscription_urls = list(map(lambda subscription: f'https://{target_bmc}{subscription["@odata.id"]}', r.json()["Members"]))
        subscription_urls.sort(reverse=True)

        if len(subscription_urls) == 0:
            print("No event subscriptions present!")
            return

        for subscription_url in subscription_urls:
            print(f"Deleting event subscription: {subscription_url}")
            r = session.delete(subscription_url)
            if is_2xx(r.status_code):
                print(f"Successfully deleted {subscription_url}")
            else:
                print(f'Unexpected status {r.status_code} from BMC, expected 2xx status')
                print(f'BMC Response:', r.text)


if __name__ == "__main__":
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    token=os.getenv("TOKEN")
    if token is None or token == "":
        print("Error environment variable TOKEN was not set")
        sys.exit(1)


    # Parse CLI Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("target_bmc", help="Target BMC to clear redfish subscriptions")
    parser.add_argument("--url-scsd", type=str, required=False, default="https://api-gw-service-nmn.local/apis/scsd/v1")


    args = parser.parse_args()
    
    if re.match("^x([0-9]{1,4})c([0-7])b([0])$", args.target_bmc) is not None:
        # This is a ChassisBMC
        print(f"Clearing subscriptions from ChassisBMC {args.target_bmc}")
    elif re.match("^x([0-9]{1,4})c([0-7])r([0-9]+)b([0-9]+)$", args.target_bmc) is not None:
        # This is a RouterBMC
        print(f"Clearing subscriptions from RouterBMC {args.target_bmc}")
    elif re.match("^x([0-9]{1,4})c([0-7])s([0-9]+)b([0-9]+)$", args.target_bmc) is not None:
        # This is a NodeBMC
        print(f"Clearing subscriptions from NodeBMC {args.target_bmc}")
    else:
        # Unsupported BMC
        print(f"Provided xname is not supported by this script.")
        sys.exit(1)

    # Retrieve BMC creds
    creds = get_bmc_creds(token, args.url_scsd, args.target_bmc)
    if creds is None:
        print("Failed to retrieve credentials from SCSD")
        sys.exit(1)
    
    # Clear the subscriptions from the BMC
    clear_bmc_subscriptions(creds["Username"], creds["Password"], args.target_bmc)