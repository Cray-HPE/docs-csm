#! /usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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
#pylint: disable=missing-docstring, C0301, C0103, C0302

import argparse
import json
import netaddr
import os
import sys
import re
import requests
import urllib3

# Need to add an import path so we can reuse code from the Add_Remove_Replace_NCNs
# scripts.
sys.path.append(os.path.join(os.path.dirname(__file__), "Add_Remove_Replace_NCNs"))

import add_management_ncn

from add_management_ncn import(
    # Exceptions
    AllocatedIPIsOutsideStaticRange,
    ExhaustedAvailableIPAddressSpace,

    # HTTP Helpers
    http_put,
    action_log,
    print_action,

    # SLS Helpers
    get_sls_networks,
    get_sls_hardware,

    # SLS IPAM Helpers
    allocate_ip_address_in_subnet,

    # HSM Helpers
    search_hsm_inventory_ethernet_interfaces,
    delete_hsm_inventory_ethernet_interfaces,
)
from sls_utils.Reservations import Reservation as IPReservation

# Global variables for service URLs. These get set in main.
HSM_URL = None
SLS_URL = None

#
# UAN IP Allocation functions
#
def allocate_uan_ip_cmd(session: requests.Session, args):
    print("Performing validation checks against SLS")

    # Verify the UAN node exists in SLS with the correct role and expected alias
    action, node = get_sls_hardware(session, args.xname)

    # Verify the node has the role of application
    if node["ExtraProperties"]["Role"] != "Application":
        action_log(action, f'Unexpected node Role for {args.xname} of {node["ExtraProperties"]["Role"]}, expected Application')
        print_action(action)
        sys.exit(1)
    else:
        action_log(action, f'Pass node {args.xname} has expected node Role of Application')


    # Verify the node has the sub-role of UAN
    if node["ExtraProperties"]["SubRole"] != "UAN":
        action_log(action, f'Unexpected node SubRole for {args.xname} of {node["ExtraProperties"]["SubRole"]}, expected UAN')
        print_action(action)
        sys.exit(1)
    else:
        action_log(action, f'Pass node {args.xname} has expected SubRole of UAN')

    # Verify the node has a alias
    alias = None
    if len(node["ExtraProperties"]["Aliases"]) == 0:
        action_log(action, f'Error node {args.xname} has no aliases defined in SLS hardware')
    else:
        alias = node["ExtraProperties"]["Aliases"][0]
        action_log(action, f'Pass node {args.xname} has alias of {alias}')

    print_action(action)

    # Retrieve all Network data from SLS
    validate_sls = False
    action, sls_networks = get_sls_networks(session, validate=validate_sls)

    # For each network allocate an IP address for the UAN
    allocated_ips = {}
    for network_name in ["CAN", "CHN"]:
        if network_name not in sls_networks:
            action_log(action, f"Skipping network {network_name} as it does not exist in SLS")
            continue

        sls_network = sls_networks[network_name]

        # This will add a new line between each iteration of this loop if both the CAN and CHN are present
        # for some reason.
        if len(allocated_ips) > 0:
            action_log(action, "")

        #
        # Check to see if a UAN IP address reservation already exists for the UAN.
        # If it has the same Alias and Xname(Comment) then there is nothing to allocate.
        #
        bootstrap_dhcp_subnet = sls_network.subnets()["bootstrap_dhcp"]
        # for name, ip_res in bootstrap_dhcp_subnet_reservations.items():
        #     print(name, json.dumps(ip_res.to_sls()))
        if alias in bootstrap_dhcp_subnet.reservations() and bootstrap_dhcp_subnet.reservations()[alias].comment() == args.xname:
            action_log(action, f"Found existing UAN node IP Reservation in subnet bootstrap_dhcp in network {network_name} in SLS: {bootstrap_dhcp_subnet.reservations()[alias].to_sls()}")
            continue

        #
        # Allocate an IP address on the network
        #
        action_log(action, f"Allocating UAN node IP address in network {network_name}")

        try:
            allocated_ips[network_name] = allocate_ip_address_in_subnet(action, sls_networks, network_name, "bootstrap_dhcp", args.network_allowed_in_dhcp_range)

        except ExhaustedAvailableIPAddressSpace:
            # This indicates that the network is too small
            print_action(action)
            sys.exit(1)
        except AllocatedIPIsOutsideStaticRange:
            action_log(action, f"Static range in the bootstrap_dhcp subnet of network {network_name} is too small. Attempting to expand the subnet")


            # Retrieve the existing DHCP range start IP address
            old_dhcp_start_address = netaddr.IPAddress(str(bootstrap_dhcp_subnet.dhcp_start_address()))
            # Get the next IP address
            new_dhcp_start_address = old_dhcp_start_address+1
            bootstrap_dhcp_subnet.dhcp_start_address(str(new_dhcp_start_address))
            action_log(action, f"Adjusting DHCP start of the bootstrap_dhcp subnet of network {network_name} from {str(old_dhcp_start_address)} to {str(new_dhcp_start_address)}")

            # Verify the next IP address is within the subnet
            subnet = netaddr.IPNetwork(str(bootstrap_dhcp_subnet.ipv4_address()))
            if new_dhcp_start_address not in subnet[2:-2]:
                action_log(action, f"Failed to expand the static IP address range of the bootstrap_dhcp subnet in network {network_name}")
                print_action(action)
                sys.exit(1)

            # Attempt to allocate the IP address again with the expanded IP address range
            try:
                allocated_ips[network_name] = allocate_ip_address_in_subnet(action, sls_networks, network_name, "bootstrap_dhcp", args.network_allowed_in_dhcp_range)
            except (AllocatedIPIsOutsideStaticRange, ExhaustedAvailableIPAddressSpace):
                print_action(action)
                sys.exit(1)

        #
        # Verify allocated IP address
        # Validate the application node IP to be added does not have an IP reservation already defined for it
        # Also validate that none of the IP addresses we have allocated are currently in use in SLS.
        #
        fail_sls_network_check = False
        for subnet in sls_network.subnets().values():
            for ip_reservation in subnet.reservations().values():
                # Verify no IP Reservations exist for the UAN
                same_alias = ip_reservation.name() == alias
                same_xname = ip_reservation.comment() == args.xname
                if same_alias and same_xname:
                    fail_sls_network_check = True
                    action_log(action, f'Error found existing IP Reservation in subnet {subnet.name()} of network {network_name} in SLS: {ip_reservation.to_sls()}')
                elif same_alias:
                    fail_sls_network_check = True
                    action_log(action, f'Error found existing IP Reservation in subnet {subnet.name()} of network {network_name} in SLS with same alias and different xname: {ip_reservation.to_sls()}')
                elif same_xname:
                    fail_sls_network_check = True
                    action_log(action, f'Error found existing IP Reservation in subnet {subnet.name()} of network {network_name} in SLS with same xname and different alias: {ip_reservation.to_sls()}')

                # Verify no IP Reservations exist with any NCN IP
                if ip_reservation.ipv4_address() == allocated_ips[network_name]:
                    fail_sls_network_check = True
                    action_log(action, f'Error found allocated UAN node IP {allocated_ips[network_name]} in subnet {subnet.name()} of network {network_name} in SLS: {ip_reservation.to_sls()}')

        if fail_sls_network_check:
            print_action(action)
            sys.exit(1)
        action_log(action, f'Pass {args.xname} ({alias}) does not currently exist in SLS Networks')
        action_log(action, f'Pass allocated IPs for UAN Node {args.xname} ({alias}) are not currently in use in SLS Networks')

    print_action(action)

    if len(allocated_ips) == 0:
        sys.exit(0)

    #
    # Validate contents of HSM
    #
    print("Performing validation checks against HSM")

    # Validate allocated IPs are not in use in the HSM EthernetInterfaces table
    for network, ip in allocated_ips.items():
        action, found_ethernet_interfaces = search_hsm_inventory_ethernet_interfaces(session, ip_address=ip)
        if len(found_ethernet_interfaces) == 0:
            action_log(action, f"Pass {network_name} IP address {ip} is not currently in use in HSM Ethernet Interfaces")
        else:
            # An IP address that has been allocated for the NCN is present in HSM.
            # If the component ID is not set, then this is not a real IP reservation and can be removed, as it is most likely
            # cruft from the past that was not cleaned up.
            for found_ie in found_ethernet_interfaces:
                if found_ie["ComponentID"] == "":
                    print(f'Removing stale Ethernet Interface from HSM: {found_ie}')
                    if args.perform_changes:
                        delete_hsm_inventory_ethernet_interfaces(session, found_ie)
                    else:
                        print("Skipping due to dry run!")
                else:
                    action_log(action, f'Error found EthernetInterfaces with allocated IP address {ip} in HSM: {found_ie}')
                    print_action(action)
                    sys.exit(1)

        print_action(action)

    #
    # Update SLS networking for the new UAN
    #
    for network_name, ip in allocated_ips.items():
        sls_network = sls_networks[network_name]

        ip_reservation = IPReservation(alias, ip, comment=args.xname, aliases=[])

        print(f"Adding UAN IP reservation to bootstrap_dhcp subnet in the {network_name} network")
        print(json.dumps(ip_reservation.to_sls(), indent=2))

        # Add the reservation to the subnet
        sls_network.subnets()["bootstrap_dhcp"].reservations().update(
            {
                ip_reservation.name(): ip_reservation
            }
        )

        print(f"Updating {network_name} network in SLS with updated IP reservations")
        if args.perform_changes:
            action = http_put(session, f'{SLS_URL}/networks/{network_name}', payload=sls_network.to_sls())
            if action["error"] is not None:
                action_log(action, f'Error failed to update {network_name} in SLS')
                print_action(action)
                sys.exit(1)
            print_action(action)
        else:
            print("Skipping due to dry run!")

    print('')
    print(f'IP Addresses have been allocated for {args.xname} ({alias}) and been added to SLS')
    print("        Network | IP Address")
    print("        --------|-----------")
    for network in sorted(allocated_ips):
        ip = allocated_ips[network]
        print(f'        {network:<8}| {ip}')


def deallocate_uan_ip_cmd(session: requests.Session, args):
    # Verify the UAN node exists in SLS with the correct role and expected alias
    action, node = get_sls_hardware(session, args.xname)

    # Verify the node has the role of application
    if node["ExtraProperties"]["Role"] != "Application":
        action_log(f'Unexpected node Role for {args.xname} of {node["ExtraProperties"]["Role"]}, expected Application')
        print_action(action)
        sys.exit(1)
    else:
        action_log(action, f'Pass node {args.xname} has expected node Role of Application')


    # Verify the node has the sub-role of UAN
    if node["ExtraProperties"]["SubRole"] != "UAN":
        action_log(action, f'Unexpected node SubRole for {args.xname} of {node["ExtraProperties"]["SubRole"]}, expected UAN')
        print_action(action)
        sys.exit(1)
    else:
        action_log(action, f'Pass node {args.xname} has expected SubRole of UAN')

    # Verify the node has a alias
    alias = None
    if len(node["ExtraProperties"]["Aliases"]) == 0:
        action_log(action, f'Error node {args.xname} has no aliases defined in SLS hardware')
    else:
        alias = node["ExtraProperties"]["Aliases"][0]
        action_log(action, f'Pass node {args.xname} has alias of {alias}')

    print_action(action)

    # Retrieve all Network data from SLS
    validate_sls = False
    action, sls_networks = get_sls_networks(session, validate=validate_sls)

    modified_networks = []
    for network_name in ["CAN", "CHN"]:
        if network_name not in sls_networks:
            action_log(action, f"Skipping network {network_name} as it does not exist in SLS")
            continue

        sls_network = sls_networks[network_name]

        # Check to see if a IP address reservation exists
        bootstrap_dhcp_subnet_reservations = sls_network.subnets()["bootstrap_dhcp"].reservations()

        fail_sls_network_check = False
        for ip_reservation in  list(bootstrap_dhcp_subnet_reservations.values()):
            same_alias = ip_reservation.name() == alias
            same_xname = ip_reservation.comment() == args.xname
            if same_alias and same_xname:
                # Remove the IP reservations
                action_log(action, f"Removing existing UAN node IP Reservation in subnet bootstrap_dhcp of network {network_name}: {ip_reservation.to_sls()}")
                del bootstrap_dhcp_subnet_reservations[alias]
                modified_networks.append(network_name)
            elif same_alias:
                fail_sls_network_check = True
                action_log(action, f'Error found existing IP Reservation in subnet bootstrap_dhcp of network {network_name} in SLS with same alias and different xname: {ip_reservation.to_sls()}')
            elif same_xname:
                fail_sls_network_check = True
                action_log(action, f'Error found existing IP Reservation in subnet bootstrap_dhcp of network {network_name} in SLS with same xname and different alias: {ip_reservation.to_sls()}')

        if fail_sls_network_check:
            print_action(action)
            sys.exit(1)

        if network_name not in modified_networks:
            action_log(action, f"No IP Reservations for {args.xname} ({alias}) exist in network {network_name}")

    print_action(action)

    #
    # Update SLS networking for the new UAN
    #
    for network_name in modified_networks:
        sls_network = sls_networks[network_name]

        print(f"Updating {network_name} network in SLS with updated IP reservations")
        if args.perform_changes:
            action = http_put(session, f'{SLS_URL}/networks/{network_name}', payload=sls_network.to_sls())
            if action["error"] is not None:
                action_log(action, f'Error failed to update {network_name} in SLS')
                print_action(action)
                sys.exit(1)
            print_action(action)
        else:
            print("Skipping due to dry run!")

#
# Main
#
def main():
    global HSM_URL
    global SLS_URL

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    token = os.environ.get('TOKEN')
    if token is None or token == "":
        print("Error environment variable TOKEN was not set")
        sys.exit(1)

    # Parse CLI Arguments
    parser = argparse.ArgumentParser()
    parser.set_defaults(show_help=True)

    subparsers = parser.add_subparsers()


    # Global arguments
    base_parser = argparse.ArgumentParser(add_help=False)
    base_parser.add_argument("--perform-changes", action="store_true", help="Allow modification of SLS, HSM, and BSS. When this option is not specified a dry run is performed")
    base_parser.add_argument("--xname", type=str, required=True, help="The xname of the ncn to add")
    base_parser.add_argument("--url-hsm", type=str, required=False, default="https://api-gw-service-nmn.local/apis/smd/hsm/v2")
    base_parser.add_argument("--url-sls", type=str, required=False, default="https://api-gw-service-nmn.local/apis/sls/v1")
    base_parser.add_argument("--network-allowed-in-dhcp-range", action="append", type=str, required=False, default=[], help=argparse.SUPPRESS)

    # allocate-uan-ip arguments
    allocate_ip_parser = subparsers.add_parser("allocate-uan-ip", parents=[base_parser])
    allocate_ip_parser.set_defaults(func=allocate_uan_ip_cmd, show_help=False)

    # allocate-uan-ip arguments
    allocate_ip_parser = subparsers.add_parser("deallocate-uan-ip", parents=[base_parser])
    allocate_ip_parser.set_defaults(func=deallocate_uan_ip_cmd, show_help=False)

    args = parser.parse_args()

    if args.show_help:
        parser.print_help(sys.stdout)
        sys.exit(1)

    HSM_URL = args.url_hsm
    SLS_URL = args.url_sls
    add_management_ncn.HSM_URL = HSM_URL
    add_management_ncn.SLS_URL = SLS_URL

    # Validate provided node xname (used by both)
    if re.match("^x([0-9]{1,4})c[0,4]s([0-9]+)b([0-9]+)n([0-9]+)$", args.xname) is None:
        print("Invalid node xname provided: ", args.xname, ", expected format xXcCsSbBn0")
        sys.exit(1)

    with requests.Session() as session:
        session.verify = False
        if token is not None:
            session.headers.update({'Authorization': f'Bearer {token}'})
        session.headers.update({'Content-Type': 'application/json'})

        args.func(session, args)

    return 0

if __name__ == "__main__":
    sys.exit(main())
