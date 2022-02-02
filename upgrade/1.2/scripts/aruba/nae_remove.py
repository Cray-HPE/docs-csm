#!/usr/bin/env python3
import requests
import urllib3
import sys
import json
import getpass
import time


def get_etc_hostnames():
    """
    Parses /etc/hosts file and returns all the hostnames in a list.
    """
    with open("/etc/hosts", "r") as f:
        hostlines = f.readlines()
    hostlines = [
        line.strip()
        for line in hostlines
        if not line.startswith("#") and line.strip() != ""
    ]
    hosts = []
    for line in hostlines:
        hostnames = line.split("#")[0].split()[1:]
        hosts.extend(hostnames)
    return hosts


#
# get list of switches
#
switches = []
for line in get_etc_hostnames():
    if "sw" in line:
        switches.append(line)

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# get switch password
password = getpass.getpass("Switch login password: ")

creds = {"username": "admin", "password": password}

session = requests.Session()

for switch in switches:
    try:
        login = session.post(
            f"https://{switch}/rest/v10.04/login", data=creds, verify=False
        )
        # get running config
        system = session.get(f"https://{switch}/rest/v10.04/system")
        platform = system.json()
        # if the switch is an Aruba 8325 then we will check see if the NAE script is already installed.
        if "8325" == platform["platform_name"]:
            response = session.get(f"https://{switch}/rest/v10.04/system/nae_scripts")
            # check if NAE script is already installed.
            if "L2X-Watchdog" in response.json():
                print(f"Removing L2X-Watchdog NAE script on {switch}.")
                response = session.delete(
                    f"https://{switch}/rest/v1/system/nae_scripts/L2X-Watchdog",
                    verify=False,
                )
                if response.ok:
                    print(f"L2X-Watchdog NAE agent is now deleted on {switch}.")
    finally:
        logout = session.post(f"https://{switch}/rest/v10.04/logout")