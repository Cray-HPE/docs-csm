#!/usr/bin/env python3
# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
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

from ipaddress import IPv4Address
import subprocess

import urllib3
from sls_utils.Managers import NetworkManager
from sls_utils.Networks import Network as SLSNetwork, Subnet as SLSSubnet
from sls_utils.Reservations import Reservation as IPReservation
from sls_utils import ipam

import argparse
import http
import os
import sys
import requests
import json
import re
import string
import netaddr
import copy
import binascii

from requests.exceptions import ConnectionError

# Global variables for service URLs. These get set in main.
BSS_URL = None
HSM_URL = None
SLS_URL = None

#
# HTTP Action stuff
#
def print_action(action):
    if action['error'] != None:
        print(f"Failed:  {action['method'].upper()} {action['url']}. {action['error']}")
        # print(json.dumps(action["response"], indent=2))
    elif action['status'] != None:
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
        
        if expected_status != None and r.status_code != expected_status:
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
        exit(1)
    elif action["error"] != None:
        action_log(action, f'Error failed to query SLS for {xname} - {action["error"]}')
        print_action(action)
        exit(1)
    
    action_log(action, f"Pass {xname} does not currently exist in SLS Hardware")
    print_action(action)

def get_sls_management_ncns(session: requests.Session):
    action = http_get(session, f'{SLS_URL}/search/hardware', params={"type": "comptype_node", "extra_properties.Role": "Management"})
    if action["status"] != http.HTTPStatus.OK:
        action_log(action, "Error failed to query SLS for Management NCNs")
        print_action(action)
        exit(1)

    existing_management_ncns = action["response"]
    if existing_management_ncns == None or len(existing_management_ncns) == 0:
        action_log(action, "Error SLS has zero Management NCNs")
        print_action(action)
        exit(1)

    return action, sorted(existing_management_ncns, key=lambda d: d["ExtraProperties"]["Aliases"][0])

def get_sls_hardware(session: requests.Session, xname: str):
    action = http_get(session, f'{SLS_URL}/hardware/{xname}', expected_status=http.HTTPStatus.OK)
    if action["status"] == http.HTTPStatus.NOT_FOUND:
        action_log(action, f"Error component {xname} does not exist in SLS.")
        print_action(action)
        exit(1)
    if action["error"] != None:
        action_log(action, f'Error failed to query SLS for {xname} - {action["error"]}')
        print_action(action)
        exit(1)

    action_log(action, f"Pass {xname} exists in SLS")
    return action, action["response"]


def get_sls_networks(session: requests.Session, validate: bool):
    action = http_get(session, f'{SLS_URL}/networks')
    if action["error"] != None:
        action_log(action, "Error failed to query SLS for Networks")
        print_action(action)
        exit(1)

    temp_networks = {} 
    for sls_network in action["response"]:
        temp_networks[sls_network["Name"]] = sls_network

    if validate:
        action_log(action, "Not validating SLS network data against schema")
    return action, NetworkManager(temp_networks, validate=validate)

def create_sls_hardware(session: requests.Session, hardware: dict):
    r = session.post(f'{SLS_URL}/hardware', json=hardware)

    # TODO Something in SLS changed where POSTs started to create 201 status codes.
    if r.status_code != http.HTTPStatus.OK and r.status_code != http.HTTPStatus.CREATED:
        print(f'Error failed to create {hardware["Xname"]}, unexpected status code {r.status_code}')
        exit(1)


#
# HSM API Helpers
#
def verify_hsm_inventory_ethernet_interface_not_found(session: requests.Session, component_id: str=None, ip_address: str=None) -> dict:
    search_params = {}
    if component_id != None:
        search_params["ComponentID"] = component_id
    if ip_address != None:
        search_params={"IPAddress": ip_address}
    if search_params == {}:
        print("Error no parameters provided to to query HSM for EthernetInterfaces")
        exit(1)

    action = http_get(session, f'{HSM_URL}/Inventory/EthernetInterfaces', params=search_params)
    if action["status"] != http.HTTPStatus.OK:
        action_log(action, "Error failed to query HSM for EthernetInterfaces")
        print_action(action)
        exit(1)

    if len(action["response"]) != 0:
        action_log(action, f"Error found EthernetInterfaces for matching {search_params} in HSM")
        print_action(action)
        exit(1)

    return action

def verify_hsm_inventory_redfish_endpoints_not_found(session: requests.session, xname: str):
    action = http_get(session, f'{HSM_URL}/Inventory/RedfishEndpoints/{xname}', expected_status=http.HTTPStatus.NOT_FOUND)
    if action["status"] == http.HTTPStatus.OK:
        action_log(action, f"Error {xname} already exists in HSM Inventory RedfishEndpoints")
        print_action(action)
        exit(1)
    elif action["error"] != None:
        action_log(action, f'Error failed to query HSM for {xname} - {action["error"]}')
        print_action(action)
    
    action_log(action, f"Pass {xname} does not currently exist in HSM Inventory RedfishEndpoints")
    print_action(action)

def verify_hsm_state_components_not_found(session: requests.Session, xname: str):
    action = http_get(session, f'{HSM_URL}/State/Components/{xname}', expected_status=http.HTTPStatus.NOT_FOUND)
    if action["status"] == http.HTTPStatus.OK:
        action_log(action, f"Error {xname} already exists in HSM State Components")
        print_action(action)
        exit(1)
    elif action["error"] != None:
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
        exit(1)

    return action, action["response"]["Components"]

def create_hsm_inventory_ethernet_interfaces(session: requests.Session, ei: dict):
    print(f'Creating {ei["MACAddress"]} in HSM...')
    r = session.post(f'{HSM_URL}/Inventory/EthernetInterfaces', json=ei)

    if r.status_code != http.HTTPStatus.CREATED:
        print(f'Error failed to create {ei["MACAddress"]}, unexpected status code {r.status_code}')
        exit(1)

    print(f'Created {ei["MACAddress"]} in HSM Inventory Ethernet Interfaces')
    print(json.dumps(ei, indent=2))

def get_hsm_inventory_ethernet_interfaces(session: requests.Session, mac: str):
    id = mac.replace(":", "").lower()
    action = http_get(session, f'{HSM_URL}/Inventory/EthernetInterfaces/{id}', expected_status=None)
    if action["error"] != None:
        action_log(action, f'Error failed to query HSM Ethernet Interfaces for {mac}. {action["error"]}')
        print_action(action)
        exit(1)
    return action, action["response"]

def patch_hsm_inventory_ethernet_interfaces(session: requests.Session, ei: dict):
    id = ei["MACAddress"].replace(":", "").lower()
    action = http_patch(session, f'{HSM_URL}/Inventory/EthernetInterfaces/{id}', payload=ei)
    if action["error"] != None:
        action_log(action, f'Error failed to patch HSM Ethernet Interfaces for {id}. {action["error"]}')
        print_action(action)
        exit(1)
    print_action(action)

    print(f'Patched {id} in HSM Inventory Ethernet Interfaces')
    print(json.dumps(ei, indent=2))


#
# BSS API Helpers
#
def verify_bss_bootparameters_not_found(session: requests.Session, name: str):
    action = http_get(session, f'{BSS_URL}/bootparameters', params={"name": name}, expected_status=http.HTTPStatus.NOT_FOUND)
    if action["error"] != None:
        action_log(action, f'Error failed to query BSS Bootparameters for {name}. {action["error"]}')
        print_action(action)
        exit(1)

    if action["status"] != http.HTTPStatus.NOT_FOUND:
        action_log(action, f"Error found bootparameters for {name} in BSS")
        print_action(action)
        exit(1)
    
    action_log(action, f"Pass {name} does not currently exist in BSS Bootparameters")
    print_action(action)

def get_bss_bootparameters(session: requests.Session, name: str):
    action = http_get(session, f'{BSS_URL}/bootparameters', params={"name": name}, expected_status=http.HTTPStatus.OK)
    if action["error"] != None:
        action_log(action, f'Error failed to query BSS Bootparameters for {name}. {action["error"]}')
        print_action(action)
        exit(1)
    if action["status"] == http.HTTPStatus.NOT_FOUND:
        action_log(action, f"Error bootparameters for {name} do not exist in BSS")
        print_action(action)
        exit(1)

    if len(action["response"]) != 1:
        action_log(action, f'Unexpected number of bootparameters for {name} in BSS {len(action["response"])}, expected 1')
        print_action(action)
        exit(1)

    return action, action["response"][0]        

def put_bss_bootparameters(session: requests.Session, bootparameters: dict):
    action = http_put(session, f'{BSS_URL}/bootparameters', payload=bootparameters)
    if action["error"] != None:
        action_log(action, f'Error failed to update bootparameters in BSS')
        print_action(action)
        exit(1)
    print_action(action)

# generate_instance_id creates an instance-id fit for use in the instance metadata
def generate_instance_id() -> str:
    b = os.urandom(4)
    return f'i-{binascii.hexlify(b).decode("utf-8").upper()}'

#
# Functions to process xnames
#

def get_componet_parent(xname:str):
    # TODO This is really hacky
    regex_cdu = "^d([0-9]+)$"
    regex_cabinet = "^x([0-9]{1,4})$"
    if re.match(regex_cdu, xname) != None or re.match(regex_cabinet, xname) != None:
        return "s0"

    # Trim all trailing numbers, then in the result, trim all trailing
	# letters.
    return xname.rstrip(string.digits).rstrip(string.ascii_letters)

#
# SLS IPAM functions
#

def find_next_available_ip(sls_subnet: SLSSubnet, cidr_override: IPv4Address=None, starting_ip: netaddr.IPAddress=None) -> netaddr.IPAddress:
    subnet = netaddr.IPNetwork(str(sls_subnet.ipv4_address()))

    # Override the CIDR if one was provided
    if cidr_override != None:
        subnet = netaddr.IPNetwork(str(cidr_override))

    existing_ip_reservations = netaddr.IPSet()
    existing_ip_reservations.add(str(sls_subnet.ipv4_gateway()))
    for ip_reservation in sls_subnet.reservations().values():
        #print("  Found existing IP reservation {} with IP {}".format(ip_reservation.name(), ip_reservation.ipv4_address()))
        existing_ip_reservations.add(str(ip_reservation.ipv4_address()))

    # Start looking for IPs after the gateway of the beginning of the subnet
    for available_ip in list(subnet[2:-2]):
        # If a starting IP was provided
        if starting_ip != None and available_ip < starting_ip:
            continue

        if available_ip not in existing_ip_reservations:
            #print("  {} Available for use.".format(available_ip))
            return available_ip

    # Exhausted available IP address
    return None


def allocate_ip_address_in_subnet(action: dict, networks: NetworkManager, network_name: str, subnet_name: str):
    fail_ip_address_allocation = False

    network = networks[network_name]
    subnets = network.subnets()
    if "bootstrap_dhcp" not in subnets:
        action_log(action, "Error Network {network} does not have bootstrap_dhcp subnet in SLS")
        print_action(action)
        exit(1)

    bootstrap_dhcp_subnet = subnets["bootstrap_dhcp"]
    # If the subnet has been supernet hacked, then the unhacked CIDR will be returned. Otherwise none will be returned.
    unhacked_cidr = ipam.is_supernet_hacked(network.ipv4_network(), bootstrap_dhcp_subnet)
    if unhacked_cidr != None:
        action_log(action, f'Info the bootstrap_dhcp subnet in the {network_name} network has been supernet hacked! Changing CIDR from {bootstrap_dhcp_subnet.ipv4_address()} to {unhacked_cidr} for IP address calculation')

    # The start of the static range begins two host IP addresses into the subnet, except for the CMN
    starting_ip = None
    if network_name == "CMN":
        starting_ip = netaddr.IPAddress(str(bootstrap_dhcp_subnet.reservations()["kubeapi-vip"].ipv4_address()))

    # As the function says, find the next available IP in the bootstrap_dhcp subnet
    next_free_ip = find_next_available_ip(bootstrap_dhcp_subnet, cidr_override=unhacked_cidr, starting_ip=starting_ip)

    action_log(action, f'Allocated IP {next_free_ip} on the {network_name} network')
    
    # Not all subnets that require IPAM on them have DHCP (CHN), so we need to perform the static IP address range check for the ones that do
    if bootstrap_dhcp_subnet.dhcp_start_address() != None:
        # Now verify the allocated IP is within the static IP range of the subnet. 
        # The static range for NCNs is allocated at the beginning of the subnet till the first DHCPStart IP address 
        dhcp_start = netaddr.IPAddress(str(bootstrap_dhcp_subnet.dhcp_start_address()))
        if dhcp_start <= next_free_ip:
            fail_ip_address_allocation = True
            action_log(action, f'Error the allocated IP {next_free_ip} is outside of the static IP address range for the bootstrap_dhcp subnet in the {network_name} network')

    if fail_ip_address_allocation:
        print_action(action)
        exit(1)

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
                                    'sed', '-i', f"'$a{line}'", f'/etc/hosts'])
        command_actions.append(sed_action)

    # BMC IPs
    line = f'{str(bmc_ip):15} {ncn_alias}-mgmt'
    sed_action = CommandAction(['pdsh', '-w', hosts,
                                'sed', '-i', f"'$a{line}'", f'/etc/hosts'])
    command_actions.append(sed_action)

    return command_actions

def main(argv):
    global BSS_URL
    global HSM_URL
    global SLS_URL

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    token = os.environ.get('TOKEN')
    if token == None or token == "":
        print("Error environment variable TOKEN was not set")
        exit(1)

    # Parse CLI Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--perform-changes", action="store_true", help="Allow modification of SLS, HSM, and BSS. When this option is not specified a dry run is performed")
    parser.add_argument("--xname", type=str, required=True, help="The xname of the ncn to add")
    parser.add_argument("--alias", type=str, required=True, help="The alias of the NCN. Ex: ncn-m001, ncn-w001, ncn-m001")
    parser.add_argument("--bmc-mgmt-switch-connector", type=str, required=False, help="Xname of the MgmtSwitchConnector connecting that the NCN BMC connected to")
    parser.add_argument("--mac-bmc",   type=str, required=True,  help="MAC address of of the NCN")
    parser.add_argument("--mac-mgmt0", type=str, required=True,  help="MAC address of mgmt0 - MAC0 of Bond0")
    parser.add_argument("--mac-mgmt1", type=str, required=False, help="MAC address of mgmt1 - MAC0 of Bond0")
    parser.add_argument("--mac-sun0",  type=str, required=False, help="MAC address of sun0 - MAC0 of Bond1")
    parser.add_argument("--mac-sun1",  type=str, required=False, help="MAC address of sun1 - MAC1 of Bond1")
    parser.add_argument("--mac-lan0",  type=str, required=False, help="MAC address of lan0")
    parser.add_argument("--mac-lan1",  type=str, required=False, help="MAC address of lan1")
    parser.add_argument("--mac-hsn0",  type=str, required=False, help="MAC address of hsn0")
    parser.add_argument("--mac-hsn1",  type=str, required=False, help="MAC address of hsn1")
    parser.add_argument("--url-bss", type=str, required=False, default="https://api-gw-service-nmn.local/apis/bss/boot/v1")
    parser.add_argument("--url-hsm", type=str, required=False, default="https://api-gw-service-nmn.local/apis/smd/hsm/v2")
    parser.add_argument("--url-sls", type=str, required=False, default="https://api-gw-service-nmn.local/apis/sls/v1")
    parser.add_argument("--log-dir", help="Directory where to log and save current state.", default='/tmp/add_management_ncn')
    parser.add_argument("--skip-etc-hosts", action="store_true", help="Causes this to not modify the /etc/hosts file on the NCNs.")


    #parser.add_argument("--do-not-validate-sls", type=bool, action=argparse.BooleanOptionalAction, required=False, help="Do not perform validation")

    args = parser.parse_args()

    BSS_URL = args.url_bss
    HSM_URL = args.url_hsm
    SLS_URL = args.url_sls

    # Validate provide node alias
    if re.match("^ncn-[mws][0-9][0-9][0-9]$", args.alias) == None:
        print("Invalid alias was provided: ", args.alias, ", expected in the format of ncn-m001, ncn-s001, or ncn-w001")
        exit(1)

    subrole = None
    if args.alias.startswith("ncn-m"):
        subrole = "Master"
    elif args.alias.startswith("ncn-w"):
        subrole = "Worker"
    elif args.alias.startswith("ncn-s"):
        subrole = "Storage"
    if subrole == None:
        print("Failed to determine NCN subrole from alias ", args.alias)
        exit(1)

    bmc_alias = f'{args.alias}-mgmt'

    # If the NCN is one of the first 9 NCNs we need to retain the IP addresses (and expect them to be present) in SLS
    # This simplifies a few things:
    # - The Ceph MONs and MGRs running on the first 3 storage node need to have the IPs stay the same
    # - The IP addresses of the first 9 NCNs are presnet in the chrony config file. If we don't change them, then we don't have to update that file. 
    use_existing_ip_addresses = re.match("^ncn-[mws]00[1-3]$", args.alias)


    # Validate provided xnames
    if re.match("^x([0-9]{1,4})c0s([0-9]+)b0n0$", args.xname) == None:
        print("Invalid node xname provided: ", args.xname, ", expected format xXc0sSb0n0")
        exit(1)
    is_m001 = args.alias == "ncn-m001"
    if (not is_m001) and re.match("^x([0-9]{1,4})c([0-7])w([1-9][0-9]*)j([1-9][0-9]*)$", args.bmc_mgmt_switch_connector) == None:
        # All NCNs except for ncn-m001 need to has a MgmtSwitchConnector provided for its BMC.
        # Typically the BMC of ncn-m001 does not have a connection to the HMN, but the HMN. 
        print("Invalid MgmtSwitchConnector xname provided: ", args.xname, ", expected format xXcCwWjJ")
        exit(1)


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
    if args.mac_mgmt0 != None:
        macs["mgmt0"] = args.mac_mgmt0
    if args.mac_mgmt1 != None:
        macs["mgmt1"] = args.mac_mgmt1
    if args.mac_sun0 != None:
        macs["mgmt2"] = args.mac_mgmt2
    if args.mac_sun0 != None:
        macs["mgmt3"] = args.mac_mgmt3
    if args.mac_lan0 != None:
        macs["lan0"] = args.mac_lan0
    if args.mac_lan1 != None:
        macs["lan1"] = args.mac_lan1
    if args.mac_hsn0 != None:
        macs["hsn0"] = args.mac_hsn0
    if args.mac_hsn1 != None:
        macs["hsn1"] = args.mac_hsn1

    # Normalize MACs
    for interface in macs:
        macs[interface] = macs[interface].lower()

    # Validate MAC addresses format
    for interface in macs:
        if not re.match("[0-9a-f]{2}([-:]?)[0-9a-f]{2}(\\1[0-9a-f]{2}){4}$", macs[interface]):
            print(f'Invalid NCN MAC address provided for {interface}: {macs[interface]}')
            exit(1)
    
    # Validate BMC MAC address
    bmc_mac = args.mac_bmc
    if not re.match("[0-9a-f]{2}([-:]?)[0-9a-f]{2}(\\1[0-9a-f]{2}){4}$", bmc_mac):
        print(f'Invalid BMC MAC address provided: {bmc_mac}')
        exit(1)

    # Verify all MACs provided are unique
    unique_macs = []
    for interface, mac in macs.items():
        if mac in unique_macs:
            print(f'Error MAC Address {mac} provided for NCN interface {interface} is not unique')
            exit(1)
        unique_macs.append(mac)
    
    if bmc_mac in unique_macs:
        print(f'Error BMC MAC Address {mac} provided is not unique')
        exit(1)

    # If this an worker, then a MAC address for hsn0 needs to be provided
    if (subrole == "Worker") and ("hsn0" not in macs):
        print(f"Error hsn0 MAC address not provided for worker managment NCN. At least 1 HSN MAC address is required")
        exit(1)

    # Either mgmt0 and mgmt1, or mgmt0, mgmt1, mgmt2, mgmt3 need to be provided
    # TODO Do we want to use the wording for BOND0 MAC 0, and BOND0 MAC 1?
    # TODO the naming of interfaces changes between CSM 1.0 and CSM 1.2. The following is for CSM 1.2.
    bond_across_two_cards = False
    if ("mgmt0" in macs) and ("mgmt1" in macs):
        # Both ports of a single card are used to form bond0
        # TODO mgmt0 < mgmt1
        print("Bond0 will be formed across mgmt0 and mgmt1")
    elif ("mgmt0" in macs) and ("mgmt1" in macs) and ("mgmt2" in macs) and ("mgmt3" in macs):
        # The lower MAC address of each card is used to form bond0 for mgmt0/mgmt1
        # The higher MAC address of each card is used to form bond1 for mgmt2/mgmt3
        # TODO mgmt0 < mgmt1
        # TODO mgmt1 < mgmt2
        bond_across_two_cards = True
        print("Bond0 will be formed across mgmt0 and mgmt2")
    else:
        print("Invalid combination of mgmt MAC addresses provided")
        exit(1)
    

    # Create log directory
    log_directory = os.path.join(args.log_dir, args.xname)
    if not os.path.exists(log_directory):
        os.makedirs(log_directory)

    # Start the actual process of adding a NCN...
    with requests.Session() as session:
        session.verify = False
        if token is not None:
            session.headers.update({'Authorization': f'Bearer {token}'})
        session.headers.update({'Content-Type': 'application/json'})

        print("Performing validation checks against SLS")
        # Verify that the NCN xname does not exist in SLS. This could be an no-op if what is in SLS matches what we want to put in
        verify_sls_hardware_not_found(session, args.xname)

        if args.alias != "ncn-m001":
            # Verify that the MgmtSwitchConnector does not exist in SLS. This could be an no-op if what is in SLS matches what we want to put in
            verify_sls_hardware_not_found(session, args.bmc_mgmt_switch_connector)

        # Retrive all Management NCNs from SLS
        action, existing_management_ncns = get_sls_management_ncns(session)

        # Verify that the alias is unique
        existing_management_ncns = sorted(existing_management_ncns, key=lambda d: d["ExtraProperties"]["Aliases"][0]) 
        for node in existing_management_ncns:
            for alias in node["ExtraProperties"]["Aliases"]:
                if alias == args.alias:
                    action_log(action, f'Error the provided alias {args.alias} is already in use by {node["Xname"]}')
                    print_action(action)
                    exit(1)
        
        action_log(action, f"Pass the alias {args.alias} is unique to {args.xname} in SLS Hardware")
        print_action(action)


        mgmt_switch_xname = None
        mgmt_switch_brand = None
        mgmt_switch_alias = None
        if not is_m001:
            # Verify the MgmtSwitchConnector is apart of a MgmtSwitch that is already present in SLS
            mgmt_switch_xname = get_componet_parent(args.bmc_mgmt_switch_connector)
            action, mgmt_switch = get_sls_hardware(session, mgmt_switch_xname)

            mgmt_switch_brand = mgmt_switch["ExtraProperties"]["Brand"]
            mgmt_switch_alias = mgmt_switch["ExtraProperties"]["Aliases"][0]
            
            action_log(action, f'Management Switch Xname: {mgmt_switch_xname}')
            action_log(action, f'Management Switch Brand: {mgmt_switch_brand}')
            action_log(action, f'Management Switch Alias: {mgmt_switch_alias}')
            print_action(action)

        # Determine the bmc xname for the NCN
        bmc_xname = get_componet_parent(args.xname)
        print(f"BMC Xname: {bmc_xname}")

        # Allocate new NID for the NCN
        allocated_nids = []
        for node in existing_management_ncns:
            allocated_nids.append(node["ExtraProperties"]["NID"])
        
        starting_nid=100001
        nid = min(set(range(starting_nid, max(allocated_nids)+2)) - set(allocated_nids))
        print("Allocated NID: ", nid)

        # Retrieve all Network data from SLS
        action, global_bootparams = get_bss_bootparameters(session, "Global")
        print_action(action)

        validate_sls = False
        action, sls_networks = get_sls_networks(session, validate=validate_sls)

        #
        # Determine NCN IPs
        #
        bmc_ip = None
        ncn_ips = {}
        if use_existing_ip_addresses:
            #
            # Reuse existing IPs from SLS if this is ncn-[mws]-00[1-3]
            # Do not allocate a new BMC IP for ncn-[mws]-00[1-3]
            #
            action_log(action, f"Reusing existing IP addresses from SLS for {args.alias} and {bmc_alias}")
            
            # Pull out existing IP addresses from BSS as it uses only the NCN alias, and no xnames.
            for host_record in global_bootparams["cloud-init"]["meta-data"]["host_records"]:
                ip = netaddr.IPAddress(str(host_record["ip"]))
                for alias in host_record["aliases"]:
                    if alias == bmc_alias:
                        # BMC IP Address
                        action_log(action, f'Found existing BMC IP Address for {bmc_alias} in BSS Global Bootparameters: {ip}')
                        bmc_ip = ip
                    elif alias == args.alias:
                        # This is the NMN Alias, but the NMN has 2 aliases present.
                        continue
                    elif alias.startswith(args.alias):
                        tokens = alias.split('.', 2)
                        network_name = tokens[1].upper()
                        action_log(action, f'Found existing NCN IP address for NCN {args.alias} in BSS Global Bootparameters: {host_record}')
                        ncn_ips[network_name] = ip

            if bmc_ip == None:
                action_log(action, f'Failed to find existing NCN BMC IP address for {bmc_alias} in BSS Global Bootparameters')
                print_action(action)
                exit(1)


            # Validate each network that has a bootstrap_dhcp subnet that a IP Reservation exists for this NCN
            failed_to_find_ip = False
            for network_name, ncn_ip in ncn_ips.items():
                network = sls_networks[network_name]
            
                if "bootstrap_dhcp" not in network.subnets():
                    continue
                dhcp_bootstrap = sls_networks[network_name].subnets()["bootstrap_dhcp"] 
            
                reservation_found = False
                for name, reservation in dhcp_bootstrap.reservations().items():
                    if str(ncn_ip) == str(reservation.ipv4_address()):
                        reservation_found = True
                        action_log(action, f'Removing existing IP Reservation with NCN IP {ncn_ip} in the bootstrap_dhcp subnet of the {network_name} network: {reservation.name()} {reservation.ipv4_address()} {reservation.aliases()} {reservation.comment()}')
                        del dhcp_bootstrap.reservations()[name]
                        break

                if not reservation_found:
                    action_log(action, f"Error IP Reservation not found for {args.xname} ({args.alias}) in the bootstrap_dhcp subnet of the {network_name} network in SLS")
                    failed_to_find_ip = True


            # Validate the HMN network has a BMC IP  that has a bootstrap_dhcp subnet has a IP Reservation for this NCN
            reservation_found = False
            hmn_dhcp_bootstrap = sls_networks["HMN"].subnets()["bootstrap_dhcp"]
            for name, reservation in hmn_dhcp_bootstrap.reservations().items():
                if str(bmc_ip) == str(reservation.ipv4_address()):
                    reservation_found = True
                    action_log(action, f'Removing existing IP Reservation for {bmc_alias} in the bootstrap_dhcp subnet of the HMN network: {reservation.name()} {reservation.ipv4_address()} {reservation.aliases()} {reservation.comment()}')
                    del hmn_dhcp_bootstrap.reservations()[name]
                    break

            if not reservation_found:
                action_log(action, f"Error BMC IP Reservation for {bmc_alias} missing from the HMN bootstrap_dhcp subnet")
                failed_to_find_ip = True        

            if failed_to_find_ip:
                print_action(action)
                exit(1)
        else:
            #
            # Allocate new NCN BMC
            #
            action_log(action, "Allocating NCN BMC IP address")
            bmc_ip = allocate_ip_address_in_subnet(action, sls_networks, "HMN", "bootstrap_dhcp")

            # Add BMC IP reservation to the HMN network.
            # Example: {"Aliases":["ncn-s001-mgmt"],"Comment":"x3000c0s13b0","IPAddress":"10.254.1.31","Name":"x3000c0s13b0"}
            bmc_ip_reservation = IPReservation(bmc_xname, bmc_ip, comment=bmc_xname, aliases=[bmc_alias])
            action_log(action, f"Temporally adding NCN BMC IP reservation to bootstrap_dhcp subnet in the HMN network: {bmc_ip_reservation.to_sls()}")

            sls_networks["HMN"].subnets()["bootstrap_dhcp"].reservations().update(
                {
                    bmc_ip_reservation.name(): bmc_ip_reservation
                }
            )

            #
            # Allocate new NCN IPs in SLS
            #
            action_log(action, "")
            action_log(action, "Allocating NCN IP addresses")
            
            for network_name in ["CAN", "CHN", "CMN", "HMN", "MTL", "NMN"]:
                if network_name not in sls_networks:
                    continue

                ncn_ips[network_name] = allocate_ip_address_in_subnet(action, sls_networks, network_name, "bootstrap_dhcp")

            action_log(action, f"Removing temporary NCN BMC IP reservation in the bootstrap_dhcp subnet for the HMN network")
            del sls_networks["HMN"].subnets()["bootstrap_dhcp"].reservations()[bmc_ip_reservation.name()]

        action_log(action, "")
        action_log(action, "=================================")
        action_log(action, "Management NCN IP Allocation")
        action_log(action, "=================================")
    
        action_log(action, "Network | IP Address")
        action_log(action, "--------|-----------")
        for network, ip in ncn_ips.items():
            action_log(action, f'{network:<8}| {ip}')

        action_log(action, "")
        action_log(action, "=================================")
        action_log(action, "Management NCN BMC IP Allocation")
        action_log(action, "=================================")
    
        action_log(action, "Network | IP Address")
        action_log(action, "--------|-----------")
        action_log(action, f'HMN     | {bmc_ip}')
        action_log(action, "")

        if not use_existing_ip_addresses:
            # Only for new IP addresses that have been allocated:
            # Validate the NCN and its BMC to be added does not have a IP reservation already defined for it
            # Also validate that none of the IP addresses we have allocated are currently in use in SLS.
            fail_sls_network_check = False
            for network_name, sls_network in sls_networks.items():
                for subnet in sls_network.subnets().values():
                    for ip_reservation in subnet.reservations().values():
                        # Verify no IP Reservations exist for the NCN
                        if ip_reservation.name() == args.alias:
                            fail_sls_network_check = True
                            action_log(action, f'Error found existing NCN IP Reservation in subnet {subnet.name()} network {network_name} in SLS: {ip_reservation.to_sls()}')
                            
                        # Verify no IP Reservations exist for the NCN BMC
                        if ip_reservation.name() == bmc_xname: 
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
                exit(1)
            action_log(action, f'Pass {args.xname} ({args.alias}) does not currently exist in SLS Networks')
            action_log(action, f'Pass {bmc_xname} ({bmc_alias}) does not currently exist in SLS Networks')
            action_log(action, f'Pass allocated IPs for NCN {args.xname} ({args.alias}) are not currently in use in SLS Networks')
            action_log(action, f'Pass allocated IP for NCN BMC {bmc_xname} ({bmc_alias}) are not currently in use in SLS Networks')
        
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
        action = verify_hsm_inventory_ethernet_interface_not_found(session, component_id=bmc_xname)
        action_log(action, f'Pass no EthernetInterfaces are associated with {bmc_xname} in HSM')
        print_action(action)

        # Validate allocated IPs are not in use in the HSM EthernetInterfaces table
        for network, ip in ncn_ips.items():
            action = verify_hsm_inventory_ethernet_interface_not_found(session, ip_address=ip)
            action_log(action, f"Pass {network} IP address {ip} is not currently in use in HSM Ethernet Interfaces")
            print_action(action)

        # Check to see if the BMC MAC address exists in HSM
        action, existing_bmc_ei = get_hsm_inventory_ethernet_interfaces(session, bmc_mac)
        if action["status"] == http.HTTPStatus.NOT_FOUND:
            action_log(action, "Pass BMC MAC address does not exist in HSM Ethernet Interfaces")
        elif action["status"] == http.HTTPStatus.OK:
            action_log(action, f'BMC MAC address exists in HSM Ethernet Interfaces: {existing_bmc_ei}')
        print_action(action)

        # Validate allocated BMC IP is not in use in the HSM EthernetInterfaces table
        # If the MAC Address associated with the BMC is already at the right IP, then we are good.
        existing_bmc_ip_matches = False
        if (existing_bmc_ei != None) and ("IPAddresses" in existing_bmc_ei) and (len(existing_bmc_ei["IPAddresses"]) == 1):
            existing_bmc_ip_matches = existing_bmc_ei["IPAddresses"][0]["IPAddress"] == str(bmc_ip)

        if not existing_bmc_ip_matches:
            action = verify_hsm_inventory_ethernet_interface_not_found(session, ip_address=bmc_ip)
            action_log(action, f"Pass BMC IP address {bmc_ip} is not currently in use in HSM Ethernet Interfaces")
            print_action(action)
        else:
            print("         Pass the BMC MAC address is currently associated with the allocated IP Address")
        
        # Validate NCN does not exist under state components
        verify_hsm_state_components_not_found(session, args.xname)

        # Validate the BMC of the NCN does not exist under state components
        verify_hsm_state_components_not_found(session, bmc_xname)

        # Validate the BMC of the NCN does not exist under inventory redfish endpoints
        verify_hsm_inventory_redfish_endpoints_not_found(session, bmc_xname)

        # Validate the NID is not in use by HSM 
        action, components = search_hsm_state_components(session, nid)
        if len(components) != 0:
            components = [comp["ID"] for comp in action["response"]["Components"]]

            action_log(action, f'Error allocated NID {nid} already in use by {",".join(components)} in HSM')
            print_action(action)
            exit(1)

        action_log(action, f"Pass allocated NID {nid} currently not in use in HSM")
        print_action(action)
        
        #
        # Validate contents of BSS
        #
        print("Performing validation checks against BSS")

        # Validate the NCN has no bootparameters
        verify_bss_bootparameters_not_found(session, args.xname)

        # Retrive the global boot parameters
        action, global_bootparams = get_bss_bootparameters(session, "Global")

        if not use_existing_ip_addresses:
            # Validate the NCN is not referenced in the Global boot parameters
            fail_host_records = False
            for host_record in global_bootparams["cloud-init"]["meta-data"]["host_records"]:
                # Check for NCN and NCN BMC
                for alias in host_record["aliases"]:
                    if alias.startswith(args.alias):
                        action_log(action, f'Error found NCN alias in Global host_records in BSS: {host_record}')
                        fail_host_records = True

                # Check for if this IP is one of our allocated IPs
                for network, ip in ncn_ips.items():
                    if host_record["ip"] == ip:
                        action_log(action, f'Error found {network} IP Address {ip} in Global host_records in BSS: {host_record}')
                        fail_host_records = True


                if host_record["ip"] == bmc_ip:
                        action_log(action, f'Error found NCN BMC IP Address {bmc_ip} in Global host_records in BSS: {host_record}')
                        fail_host_records = True


            if fail_host_records:
                print_action(action)
                exit(1)
            action_log(action, f"Pass {args.xname} does not currently exist in BSS Global host_records")
            print_action(action)
        else:
            # Validate the NCN has the expected data in the BSS Global boot parameters
            fail_host_records = False
            for host_record in global_bootparams["cloud-init"]["meta-data"]["host_records"]:
                for network_name, ip in ncn_ips.items():
                    # Verify each NCN IP is associated with correct NCN
                    expected_alias = f'{args.alias}.{network_name.lower()}'
                    if str(ip) == host_record["ip"]:
                        expected_aliases = [expected_alias]
                        if network_name == "NMN":
                            expected_aliases.append(args.alias)

                        if expected_aliases == host_record["aliases"]:
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
                if str(bmc_ip) == host_record["ip"]:
                    expected_aliases = [bmc_alias]
                    if expected_aliases == host_record["aliases"]:
                        action_log(action, f"Pass found existing BMC host_record with the IP address {ip} which contains the expected aliases of {expected_aliases}")
                    else:
                        fail_host_records = True
                        action_log(action, f'Error existing BMC host_record with IP address {ip} with aliases {host_record["aliases"]}, instead of {expected_aliases}')

                
                if bmc_alias in host_record["aliases"]:
                    if str(bmc_ip) == host_record["ip"]:
                        action_log(action, f"Pass found existing BMC host_record for alias {bmc_alias} which has the expected IP address of {bmc_ip}")
                    else:
                        fail_host_records = True
                        action_log(action, f'Error existing BMC host_record for alias {expected_alias} has the IP address of {host_record["ip"]}, instead of the expected {bmc_ip}')


            if fail_host_records:
                print_action(action)
                exit(1)

            # Validate the NCN being added is not configured as the 'first-master-hostname'
            first_master_hostname = global_bootparams["cloud-init"]["meta-data"]["first-master-hostname"]
            if first_master_hostname == args.alias:
                action_log(action, f'Error the NCN being added {args.alias} is currently configured as the "first-master-hostname" in the Global BSS Bootparameters')
                print_action(action)
                exit(1)
            else:
                action_log(action, f'Pass the NCN being added {args.alias} is not configured as the "first-master-hostname", currently {first_master_hostname} is in the Global BSS Bootparameters.')

            print_action(action)

        #
        # Validate BSS contains bootparameters for a NCN of a similar type
        #
        donor_ncn = None
        for ncn in existing_management_ncns:
            if ncn["ExtraProperties"]["SubRole"] == subrole:
                donor_ncn = ncn
                break
        if donor_ncn == None:
            print(f"Failed to find a Management NCN with subrole {subrole} to donate bootparameters")
            exit(1)
        
        donor_alias = ncn["ExtraProperties"]["Aliases"][0]
        print(f'Found existing NCN {donor_ncn["Xname"]} ({donor_alias}) of the same type to donate bootparameters to {args.xname} ({args.alias})')

        action, donor_bootparameters = get_bss_bootparameters(session,  donor_ncn["Xname"])
        action_log(action, f'Pass {donor_ncn["Xname"]} currently exists in BSS Bootparameters')
        print_action(action)

        # Modify donor bootparameters for the NCN being added:
        # This is what CSI does:
        # https://github.com/Cray-HPE/cray-site-init/blob/main/cmd/handoff-bss-metadata.go#L364-L396
            
        # Once the munging occurs CSI does this: https://github.com/Cray-HPE/cray-site-init/blob/main/cmd/handoff-bss-metadata.go#L286-L352
        
        # Determine the cabinet containing the node
        slot_xname = get_componet_parent(bmc_xname)
        chassis_xname = get_componet_parent(slot_xname)
        cabinet_xname = get_componet_parent(chassis_xname)

        # Build up the kernel command line parameters
        interface_kernel_params = []
        for interface, mac in macs.items():
            interface_kernel_params.append(f'ifname={interface}:{mac}')
            interface_kernel_params.append(f'ip={interface}:auto6')

        # Update kernel command line params
        donor_kernel_params = donor_bootparameters["params"].split()
        kernel_params = []

        for param in donor_kernel_params:
            if param.startswith("hostname="):
                kernel_params.append(f'hostname={args.alias}')
            elif param.startswith("ifname=") or (param.startswith("ip=") and (not param.startswith("ip=vlan"))):
                # Ignore MAC specific params.
                pass
            elif param.startswith("bond="):
                if bond_across_two_cards:
                    # Form the bond across mgmt0 and mgmt2
                    kernel_params.append("bond=bond0:mgmt0,mgmt2:mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3:9000")
                else:
                    # Form the bond across mgmt0 and mgmt1
                    kernel_params.append("bond=bond0:mgmt0,mgmt1:mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3:9000")

                kernel_params.extend(interface_kernel_params)
            elif param.startswith("metal.no-wipe"):
                kernel_params.append("metal.no-wipe=0")
            else:
                kernel_params.append(param)


        # Update BSS bootparameters
        ncn_cidrs = {}
        for network_name, ip in ncn_ips.items():
            bootstrap_dhcp_subnet = sls_networks[network_name].subnets()["bootstrap_dhcp"]
            ncn_cidrs[network_name] = f'{ip}/{bootstrap_dhcp_subnet.ipv4_network().prefixlen}'

        bootparams = copy.deepcopy(donor_bootparameters)
        bootparams["hosts"] = [args.xname]
        bootparams["params"] = " ".join(kernel_params)
        bootparams["cloud-init"]["user-data"]["hostname"] = args.alias
        bootparams["cloud-init"]["user-data"]["local_hostname"] = args.alias
        bootparams["cloud-init"]["user-data"]["ntp"]["allow"] = []
        for network_name, ip_cidr in ncn_cidrs.items():
            bootparams["cloud-init"]["user-data"]["ntp"]["allow"].append(ip_cidr)
        bootparams["cloud-init"]["meta-data"]["availability-zone"] = cabinet_xname
        bootparams["cloud-init"]["meta-data"]["instance-id"] = generate_instance_id()
        bootparams["cloud-init"]["meta-data"]["local-hostname"] = args.alias
        # bootparams["cloud-init"]["meta-data"]["region"] # This will remain the same. This is the name of the system.
        # bootparams["cloud-init"]["meta-data"]["shasta-role"] # This will remain the same for the particalar node type. ncn-master, ncn-storage, ncn-worker
        bootparams["cloud-init"]["meta-data"]["xname"] = args.xname
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

        print(f'Generated BSS bootparameters for {args.xname} ({args.alias}) from donor bootparameters')
        print(json.dumps(bootparams, indent=2))
    

        #
        # Create new hardware in SLS
        #
        node = {
            "Parent": bmc_xname,
            "Xname": args.xname,
            "Type": "comptype_node",
            "TypeString": "Node",
            "Class": "River",
            "ExtraProperties": {
                "NID": nid,
                "Role": "Management",
                "SubRole": subrole,
                "Aliases": [args.alias]
            }
        }
        
        mgmt_switch_connector = None
        if not is_m001:
            # Calculate VendorName for the switch port
            port = re.search("j(\d+)$", args.bmc_mgmt_switch_connector).group(1)
            vendor_name = None
            if mgmt_switch_brand == "Aruba":
                vendor_name = f"1/1/{port}"
            elif mgmt_switch_brand == "Dell":
                vendor_name = f"ethernet1/1/{port}"
            else:
                print(f"Unknown switch brand {mgmt_switch_brand} for {mgmt_switch_xname}")
                exit(1)

            mgmt_switch_connector = {
                "Parent": mgmt_switch_xname,
                "Xname": args.bmc_mgmt_switch_connector,
                "Type": "comptype_mgmt_switch_connector",
                "TypeString": "MgmtSwitchConnector",
                "Class": "River",
                "ExtraProperties": {
                    "VendorName": vendor_name,
                    "NodeNics": [bmc_xname]
                }
            }

        #
        # Update SLS with new hardware!
        #
        print(f'Creating {node["Xname"]} in SLS...')
        print(json.dumps(node, indent=2))
        if args.perform_changes:
            create_sls_hardware(session, node)
        else:
            print("Skipping due to dry run!")


        if not is_m001:
            print(f'Creating {mgmt_switch_connector["Xname"]} in SLS...')
            print(json.dumps(mgmt_switch_connector, indent=2))

            if args.perform_changes:
                create_sls_hardware(session, mgmt_switch_connector)
            else:
                print("Skipping due to dry run!")


        #
        # Update SLS networking for the new NCN
        #

        # Add IP Reservations for all of the networks that make sense
        for network_name, ip in ncn_ips.items():
            sls_network = sls_networks[network_name]
            # CAN
            # Master:  {"Aliases":["ncn-m002-can","time-can","time-can.local"],"Comment":"x3000c0s3b0n0","IPAddress":"10.101.5.134","Name":"ncn-m002"}
            # Worker:  {"Aliases":["ncn-w001-can","time-can","time-can.local"],"Comment":"x3000c0s7b0n0","IPAddress":"10.101.5.136","Name":"ncn-w001"}
            # Storage: {"Aliases":["ncn-s001-can","time-can","time-can.local"],"Comment":"x3000c0s13b0n0","IPAddress":"10.101.5.147","Name":"ncn-s001"}

            # CHN
            # Master:  {"Comment":"x3000c0s3b0n0","IPAddress":"10.101.5.198","Name":"x3000c0s3b0n0"}
            # Worker:  {"Comment":"x3000c0s7b0n0","IPAddress":"10.101.5.200","Name":"x3000c0s7b0n0"}
            # Storage: {"Comment":"x3000c0s13b0n0","IPAddress":"10.101.5.211","Name":"x3000c0s13b0n0"}

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
            #   - NCN Aliase is the IP reservation name
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
            name = args.alias
            if network_name == "CHN":
                name = args.xname

            # All NCN types have thier xname as the comment for their IP reservation
            comment = args.xname

            # For all networks except the CHN the following aliases are present
            #   - ncn-{*}-{network}
            #   - time-{network}
            #   - time-{network}.local
            aliases = []
            if network_name != "CHN":
                aliases.append(f'{args.alias}-{network_name.lower()}')
                aliases.append(f'time-{network_name.lower()}')
                aliases.append(f'time-{network_name.lower()}.local')

            # Storage nodes on the HMN have additional alias rgw-vip.hmn
            if network_name == "HMN" and subrole == "Storage":
                aliases.append("rgw-vip.hmn")

            # All NCNs on the NMN have the additional aliases:
            # - xname 
            # - ncn-{*}.local 
            if network_name == "NMN":
                aliases.append(args.xname)
                aliases.append(f'{args.alias}.local')
            
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
                bmc_ip_reservation = IPReservation(bmc_xname, bmc_ip, comment=bmc_xname, aliases=[bmc_alias])
                print(f"Adding NCN BMC IP reservation to bootstrap_dhcp subnet in the HMN network")
                print(json.dumps(bmc_ip_reservation.to_sls(), indent=2))

                sls_network.subnets()["bootstrap_dhcp"].reservations().update(
                    {
                        bmc_ip_reservation.name(): bmc_ip_reservation
                    }
                )

            print(f"Updating {network_name} network in SLS with updated IP reservations")
            if args.perform_changes:
                action = http_put(session, f'{SLS_URL}/networks/{network_name}', payload=sls_network.to_sls())
                if action["error"] != None:
                    action_log(action, f'Error failed to update {network_name} in SLS')
                    print_action(action)
                    exit(1)
                print_action(action)
            else:
                print("Skipping due to dry run!")

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
            #ei["ID"] = mac.lower().replace(":", "")
            ei["MACAddress"] = mac
            ei["ComponentID"] = args.xname
            ei["IPAddresses"] = []

            if interface == "mgmt0":
                ei["IPAddresses"].append({"IPAddress": str(ncn_ips["NMN"])})

            print(f"Adding MAC Addresses {mac} to HSM Inventory EthernetInterfaces")
            print(json.dumps(ei, indent=2))
            if args.perform_changes:
                create_hsm_inventory_ethernet_interfaces(session, ei)
            else:
                print("Skipping due to dry run!")

            

        bmc_ei = {}
        bmc_ei["MACAddress"] = bmc_mac
        bmc_ei["ComponentID"] = bmc_xname
        bmc_ei["IPAddresses"] = [{"IPAddress": str(bmc_ip)}]
        if existing_bmc_ei == None:
            # Create a new entry
            print(f"Adding BMC MAC Addresses {bmc_mac} to HSM Inventory EthernetInterfaces")
            print(json.dumps(bmc_ei, indent=2))
            if args.perform_changes:
                create_hsm_inventory_ethernet_interfaces(session, bmc_ei)
        else:
            # Update an existing entry
            print(f"Patching BMC MAC Addresses {bmc_mac} in HSM Inventory EthernetInterfaces")
            print(json.dumps(bmc_ei, indent=2))
            if args.perform_changes:
                patch_hsm_inventory_ethernet_interfaces(session, bmc_ei)
            else:
                print("Skipping due to dry run!")


        #
        # Update Global host_records in BSS with IPs
        #
        if not use_existing_ip_addresses:
            # Add NCN IPs
            for network_name, ip in ncn_ips.items():
                # For the different networks the master, worker, and storage nodes follow the same pattern
                # CAN: {"aliases":["ncn-m001.can"],"ip":"10.101.5.133"}
                # CHN: {"aliases":["ncn-m001.chn"],"ip":"10.101.5.197"}
                # CMN: {"aliases":["ncn-m001.cmn"],"ip":"10.101.5.19"}
                # HMN: {"aliases":["ncn-w001.hmn"],"ip":"10.254.1.10"}
                # NMN: {"aliases":["ncn-m001.nmn","ncn-m001"],"ip":"10.252.1.4"}
                # MTL: {"aliases":["ncn-w001.mtl"],"ip":"10.1.1.5"}
                
                host_record = {
                    "aliases": [f'{args.alias}.{network_name.lower()}'],
                    "ip": str(ip),
                }

                if network_name == "NMN":
                    host_record["aliases"].append(args.alias)
        
                print(f"Adding NCN IP reservation for the {network_name} network to Global host_records in BSS")
                print(json.dumps(host_record, indent=2))

                global_bootparams["cloud-init"]["meta-data"]["host_records"].append(host_record)

            # Add BMC IP
            # {"aliases":["ncn-m001-mgmt"],"ip":"10.254.1.3"}
            host_record = {
                "aliases": [bmc_alias],
                "ip": str(bmc_ip),
            }

            print(f"Adding NCN BMC IP reservation for the HMN Network to Global host_records in BSS")
            print(json.dumps(host_record, indent=2))
            global_bootparams["cloud-init"]["meta-data"]["host_records"].append(host_record)
            
            print(f"Updating Global bootparameters in BSS with updated host records")
            print(json.dumps(host_record, indent=2))
            if args.perform_changes:
                put_bss_bootparameters(session, global_bootparams)
            else:
                print("Skipping due to dry run!")


        #
        # Create new Bootparameters in BSS
        #

        print(f"Adding bootparameters for {args.xname} in BSS ")
        print(json.dumps(bootparams, indent=2))
        if args.perform_changes:
            put_bss_bootparameters(session, bootparams)
        else:
            print("Skipping due to dry run!")

        
        #
        # Update /etc/hosts on the NCNs with the newly allocated IPs
        #
        etc_hosts_actions = []
        if not args.skip_etc_hosts:
            if not use_existing_ip_addresses:
                print("Updating /etc/hosts with NCN IPs")
                etc_hosts_actions = create_update_etc_hosts_actions(existing_management_ncns, args.alias, args.xname, ncn_ips, bmc_ip, log_directory)
                print_command_actions(etc_hosts_actions)
            else:
                print('Leaving /etc/hosts unchanged')

            if args.perform_changes:
               run_command_actions(etc_hosts_actions)

        print('')
        print(f'{args.xname} ({args.alias}) has been added to SLS/HSM/BSS')
        if existing_bmc_ei != None and not existing_bmc_ip_matches:
            existing_bmc_ip = ",".join(existing_bmc_ei["IPAddresses"])
            print(f'        WARNING The NCN BMC currently has the IP address: {existing_bmc_ip}, and needs to have IP Address {bmc_ip}')

if __name__ == "__main__":
    sys.exit(main(sys.argv))

