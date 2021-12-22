#! /usr/bin/env python3

import argparse
import json
from itertools import groupby
from operator import itemgetter

def find_cabinet_nids(allHardware, cabinetXname):
    nids = []
    for xname in allHardware:
        hardware = allHardware[xname]

        if not xname.startswith(cabinetXname):
            continue

        if hardware["Type"] != "comptype_node" or "ExtraProperties" not in hardware:
            continue

        if "NID" not in hardware["ExtraProperties"]:
            continue

        nids.append(hardware["ExtraProperties"]["NID"])

    nids.sort()

    return nids

def get_nid_ranges(nids):
    '''
    Create a nicely formated array of nid ranges
    '''
    ranges = []

    for k, g in groupby( enumerate(nids), lambda x: x[1]-x[0]):
        consecutive_nids = list(map(itemgetter(1), g))

        if len(consecutive_nids) == 1:
            ranges.append(str(consecutive_nids[0]))
        else:
            ranges.append("{}-{}".format(consecutive_nids[0], consecutive_nids[-1]))
    
    return ranges


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

cabinet_xnames = []
for xname in cabinets:
    cabinet_xnames.append(xname)
    cabinets[xname]["class"] = allHardware[xname]["Class"] 

cabinet_xnames.sort()

print("=================================")
print("Cabinet NID Allocations")
print("=================================")

print("Cabinet             | NID Ranges")
print("--------------------|---------------------")
for xname in cabinet_xnames:
    cabinet = cabinets[xname]
    cabinetStr = "{} ({})".format(xname, cabinet["class"])
    cabinet_nids = find_cabinet_nids(allHardware, xname)
    nidRangeStr = ', '.join(get_nid_ranges(cabinet_nids))

    print("{:<20}| {:<10}".format(cabinetStr, nidRangeStr))


print("")
print("=================================")
print("Cabinet Subnet & VLAN Allocations")
print("=================================")

print("Cabinet             | HMN VLAN  | HMN CIDR            | NMN VLAN  | NMN CIDR")
print("--------------------|-----------|---------------------|-----------|---------------------")
for xname in cabinet_xnames:
    cabinet = cabinets[xname]
    cabinetStr = "{} ({})".format(xname, cabinet["class"])
    print("{:<20}| {:<10}| {:<20}| {:<10}| {:<10}".format(cabinetStr, cabinet["hmn_vlan"], cabinet["hmn_cidr"], cabinet["nmn_vlan"], cabinet["nmn_cidr"]))
