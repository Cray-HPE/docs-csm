#!/usr/bin/env python3
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

import subprocess

import argparse
import http
import os
import sys
import json
import re
import copy
import binascii
import string
from ipaddress import IPv4Address
from requests.exceptions import ConnectionError
import requests
import netaddr
import urllib3

from sls_utils.Managers import NetworkManager
from sls_utils.Networks import Subnet as SLSSubnet
from sls_utils.Reservations import Reservation as IPReservation
from sls_utils import ipam

# Global variables for service URLs. These get set in main.
BSS_URL = None
HSM_URL = None
SLS_URL = None
KEA_URL = None

#
# HTTP Action stuff
#
def print_action(action):
    if action['error'] is not None:
        print(f"Failed:  {action['method'].upper()} {action['url']}. {action['error']}")
        # print(json.dumps(action["response"], indent=2))
    elif action['status'] is not None:
        print(f"Called:  {action['method'].upper()} {action['url']} with params {action['params']}")
    else:
        print(f"Planned: {action['method'].upper()} {action['url']}")

    # if action.get('body'):
    #     print(json.dumps(action.get('body'), indent=2))
    for log in action.get('logs'):
        print('         ' + log)

def print_actions(actions):
    for action in actions:
        print_action(action)

def action_create(method, url, logs=None, params=None, request_body="", response=None, completed=False, status=None, error=None):
    if logs is None:
        logs = []

    return {
        "method": method,
        "url": url,
        "params": params,
        "logs": logs,
        "request_body": request_body,
        "response": response,
        "status": status,
        "error": error,
    }

def action_set(action, name, value):
    action[name] = value

def action_log(action, log):
    action.get('logs').append(log)

def is_2xx(http_status):
    return http_status // 200 == 1

def http_get(session, url, params=None, expected_status=http.HTTPStatus.OK):
    action = action_create('get', url, params=params)
    try:
        r = session.get(url, params=params)
        action["status"] = r.status_code
        if is_2xx(r.status_code):
            action["response"] = r.json()

        if expected_status is not None and r.status_code != expected_status:
            action["error"] = f'Unexpected status {r.status_code}, expected {expected_status}'

        return action
    except ConnectionError as e:
        action["error"] = e
        return action

def http_put(session: requests.Session, url, payload, expected_status=http.HTTPStatus.OK):
    action = action_create('put', url)
    try:
        r = session.put(url, json=payload)
        action["status"] = r.status_code
        if r.status_code == http.HTTPStatus.OK and len(r.text) != 0:
            action["response"] = r.json()

        if r.status_code != expected_status:
            action["error"] = f'Unexpected status {r.status_code}, expected {expected_status}'

        return action
    except ConnectionError as e:
        action["error"] = e
        return action

def http_patch(session: requests.Session, url, payload, expected_status=http.HTTPStatus.OK):
    action = action_create('patch', url)
    try:
        r = session.patch(url, json=payload)
        action["status"] = r.status_code
        if r.status_code == http.HTTPStatus.OK and len(r.text) != 0:
            action["response"] = r.json()

        if r.status_code != expected_status:
            print(r.json())
            action["error"] = f'Unexpected status {r.status_code}, expected {expected_status}'

        return action
    except ConnectionError as e:
        action["error"] = e
        return action

def http_post(session: requests.Session, url, payload, expected_status=http.HTTPStatus.OK):
    action = action_create('post', url)
    try:
        r = session.post(url, json=payload)
        action["status"] = r.status_code
        if r.status_code == http.HTTPStatus.OK and len(r.text) != 0:
            action["response"] = r.json()

        if r.status_code != expected_status:
            action["error"] = f'Unexpected status {r.status_code}, expected {expected_status}'

        return action
    except ConnectionError as e:
        action["error"] = e
        return action

def http_delete(session: requests.Session, url, payload, expected_status=http.HTTPStatus.OK):
    action = action_create('delete', url)
    try:
        r = session.delete(url, json=payload)
        action["status"] = r.status_code
        if r.status_code == http.HTTPStatus.OK and len(r.text) != 0:
            action["response"] = r.json()

        if r.status_code != expected_status:
            action["error"] = f'Unexpected status {r.status_code}, expected {expected_status}'

        return action
    except ConnectionError as e:
        action["error"] = e
        return action

#
# SLS API Helpers
#
def verify_sls_hardware_not_found(session: requests.Session, xname: str):
    action = http_get(session, f'{SLS_URL}/hardware/{xname}', expected_status=http.HTTPStatus.NOT_FOUND)
    if action["status"] == http.HTTPStatus.OK:
        if "Aliases" in action["response"]["ExtraProperties"]:
            alias = ", ".join(action["response"]["ExtraProperties"]["Aliases"])
            action_log(action, f"Error {xname} ({alias}) already exists in SLS")
        else:
            action_log(action, f"Error {xname} already exists in SLS")
        print_action(action)
        sys.exit(1)
    elif action["error"] is not None:
        action_log(action, f'Error failed to query SLS for {xname} - {action["error"]}')
        print_action(action)
        sys.exit(1)

    action_log(action, f"Pass {xname} does not currently exist in SLS Hardware")
    print_action(action)

def get_sls_management_ncns(session: requests.Session):
    action = http_get(session, f'{SLS_URL}/search/hardware', params={"type": "comptype_node", "extra_properties.Role": "Management"})
    if action["status"] != http.HTTPStatus.OK:
        action_log(action, "Error failed to query SLS for Management NCNs")
        print_action(action)
        sys.exit(1)

    existing_management_ncns = action["response"]
    if existing_management_ncns is None or len(existing_management_ncns) == 0:
        action_log(action, "Error SLS has zero Management NCNs")
        print_action(action)
        sys.exit(1)

    return action, sorted(existing_management_ncns, key=lambda d: d["ExtraProperties"]["Aliases"][0])

def get_sls_hardware(session: requests.Session, xname: str):
    action = http_get(session, f'{SLS_URL}/hardware/{xname}', expected_status=http.HTTPStatus.OK)
    if action["status"] == http.HTTPStatus.NOT_FOUND:
        action_log(action, f"Error component {xname} does not exist in SLS.")
        print_action(action)
        sys.exit(1)
    if action["error"] is not None:
        action_log(action, f'Error failed to query SLS for {xname} - {action["error"]}')
        print_action(action)
        sys.exit(1)

    action_log(action, f"Pass {xname} exists in SLS")
    return action, action["response"]

def get_sls_networks(session: requests.Session, validate: bool):
    action = http_get(session, f'{SLS_URL}/networks')
    if action["error"] is not None:
        action_log(action, "Error failed to query SLS for Networks")
        print_action(action)
        sys.exit(1)

    temp_networks = {}
    for sls_network in action["response"]:
        temp_networks[sls_network["Name"]] = sls_network

    if validate:
        action_log(action, "Not validating SLS network data against schema")
    return action, NetworkManager(temp_networks, validate=validate)

def create_sls_hardware(session: requests.Session, hardware: dict):
    r = session.post(f'{SLS_URL}/hardware', json=hardware)

    # TODO Something in SLS changed where POSTs started to create 201 status codes.
    if r.status_code not in (http.HTTPStatus.OK, http.HTTPStatus.CREATED):
        print(f'Error failed to create {hardware["Xname"]}, unexpected status code {r.status_code}')
        sys.exit(1)

#
# HSM API Helpers
#
def search_hsm_inventory_ethernet_interfaces(session: requests.Session, component_id: str=None, ip_address: str=None, mac_address: str=None):
    search_params = {}
    if component_id is not None:
        search_params["ComponentID"] = component_id
    if ip_address is not None:
        search_params["IPAddress"] = ip_address
    if mac_address is not None:
        search_params["MACAddress"] = mac_address
    if search_params == {}:
        print("Error no parameters provided to to query HSM for EthernetInterfaces")
        sys.exit(1)

    action = http_get(session, f'{HSM_URL}/Inventory/EthernetInterfaces', params=search_params)
    if action["status"] != http.HTTPStatus.OK:
        action_log(action, "Error failed to query HSM for EthernetInterfaces")
        print_action(action)
        sys.exit(1)

    action["search_params"] = search_params
    return action, action["response"]

def verify_hsm_inventory_ethernet_interface_not_found(session: requests.Session, component_id: str=None, ip_address: str=None, mac_address: str=None) -> dict:
    action, results = search_hsm_inventory_ethernet_interfaces(session, component_id, ip_address, mac_address)

    if len(results) != 0:
        action_log(action, f'Error found EthernetInterfaces for matching {action["search_params"]} in HSM: {results}')
        print_action(action)
        sys.exit(1)

    return action

def verify_hsm_inventory_redfish_endpoints_not_found(session: requests.session, xname: str):
    action = http_get(session, f'{HSM_URL}/Inventory/RedfishEndpoints/{xname}', expected_status=http.HTTPStatus.NOT_FOUND)
    if action["status"] == http.HTTPStatus.OK:
        action_log(action, f"Error {xname} already exists in HSM Inventory RedfishEndpoints")
        print_action(action)
        sys.exit(1)
    elif action["error"] is not None:
        action_log(action, f'Error failed to query HSM for {xname} - {action["error"]}')
        print_action(action)

    action_log(action, f"Pass {xname} does not currently exist in HSM Inventory RedfishEndpoints")
    print_action(action)

def verify_hsm_state_components_not_found(session: requests.Session, xname: str):
    action = http_get(session, f'{HSM_URL}/State/Components/{xname}', expected_status=http.HTTPStatus.NOT_FOUND)
    if action["status"] == http.HTTPStatus.OK:
        action_log(action, f"Error {xname} already exists in HSM State Components")
        print_action(action)
        sys.exit(1)
    elif action["error"] is not None:
        action_log(action, f'Error failed to query HSM for {xname} - {action["error"]}')
        print_action(action)

    action_log(action, f"Pass {xname} does not currently exist in HSM State Components")
    print_action(action)

def search_hsm_state_components(session: requests.Session, nid: int):
    search_params = {"NID": nid}

    action = http_get(session, f'{HSM_URL}/State/Components', params=search_params)
    if action["status"] != http.HTTPStatus.OK:
        action_log(action, "Error failed to query HSM for EthernetInterfaces")
        print_action(action)
        sys.exit(1)

    return action, action["response"]["Components"]

def create_hsm_state_component(session: requests.Session, component: dict):
    print(f'Creating component {component["ID"]} in HSM State Component...')

    payload = {"Components": [component]}
    r = session.post(f'{HSM_URL}/State/Components', json=payload)

    if r.status_code != http.HTTPStatus.NO_CONTENT:
        print(f'Error failed to create  {component["ID"]}, unexpected status code {r.status_code}')
        sys.exit(1)

    print(f'Created {component["ID"]} in HSM State Components')
    print(json.dumps(payload, indent=2))

def create_hsm_inventory_ethernet_interfaces(session: requests.Session, ei: dict):
    print(f'Creating {ei["MACAddress"]} in HSM Ethernet Interfaces...')
    r = session.post(f'{HSM_URL}/Inventory/EthernetInterfaces', json=ei)

    if r.status_code == http.HTTPStatus.CONFLICT:
        print(f'Error creating {ei["MACAddress"]}, as it already exists in HSM EthernetInterfaces')
    elif r.status_code != http.HTTPStatus.CREATED:
        print(f'Error failed to create {ei["MACAddress"]}, unexpected status code {r.status_code}')
        sys.exit(1)
    else:
        print(f'Created {ei["MACAddress"]} in HSM Inventory Ethernet Interfaces')
        print(json.dumps(ei, indent=2))

    return r.status_code

def get_hsm_inventory_ethernet_interfaces(session: requests.Session, mac: str):
    id = mac.replace(":", "").lower()
    action = http_get(session, f'{HSM_URL}/Inventory/EthernetInterfaces/{id}', expected_status=None)
    if action["error"] is not None:
        action_log(action, f'Error failed to query HSM Ethernet Interfaces for {mac}. {action["error"]}')
        print_action(action)
        sys.exit(1)
    return action, action["response"]

def patch_hsm_inventory_ethernet_interfaces(session: requests.Session, ei: dict):
    id = ei["MACAddress"].replace(":", "").lower()
    action = http_patch(session, f'{HSM_URL}/Inventory/EthernetInterfaces/{id}', payload=ei)
    if action["error"] is not None:
        action_log(action, f'Error failed to patch HSM Ethernet Interfaces for {id}. {action["error"]}')
        print_action(action)
        sys.exit(1)
    print_action(action)

    print(f'Patched {id} in HSM Inventory Ethernet Interfaces')
    print(json.dumps(ei, indent=2))

def delete_hsm_inventory_ethernet_interfaces(session: requests.Session, ei: dict):
    id = ei["MACAddress"].replace(":", "").lower()
    if len(id) == "":
        print("Error unable to delete EthernetInterface from HSM as an empty value was provided as the MAC Address")
        sys.exit(1)
    action = http_delete(session, f'{HSM_URL}/Inventory/EthernetInterfaces/{id}', payload=ei)
    if action["error"] is not None:
        action_log(action, f'Error failed to delete HSM Ethernet Interface {id} from HSM. {action["error"]}')
        print_action(action)
        sys.exit(1)
    print_action(action)

    print(f'Deleted {id} from HSM Inventory Ethernet Interfaces')
    print(json.dumps(ei, indent=2))

#
# BSS API Helpers
#
def verify_bss_bootparameters_not_found(session: requests.Session, name: str):
    action = http_get(session, f'{BSS_URL}/bootparameters', params={"name": name}, expected_status=http.HTTPStatus.NOT_FOUND)
    if action["error"] is not None:
        action_log(action, f'Error failed to query BSS Bootparameters for {name}. {action["error"]}')
        print_action(action)
        sys.exit(1)

    if action["status"] != http.HTTPStatus.NOT_FOUND:
        action_log(action, f"Error found bootparameters for {name} in BSS")
        print_action(action)
        sys.exit(1)

    action_log(action, f"Pass {name} does not currently exist in BSS Bootparameters")
    print_action(action)

def get_bss_bootparameters(session: requests.Session, name: str):
    action = http_get(session, f'{BSS_URL}/bootparameters', params={"name": name}, expected_status=http.HTTPStatus.OK)
    if action["error"] is not None:
        action_log(action, f'Error failed to query BSS Bootparameters for {name}. {action["error"]}')
        print_action(action)
        sys.exit(1)
    if action["status"] == http.HTTPStatus.NOT_FOUND:
        action_log(action, f"Error bootparameters for {name} do not exist in BSS")
        print_action(action)
        sys.exit(1)

    if len(action["response"]) != 1:
        action_log(action, f'Unexpected number of bootparameters for {name} in BSS {len(action["response"])}, expected 1')
        print_action(action)
        sys.exit(1)

    return action, action["response"][0]

def put_bss_bootparameters(session: requests.Session, bootparameters: dict):
    action = http_put(session, f'{BSS_URL}/bootparameters', payload=bootparameters)
    if action["error"] is not None:
        action_log(action, 'Error failed to update bootparameters in BSS')
        print_action(action)
        sys.exit(1)
    print_action(action)

# generate_instance_id creates an instance-id fit for use in the instance metadata
def generate_instance_id() -> str:
    b = os.urandom(4)
    return f'i-{binascii.hexlify(b).decode("utf-8").upper()}'

#
# KEA API Helpers
#
def get_kea_lease4_get_by_hw_address(session: requests.Session, mac_address: str):
    action = http_post(session, KEA_URL, payload={
        "command": "lease4-get-by-hw-address",
        "arguments": {
            "hw-address": mac_address
        },
        "service": [ "dhcp4" ]
    })

    if action["error"] is not None:
        action_log(action, f'Error failed to query KEA for DHCP leases associated with {mac_address}. {action["error"]}')
        print_action(action)
        sys.exit(1)

    return action, action["response"][0]["arguments"]["leases"]

#
# Functions to process xnames
#

def get_component_parent(xname:str):
    # TODO This is really hacky
    regex_cdu = "^d([0-9]+)$"
    regex_cabinet = "^x([0-9]{1,4})$"
    if re.match(regex_cdu, xname) is not None or re.match(regex_cabinet, xname) is not None:
        return "s0"

    # Trim all trailing numbers, then in the result, trim all trailing
	# letters.
    return xname.rstrip(string.digits).rstrip(string.ascii_letters)

#
# SLS IPAM functions
#

class ExhaustedAvailableIPAddressSpace(Exception):
    pass

class AllocatedIPIsOutsideStaticRange(Exception):
    pass

def find_next_available_ip(sls_subnet: SLSSubnet, cidr_override: IPv4Address=None, starting_ip: netaddr.IPAddress=None) -> netaddr.IPAddress:
    subnet = netaddr.IPNetwork(str(sls_subnet.ipv4_address()))

    # Override the CIDR if one was provided
    if cidr_override is not None:
        subnet = netaddr.IPNetwork(str(cidr_override))

    existing_ip_reservations = netaddr.IPSet()
    existing_ip_reservations.add(str(sls_subnet.ipv4_gateway()))
    for ip_reservation in sls_subnet.reservations().values():
        existing_ip_reservations.add(str(ip_reservation.ipv4_address()))

    # Start looking for IPs after the gateway of the beginning of the subnet
    for available_ip in list(subnet[2:-2]):
        # If a starting IP was provided
        if starting_ip is not None and available_ip < starting_ip:
            continue

        if available_ip not in existing_ip_reservations:
            return available_ip

    # Exhausted available IP address
    raise ExhaustedAvailableIPAddressSpace()

def allocate_ip_address_in_subnet(action: dict, networks: NetworkManager, network_name: str, subnet_name: str, networks_allowed_in_dhcp_range: list=[]):

    network = networks[network_name]
    subnets = network.subnets()
    if subnet_name not in subnets:
        action_log(action, f"Error Network {network} does not have {subnet_name} subnet in SLS")
        print_action(action)
        sys.exit(1)

    bootstrap_dhcp_subnet = subnets[subnet_name]
    # If the subnet has been supernet hacked, then the unhacked CIDR will be returned. Otherwise none will be returned.
    unhacked_cidr = ipam.is_supernet_hacked(network.ipv4_network(), bootstrap_dhcp_subnet)
    if unhacked_cidr is not None:
        action_log(action, f'Info the bootstrap_dhcp subnet in the {network_name} network has been supernet hacked! Changing CIDR from {bootstrap_dhcp_subnet.ipv4_address()} to {unhacked_cidr} for IP address calculation')

    # The start of the static range begins two host IP addresses into the subnet, except for the CMN
    starting_ip = None
    if network_name == "CMN":
        starting_ip = None
        if "kubeapi-vip" in bootstrap_dhcp_subnet.reservations():
            # Fresh install case.
            starting_ip = netaddr.IPAddress(str(bootstrap_dhcp_subnet.reservations()["kubeapi-vip"].ipv4_address()))
        else:
            # Upgraded system case

            # Build up a list of IP addresses currently allocated in the Bootstrap DHCP subnet
            existing_ips = []
            for ip_reservation in bootstrap_dhcp_subnet.reservations().values():
                existing_ips.append(netaddr.IPAddress(str(ip_reservation.ipv4_address())))

            # First the first IP in the list
            starting_ip = existing_ips[0]

    # As the function says, find the next available IP in the bootstrap_dhcp subnet
    next_free_ip = find_next_available_ip(bootstrap_dhcp_subnet, cidr_override=unhacked_cidr, starting_ip=starting_ip)

    action_log(action, f'Allocated IP {next_free_ip} on the {network_name} network')

    # Not all subnets that require IPAM on them have DHCP (CHN), so we need to perform the static IP address range check for the ones that do
    if bootstrap_dhcp_subnet.dhcp_start_address() is not None:
        # Now verify the allocated IP is within the static IP range of the subnet.
        # The static range for NCNs is allocated at the beginning of the subnet till the first DHCPStart IP address
        dhcp_start = netaddr.IPAddress(str(bootstrap_dhcp_subnet.dhcp_start_address()))
        if dhcp_start <= next_free_ip:
            if network_name in networks_allowed_in_dhcp_range:
                action_log(action, f'Warning the allocated IP {next_free_ip} is outside of the static IP address range for the bootstrap_dhcp subnet in the {network_name} network')
            else:
                action_log(action, f'Error the allocated IP {next_free_ip} is outside of the static IP address range for the bootstrap_dhcp subnet in the {network_name} network')
                raise AllocatedIPIsOutsideStaticRange()

    return next_free_ip

#
# Command based Actions
#
class CommandAction:
    def __init__(self, command):
        self.command = command
        self.has_run = False
        self.return_code = -1
        self.stdout = None
        self.stderr = None

def print_command_action(action):
    if action.has_run:
        print(f'Ran:     {" ".join(action.command)}')
        if action.return_code != 0:
            print(f'         Failed: {action.return_code}')
            print(f'         stdout:\n{action.stdout}')
            print(f'         stderr:\n{action.stderr}')
    else:
        print(f'Planned: {" ".join(action.command)}')

def print_command_actions(actions):
    for action in actions:
        print_command_action(action)

def run_command(command):
    cmd = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result = cmd.communicate()
    stdout = None if not result[0] else result[0].decode('utf-8')
    stderr = None if not result[1] else result[1].decode('utf-8')
    return cmd.returncode, stdout, stderr

def run_command_action(command):
    command.return_code, command.stdout, command.stderr = run_command(command.command)
    command.has_run = True

def run_command_actions(command_actions):
    for command in command_actions:
        if command.has_run:
            pass
        else:
            run_command_action(command)
            print_command_action(command)

def create_update_etc_hosts_actions(existing_management_ncns, ncn_alias, ncn_xname, ncn_ips, bmc_ip, log_dir):
    command_actions = []

    ncn_aliases = list(map(lambda ncn: ncn["ExtraProperties"]["Aliases"][0], existing_management_ncns))
    for alias in ncn_aliases:
        scp_action = CommandAction(['scp', f'{alias}:/etc/hosts', f'{log_dir}/etc-hosts-{alias}'])
        command_actions.append(scp_action)

    hosts = ','.join(ncn_aliases)
    cp_backup_action = CommandAction(['pdsh', '-w', hosts,
                                        'cp', '/etc/hosts', f'/tmp/hosts.backup.{ncn_xname}.{ncn_alias}'])
    command_actions.append(cp_backup_action)

    # NCN IPs
    for network_name, ip in ncn_ips.items():
        line = f'{str(ip):15} {ncn_alias}.{network_name.lower()}'
        if network_name == "NMN":
            line += f' {ncn_alias}'

        sed_action = CommandAction(['pdsh', '-w', hosts,
                                    'sed', '-i', f"'$a{line}'", '/etc/hosts'])
        command_actions.append(sed_action)

    # BMC IPs
    line = f'{str(bmc_ip):15} {ncn_alias}-mgmt'
    sed_action = CommandAction(['pdsh', '-w', hosts,
                                'sed', '-i', f"'$a{line}'", '/etc/hosts'])
    command_actions.append(sed_action)

    return command_actions

#
# Logic that is shared between the allocate-ip and ncn-data sub-commands
#
class State:
    def __init__(self, ncn_xname: str=None, ncn_alias: str=None, ncn_subrole: str=None, log_directory: str=None, perform_changes: bool=False, networks_allowed_in_dhcp_range: list=[]):
        # NCN Information
        self.ncn_xname = ncn_xname
        self.ncn_alias = ncn_alias
        self.ncn_subrole = ncn_subrole
        self.ncn_ips = {}

        # Determine the bmc xname for the NCN
        self.bmc_xname = get_component_parent(ncn_xname)
        self.bmc_alias = f'{ncn_alias}-mgmt'
        self.bmc_ip = None

        # System information
        self.global_bootparameters = None
        self.sls_networks = None

        self.use_existing_ip_addresses = None
        self.log_directory = log_directory
        self.perform_changes = perform_changes
        self.networks_allowed_in_dhcp_range = networks_allowed_in_dhcp_range

    def retrieve_existing_ncn_ips(self, action: dict):
        #
        # Reuse existing IPs from SLS if this is ncn-[mws]-00[1-3]
        # Do not allocate a new BMC IP for ncn-[mws]-00[1-3]
        #
        action_log(action, f"Reusing existing IP addresses from SLS for {self.ncn_alias} and {self.bmc_alias}")

        bmc_ip = None
        ncn_ips = {}

        # Pull out existing IP addresses from BSS as it uses only the NCN alias, and no xnames.
        for host_record in self.global_bootparameters["cloud-init"]["meta-data"]["host_records"]:
            ip = netaddr.IPAddress(str(host_record["ip"]))
            for alias in host_record["aliases"]:
                if alias == self.bmc_alias:
                    # BMC IP Address
                    action_log(action, f'Found existing BMC IP Address for {self.bmc_alias} in BSS Global Bootparameters: {ip}')
                    bmc_ip = ip
                elif alias == self.ncn_alias:
                    # This is the NMN Alias, but the NMN has 2 aliases present.
                    continue
                elif alias.startswith(self.ncn_alias):
                    tokens = alias.split('.', 2)
                    network_name = tokens[1].upper()
                    action_log(action, f'Found existing NCN IP address for NCN {self.ncn_alias} in BSS Global Bootparameters: {host_record}')
                    ncn_ips[network_name] = ip

        if bmc_ip is None:
            action_log(action, f'Failed to find existing NCN BMC IP address for {self.bmc_alias} in BSS Global Bootparameters')
            print_action(action)
            sys.exit(1)

        # Validate each network that has a bootstrap_dhcp subnet that an IP Reservation exists for this NCN
        failed_to_find_ip = False
        for network_name, ncn_ip in ncn_ips.items():
            network = self.sls_networks[network_name]

            if "bootstrap_dhcp" not in network.subnets():
                continue
            dhcp_bootstrap = self.sls_networks[network_name].subnets()["bootstrap_dhcp"]

            reservation_found = False
            for name, reservation in dhcp_bootstrap.reservations().items():
                if str(ncn_ip) == str(reservation.ipv4_address()):
                    reservation_found = True
                    action_log(action, f'Removing existing IP Reservation with NCN IP {ncn_ip} in the bootstrap_dhcp subnet of the {network_name} network: {reservation.name()} {reservation.ipv4_address()} {reservation.aliases()} {reservation.comment()}')
                    del dhcp_bootstrap.reservations()[name]
                    break

            if not reservation_found:
                action_log(action, f"Error IP Reservation not found for {self.ncn_xname} ({self.ncn_alias}) in the bootstrap_dhcp subnet of the {network_name} network in SLS")
                failed_to_find_ip = True


        # Validate the HMN network has a BMC IP that has a bootstrap_dhcp subnet has an IP Reservation for this NCN
        reservation_found = False
        hmn_dhcp_bootstrap = self.sls_networks["HMN"].subnets()["bootstrap_dhcp"]
        for name, reservation in hmn_dhcp_bootstrap.reservations().items():
            if str(bmc_ip) == str(reservation.ipv4_address()):
                reservation_found = True
                action_log(action, f'Removing existing IP Reservation for {self.bmc_alias} in the bootstrap_dhcp subnet of the HMN network: {reservation.name()} {reservation.ipv4_address()} {reservation.aliases()} {reservation.comment()}')
                del hmn_dhcp_bootstrap.reservations()[name]
                break

        if not reservation_found:
            action_log(action, f"Error BMC IP Reservation for {self.bmc_alias} missing from the HMN bootstrap_dhcp subnet")
            failed_to_find_ip = True

        if failed_to_find_ip:
            print_action(action)
            sys.exit(1)

        # Update State
        self.ncn_ips = ncn_ips
        self.bmc_ip = bmc_ip

    def allocate_ncn_ips(self, action: dict,):
        #
        # Allocate new NCN BMC
        #
        action_log(action, "Allocating NCN BMC IP address")
        bmc_ip = None
        try:
            bmc_ip = allocate_ip_address_in_subnet(action, self.sls_networks, "HMN", "bootstrap_dhcp")
        except (AllocatedIPIsOutsideStaticRange, ExhaustedAvailableIPAddressSpace):
            print_action(action)
            sys.exit(1)

        # Add BMC IP reservation to the HMN network.
        # Example: {"Aliases":["ncn-s001-mgmt"],"Comment":"x3000c0s13b0","IPAddress":"10.254.1.31","Name":"x3000c0s13b0"}
        bmc_ip_reservation = IPReservation(self.bmc_xname, bmc_ip, comment=self.bmc_xname, aliases=[self.bmc_alias])
        action_log(action, f"Temporally adding NCN BMC IP reservation to bootstrap_dhcp subnet in the HMN network: {bmc_ip_reservation.to_sls()}")

        self.sls_networks["HMN"].subnets()["bootstrap_dhcp"].reservations().update(
            {
                bmc_ip_reservation.name(): bmc_ip_reservation
            }
        )

        #
        # Allocate new NCN IPs in SLS
        #
        action_log(action, "")
        action_log(action, "Allocating NCN IP addresses")

        ncn_ips = {}
        for network_name in ["CAN", "CHN", "CMN", "HMN", "MTL", "NMN"]:
            if network_name not in self.sls_networks:
                continue

            try:
                ncn_ips[network_name] = allocate_ip_address_in_subnet(action, self.sls_networks, network_name, "bootstrap_dhcp", self.networks_allowed_in_dhcp_range)
            except (AllocatedIPIsOutsideStaticRange, ExhaustedAvailableIPAddressSpace):
                print_action(action)
                sys.exit(1)

        action_log(action, "Removing temporary NCN BMC IP reservation in the bootstrap_dhcp subnet for the HMN network")
        del self.sls_networks["HMN"].subnets()["bootstrap_dhcp"].reservations()[bmc_ip_reservation.name()]

        # Update State
        self.ncn_ips = ncn_ips
        self.bmc_ip = bmc_ip
        self.action_log_ncn_ips(action)

        # Only for new IP addresses that have been allocated:
        # Validate the NCN and its BMC to be added does not have an IP reservation already defined for it
        # Also validate that none of the IP addresses we have allocated are currently in use in SLS.
        fail_sls_network_check = False
        for network_name, sls_network in self.sls_networks.items():
            for subnet in sls_network.subnets().values():
                for ip_reservation in subnet.reservations().values():
                    # Verify no IP Reservations exist for the NCN
                    if ip_reservation.name() == self.ncn_alias:
                        fail_sls_network_check = True
                        action_log(action, f'Error found existing NCN IP Reservation in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

                    # Verify no IP Reservations exist for the NCN BMC
                    if ip_reservation.name() == self.bmc_xname:
                        fail_sls_network_check = True
                        action_log(action, f'Error found existing NCN BMC IP Reservation in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

                    # Verify no IP Reservations exist with any NCN IP
                    if sls_network.name() in ncn_ips:
                        allocated_ip = ncn_ips[network_name]
                        if ip_reservation.ipv4_address() == allocated_ip:
                            fail_sls_network_check = True
                            action_log(action, f'Error found allocated NCN IP {allocated_ip} in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

                    # Verify no IP Reservations exist with the NCN BMC IP
                    if sls_network.name() == "HMN" and ip_reservation.ipv4_address() == bmc_ip:
                        fail_sls_network_check = True
                        action_log(action, f'Error found allocated NCN BMC IP {allocated_ip} in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

        if fail_sls_network_check:
            print_action(action)
            sys.exit(1)
        action_log(action, f'Pass {self.ncn_xname} ({self.ncn_alias}) does not currently exist in SLS Networks')
        action_log(action, f'Pass {self.bmc_xname} ({self.bmc_alias}) does not currently exist in SLS Networks')
        action_log(action, f'Pass allocated IPs for NCN {self.ncn_xname} ({self.ncn_alias}) are not currently in use in SLS Networks')
        action_log(action, f'Pass allocated IP for NCN BMC {self.bmc_xname} ({self.bmc_alias}) are not currently in use in SLS Networks')

    def action_log_ncn_ips(self, action: dict):
        action_log(action, "")
        action_log(action, "=================================")
        action_log(action, "Management NCN IP Allocation")
        action_log(action, "=================================")

        action_log(action, "Network | IP Address")
        action_log(action, "--------|-----------")
        for network in sorted(self.ncn_ips):
            ip = self.ncn_ips[network]
            action_log(action, f'{network:<8}| {ip}')

        action_log(action, "")
        action_log(action, "=================================")
        action_log(action, "Management NCN BMC IP Allocation")
        action_log(action, "=================================")

        action_log(action, "Network | IP Address")
        action_log(action, "--------|-----------")
        action_log(action, f'HMN     | {self.bmc_ip}')
        action_log(action, "")

    def print_ncn_ips(self):
        print("")
        print("        =================================")
        print("        Management NCN IP Allocation")
        print("        =================================")

        print("        Network | IP Address")
        print("        --------|-----------")
        for network in sorted(self.ncn_ips):
            ip = self.ncn_ips[network]
            print(f'        {network:<8}| {ip}')

        print("")
        print("        =================================")
        print("        Management NCN BMC IP Allocation")
        print("        =================================")

        print("        Network | IP Address")
        print("        --------|-----------")
        print(f'        HMN     | {self.bmc_ip}')
        print("")

    def validate_global_bss_bootparameters(self, action: dict):
        if not self.use_existing_ip_addresses:
            # Validate the NCN is not referenced in the Global boot parameters
            fail_host_records = False
            for host_record in self.global_bootparameters["cloud-init"]["meta-data"]["host_records"]:
                # Check for NCN and NCN BMC
                for alias in host_record["aliases"]:
                    if alias.startswith(self.ncn_alias):
                        action_log(action, f'Error found NCN alias in Global host_records in BSS: {host_record}')
                        fail_host_records = True

                # Check for if this IP is one of our allocated IPs
                for network, ip in self.ncn_ips.items():
                    if host_record["ip"] == ip:
                        action_log(action, f'Error found {network} IP Address {ip} in Global host_records in BSS: {host_record}')
                        fail_host_records = True


                if host_record["ip"] == self.bmc_ip:
                    action_log(action, f'Error found NCN BMC IP Address {self.bmc_ip} in Global host_records in BSS: {host_record}')
                    fail_host_records = True


            if fail_host_records:
                print_action(action)
                sys.exit(1)
            action_log(action, f"Pass {self.ncn_xname} does not currently exist in BSS Global host_records")
            print_action(action)
        else:
            # Validate the NCN has the expected data in the BSS Global boot parameters
            fail_host_records = False
            for host_record in self.global_bootparameters["cloud-init"]["meta-data"]["host_records"]:
                for network_name, ip in self.ncn_ips.items():
                    # Verify each NCN IP is associated with correct NCN
                    expected_alias = f'{self.ncn_alias}.{network_name.lower()}'
                    if str(ip) == host_record["ip"]:
                        expected_aliases = [expected_alias]
                        alternate_aliases = [] # ncn-m001 on the NMN can have an alternate host record for the PIT
                        if network_name == "NMN":
                            expected_aliases.append(self.ncn_alias)
                            alternate_aliases = ["pit", "pit.nmn"]

                        if expected_aliases == host_record["aliases"] or alternate_aliases == host_record["aliases"]:
                            action_log(action, f"Pass found existing host_record with the IP address {ip} which contains the expected aliases of {expected_aliases}")
                        else:
                            fail_host_records = True
                            action_log(action, f'Error existing host_record with IP address {ip} with aliases {host_record["aliases"]}, instead of {expected_aliases}')

                    # Verify each NCN alias is associated with the correct IP
                    if expected_alias in host_record["aliases"]:
                        if str(ip) == host_record["ip"]:
                            action_log(action, f"Pass found existing host_record for alias {expected_alias} which has the expected IP address of {ip}")
                        else:
                            fail_host_records = True
                            action_log(action, f'Error existing host_record for alias {expected_alias} has the IP address of {host_record["ip"]}, instead of the expected {ip}')




                # Verify the NCN BMC IP is associated with correct BMC
                if str(self.bmc_ip) == host_record["ip"]:
                    expected_aliases = [self.bmc_alias]
                    if expected_aliases == host_record["aliases"]:
                        action_log(action, f"Pass found existing BMC host_record with the IP address {self.bmc_ip} which contains the expected aliases of {expected_aliases}")
                    else:
                        fail_host_records = True
                        action_log(action, f'Error existing BMC host_record with IP address {self.bmc_ip} with aliases {host_record["aliases"]}, instead of {expected_aliases}')


                if self.bmc_alias in host_record["aliases"]:
                    if str(self.bmc_ip) == host_record["ip"]:
                        action_log(action, f"Pass found existing BMC host_record for alias {self.bmc_alias} which has the expected IP address of {self.bmc_ip}")
                    else:
                        fail_host_records = True
                        action_log(action, f'Error existing BMC host_record for alias {expected_alias} has the IP address of {host_record["ip"]}, instead of the expected {self.bmc_ip}')


            if fail_host_records:
                print_action(action)
                sys.exit(1)

        # Validate the NCN being added is not configured as the 'first-master-hostname'
        first_master_hostname = self.global_bootparameters["cloud-init"]["meta-data"]["first-master-hostname"]
        if first_master_hostname == self.ncn_alias:
            action_log(action, f'Error the NCN being added {self.ncn_alias} is currently configured as the "first-master-hostname" in the Global BSS Bootparameters')
            print_action(action)
            sys.exit(1)
        else:
            action_log(action, f'Pass the NCN being added {self.ncn_alias} is not configured as the "first-master-hostname", currently {first_master_hostname} is in the Global BSS Bootparameters.')

        print_action(action)

    def update_sls_networking(self, session: requests.Session):
        # Add IP Reservations for all of the networks that make sense
        for network_name, ip in self.ncn_ips.items():
            sls_network = self.sls_networks[network_name]
            # CAN
            # Master:  {"Aliases":["ncn-m002-can","time-can","time-can.local"],"Comment":"x3000c0s3b0n0","IPAddress":"10.101.5.134","Name":"ncn-m002"}
            # Worker:  {"Aliases":["ncn-w001-can","time-can","time-can.local"],"Comment":"x3000c0s7b0n0","IPAddress":"10.101.5.136","Name":"ncn-w001"}
            # Storage: {"Aliases":["ncn-s001-can","time-can","time-can.local"],"Comment":"x3000c0s13b0n0","IPAddress":"10.101.5.147","Name":"ncn-s001"}

            # CHN
            # Master:  {"Aliases":["ncn-m002-chn","time-chn","time-chn.local"],"Comment":"x3000c0s3b0n0","IPAddress":"10.101.5.198","Name":"ncn-m002"}
            # Worker:  {"Aliases":["ncn-w001-chn","time-chn","time-chn.local"],"Comment":"x3000c0s7b0n0","IPAddress":"10.101.5.200","Name":"ncn-w001"}
            # Storage: {"Aliases":["ncn-s001-chn","time-chn","time-chn.local"],"Comment":"x3000c0s13b0n0","IPAddress":"10.101.5.211","Name":"ncn-s001"}

            # CMN
            # Master:  {"Aliases":["ncn-m002-cmn","time-cmn","time-cmn.local"],"Comment":"x3000c0s3b0n0","IPAddress":"10.101.5.20","Name":"ncn-m002"}
            # Worker:  {"Aliases":["ncn-w001-cmn","time-cmn","time-cmn.local"],"Comment":"x3000c0s7b0n0","IPAddress":"10.101.5.22","Name":"ncn-w001"}
            # Storage: {"Aliases":["ncn-s001-cmn","time-cmn","time-cmn.local"],"Comment":"x3000c0s13b0n0","IPAddress":"10.101.5.33","Name":"ncn-s001"}

            # HMN
            # Master:  {"Aliases":["ncn-m002-hmn","time-hmn","time-hmn.local"],"Comment":"x3000c0s3b0n0","IPAddress":"10.254.1.6","Name":"ncn-m002"}
            # Worker:  {"Aliases":["ncn-w001-hmn","time-hmn","time-hmn.local"],"Comment":"x3000c0s7b0n0","IPAddress":"10.254.1.10","Name":"ncn-w001"}
            # Storage: {"Aliases":["ncn-s001-hmn","time-hmn","time-hmn.local","rgw-vip.hmn"],"Comment":"x3000c0s13b0n0","IPAddress":"10.254.1.32","Name":"ncn-s001"}

            # MTL
            # Master:  {"Aliases":["ncn-m002-mtl","time-mtl","time-mtl.local"],"Comment":"x3000c0s3b0n0","IPAddress":"10.1.1.3","Name":"ncn-m002"}
            # Worker:  {"Aliases":["ncn-w001-mtl","time-mtl","time-mtl.local"],"Comment":"x3000c0s7b0n0","IPAddress":"10.1.1.5","Name":"ncn-w001"}
            # Storage: {"Aliases":["ncn-s001-mtl","time-mtl","time-mtl.local"],"Comment":"x3000c0s13b0n0","IPAddress":"10.1.1.16","Name":"ncn-s001"}

            # NMN
            # Master:  {"Aliases":["ncn-m002-nmn","time-nmn","time-nmn.local","x3000c0s3b0n0","ncn-m002.local"],"Comment":"x3000c0s3b0n0","IPAddress":"10.252.1.5","Name":"ncn-m002"}
            # Worker:  {"Aliases":["ncn-w001-nmn","time-nmn","time-nmn.local","x3000c0s7b0n0","ncn-w001.local"],"Comment":"x3000c0s7b0n0","IPAddress":"10.252.1.7","Name":"ncn-w001"}
            # Storage: {"Aliases":["ncn-s001-nmn","time-nmn","time-nmn.local","x3000c0s13b0n0","ncn-s001.local"],"Comment":"x3000c0s13b0n0","IPAddress":"10.252.1.18","Name":"ncn-s001"}

            # Generalizations
            # - All IP reservations have the NCN xname for the comment
            # - Following rules apply to all but CHN
            #   - NCN Alias is the IP reservation name
            #   - Each master/worker/storage have the following aliases
            #     - ncn-{*}-{network}
            #     - time-{network}
            #     - time-{network}.local
            # - Storage nodes on the HMN have additional alias rgw-vip.hmn
            # - All NCNs on the NMN have the additional aliases:
            #   - xname
            #   - ncn-{*}.local
            # - The CHN
            #   - No reservations
            #   - have IP reservations with the node xname for the reservation name

            # All networks except for the CHN have the NCNs alias as the name for the reservation. The CHN has the node xname.
            name = self.ncn_alias

            # All NCN types have their xname as the comment for their IP reservation
            comment = self.ncn_xname

            # For all networks except the CHN the following aliases are present
            #   - ncn-{*}-{network}
            #   - time-{network}
            #   - time-{network}.local
            aliases = [
                f'{self.ncn_alias}-{network_name.lower()}',
                f'time-{network_name.lower()}',
                f'time-{network_name.lower()}.local'
            ]

            # Storage nodes on the HMN have additional alias rgw-vip.hmn
            if network_name == "HMN" and self.ncn_subrole == "Storage":
                aliases.append("rgw-vip.hmn")

            # All NCNs on the NMN have the additional aliases:
            # - xname
            # - ncn-{*}.local
            if network_name == "NMN":
                aliases.append(self.ncn_xname)
                aliases.append(f'{self.ncn_alias}.local')

            ip_reservation = IPReservation(name, ip, aliases=aliases, comment=comment)

            print(f"Adding NCN IP reservation to bootstrap_dhcp subnet in the {network_name} network")
            print(json.dumps(ip_reservation.to_sls(), indent=2))

            # Add the reservation to the subnet
            sls_network.subnets()["bootstrap_dhcp"].reservations().update(
                {
                    ip_reservation.name(): ip_reservation
                }
            )

            if network_name == "HMN":
                # Add BMC IP reservation to the HMN network.
                # Example: {"Aliases":["ncn-s001-mgmt"],"Comment":"x3000c0s13b0","IPAddress":"10.254.1.31","Name":"x3000c0s13b0"}
                bmc_ip_reservation = IPReservation(self.bmc_xname, self.bmc_ip, comment=self.bmc_xname, aliases=[self.bmc_alias])
                print("Adding NCN BMC IP reservation to bootstrap_dhcp subnet in the HMN network")
                print(json.dumps(bmc_ip_reservation.to_sls(), indent=2))

                sls_network.subnets()["bootstrap_dhcp"].reservations().update(
                    {
                        bmc_ip_reservation.name(): bmc_ip_reservation
                    }
                )

            print(f"Updating {network_name} network in SLS with updated IP reservations")
            if self.perform_changes:
                action = http_put(session, f'{SLS_URL}/networks/{network_name}', payload=sls_network.to_sls())
                if action["error"] is not None:
                    action_log(action, f'Error failed to update {network_name} in SLS')
                    print_action(action)
                    sys.exit(1)
                print_action(action)
            else:
                print("Skipping due to dry run!")

    def update_global_bss_host_records(self, session: requests.Session):
        #
        # Update Global host_records in BSS with IPs
        #

        # Add NCN IPs
        for network_name, ip in self.ncn_ips.items():
            # For the different networks the master, worker, and storage nodes follow the same pattern
            # CAN: {"aliases":["ncn-m001.can"],"ip":"10.101.5.133"}
            # CHN: {"aliases":["ncn-m001.chn"],"ip":"10.101.5.197"}
            # CMN: {"aliases":["ncn-m001.cmn"],"ip":"10.101.5.19"}
            # HMN: {"aliases":["ncn-w001.hmn"],"ip":"10.254.1.10"}
            # NMN: {"aliases":["ncn-m001.nmn","ncn-m001"],"ip":"10.252.1.4"}
            # MTL: {"aliases":["ncn-w001.mtl"],"ip":"10.1.1.5"}

            host_record = {
                "aliases": [f'{self.ncn_alias}.{network_name.lower()}'],
                "ip": str(ip),
            }

            if network_name == "NMN":
                host_record["aliases"].append(self.ncn_alias)

            print(f"Adding NCN IP reservation for the {network_name} network to Global host_records in BSS")
            print(json.dumps(host_record, indent=2))

            self.global_bootparameters["cloud-init"]["meta-data"]["host_records"].append(host_record)

        # Add BMC IP
        # {"aliases":["ncn-m001-mgmt"],"ip":"10.254.1.3"}
        host_record = {
            "aliases": [self.bmc_alias],
            "ip": str(self.bmc_ip),
        }

        print("Adding NCN BMC IP reservation for the HMN Network to Global host_records in BSS")
        print(json.dumps(host_record, indent=2))
        self.global_bootparameters["cloud-init"]["meta-data"]["host_records"].append(host_record)

        print("Updating Global bootparameters in BSS with updated host records")
        print(json.dumps(host_record, indent=2))
        if self.perform_changes:
            put_bss_bootparameters(session, self.global_bootparameters)
        else:
            print("Skipping due to dry run!")

#
# Sub commands
#

def allocate_ips_command(session: requests.Session, args, state: State):
    print("Allocating NCN IP addresses")

    # If the NCN is one of the first 9 NCNs we need to retain the IP addresses (and expect them to be present) in SLS
    # This simplifies a few things:
    # - The Ceph MONs and MGRs running on the first 3 storage node need to have the IPs stay the same
    # - The IP addresses of the first 9 NCNs are present in the chrony config file. If we don't change them, then we don't have to update that file.
    state.use_existing_ip_addresses = re.match("^ncn-[mws]00[1-3]$", state.ncn_alias)

    print("Performing validation checks against SLS")
    # Verify that the NCN xname does not exist in SLS. This could be an no-op if what is in SLS matches what we want to put in
    verify_sls_hardware_not_found(session, args.xname)

    # Retrieve all Management NCNs from SLS
    action, existing_management_ncns = get_sls_management_ncns(session)

    # Verify that the alias is unique
    existing_management_ncns = sorted(existing_management_ncns, key=lambda d: d["ExtraProperties"]["Aliases"][0])
    for node in existing_management_ncns:
        for alias in node["ExtraProperties"]["Aliases"]:
            if alias == args.alias:
                action_log(action, f'Error the provided alias {state.ncn_alias} is already in use by {node["Xname"]}')
                print_action(action)
                sys.exit(1)

    action_log(action, f"Pass the alias {state.ncn_alias} is unique to {state.ncn_xname} in SLS Hardware")
    print_action(action)

    # Retrieve all Management NCNs from SLS
    action, existing_management_ncns = get_sls_management_ncns(session)

    # Verify that the alias is unique
    existing_management_ncns = sorted(existing_management_ncns, key=lambda d: d["ExtraProperties"]["Aliases"][0])
    for node in existing_management_ncns:
        for alias in node["ExtraProperties"]["Aliases"]:
            if alias == args.alias:
                action_log(action, f'Error the provided alias {state.ncn_alias} is already in use by {node["Xname"]}')
                print_action(action)
                sys.exit(1)

    action_log(action, f"Pass the alias {state.ncn_alias} is unique to {state.ncn_xname} in SLS Hardware")
    print_action(action)

    # Retrieve all Network data from SLS
    action, global_bootparameters = get_bss_bootparameters(session, "Global")
    state.global_bootparameters = global_bootparameters
    print_action(action)

    validate_sls = False
    action, sls_networks = get_sls_networks(session, validate=validate_sls)
    state.sls_networks = sls_networks

    #
    # Determine NCN IPs
    #
    if state.use_existing_ip_addresses:
        #
        # Reuse existing IPs from SLS if this is ncn-[mws]-00[1-3]
        # Do not allocate a new BMC IP for ncn-[mws]-00[1-3]
        #
        state.retrieve_existing_ncn_ips(action)
    else:
        #
        # Allocate new NCN BMC
        #
        state.allocate_ncn_ips(action)


    state.action_log_ncn_ips(action)

    if not state.use_existing_ip_addresses:
        # Only for new IP addresses that have been allocated:
        # Validate the NCN and its BMC to be added does not have an IP reservation already defined for it
        # Also validate that none of the IP addresses we have allocated are currently in use in SLS.
        fail_sls_network_check = False
        for network_name, sls_network in sls_networks.items():
            for subnet in sls_network.subnets().values():
                for ip_reservation in subnet.reservations().values():
                    # Verify no IP Reservations exist for the NCN
                    if ip_reservation.name() == state.ncn_alias:
                        fail_sls_network_check = True
                        action_log(action, f'Error found existing NCN IP Reservation in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

                    # Verify no IP Reservations exist for the NCN BMC
                    if ip_reservation.name() == state.bmc_xname:
                        fail_sls_network_check = True
                        action_log(action, f'Error found existing NCN BMC IP Reservation in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

                    # Verify no IP Reservations exist with any NCN IP
                    if sls_network.name() in state.ncn_ips:
                        allocated_ip = state.ncn_ips[network_name]
                        if ip_reservation.ipv4_address() == allocated_ip:
                            fail_sls_network_check = True
                            action_log(action, f'Error found allocated NCN IP {allocated_ip} in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

                    # Verify no IP Reservations exist with the NCN BMC IP
                    if sls_network.name() == "HMN" and ip_reservation.ipv4_address() == state.bmc_ip:
                        fail_sls_network_check = True
                        action_log(action, f'Error found allocated NCN BMC IP {allocated_ip} in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')

        if fail_sls_network_check:
            print_action(action)
            sys.exit(1)
        action_log(action, f'Pass {state.ncn_xname} ({state.ncn_alias}) does not currently exist in SLS Networks')
        action_log(action, f'Pass {state.bmc_xname} ({state.bmc_alias}) does not currently exist in SLS Networks')
        action_log(action, f'Pass allocated IPs for NCN {state.ncn_xname} ({state.ncn_alias}) are not currently in use in SLS Networks')
        action_log(action, f'Pass allocated IP for NCN BMC {state.bmc_xname} ({state.bmc_alias}) are not currently in use in SLS Networks')

    print_action(action)

    #
    # Validate contents of HSM
    #
    print("Performing validation checks against HSM")

    # Validate HSM does not contain any EthernetInterfaces for the NCN to be added
    action = verify_hsm_inventory_ethernet_interface_not_found(session, component_id=state.ncn_xname)
    action_log(action, f'Pass no EthernetInterfaces are associated with {args.xname} in HSM')
    print_action(action)

    # Validate HSM does not contain any EthernetInterfaces for the NCN BMC to be added
    action = verify_hsm_inventory_ethernet_interface_not_found(session, component_id=state.bmc_xname)
    action_log(action, f'Pass no EthernetInterfaces are associated with {state.bmc_xname} in HSM')
    print_action(action)

    # Validate allocated IPs are not in use in the HSM EthernetInterfaces table
    for network, ip in state.ncn_ips.items():
        action, found_ethernet_interfaces = search_hsm_inventory_ethernet_interfaces(session, ip_address=ip)
        if len(found_ethernet_interfaces) == 0:
            action_log(action, f"Pass {network} IP address {ip} is not currently in use in HSM Ethernet Interfaces")
        else:
            # An IP address that has been allocated for the NCN is present in HSM.
            # If the component ID is not set, then this is not a real IP reservation and can be removed, as it is most likely
            # cruft from the past that was not cleaned up.
            for found_ie in found_ethernet_interfaces:
                if found_ie["ComponentID"] == "":
                    print(f'Removing stale Ethernet Interface from HSM: {found_ie}')
                    if state.perform_changes:
                        delete_hsm_inventory_ethernet_interfaces(session, found_ie)
                    else:
                        print("Skipping due to dry run!")
                else:
                    action_log(action, f'Error found EthernetInterfaces with allocated IP address {ip} in HSM: {found_ie}')
                    print_action(action)
                    sys.exit(1)

        print_action(action)

    # Validate NCN does not exist under state components
    verify_hsm_state_components_not_found(session, state.ncn_xname)

    # Validate the BMC of the NCN does not exist under state components
    verify_hsm_state_components_not_found(session, state.bmc_xname)

    # Validate the BMC of the NCN does not exist under inventory redfish endpoints
    verify_hsm_inventory_redfish_endpoints_not_found(session, state.bmc_xname)

    #
    # Validate contents of BSS
    #
    print("Performing validation checks against BSS")

    # Validate the NCN has no bootparameters
    verify_bss_bootparameters_not_found(session, args.xname)

    # Retrieve the global boot parameters
    action, global_bootparameters = get_bss_bootparameters(session, "Global")
    state.global_bootparameters = global_bootparameters

    state.validate_global_bss_bootparameters(action)

    #
    # Update SLS networking for the new NCN
    #
    state.update_sls_networking(session)

    #
    # Update Global host_records in BSS with IPs
    #
    if not state.use_existing_ip_addresses:
        state.update_global_bss_host_records(session)

    #
    # Update /etc/hosts on the NCNs with the newly allocated IPs
    #
    etc_hosts_actions = []
    if not args.skip_etc_hosts:
        if not state.use_existing_ip_addresses:
            print("Updating /etc/hosts with NCN IPs")
            etc_hosts_actions = create_update_etc_hosts_actions(
                existing_management_ncns=existing_management_ncns,
                ncn_alias=state.ncn_alias,
                ncn_xname=state.ncn_xname,
                ncn_ips=state.ncn_ips,
                bmc_ip=state.bmc_ip,
                log_dir=state.log_directory
            )
            print_command_actions(etc_hosts_actions)
        else:
            print('Leaving /etc/hosts unchanged')

        if args.perform_changes:
            run_command_actions(etc_hosts_actions)

    print('')
    print(f'IP Addresses have been allocated for {args.xname} ({args.alias}) and been added to SLS and BSS')
    if not args.perform_changes:
        print('        WARNING A Dryrun was performed, and no changes were performed to the system')

    state.print_ncn_ips()

def ncn_data_command(session: requests.Session, args, state: State):
    print("Adding NCN specific data to SLS, HSM, and BSS!")

    # We Expect IPs to exist already in SLS
    state.use_existing_ip_addresses = True

        # Validate provided BMC MgmtSwitchConnector (used by ncn-data)
    is_m001 = args.alias == "ncn-m001"
    bmc_mgmt_switch_connector_provided = args.bmc_mgmt_switch_connector is not None
    bmc_connected_to_hmn = True
    if is_m001 and not bmc_mgmt_switch_connector_provided:
        # This is acceptable as typically the BMC of ncn-m001 does not have a connection to the HMN, but the HMN.
        print("The BMC of ncn-m001 is not connected to the HMN")
        bmc_connected_to_hmn = False
    elif args.bmc_mgmt_switch_connector is None:
        print(f'Error --bmc-mgmt-switch-connector not provided, the BMC of {state.ncn_alias} is expected to be connected to the HMN')
        sys.exit(1)
    elif re.match("^x([0-9]{1,4})c([0-7])w([1-9][0-9]*)j([1-9][0-9]*)$", args.bmc_mgmt_switch_connector) is None:
        # All NCNs except for ncn-m001 need to has a MgmtSwitchConnector provided for its BMC.
        print("Invalid MgmtSwitchConnector xname provided: ", state.xname, ", expected format xXcCwWjJ")
        sys.exit(1)


    # Validate provided MAC address
    # - Verify MAC addresses are in expected format
    # - Verify that mgmt0 and mgmt3, or mgmt0 and mgm1 are provided.

    # MAC Address problem
    # metal-ipxe finds all MAC addresses via and gives then names like mgmt0, lan0 or hsn0
    # https://github.com/Cray-HPE/metal-ipxe/blob/main/script.ipxe#L77
    #
    # When the nodes boot with metal-ipxe they get the mgmt0 lan0, hsn0 assigned.
    #
    # Example what gets found:
    # ncn-w001:~ # ip -j address  | jq '.[]' -c | egrep '"(mgmt|hsn|lan)' | jq '{ifname: .ifname, address: .address}' -c
    # {"ifname":"mgmt0","address":"a4:bf:01:38:e9:36"}
    # {"ifname":"mgmt1","address":"a4:bf:01:38:e9:36"}
    # {"ifname":"hsn0","address":"ec:0d:9a:d9:c4:5a"}
    # {"ifname":"lan0","address":"b8:59:9f:f9:27:e2"}
    # {"ifname":"lan1","address":"b8:59:9f:f9:27:e3"}

    macs = {}
    if args.mac_mgmt0 is not None:
        macs["mgmt0"] = args.mac_mgmt0
    if args.mac_mgmt1 is not None:
        macs["mgmt1"] = args.mac_mgmt1
    if args.mac_sun0 is not None:
        macs["sun0"] = args.mac_sun0
    if args.mac_sun0 is not None:
        macs["sun1"] = args.mac_sun1
    if not is_m001:
        if args.mac_lan0 is not None:
            macs["lan0"] = args.mac_lan0
        if args.mac_lan1 is not None:
            macs["lan1"] = args.mac_lan1
        if args.mac_lan2 is not None:
            macs["lan2"] = args.mac_lan2
        if args.mac_lan3 is not None:
            macs["lan3"] = args.mac_lan3
        if args.mac_hsn0 is not None:
            macs["hsn0"] = args.mac_hsn0
        if args.mac_hsn1 is not None:
            macs["hsn1"] = args.mac_hsn1

    # Normalize MACs
    for interface in macs.copy():
        macs[interface] = macs[interface].lower()

    # Validate MAC addresses format
    for interface, mac in macs.items():
        if not re.match("[0-9a-f]{2}([-:]?)[0-9a-f]{2}(\\1[0-9a-f]{2}){4}$", mac):
            print(f'Invalid NCN MAC address provided for {interface}: {mac}')
            sys.exit(1)

    # Validate BMC MAC address
    bmc_mac = args.mac_bmc
    if (bmc_mac is not None) and (not re.match("[0-9a-f]{2}([-:]?)[0-9a-f]{2}(\\1[0-9a-f]{2}){4}$", bmc_mac)):
        print(f'Invalid BMC MAC address provided: {bmc_mac}')
        sys.exit(1)

    # Verify all MACs provided are unique
    unique_macs = []
    for interface, mac in macs.items():
        if mac in unique_macs:
            print(f'Error MAC Address {mac} provided for NCN interface {interface} is not unique')
            sys.exit(1)
        unique_macs.append(mac)

    if bmc_mac in unique_macs:
        print(f'Error BMC MAC Address {bmc_mac} provided is not unique')
        sys.exit(1)

    if not is_m001 and bmc_mac is None:
        print(f'Error a BMC MAC address is required for {state.ncn_alias}')
        sys.exit(1)

    # If this a worker, then a MAC address for hsn0 needs to be provided
    if (state.ncn_subrole == "Worker") and ("hsn0" not in macs):
        print("Error hsn0 MAC address not provided for worker management NCN. At least 1 HSN MAC address is required")
        sys.exit(1)

    # Either mgmt0 and mgmt1, or mgmt0, mgmt1, sun0, sun1 need to be provided
    # TODO Do we want to use the wording for BOND0 MAC 0, and BOND0 MAC 1?
    # TODO the naming of interfaces changes between CSM 1.0 and CSM 1.2. The following is for CSM 1.0.
    if ("mgmt0" in macs) and ("mgmt1" in macs):
        # Both ports of a single card are used to form bond0
        # TODO mgmt0 < mgmt1
        print("Bond0 will be formed across mgmt0 and mgmt1")
    elif ("mgmt0" in macs) and ("mgmt1" in macs) and ("sun0" in macs) and ("sun1" in macs):
        # The lower MAC address of each card is used to form bond0 for mgmt0/sun0
        # The higher MAC address of each card is used to form bond1 for mgmt1/sun1
        # TODO mgmt0 < sun0
        # TODO mgmt1 < sun1
        print("Bond0 will be formed across mgmt0 and mgmt2")
    else:
        print("Invalid combination of mgmt/sun MAC addresses provided")
        sys.exit(1)


    print("Performing validation checks against SLS")
    # Verify that the NCN xname does not exist in SLS. This could be an no-op if what is in SLS matches what we want to put in
    verify_sls_hardware_not_found(session, state.ncn_xname)

    if args.alias != "ncn-m001":
        # Verify that the MgmtSwitchConnector does not exist in SLS. This could be an no-op if what is in SLS matches what we want to put in
        verify_sls_hardware_not_found(session, args.bmc_mgmt_switch_connector)

    # Retrieve all Management NCNs from SLS
    action, existing_management_ncns = get_sls_management_ncns(session)

    # Verify that the alias is unique
    existing_management_ncns = sorted(existing_management_ncns, key=lambda d: d["ExtraProperties"]["Aliases"][0])
    for node in existing_management_ncns:
        for alias in node["ExtraProperties"]["Aliases"]:
            if alias == args.alias:
                action_log(action, f'Error the provided alias {state.ncn_alias} is already in use by {node["Xname"]}')
                print_action(action)
                sys.exit(1)

    action_log(action, f"Pass the alias {state.ncn_alias} is unique to {state.ncn_xname} in SLS Hardware")
    print_action(action)

    mgmt_switch_xname = None
    mgmt_switch_brand = None
    mgmt_switch_alias = None
    if not is_m001:
        # Verify the MgmtSwitchConnector is apart of a MgmtSwitch that is already present in SLS
        mgmt_switch_xname = get_component_parent(args.bmc_mgmt_switch_connector)
        action, mgmt_switch = get_sls_hardware(session, mgmt_switch_xname)

        mgmt_switch_brand = mgmt_switch["ExtraProperties"]["Brand"]
        mgmt_switch_alias = mgmt_switch["ExtraProperties"]["Aliases"][0]

        action_log(action, f'Management Switch Xname: {mgmt_switch_xname}')
        action_log(action, f'Management Switch Brand: {mgmt_switch_brand}')
        action_log(action, f'Management Switch Alias: {mgmt_switch_alias}')
        print_action(action)

    # Allocate new NID for the NCN
    allocated_nids = []
    for node in existing_management_ncns:
        allocated_nids.append(node["ExtraProperties"]["NID"])

    starting_nid=100001
    nid = min(set(range(starting_nid, max(allocated_nids)+2)) - set(allocated_nids))
    print("Allocated NID: ", nid)

    # Retrieve all Network data from SLS
    action, global_bootparameters = get_bss_bootparameters(session, "Global")
    state.global_bootparameters = global_bootparameters
    print_action(action)

    validate_sls = False
    action, sls_networks = get_sls_networks(session, validate=validate_sls)
    state.sls_networks = sls_networks

    #
    # Determine NCN IPs
    #
    if state.use_existing_ip_addresses:
        #
        # Reuse existing IPs from SLS if this is ncn-[mws]-00[1-3]
        # Do not allocate a new BMC IP for ncn-[mws]-00[1-3]
        #
        state.retrieve_existing_ncn_ips(action)
    else:
        #
        # Allocate new NCN BMC
        #
        state.allocate_ncn_ips(action)

    print_action(action)

    #
    # Validate contents of HSM
    #
    print("Performing validation checks against HSM")

    # Validate HSM does not contain any EthernetInterfaces for the NCN to be added
    action = verify_hsm_inventory_ethernet_interface_not_found(session, component_id=args.xname)
    action_log(action, f'Pass no EthernetInterfaces are associated with {args.xname} in HSM')
    print_action(action)

    # Validate HSM does not contain any EthernetInterfaces for the NCN BMC to be added
    action = verify_hsm_inventory_ethernet_interface_not_found(session, component_id=state.bmc_xname)
    action_log(action, f'Pass no EthernetInterfaces are associated with {state.bmc_xname} in HSM')
    print_action(action)

    # Validate HSM does not contain any EthernetInterfaces for the provided NCN MAC Addresses
    for interface, mac in macs.items():
        action = verify_hsm_inventory_ethernet_interface_not_found(session, mac_address=mac)
        action_log(action, f"Pass {interface} MAC address {mac} is not currently present in HSM Ethernet Interfaces")
        print_action(action)

    # Validate allocated IPs are not in use in the HSM EthernetInterfaces table
    for network, ip in state.ncn_ips.items():
        action, found_ethernet_interfaces = search_hsm_inventory_ethernet_interfaces(session, ip_address=ip)
        if len(found_ethernet_interfaces) == 0:
            action_log(action, f"Pass {network} IP address {ip} is not currently in use in HSM Ethernet Interfaces")
        else:
            # An IP address that has been allocated for the NCN is present in HSM.
            # If the component ID is not set, then this is not a real IP reservation and can be removed, as it is most likely
            # cruft from the past that was not cleaned up.
            for found_ie in found_ethernet_interfaces:
                if found_ie["ComponentID"] == "":
                    print(f'Removing stale Ethernet Interface from HSM: {found_ie}')
                    if state.perform_changes:
                        delete_hsm_inventory_ethernet_interfaces(session, found_ie)
                    else:
                        print("Skipping due to dry run!")
                else:
                    action_log(action, f'Error found EthernetInterfaces with allocated IP address {ip} in HSM: {found_ie}')
                    print_action(action)
                    sys.exit(1)

        print_action(action)

    # Check to see if the BMC MAC address exists in HSM
    existing_bmc_ip = None
    if bmc_connected_to_hmn:
        # KEA Check
        action, existing_bmc_leases = get_kea_lease4_get_by_hw_address(session, bmc_mac)
        if len(existing_bmc_leases) == 0:
            action_log(action, "BMC MAC address is not associated with a DHCP lease in KEA")
        elif len(existing_bmc_leases) == 1:
            action_log(action, f'BMC MAC address associated with KEA DHCP lease: {existing_bmc_leases[0]}')
            existing_bmc_ip = existing_bmc_leases[0]["ip-address"]
        else:
            action_log(action, "Fail BMC MAC address is associated with multiple KEA DHCP lease: ", existing_bmc_leases)
            print_action(action)
            sys.exit(1)

    # Validate allocated BMC IP is not in use in the HSM EthernetInterfaces table
    # If the MAC Address associated with the BMC is already at the right IP, then we are good.
    existing_bmc_ip_matches = False
    if existing_bmc_ip is not None:
        existing_bmc_ip_matches = existing_bmc_ip == str(state.bmc_ip)

    if not existing_bmc_ip_matches:
        action, found_ethernet_interfaces = search_hsm_inventory_ethernet_interfaces(session, ip_address=state.bmc_ip)
        # An IP address that has been allocated for the NCN BMC is present in HSM.
        # If the component ID is not set, then this is not a real IP reservation and can be removed, as it is most likely
        # cruft from the past that was not cleaned up.
        for found_ie in found_ethernet_interfaces:
            if found_ie["ComponentID"] == "":
                print(f'Removing stale Ethernet Interface from HSM: {found_ie}')
                if state.perform_changes:
                    delete_hsm_inventory_ethernet_interfaces(session, found_ie)
                else:
                    print("Skipping due to dry run!")
            else:
                action_log(action, f'Error found EthernetInterfaces with allocated BMC IP address {state.bmc_ip} in HSM: {found_ie}')
                print_action(action)
                sys.exit(1)
    else:
        print("         Pass the BMC MAC address is currently associated with the allocated IP Address")

    # Validate NCN does not exist under state components
    verify_hsm_state_components_not_found(session, state.ncn_xname)

    # Validate the BMC of the NCN does not exist under state components
    verify_hsm_state_components_not_found(session, state.bmc_xname)

    # Validate the BMC of the NCN does not exist under inventory redfish endpoints
    verify_hsm_inventory_redfish_endpoints_not_found(session, state.bmc_xname)

    # Validate the NID is not in use by HSM
    action, components = search_hsm_state_components(session, nid)
    if len(components) != 0:
        components = [comp["ID"] for comp in action["response"]["Components"]]

        action_log(action, f'Error allocated NID {nid} already in use by {",".join(components)} in HSM')
        print_action(action)
        sys.exit(1)

    action_log(action, f"Pass allocated NID {nid} currently not in use in HSM")
    print_action(action)

    #
    # Validate contents of BSS
    #
    print("Performing validation checks against BSS")

    # Validate the NCN has no bootparameters
    verify_bss_bootparameters_not_found(session, args.xname)

    # Retrieve the global boot parameters
    action, global_bootparameters = get_bss_bootparameters(session, "Global")
    state.global_bootparameters = global_bootparameters

    state.validate_global_bss_bootparameters(action)

    #
    # Validate BSS contains bootparameters for an NCN of a similar type
    #
    donor_ncn = None
    for ncn in existing_management_ncns:
        if ncn["ExtraProperties"]["SubRole"] == state.ncn_subrole:
            donor_ncn = ncn
            break
    if donor_ncn is None:
        print(f"Failed to find a Management NCN with subrole {state.ncn_subrole} to donate bootparameters")
        sys.exit(1)

    donor_alias = donor_ncn["ExtraProperties"]["Aliases"][0]
    print(f'Found existing NCN {donor_ncn["Xname"]} ({donor_alias}) of the same type to donate bootparameters to {state.ncn_xname} ({state.ncn_alias})')

    action, donor_bootparameters = get_bss_bootparameters(session,  donor_ncn["Xname"])
    action_log(action, f'Pass {donor_ncn["Xname"]} currently exists in BSS Bootparameters')
    print_action(action)

    # Modify donor bootparameters for the NCN being added:
    # This is what CSI does:
    # https://github.com/Cray-HPE/cray-site-init/blob/main/cmd/handoff-bss-metadata.go#L364-L396

    # Once the munging occurs CSI does this: https://github.com/Cray-HPE/cray-site-init/blob/main/cmd/handoff-bss-metadata.go#L286-L352

    # Determine the cabinet containing the node
    slot_xname = get_component_parent(state.bmc_xname)
    chassis_xname = get_component_parent(slot_xname)
    cabinet_xname = get_component_parent(chassis_xname)

    # Update kernel command line params
    donor_kernel_params = donor_bootparameters["params"].split()
    kernel_params = []

    # Build up the kernel command line parameters
    interface_kernel_params = []
    for interface, mac in macs.items():
        interface_kernel_params.append(f'ifname={interface}:{mac}')
    kernel_params.extend(interface_kernel_params)

    for param in donor_kernel_params:
        if param.startswith("hostname="):
            kernel_params.append(f'hostname={args.alias}')
        elif param.startswith("ifname="):
            # Ignore MAC specific params.
            pass
        elif param.startswith("metal.no-wipe"):
            kernel_params.append("metal.no-wipe=0")
        else:
            kernel_params.append(param)


    # Update BSS bootparameters
    ncn_cidrs = {}
    for network_name, ip in state.ncn_ips.items():
        bootstrap_dhcp_subnet = sls_networks[network_name].subnets()["bootstrap_dhcp"]
        ncn_cidrs[network_name] = f'{ip}/{bootstrap_dhcp_subnet.ipv4_network().prefixlen}'

    bootparams = copy.deepcopy(donor_bootparameters)
    bootparams["hosts"] = [state.ncn_xname]
    bootparams["params"] = " ".join(kernel_params)
    bootparams["cloud-init"]["user-data"]["hostname"] = state.ncn_alias
    bootparams["cloud-init"]["user-data"]["local_hostname"] = state.ncn_alias
    if "ntp" in bootparams["cloud-init"]["user-data"]:
        bootparams["cloud-init"]["user-data"]["ntp"]["allow"] = []
        for network_name in ["HMN", "NMN", "HMN_RVR", "NMN_RVR", "NMN_MTN", "HMN_MTN"]:
            if  network_name in sls_networks:
                subnet_cidr = str(sls_networks[network_name].ipv4_address())
                bootparams["cloud-init"]["user-data"]["ntp"]["allow"].append(subnet_cidr)
    bootparams["cloud-init"]["meta-data"]["availability-zone"] = cabinet_xname
    bootparams["cloud-init"]["meta-data"]["instance-id"] = generate_instance_id()
    bootparams["cloud-init"]["meta-data"]["local-hostname"] = state.ncn_alias
    # bootparams["cloud-init"]["meta-data"]["region"] # This will remain the same. This is the name of the system.
    # bootparams["cloud-init"]["meta-data"]["shasta-role"] # This will remain the same for the particular node type. ncn-master, ncn-storage, ncn-worker
    bootparams["cloud-init"]["meta-data"]["xname"] = state.ncn_xname
    if "ipam" in bootparams["cloud-init"]["meta-data"]:
        # This is a CSM 1.2 Specific thing
        bootparams["cloud-init"]["meta-data"]["ipam"] = {}
        for network_name, ip_cidr in ncn_cidrs.items():
            if network_name not in ["CAN", "CMN", "HMN", "MTL", "NMN"]:
                # This network is not managed by cloud-init
                continue

            bootstrap_dhcp_subnet = sls_networks[network_name].subnets()["bootstrap_dhcp"]

            bootparams["cloud-init"]["meta-data"]["ipam"][network_name.lower()] = {
                "gateway": str(bootstrap_dhcp_subnet.ipv4_gateway()),
                "ip": ip_cidr,
                "parent_device": "bond0",
                "vlanid": bootstrap_dhcp_subnet.vlan(),
            }

    print(f'Generated BSS bootparameters for {state.ncn_xname} ({state.ncn_alias}) from donor bootparameters')
    print(json.dumps(bootparams, indent=2))


    #
    # Create new hardware in SLS
    #
    node = {
        "Parent": state.bmc_xname,
        "Xname": state.ncn_xname,
        "Type": "comptype_node",
        "TypeString": "Node",
        "Class": "River",
        "ExtraProperties": {
            "NID": nid,
            "Role": "Management",
            "SubRole": state.ncn_subrole,
            "Aliases": [state.ncn_alias]
        }
    }

    mgmt_switch_connector = None
    if not is_m001:
        # Calculate VendorName for the switch port
        port = re.search(r"j(\d+)$", args.bmc_mgmt_switch_connector).group(1)
        vendor_name = None
        if mgmt_switch_brand == "Aruba":
            vendor_name = f"1/1/{port}"
        elif mgmt_switch_brand == "Dell":
            vendor_name = f"ethernet1/1/{port}"
        else:
            print(f"Unknown switch brand {mgmt_switch_brand} for {mgmt_switch_xname}")
            sys.exit(1)

        mgmt_switch_connector = {
            "Parent": mgmt_switch_xname,
            "Xname": args.bmc_mgmt_switch_connector,
            "Type": "comptype_mgmt_switch_connector",
            "TypeString": "MgmtSwitchConnector",
            "Class": "River",
            "ExtraProperties": {
                "VendorName": vendor_name,
                "NodeNics": [state.bmc_xname]
            }
        }

    #
    # Update SLS with new hardware!
    #
    print(f'Creating {node["Xname"]} in SLS...')
    print(json.dumps(node, indent=2))
    if state.perform_changes:
        create_sls_hardware(session, node)
    else:
        print("Skipping due to dry run!")


    if not is_m001:
        print(f'Creating {mgmt_switch_connector["Xname"]} in SLS...')
        print(json.dumps(mgmt_switch_connector, indent=2))

        if state.perform_changes:
            create_sls_hardware(session, mgmt_switch_connector)
        else:
            print("Skipping due to dry run!")


    #
    # Update SLS networking for the new NCN
    #
    state.update_sls_networking(session)

    #
    # Update HSM with IP address and MAC address data
    #

    # For each MAC address provided push it into HSM with only MAC and ComponentID except for the MAC0 of the bond0
    # {
    #     "ID": "b8599fdeb4b9",
    #     "Description": "CSI Handoff MAC",
    #     "MACAddress": "b8:59:9f:de:b4:b9",
    #     "LastUpdate": "2022-01-26T19:14:04.25944Z",
    #     "ComponentID": "x3001c0s39b0n0",
    #     "Type": "Node",
    #     "IPAddresses": []
    # },

    # The EthernetInterfaces for MAC0 of Bond0 has the following in HSM
    # CSM 1.2
    # {
    #     "ID": "a4bf0165c152",
    #     "Description": "Bond0 - bond0.nmn0- kea",
    #     "MACAddress": "a4:bf:01:65:c1:52",
    #     "LastUpdate": "2022-01-26T19:16:06.928277Z",
    #     "ComponentID": "x3001c0s39b0n0",
    #     "Type": "Node",
    #     "IPAddresses": [
    #         {
    #         "IPAddress": "10.252.1.17" // NMN
    #         },
    #         {
    #         "IPAddress": "10.101.5.146" // CAN
    #         },
    #         {
    #         "IPAddress": "10.1.1.15" // MTL
    #         },
    #         {
    #         "IPAddress": "10.254.1.30" // HMN
    #         }
    #     ]
    # }
    #
    # CSM 1.0
    # {
    #     "ID": "b8599f34893a",
    #     "Description": "Bond0 - vlan002",
    #     "MACAddress": "b8:59:9f:34:89:3a",
    #     "LastUpdate": "2021-04-14T20:55:32.92734Z",
    #     "ComponentID": "x3000c0s5b0n0",
    #     "Type": "Node",
    #     "IPAddresses": [
    #     {
    #         "IPAddress": "10.252.1.9"
    #     }
    #     ]
    # },
    for interface, mac in macs.items():
        ei = {}
        ei["MACAddress"] = mac
        ei["ComponentID"] = args.xname
        ei["IPAddresses"] = []

        if interface == "mgmt0":
            ei["Description"] = "- kea"
            for network in ["NMN", "CAN", "CMN", "MTL", "HMN"]:
                if network in state.ncn_ips:
                    ei["IPAddresses"].append({"IPAddress": str(state.ncn_ips[network])})

        print(f"Adding MAC Addresses {mac} to HSM Inventory EthernetInterfaces")
        print(json.dumps(ei, indent=2))
        if args.perform_changes:
            create_hsm_inventory_ethernet_interfaces(session, ei)
        else:
            print("Skipping due to dry run!")


    if bmc_connected_to_hmn:
        bmc_ei = {}
        bmc_ei["MACAddress"] = bmc_mac
        bmc_ei["ComponentID"] = state.bmc_xname
        bmc_ei["Description"] = "- kea"
        bmc_ei["IPAddresses"] = [{"IPAddress": str(state.bmc_ip)}]

        # Attempt creation of HSM EthernetInterface for the BMC
        print(f"Adding BMC MAC Addresses {bmc_mac} to HSM Inventory EthernetInterfaces")
        print(json.dumps(bmc_ei, indent=2))
        if args.perform_changes:
            status = create_hsm_inventory_ethernet_interfaces(session, bmc_ei)
            if status == http.HTTPStatus.CONFLICT:
                # If the EI already exists, then patch it
                print(f"Patching BMC MAC Addresses {bmc_mac} in HSM Inventory EthernetInterfaces")
                patch_hsm_inventory_ethernet_interfaces(session, bmc_ei)


    #
    # Create an entry under HSM State Components for ncn-m001.
    # The other NCNs will be populated by the normal HSM Discovery/Invnetory process, but since
    # the BMC of ncn-m001 is not connected to the HMN, we need to manually do this.
    #
    if is_m001:
        #     component := base.Component{
		# 	ID:      ncn.Xname,
		# 	Type:    "Node",
		# 	Flag:    "OK",
		# 	State:   "Ready",
		# 	Enabled: &true,
		# 	Role:    extraProperties.Role,
		# 	SubRole: extraProperties.SubRole,
		# 	NID:     json.Number(strconv.Itoa(extraProperties.NID)),
		# 	NetType: "Sling",
		# 	Arch:    "X86",
		# 	Class:   "River",
		# }
        component = {
            "ID": state.ncn_xname,
            "Flag": "OK",
            "State": "Ready",
            "Enabled": True,
            "Role": "Management",
            "SubRole": state.ncn_subrole,
            "NID": nid,
            "NetType": "Sling",
            "Arch": "X86",
            "Class": "River"
        }

        print(f"Creating component {state.ncn_xname} to HSM State Components")
        print(json.dumps(component, indent=2))
        if args.perform_changes:
            create_hsm_state_component(session, component)
        else:
            print("Skipping due to dry run!")

    #
    # Update Global host_records in BSS with IPs
    #
    if not state.use_existing_ip_addresses:
        state.update_global_bss_host_records(session)

    #
    # Create new Bootparameters in BSS
    #
    print(f"Adding bootparameters for {state.ncn_xname} in BSS ")
    print(json.dumps(bootparams, indent=2))
    if args.perform_changes:
        put_bss_bootparameters(session, bootparams)
    else:
        print("Skipping due to dry run!")

    print('')
    print(f'{state.ncn_xname} ({state.ncn_alias}) has been added to SLS/HSM/BSS')
    if not args.perform_changes:
        print('        WARNING A Dryrun was performed, and no changes were performed to the system')
    if existing_bmc_ip is not None and not existing_bmc_ip_matches:
        print(f'        WARNING The NCN BMC currently has the IP address: {existing_bmc_ip}, and needs to have IP Address {state.bmc_ip}')
    if not bmc_connected_to_hmn:
        print(f'        The BMC of {state.ncn_alias} is not connected to the system\'s HMN, this is typical for ncn-m001')

    state.print_ncn_ips()

def main():
    global BSS_URL
    global HSM_URL
    global SLS_URL
    global KEA_URL

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
    base_parser.add_argument("--alias", type=str, required=True, help="The alias of the NCN. Ex: ncn-m001, ncn-w001, ncn-m001")
    base_parser.add_argument("--url-bss", type=str, required=False, default="https://api-gw-service-nmn.local/apis/bss/boot/v1")
    base_parser.add_argument("--url-hsm", type=str, required=False, default="https://api-gw-service-nmn.local/apis/smd/hsm/v2")
    base_parser.add_argument("--url-sls", type=str, required=False, default="https://api-gw-service-nmn.local/apis/sls/v1")
    base_parser.add_argument("--url-kea", type=str, required=False, default="https://api-gw-service-nmn.local/apis/dhcp-kea")
    base_parser.add_argument("--log-dir", help="Directory where to log and save current state.", default='/tmp/add_management_ncn')
    base_parser.add_argument("--network-allowed-in-dhcp-range", action="append", type=str, required=False, default=[])

    # allocate-ip arguments
    allocate_ips_parser = subparsers.add_parser("allocate-ips", parents=[base_parser])
    allocate_ips_parser.add_argument("--skip-etc-hosts", action="store_true", help="Causes this to not modify the /etc/hosts file on the NCNs.")
    allocate_ips_parser.set_defaults(func=allocate_ips_command, show_help=False)

    # ncn-data arguments
    ncn_data_parser = subparsers.add_parser("ncn-data", parents=[base_parser])
    ncn_data_parser.add_argument("--bmc-mgmt-switch-connector", type=str, required=False, help="Xname of the MgmtSwitchConnector connecting that the NCN BMC connected to")
    ncn_data_parser.add_argument("--mac-bmc",   type=str, required=False, help="MAC address of of the NCN")
    ncn_data_parser.add_argument("--mac-mgmt0", type=str, required=True,  help="MAC address of mgmt0")
    ncn_data_parser.add_argument("--mac-mgmt1", type=str, required=True,  help="MAC address of mgmt1")
    ncn_data_parser.add_argument("--mac-sun0",  type=str, required=False, help="MAC address of sun0")
    ncn_data_parser.add_argument("--mac-sun1",  type=str, required=False, help="MAC address of sun1")
    ncn_data_parser.add_argument("--mac-lan0",  type=str, required=False, help="MAC address of lan0")
    ncn_data_parser.add_argument("--mac-lan1",  type=str, required=False, help="MAC address of lan1")
    ncn_data_parser.add_argument("--mac-lan2",  type=str, required=False, help="MAC address of lan2")
    ncn_data_parser.add_argument("--mac-lan3",  type=str, required=False, help="MAC address of lan3")
    ncn_data_parser.add_argument("--mac-hsn0",  type=str, required=False, help="MAC address of hsn0")
    ncn_data_parser.add_argument("--mac-hsn1",  type=str, required=False, help="MAC address of hsn1")
    ncn_data_parser.set_defaults(func=ncn_data_command, show_help=False)

    args = parser.parse_args()

    if args.show_help:
        parser.print_help(sys.stdout)
        sys.exit(1)

    BSS_URL = args.url_bss
    HSM_URL = args.url_hsm
    SLS_URL = args.url_sls
    KEA_URL = args.url_kea

    # Validate provide node alias
    if re.match("^ncn-[mws][0-9][0-9][0-9]$", args.alias) is None:
        print("Invalid alias was provided: ", args.alias, ", expected in the format of ncn-m001, ncn-s001, or ncn-w001")
        sys.exit(1)

    subrole = None
    if args.alias.startswith("ncn-m"):
        subrole = "Master"
    elif args.alias.startswith("ncn-w"):
        subrole = "Worker"
    elif args.alias.startswith("ncn-s"):
        subrole = "Storage"
    if subrole is None:
        print("Failed to determine NCN subrole from alias ", args.alias)
        sys.exit(1)

    # Validate provided node xname (used by both)
    if re.match("^x([0-9]{1,4})c[0,4]s([0-9]+)b0n0$", args.xname) is None:
        print("Invalid node xname provided: ", args.xname, ", expected format xXc0sSb0n0")
        sys.exit(1)

    # Create log directory
    log_directory = os.path.join(args.log_dir, args.xname)
    if not os.path.exists(log_directory):
        os.makedirs(log_directory)

    # Start the actual process of adding a NCN...
    state = State(
        ncn_xname=args.xname,
        ncn_alias=args.alias,
        ncn_subrole=subrole,
        log_directory=log_directory,
        perform_changes=args.perform_changes,
        networks_allowed_in_dhcp_range=args.network_allowed_in_dhcp_range
    )
    with requests.Session() as session:
        session.verify = False
        if token is not None:
            session.headers.update({'Authorization': f'Bearer {token}'})
        session.headers.update({'Content-Type': 'application/json'})

        args.func(session, args, state)

    return 0

if __name__ == "__main__":
    sys.exit(main())
