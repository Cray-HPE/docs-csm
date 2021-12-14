#! /usr/bin/env python3

import argparse
import json
import re
import netaddr

def find_next_available_subnet(sls_network):
    name = sls_network["Name"]
    network_subnet = netaddr.IPNetwork(sls_network["ExtraProperties"]["CIDR"])

    existing_subnets = netaddr.IPSet()
    for sls_subnet in sls_network["ExtraProperties"]["Subnets"]:
        subnet_name = sls_subnet["Name"]
        subnet_cidr = sls_subnet["CIDR"]
        print("Found subnet {} with CIDR {}".format(subnet_name, subnet_cidr))
        existing_subnets.add(subnet_cidr)

    for available_subnet in list(network_subnet.subnet(22)):
        if available_subnet in existing_subnets:
            print(available_subnet, "Already in use!")
        else:
            print(available_subnet, "Available for use")
            return available_subnet

    return None

MOUNTAIN_CHASSIS_LIST = ["c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7"]
HILL_TDS_CHASSIS_LIST = ["c1", "c3"]

DEFAULT_HMN_MTN_CIDR="10.104.0.0/17"
DEFAULT_NMN_MTN_CIDR="10.100.0.0/17"

# Parse CLI Arguments
parser = argparse.ArgumentParser()
parser.add_argument("sls_state_file", type=str, help="SLS State file to modify")
parser.add_argument("--cabinet", type=str, required=True, help="Cabinet xname to add, ex: x1000")
parser.add_argument("--cabinet-type", type=str, required=True, help="Cabinet type", choices={"Hill", "Mountain"})
parser.add_argument("--cabinet-vlan-hmn", type=int, required=True, help="Cabinet HMN vlan add, ex: 1000")
parser.add_argument("--cabinet-vlan-nmn", type=int, required=True, help="Cabinet NMN vlan add, ex: 2000")
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
with open(args.sls_state_file) as f:
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
        print("Error {} already exists in {}!".format(xname, args.sls_state_file))
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
allNetworks = sls_state["Networks"]

# Add in the HMN_MTN and NMN_MTN networks if they do not exist
if "HMN_MTN" not in sls_state["Networks"]:
    hmn_network = {
        "Name": "HMN_MTN",
        "FullName": "Mountain Hardware Management Network",
        "IPRanges": [
            DEFAULT_HMN_MTN_CIDR
        ],
        "Type": "ethernet",
        "ExtraProperties": {
            "CIDR": DEFAULT_HMN_MTN_CIDR,
            "VlanRange": [1000, 1256],
            "MTU": 9000,
            "Subnets": []
        }
    }
    allNetworks["HMN_MTN"] = hmn_network
if "NMN_MTN" not in sls_state["Networks"]:
    hmn_network = {
        "Name": "NMN_MTN",
        "FullName": "Mountain Node Management Network",
        "IPRanges": [
            DEFAULT_NMN_MTN_CIDR
        ],
        "Type": "ethernet",
        "ExtraProperties": {
            "CIDR": DEFAULT_NMN_MTN_CIDR,
            "VlanRange": [1257, 1512],
            "MTU": 9000,
            "Subnets": []
        }
    }
    allNetworks["NMN_MTN"] = hmn_network



hmn_network = allNetworks["HMN_MTN"]
cabinet_hmn_subnet = find_next_available_subnet(hmn_network)

sls_cabinet_hmn_subnet = {
    # TODO Figure out preferred order of keys
    "Name": args.cabinet.replace("x", "cabinet_"), # cabinet_1000
    "FullName": "",
    "CIDR": str(cabinet_hmn_subnet),
    "VlanID": args.cabinet_vlan_hmn,
    "Gateway": str(cabinet_hmn_subnet[1]),
    "DHCPStart": str(cabinet_hmn_subnet[10]),
    "DHCPEnd": str(cabinet_hmn_subnet[-2]) # Pick the address right before the broadcast address
}

hmn_network["ExtraProperties"]["Subnets"].append(sls_cabinet_hmn_subnet)

nmn_network = allNetworks["NMN_MTN"]
cabinet_nmn_subnet = find_next_available_subnet(nmn_network)

sls_cabinet_nmn_subnet = {
    # TODO Figure out preferred order of keys
    "Name": args.cabinet.replace("x", "cabinet_"), # cabinet_1000
    "FullName": "",
    "CIDR": str(cabinet_nmn_subnet),
    "VlanID": args.cabinet_vlan_nmn,
    "Gateway": str(cabinet_nmn_subnet[1]),
    "DHCPStart": str(cabinet_nmn_subnet[10]),
    "DHCPEnd": str(cabinet_nmn_subnet[-2]) # Pick the address right before the broadcast address
}
nmn_network["ExtraProperties"]["Subnets"].append(sls_cabinet_nmn_subnet)


# Verify no duplicate Cabinet VLANs
foundDuplicateVlans = False
vlanSet = set()
for subnet in hmn_network["ExtraProperties"]["Subnets"]:
    vlan = subnet["VlanID"]
    if vlan in vlanSet:
        foundDuplicateVlan = True
        print("Error found duplicate VLAN {} with subnet {} in {}".format(vlan, subnet["Name"], "HMN_MTN"))

    vlanSet.add(vlan)
if foundDuplicateVlans:
    exit(1)

# Write/Move out original file?
# Write out new SLS dump
with open("sls_dump.out.json", "w") as f:
    json.dump(sls_state, f, indent=2)
