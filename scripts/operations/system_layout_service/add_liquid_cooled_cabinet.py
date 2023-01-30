#! /usr/bin/env python3

# MIT License
#
# (C) Copyright [2022-2023] Hewlett Packard Enterprise Development LP
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
        print("  Found existing subnet {} with CIDR {}".format(subnet_name, subnet_cidr))
        existing_subnets.add(subnet_cidr)

    for available_subnet in list(network_subnet.subnet(22)):
        if available_subnet not in existing_subnets:
            print("  {} Available for use.".format(available_subnet))
            return available_subnet

    return None

def build_network(name, full_name, cidr, vlan_range):
    return {
        "Name": name,
        "FullName": full_name,
        "IPRanges": [
            cidr
        ],
        "Type": "ethernet",
        "ExtraProperties": {
            "CIDR": cidr,
            "VlanRange": vlan_range,
            "MTU": 9000,
            "Subnets": []
        }
    }

def add_cabinet_subnet(sls_network, cabinet_xname, vlan):
    print("Selecting subnet for {} cabinet in {} network".format(cabinet_xname, sls_network["Name"]))
    cabinet_subnet = find_next_available_subnet(sls_network)

    sls_subnet = {
        # TODO Figure out preferred order of keys
        "Name": cabinet_xname.replace("x", "cabinet_"), # cabinet_1000
        "FullName": "",
        "CIDR": str(cabinet_subnet),
        "VlanID": vlan,
        "Gateway": str(cabinet_subnet[1]),
        "DHCPStart": str(cabinet_subnet[10]),
        "DHCPEnd": str(cabinet_subnet[-2]) # Pick the address right before the broadcast address
    }

    sls_network["ExtraProperties"]["Subnets"].append(sls_subnet)

    return sls_subnet

MOUNTAIN_CHASSIS_LIST = ["c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7"]
HILL_TDS_CHASSIS_LIST = ["c1", "c3"]

DEFAULT_HMN_MTN_CIDR="10.104.0.0/17"
DEFAULT_NMN_MTN_CIDR="10.100.0.0/17"

# Parse CLI Arguments
parser = argparse.ArgumentParser()
parser.add_argument("sls_state_file", type=str, help="SLS State file to modify")
parser.add_argument("--cabinet", type=str, required=True, help="Cabinet component name (xname) to add, ex: x1000")
parser.add_argument("--cabinet-type", type=str, required=True, help="Cabinet type", choices={"Hill", "Mountain", "EX2500"})
parser.add_argument("--cabinet-vlan-hmn", type=int, required=True, help="Hardware Management Network (HMN) VLAN ID configured on the CEC, ex: 1000")
parser.add_argument("--cabinet-vlan-nmn", type=int, required=True, help="Cabinet NMN vlan add, ex: 2000")
parser.add_argument("--starting-nid", type=int, required=True, help="Starting NID for new cabinet, ex: 1000")
parser.add_argument("--liquid-cooled-chassis-count", type=int, required=False, help="Number of liquid-cooled chassis present in a EX2500 cabinet, ex 3")
args = parser.parse_args()

if re.match("^x([0-9]{1,4})$", args.cabinet) == None:
    print("Invalid cabinet component name (xname) provided: ", args.cabinet)
    exit(1)

cabinet_class=None
if args.cabinet_type == "Mountain":
    chassis_list = MOUNTAIN_CHASSIS_LIST
    cabinet_class = "Mountain"
elif args.cabinet_type == "Hill":
    chassis_list = HILL_TDS_CHASSIS_LIST
    cabinet_class = "Hill"
elif args.cabinet_type == "EX2500":
    if args.liquid_cooled_chassis_count == None:
        print("Error --liquid-cooled-chassis-count argument is required for EX2500 cabinet", args.cabinet)
        exit(1)
    
    if (args.liquid_cooled_chassis_count < 1) or (3 < args.liquid_cooled_chassis_count):
        print("Error --liquid-cooled-chassis-count argument is out of range: {} Expected range is 1 to 3".format(args.liquid_cooled_chassis_count))
        exit(1)

    chassis_list = ["c{}".format(i) for i in range(0, args.liquid_cooled_chassis_count)]
    cabinet_class = "Hill"
else:
    print("Error unknown --cabinet-type specified:", args.cabinet_type)
    exit(1)

print("========================")
print("Configuration")
print("========================")
print("SLS State File:   ", args.sls_state_file)
print("Starting NID:     ", args.starting_nid)
print("Cabinet:          ", args.cabinet)
print("Cabinet Type:     ", args.cabinet_type)
print("Cabinet Class:    ", cabinet_class)
print("Cabinet VLAN HMN: ", args.cabinet_vlan_hmn)
print("Cabinet VLAN NMN: ", args.cabinet_vlan_nmn)
print("Chassis List:      [{}]".format(','.join(chassis_list)))
print()

# Load in existing SLS State
sls_state = None
with open(args.sls_state_file) as f:
    sls_state = json.load(f)

allHardware = sls_state["Hardware"]
allNetworks = sls_state["Networks"]

#
# Hardware
#

# Add Hardware required for Hill or Mountain Cabinet
#   If this pieces of hardware already exists, stop!
#
# Cabinet
# ChassisBMC
# Node

hardwareToAdd = []

cabinet = {
    "Parent": "s0",
    "Xname": args.cabinet,
    "Class": cabinet_class,
    "Type": "comptype_cabinet",
    "TypeString": "Cabinet",
    "ExtraProperties": {
        "Networks": { # This networks block is only present for MEDS compatibility
            "cn": {
                "HMN": {},
                "NMN": {},
            }
        }
    }
}

if args.cabinet_type == "EX2500":
    cabinet["ExtraProperties"]["Model"] = "EX2500"

hardwareToAdd.append(cabinet)

currentNID = args.starting_nid
for chassis in chassis_list:
    # Start with the CMM
    chassisXname = "{}{}".format(args.cabinet, chassis)
    chassisBMCXname = "{}b0".format(chassisXname)
    
    # ChassisBMC SLS Object
    chassisBMC = {
        "Parent": chassisXname,
        "Xname": chassisBMCXname,
        "Type": "comptype_chassis_bmc",
        "TypeString": "ChassisBMC",
        "Class": cabinet_class,
    }
    hardwareToAdd.append(chassisBMC)

    # Chassis SLS Object
    chassis = {
        "Parent": args.cabinet,
        "Xname": chassisXname,
        "Type": "comptype_chassis",
        "TypeString": "Chassis",
        "Class": cabinet_class,
    }
    hardwareToAdd.append(chassis)

    for slot in range(8):
        for bmc in range(2):
            nodeBMCXname = "{}s{}b{}".format(chassisXname, slot, bmc)
            for node in range(2):
                nodeXname = "{}n{}".format(nodeBMCXname, node)

                node = {
                    "Parent": nodeBMCXname,
                    "Xname": nodeXname,
                    "Type": "comptype_node",
                    "TypeString": "Node",
                    "Class": cabinet_class,
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
    if xname in allHardware:
        print("Error {} already exists in {}!".format(xname, args.sls_state_file))
        exit(1)

    allHardware[xname] = hardware

# Verify no duplicate NIDs
foundDuplicateNIDs = False
nidSet = set()
for xname in allHardware:
    hardware = allHardware[xname]

    if hardware["Type"] != "comptype_node" or "ExtraProperties" not in hardware:
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

# Add in the HMN_MTN and NMN_MTN networks if they do not exist
if "HMN_MTN" not in sls_state["Networks"]:
    allNetworks["HMN_MTN"] = build_network("HMN_MTN", "Mountain Hardware Management Network", DEFAULT_HMN_MTN_CIDR, [1000, 1256])

if "NMN_MTN" not in sls_state["Networks"]:
    allNetworks["NMN_MTN"] = build_network("NMN_MTN", "Mountain Node Management Network", DEFAULT_NMN_MTN_CIDR, [1257, 1512])

print("========================")
print("Network Configuration")
print("========================")

hmn_subnet = add_cabinet_subnet(allNetworks["HMN_MTN"], args.cabinet, args.cabinet_vlan_hmn)
nmn_subnet = add_cabinet_subnet(allNetworks["NMN_MTN"], args.cabinet, args.cabinet_vlan_nmn)

cabinet_networks = allHardware[args.cabinet]["ExtraProperties"]["Networks"]["cn"]
cabinet_networks["HMN"]["CIDR"] = hmn_subnet["CIDR"]
cabinet_networks["HMN"]["Gateway"] = hmn_subnet["Gateway"]
cabinet_networks["HMN"]["VLan"] = hmn_subnet["VlanID"]

cabinet_networks["NMN"]["CIDR"] = nmn_subnet["CIDR"]
cabinet_networks["NMN"]["Gateway"] = nmn_subnet["Gateway"]
cabinet_networks["NMN"]["VLan"] = nmn_subnet["VlanID"]

print()
print("HMN_MTN Subnet")
print("  VlanID:     ", hmn_subnet["VlanID"])
print("  CIDR:       ", hmn_subnet["CIDR"])
print("  Gateway:    ", hmn_subnet["Gateway"])
print("  DHCP Start: ", hmn_subnet["DHCPStart"])
print("  DHCP End:   ", hmn_subnet["DHCPEnd"])
print("NMN_MTN Subnet")
print("  VlanID:     ", nmn_subnet["VlanID"])
print("  CIDR:       ", nmn_subnet["CIDR"])
print("  Gateway:    ", nmn_subnet["Gateway"])
print("  DHCP Start: ", nmn_subnet["DHCPStart"])
print("  DHCP End:   ", nmn_subnet["DHCPEnd"])
print()


# Verify no duplicate Cabinet VLANs
foundDuplicateVlans = False
vlanSet = set()
for network in ["HMN_MTN", "NMN_MTN"]:
    for subnet in  allNetworks[network]["ExtraProperties"]["Subnets"]:
        vlan = subnet["VlanID"]
        if vlan in vlanSet:
            foundDuplicateVlans = True
            print("Error found duplicate VLAN {} with subnet {} in {}".format(vlan, subnet["Name"], network))

        vlanSet.add(vlan)
if foundDuplicateVlans:
    exit(1)

print("Next available NID", currentNID)

# Write out the updated SLS dump
print("Writing updated SLS state to", args.sls_state_file)
with open(args.sls_state_file, "w") as f:
    json.dump(sls_state, f, indent=2)
