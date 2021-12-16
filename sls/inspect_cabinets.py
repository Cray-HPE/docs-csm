#! /usr/bin/env python3

import argparse
import json

# Parse CLI Arguments
parser = argparse.ArgumentParser()
parser.add_argument("sls_state_file", type=str, help="SLS State file to modify")

args = parser.parse_args()

# Load in existing SLS State
sls_state = None
with open(args.sls_state_file) as f:
    sls_state = json.load(f)

allHardware = sls_state["Hardware"]
allNetworks = sls_state["Networks"]

# Find Mountain/Hill VLANs

cabinets = {}
for networks in [("HMN_MTN", "NMN_MTN"), ("HMN_RVR", "NMN_RVR")]:
    hmnNetwork, nmnNetwork = networks

    if hmnNetwork not in allNetworks or nmnNetwork not in allNetworks:
        continue

    for subnet in allNetworks[hmnNetwork]["ExtraProperties"]["Subnets"]:
        xname = subnet["Name"].replace("cabinet_", "x")

        if xname not in cabinets:
            cabinets[xname] = {"xname": xname}

        cabinets[xname]["xname"] = xname
        cabinets[xname]["hmn_vlan"] = subnet["VlanID"]
        cabinets[xname]["hmn_cidr"] = subnet["CIDR"]

    for subnet in allNetworks[nmnNetwork]["ExtraProperties"]["Subnets"]:
        xname = subnet["Name"].replace("cabinet_", "x")

        cabinets[xname]["xname"] = xname
        cabinets[xname]["nmn_vlan"] = subnet["VlanID"]
        cabinets[xname]["nmn_cidr"] = subnet["CIDR"]

for xname in cabinets:
    slsCabinet = allHardware[xname]

    cabinets[xname]["class"] = slsCabinet["Class"] 

print("=================================")
print("Cabinet Subnet & VLAN Allocations")
print("=================================")

print("Cabinet             | HMN VLAN  | HMN CIDR            | NMN VLAN  | NMN CIDR")
print("--------------------|-----------|---------------------|-----------|---------------------")
for xname in cabinets:
    cabinet = cabinets[xname]
    cabinetStr = "{} ({})".format(xname, cabinet["class"])
    print("{:<20}| {:<10}| {:<20}| {:<10}| {:<10}".format(cabinetStr, cabinet["hmn_vlan"], cabinet["hmn_cidr"], cabinet["nmn_vlan"], cabinet["nmn_cidr"]))
