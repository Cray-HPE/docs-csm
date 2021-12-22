#! /usr/bin/env python3

import argparse
import json
from itertools import groupby
from operator import itemgetter

def find_node_nids(allHardware, slsClass, role):
    nids = []
    for xname in allHardware:
        hardware = allHardware[xname]
        
        if hardware["Type"] != "comptype_node" or "ExtraProperties" not in hardware:
            continue

        if hardware["Class"] != slsClass:
            continue

        extraProperties = hardware["ExtraProperties"]
        if role != None and extraProperties["Role"] != role:
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

nids = {}

# Find River NIDs
nids["River"] = {}
nids["River"]["Compute"] = find_node_nids(allHardware, "River", "Compute")
nids["River"]["Management"] = find_node_nids(allHardware, "River", "Management")

# Find Hill NIDs
nids["Hill"] = {}
nids["Hill"]["Compute"] = find_node_nids(allHardware, "Hill", "Compute")

# Find Mountain NIDs
nids["Mountain"] = {}
nids["Mountain"]["Compute"] = find_node_nids(allHardware, "Mountain", "Compute")

print("===============")
print("NID Allocations")
print("===============")

for slsClass in nids:
    print("{}".format(slsClass))
    for role in nids[slsClass]:
        nid_ranges = get_nid_ranges(nids[slsClass][role])
        print("- {:<18}[{}]".format(role+" Nodes:", ','.join(nid_ranges)))
    print()
