#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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
script = {
    "name": "L2X-Watchdog",
    "script": "IyAtKi0gY29kaW5nOiB1dGYtOCAtKi0KIwojIChjKSBDb3B5cmlnaHQgMjAxOC0yMDE5IEhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIERldmVsb3BtZW50IExQCiMKIyBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIyB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiMgWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CiMKIyBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKIwojIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywKIyBzb2Z0d2FyZSBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbgojICJBUyBJUyIgQkFTSVMsIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWQojIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlCiMgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZCBsaW1pdGF0aW9ucwojIHVuZGVyIHRoZSBMaWNlbnNlLgoKTWFuaWZlc3QgPSB7CiAgICAnTmFtZSc6ICdMMlgtV2F0Y2hkb2cnLAogICAgJ0Rlc2NyaXB0aW9uJzogJ01vbml0b3IgZm9yIEwyIE1BQyBsZWFybmluZyBzeXN0ZW0gcHJvY2VzcyAnCiAgICAgICAgICAgICAgICAgICAnYW5kIGF0dGVtcHQgdG8gcmVzdGFydCB0byByZWNvdmVyIHN5c3RlbSBoZWFsdGguJywKICAgICdWZXJzaW9uJzogJzEuMCcsCiAgICAnVGFyZ2V0U29mdHdhcmVWZXJzaW9uJzogJzEwLjA0JywKICAgICdBdXRob3InOiAnQXJ1YmEgTmV0d29ya3MgLSBDRUUgVGVhbScKICAgIAp9CgpjbGFzcyBQb2xpY3koTkFFKToKICAgIGRlZiBfX2luaXRfXyhzZWxmKToKICAgICAgICBzZWxmLnIxID0gUnVsZSgiTDJYIFdhdGNoZG9nIikKICAgICAgICBzZWxmLnIxLmNvbmRpdGlvbigiZXZlcnkgNjAgc2Vjb25kcyIpCiAgICAgICAgc2VsZi5yMS5hY3Rpb24oc2VsZi5hY3Rpb25fdXBvbl9ib290KQogICAgICAgIHNlbGYudmFyaWFibGVzWydjb25maWd1cmVkJ10gPSAnMCcKCiAgICBkZWYgYWN0aW9uX3Vwb25fYm9vdChzZWxmLCBldmVudCk6CiAgICAgICAgaWYgaW50KHNlbGYudmFyaWFibGVzWydjb25maWd1cmVkJ10pID09IDE6CiAgICAgICAgICAgIEFjdGlvblNoZWxsKCJzdWRvIC90bXAvdG9wYmNtLnNoIikKICAgICAgICBlbHNlOgogICAgICAgICAgICBzZWxmLndyaXRlU2NyaXB0KCkKCiAgICBkZWYgd3JpdGVTY3JpcHQgKHNlbGYpOgogICAgICAgIHNlbGYudmFyaWFibGVzWydjb25maWd1cmVkJ10gPSAnMScKICAgICAgICAjIFRoZSBmb2xsb3dpbmcgQWN0aW9uU2hlbGwgd2lsbCBkbyB0aGUgZm9sbG93aW5nOgogICAgICAgICMgMS4gY3JlYXRlIGEgdGVtcG9yYXJ5IGZpbGUgZm9yIAogICAgICAgICMgMi4gaW5zdGFsbCBhIGJhc2ggc2NyaXB0IHRvIHRoZSBzd2l0Y2ggd2hpY2ggdXNlZAogICAgICAgICMgICAgZm9yIGNyZWF0aW5nIHRoZSB3YXRjaGRvZyBmb3IgQkNNTDJYCiAgICAgICAgQWN0aW9uU2hlbGwoCiAgICAgICAgICAgICcnJ2VjaG8gIiMhL2Jpbi9iYXNoIiA+IC90bXAvdG9wYmNtLnNoIFxuJycnCiAgICAgICAgICAgICcnJ2VjaG8gIlRPUD1cYHRvcCAtdyA1MTIgLWIgLW4gMSAtbyAlQ1BVIC1IIHwgZ3JlcCBiY21MMlhcYCIgPj4gL3RtcC90b3BiY20uc2hcbicnJwogICAgICAgICAgICAnJydlY2hvICJpZiBbWyBcJFRPUCBdXTsgdGhlbiIgPj4gL3RtcC90b3BiY20uc2hcbicnJwogICAgICAgICAgICAnJydlY2hvICIgICAgOiIgPj4gL3RtcC90b3BiY20uc2hcbicnJwogICAgICAgICAgICAnJydlY2hvICJlbHNlIiA+PiAvdG1wL3RvcGJjbS5zaFxuJycnCiAgICAgICAgICAgICcnJ2VjaG8gIiAgICBlY2hvIFxgZGF0ZVxgIiA+PiAvdG1wL3RvcGJjbS5zaFxuJycnCiAgICAgICAgICAgICcnJ2VjaG8gIiAgICBlY2hvICdCQ01MMnggUElEIG5vdCBmb3VuZCciID4+IC90bXAvdG9wYmNtLnNoXG4nJycKICAgICAgICAgICAgJycnZWNobyAiICAgIGVjaG8gJ0V4ZWN1dGluZyBiY21MMlguMCByZWNvdmVyeS4uLiciID4+IC90bXAvdG9wYmNtLnNoXG4nJycKICAgICAgICAgICAgJycnZWNobyAiICAgIGxvZ2dlciAiQkNNTDJYIGhhcyBxdWl0IHVuZXhwZWN0ZWRseSwgYXR0ZW1wdGluZyB0byByZXN0YXJ0Li4uIiIgPj4gL3RtcC90b3BiY20uc2hcbicnJwogICAgICAgICAgICAnJydlY2hvICIgICAgeyBlY2hvICJsMiB3YXRjaCBzdGFydCI7IHNsZWVwIDE7IGVjaG8gImwyIHdhdGNoIHN0b3AiOyBzbGVlcCAxOyB9IHwgL3Vzci9iaW4vc3RhcnRfYmNtX3NoZWxsIiA+PiAvdG1wL3RvcGJjbS5zaFxuJycnCiAgICAgICAgICAgICcnJ2VjaG8gImZpIiA+PiAvdG1wL3RvcGJjbS5zaFxuJycnCiAgICAgICAgICAgICcnJ2NobW9kIDc1NSAvdG1wL3RvcGJjbS5zaCBcbicnJyk=",
}
nae_agent = {"name": "L2X-Watchdog", "disabled": False}

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
                print(f"L2X-Watchdog NAE script is already installed on {switch}.")
            else:
                # upload the script to the switch.
                response = session.post(
                    f"https://{switch}/rest/v1/system/nae_scripts",
                    json=script,
                    verify=False,
                )
                if response.ok:
                    print(f"L2X-Watchdog NAE script is now installed. on {switch}")
                # wait 3 seconds for the script to be created, the agent creation fails without the wait.
                time.sleep(3)
                # upload the agent to the script
                upload_agent = session.post(
                    f"https://{switch}/rest/v1/system/nae_scripts/L2X-Watchdog/nae_agents",
                    json=nae_agent,
                    verify=False,
                )
                if response.ok:
                    print(f"L2X-Watchdog NAE agent is now installed on {switch}.")
    finally:
        logout = session.post(f"https://{switch}/rest/v10.04/logout")

