#! /usr/bin/env python3

import argparse
import json
import re
import netaddr
import shutil

def find_subnet(sls_network, name):
    network_hardware_subnet = None
    for subnet in sls_network["ExtraProperties"]["Subnets"]:
        if subnet["Name"] == name:
            network_hardware_subnet = subnet
            break
    
    return  network_hardware_subnet

def find_next_available_ip(sls_subnet):
    subnet = netaddr.IPNetwork(sls_subnet["CIDR"])

    existing_ip_reservations = netaddr.IPSet()
    existing_ip_reservations.add(sls_subnet["Gateway"])
    for ip_reservation in sls_subnet["IPReservations"]:
        print("  Found existing IP reservation {} with IP {}".format(ip_reservation["Name"], ip_reservation["IPAddress"]))
        existing_ip_reservations.add(ip_reservation["IPAddress"])

    for available_ip in list(subnet[1:-2]):
        if available_ip not in existing_ip_reservations:
            print("  {} Available for use.".format(available_ip))
            return available_ip

def add_cdu_ip_reservation(sls_network, xname, alias):
    sls_subnet = find_subnet(sls_network, "network_hardware")
    if sls_subnet == None:
        print("Error: Unable to find network_hardware subnet in {} network!".format(network_name))
        exit(1)

    print("Selecting IP Reservation for {} CDU Switch in {}'s network_hardware subnet".format(xname, sls_network["Name"]))

    ip = find_next_available_ip(sls_subnet)
    ip_reservation = {
        "Name": alias,
        "IPAddress": str(ip),
        "Comment": xname
    }

    sls_subnet["IPReservations"].append(ip_reservation)

    return ip


# Parse CLI Arguments
parser = argparse.ArgumentParser()
parser.add_argument("sls_state_file", type=str, help="SLS State file to modify")
parser.add_argument("--cdu-switch", type=str, required=True, help="CDU Switch xname to add, ex: d1w1")
parser.add_argument("--brand", type=str, required=True, help="Switch brand", choices={"Dell", "Aruba"})
parser.add_argument("--alias", type=str, required=True, help="CDU Switch alias, ex: sw-cdu-003")
args = parser.parse_args()

if re.match("^d([0-9]+)w([0-9]+)$", args.cdu_switch) == None:
    print("Invalid CDU Switch xname provided: ", args.cdu_switch)
    exit(1)

if re.match("^sw-cdu-[0-9][0-9][0-9]$", args.alias) == None:
    print("Invalid CDU Switch alias: ", args.alias)
    exit(1)

print("========================")
print("Configuration")
print("========================")
print("SLS State File:", args.sls_state_file)
print("CDU Switch:    ", args.cdu_switch)
print("Brand:         ", args.brand)
print("Alias:         ", args.alias)
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
cdu_switch = {
    "Parent": re.compile("w([0-9]+)$").sub("", args.cdu_switch),
    "Xname": args.cdu_switch,
    "Type": "comptype_cdu_mgmt_switch",
    "Class": "Mountain",
    "TypeString": "CDUMgmtSwitch",
    "ExtraProperties": {
        "Brand": args.brand,
        "Aliases": [args.alias]
    }
}

# Verify the CDU switch has a unique xname
if args.cdu_switch in allHardware:
    print("Error {} already exists in {}!".format(args.cdu_switch, args.sls_state_file))
    exit(1)

# Verify the CDU switch has a unique alias
for xname in allHardware:
    hardware = allHardware[xname]

    if hardware["Type"] != "comptype_cdu_mgmt_switch" or "ExtraProperties" not in hardware:
        continue
    
    if "Aliases" not in hardware["ExtraProperties"]:
        print("Error {} is missing Alias extra property!".format(xname))
        exit(1)

    if args.alias in hardware["ExtraProperties"]["Aliases"]:
        print("Error {} already has alias {}!".format(xname, args.alias))
        exit(1)


allHardware[args.cdu_switch] = cdu_switch

#
# Networks
#
print("================================")
print("CDU Switch Network Configuration")
print("================================")

ips = {}
for network_name in ["HMN", "NMN", "MTL"]:
    ips[network_name] = add_cdu_ip_reservation(allNetworks[network_name], args.cdu_switch, args.alias)

print()
print("HMN IP: {}".format(ips["HMN"]))
print("NMN IP: {}".format(ips["NMN"]))
print("MTL IP: {}".format(ips["MTL"]))
print()

# Write out the updated SLS dump
print("Writing updated SLS state to", args.sls_state_file)
with open(args.sls_state_file, "w") as f:
    json.dump(sls_state, f, indent=2)
