#!/usr/bin/python3
# Copyright 2022 Hewlett Packard Enterprise Development LP
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# (MIT License)

# Script for getting firmware versions from Mountain BMCs
# Requires the following environment variables to be set:
# TOKEN - API token
# BMC_USER - Mountain BMC username
# BMC_PASS - Mountain BMC password

# usage: get_mountain_cmm_firmware_versions.py

import os
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from simplejson.errors import JSONDecodeError
import sys

api_gw_url="https://api-gw-service-nmn.local/apis"

def print_stderr(msg):
    print(msg, file=sys.stderr)

def err_exit(msg):
    print_stderr(f"ERROR: {msg}")
    sys.exit(1)

# Returns the values of the TOKEN, BMC_USER, and BMC_PASS environment variables
# Exits script in error if any are not set
def get_env_parameters():
    try:
        token = os.environ["TOKEN"]
    except KeyError:
        err_exit("Must export TOKEN variable with API authorization token")
    try:
        user = os.environ["BMC_USER"]
    except KeyError:
        err_exit("Must export BMC_USER variable with the Mountain BMC username")
    try:
        password = os.environ["BMC_PASS"]
    except KeyError:
        err_exit(f"Must export BMC_PASS variable with the Mountain BMC password for user {user}")
    return token, user, password

def api_get(url, exit_on_fail=True, **kwargs):
    print(f"Making GET request to {url}")
    response = requests.get(url, verify=False, **kwargs)
    if response.status_code != 200:
        if response.reason:
            print_stderr(f"Response reason: {response.reason}")
        if response.text:
            print_stderr(f"Response text: {response.text}")
        msg = f"GET request to {url} returned with status code {response.status_code} (expected 200)"
        if exit_on_fail:
            err_exit(msg)
        else:
            print_stderr(f"ERROR: {msg}")
            return None
    try:
        return response.json()
    except JSONDecodeError:
        print_stderr("Response status code was 200 but error decoding response text into JSON")
        if response.text:
            print_stderr("Response test:")
            print_stderr(f"Response text: {response.text}")
        else:
            print_stderr("No text in response")
        msg = "Unable to decode response text into JSON"
        if exit_on_fail:
            err_exit(msg)
        else:
            print_stderr(f"ERROR: {msg}")
            return None

def api_gw_get(uri, token):
    url = f"{api_gw_url}/{uri}"
    return api_get(url, headers={"Authorization": f"Bearer {token}"})

# Assumes we have already verified that this is a list
# This function verifies that every entry in the list is a non-empty string
def list_of_nonempty_strings(obj_list):
    # This could be done more efficiently, but in the interest of clarity
    # I am breaking this into multiple checks
    if not all( isinstance(obj, str) for obj in obj_list ):
        return False
    elif not all( obj for obj in obj_list ):
        return False
    return True

def response_object_error(obj, msg, exit_on_fail=True):
    # Surround API response with whitespace
    print_stderr(f"\nAPI response object:\n{obj}\n")
    if exit_on_fail:
        err_exit(msg)
    else:
        print_stderr(f"ERROR: {msg}")

def get_mountain_cmm_xnames(token):
    print("Retrieving list of Mountain CMM xnames")
    json_object = api_gw_get(
        "sls/v1/search/hardware?type=comptype_chassis_bmc&class=Mountain",
        token)
    if json_object == None:
        # This is what HSM returns when no matching objects are found
        json_object = []
    elif not isinstance(json_object, list):
        response_object_error(json_object,
            f"Expected API response to be a list, but we received a {type(json_object).__name__}")
    try:
        xnames = [ cmm["Xname"] for cmm in json_object ]
    except KeyError:
        response_object_error(json_object,
            "Every entry in the API response should have an 'Xname' field but at least one does not.")
    if not list_of_nonempty_strings(xnames):
        response_object_error(json_object,
            "Every 'Xname' field should be a nonempty string, but at least one is not.")
    return xnames

def get_redfish_endpoint_fqdns(xnames, token):
    print("Retrieving list of Redfish endpoint FQDNs of the Mountain CMM(s)")
    parameters = "&id=".join(xnames)
    json_object = api_gw_get(
        f"smd/hsm/v2/Inventory/ComponentEndpoints?id={parameters}",
        token)
    if not isinstance(json_object, dict):
        response_object_error(json_object,
            f"Expected API response to be a dict, but we received a {type(json_object).__name__}")
    try:
        endpoints = json_object["ComponentEndpoints"]
    except KeyError:
        response_object_error(json_object,
            "'ComponentEndpoints' field not found in API response")
    if not isinstance(endpoints, list):
        response_object_error(json_object,
            f"Expected 'ComponentEndpoints' field to map to a list, but it maps to a {type(endpoints).__name__}")
    try:
        fqdns = [ endpoint["RedfishEndpointFQDN"] for endpoint in endpoints ]
    except KeyError:
        response_object_error(json_object,
            "Every entry in the ComponentEndpoints list should have a 'RedfishEndpointFQDN' field but at least one does not.")
    if not list_of_nonempty_strings(fqdns):
        response_object_error(json_object,
            "Every 'RedfishEndpointFQDN' field should be a nonempty string, but at least one is not.")
    print(f"\nFound {len(fqdns)} Mountain CMM Redfish FQDN(s) in the system: {', '.join(fqdns)}")
    if len(xnames) != len(fqdns):
        response_object_error(json_object,
            "Number of FQDNs ({len(fqdns)}) does not match number of xnames ({len(xnames)})")
    return fqdns

def get_firmware_version(fqdn, user, password):
    print(f"\nChecking firmware version of {fqdn}")
    json_object = api_get(
        f"https://{fqdn}/redfish/v1/UpdateService/FirmwareInventory/BMC",
        exit_on_fail=False, 
        auth=(user, password))
    if json_object == None:
        return None
    if not isinstance(json_object, dict):
        response_object_error(json_object,
            f"Expected API response to be a dict, but we received a {type(json_object).__name__}",
            exit_on_fail=False)
        return None
    try:
        version = json_object["Version"]
    except KeyError:
        response_object_error(json_object,
            "'Version' field not found in API response\n",
            exit_on_fail=False)
        return None
    if not isinstance(version, str):
        response_object_error(json_object,
            f"Expected 'Version' field to map to a string, but it maps to a {type(version).__name__}",
            exit_on_fail=False)
        return None
    elif not version:
        print_stderr(f"ERROR: Version string is blank for {fqdn}")
        return None
    return version

def main():
    # Get necessary parameters
    token, user, password = get_env_parameters()

    # Suppress insecure request warnings. This script is replacing a curl command, and
    # that curl command used -k, so the script will behave in the same way.
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
    
    xnames = get_mountain_cmm_xnames(token)
    if not xnames:
        print("\nNo Mountain CMMs found in the system.\n")
        sys.exit(0)
    print(f"\nFound {len(xnames)} Mountain CMM(s) in the system: {', '.join(xnames)}\n")

    fqdns = get_redfish_endpoint_fqdns(xnames, token)
    
    rc=0
    fqdn_to_fw_version = dict()
    for fqdn in fqdns:
        ver = get_firmware_version(fqdn, user, password)
        if ver == None:
            print_stderr(f"ERROR: Unable to obtain firmware version for {fqdn}")
            ver = "UNKNOWN"
            rc=1
        fqdn_to_fw_version[fqdn] = ver
    table_header = [ "Mountain CMM", "Firmware Version" ]
    max_cmm_len = max(
                    len(table_header[0]), 
                    max([len(f) for f in fqdns]))
    table_format="{:<%d} | {}" % max_cmm_len
    print("\n"+table_format.format(*table_header))
    for fqdn in sorted(fqdns):
        print(table_format.format(fqdn, fqdn_to_fw_version[fqdn]))

    if rc != 0:
        err_exit("\nAt least one error occurred. Investigate and resolve the problems, then re-run this script.")
    print("\nFirmware versions successfully reported")
    sys.exit(0)

if __name__ == "__main__":
    main()