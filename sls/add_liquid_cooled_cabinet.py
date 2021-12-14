#! /usr/bin/env python3

import argparse
import json
import re

MOUNTAIN_CHASSIS_LIST = {"c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7"}
HILL_TDS_CHASSIS_LIST = {"c1", "c3"}

# Parse CLI Arguments
parser = argparse.ArgumentParser()
parser.add_argument("sls_state_file", type=str, help="SLS State file to modify")
parser.add_argument("--cabinet", type=str, required=True, help="Cabinet xname to add, ex: x1000")
parser.add_argument("--cabinet-type", type=str, required=True, help="Cabinet type", choices={"Hill", "Mountain"})
parser.add_argument("--starting-nid", type=int, required=True, help="Starting NID for new cabinet, ex: 1000")
args = parser.parse_args()

print(args)

if re.match("^x([0-9]{1,4})$", args.cabinet) == None:
    print("Invalid cabinet xname provided: ", args.cabinet)
    exit(1)

chassis_list = MOUNTAIN_CHASSIS_LIST
if args.cabinet_type == "Hill":
    chassis_list = MOUNTAIN_CHASSIS_LIST

print("SLS State File:", args.sls_state_file)
print("Cabinet:       ", args.cabinet)
print("Cabinet Type:  ", args.cabinet_type)
print("Starting NID:  ", args.starting_nid)

# Load in existing SLS State
sls_state = None
with open('sls_dump.json') as f:
    sls_state = json.load(f)

allHardware = sls_state["Hardware"]

#
# Hardware
#

# Add Hardware required for Hill or Mountain Cabinet
#   If this peices of hardware already exists, stop!
#
# Cabinet
# ChassisBMC
# Node

hardwareToAdd = []

cabinet = {
    "Parent": "s0",
    "Xname": args.cabinet,
    "Class": args.cabinet_type,
    "Type": "comptype_cabinet",
    "TypeString": "Cabinet",
    "ExtraProperties": {
        "Networks": { # This networks block is only presnet for MEDS compatability
            "cn": {
                "HMN": {},
                "NMN": {},
            }
        }
    }
}

hardwareToAdd.append(cabinet)

currentNID = args.starting_nid
for chassis in chassis_list:
    # Start with the CMM
    chassisXname = "{}{}".format(args.cabinet, chassis)
    chassisBMCXname = "{}b0".format(chassisXname)
    # print(chassisBMCXname)
    
    # chassisBMC = {
    #     "Parent": chassisXname,
    #     "Xname": chassisBMCXname,
    #     "Type": "comptype_chassis_bmc",
    #     "TypeString": "ChassisBMC",
    #     "Class": args.cabinet_type,
    # }
    # hardwareToAdd.append(chassisBMC)

    # There is a bug in CSI that generates Chassis wrong.
    chassis = {
        "Parent": args.cabinet,
        "Xname": chassisXname,
        "Type": "comptype_chassis_bmc",
        "TypeString": "ChassisBMC",
        "Class": args.cabinet_type,
    }
    hardwareToAdd.append(chassis)

    for slot in range(8):
        for bmc in range(2):
            nodeBMCXname = "{}s{}b{}".format(chassisBMCXname, slot, bmc)
            for node in range(2):
                nodeXname = "{}n{}".format(nodeBMCXname, node)
                # print(nodeXname)

                node = {
                    "Parent": nodeBMCXname,
                    "Xname": nodeXname,
                    "Type": "comptype_node",
                    "TypeString": "Node",
                    "Class": args.cabinet_type,
                    "ExtraProperties": {
                        "NID": currentNID,
                        "Role": "Compute",
                        "Aliases": ["nid%06d" % currentNID]
                    }
                }
                hardwareToAdd.append(node)

                currentNID += 1

for hardware in hardwareToAdd:
    xname = hardware["Xname"] 
    # print("Adding {}".format(xname))
    if xname in allHardware:
        print("Error {} already exists in sls state!".format(xname))
        exit(1)

    allHardware[xname] = hardware

# Verify no duplicate NIDs
foundDuplicateNIDs = False
nidSet = set()
for xname in allHardware:
    hardware = allHardware[xname]

    if hardware["Type"] != "comptype_node":
        continue

    if "ExtraProperties" not in hardware:
        continue

    extraProperties = hardware["ExtraProperties"]

    if extraProperties["Role"] != "Compute":
        continue

    nid = hardware["ExtraProperties"]["NID"]

    if nid in nidSet:
        foundDuplicateNIDs = True
        print("Error found duplicate NID {}".format(nid))

    nidSet.add(nid)

if foundDuplicateNIDs:
    exit(1)


#
# Networks
#
hmn_network = sls_state["Networks"]["HMN"]
nmn_network = sls_state["Networks"]["NMN"]


# Write/Move out original file?
# Write out new SLS dump
with open("sls_dump.out.json", "w") as f:
    json.dump(sls_state, f, indent=2)
