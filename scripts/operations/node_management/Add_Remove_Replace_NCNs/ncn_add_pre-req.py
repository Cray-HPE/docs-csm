#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2022, 2025 Hewlett Packard Enterprise Development LP
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
from kubernetes import client, config
import base64
import sys
import json
import requests
import os
import logging
from urllib.parse import urljoin

from kubernetes.client import ApiException
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
import ipaddress
from datetime import datetime

# logger setup
log = logging.getLogger(__name__)
log.setLevel(logging.WARN)

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
log.addHandler(handler)


class Transcript(object):
    """
    Usage:

    start_log('logfile.log')
    print("inside file")
    stop_log()
    print("outside file")
    """


    def __init__(self, filename):
        self.terminal = sys.stdout
        self.logfile = open(filename, "a")


    def write(self, message):
        self.terminal.write(message)
        self.logfile.write(message)


    def flush(self):
        # this flush method is needed for python 3 compatibility.
        # this handles the flush command by doing nothing.
        # you might want to specify some extra behavior here.
        pass


def start_log(filename):
    """
    Start transcript, appending print output to given filename
    """

    sys.stdout = Transcript(filename)


def stop_log():
    """
    Stop transcript and return print functionality to normal
    """

    sys.stdout.logfile.close()
    sys.stdout = sys.stdout.terminal


class APIRequest(object):
    """
        Example use:
        api_request = APIRequest('http://api.com')
        response = api_request('GET', '/get/stuff')

        print (f"response.status_code")
        print (f"{response.status_code}")
        print()
        print (f"response.reason")
        print (f"{response.reason}")
        print()
        print (f"response.text")
        print (f"{response.text}")
        print()
        print (f"response.json")
        print (f"{response.json()}")
    """

    def __init__(self, base_url, headers=None):
        if not base_url.endswith('/'):
            base_url += '/'
        self._base_url = base_url

        if headers is not None:
            self._headers = headers
        else:
            self._headers = {}

    def __call__(self, method, route, **kwargs):

        if route.startswith('/'):
            route = route[1:]

        url = urljoin(self._base_url, route, allow_fragments=False)

        headers = kwargs.pop('headers', {})
        headers.update(self._headers)

        retry_strategy = Retry(
            total=10,
            backoff_factor=0.1,
            status_forcelist=[429, 500, 502, 503, 504],
            method_whitelist=["PATCH", "DELETE", "POST", "HEAD", "GET", "OPTIONS", "PUT"]
        )

        adapter = HTTPAdapter(max_retries=retry_strategy)
        http = requests.Session()
        http.mount("https://", adapter)
        http.mount("http://", adapter)

        response = http.request(method=method, url=url, headers=headers, **kwargs)

        if 'data' in kwargs:
            log.debug(f"{method} {url} with headers:"
                      f"{json.dumps(headers, indent=4)}"
                      f"and data:"
                      f"{json.dumps(kwargs['data'], indent=4)}")
        elif 'json' in kwargs:
            log.debug(f"{method} {url} with headers:"
                      f"{json.dumps(headers, indent=4)}"
                      f"and JSON:"
                      f"{json.dumps(kwargs['json'], indent=4)}")
        else:
            log.debug(f"{method} {url} with headers:"
                      f"{json.dumps(headers, indent=4)}")
        log.debug(f"Response to {method} {url} => {response.status_code} {response.reason}"
                  f"{response.text}")

        return response


# setup api object
ingress_api = APIRequest('https://api-gw-service-nmn.local')


def integer_question(question):
    """
    Ask for user input requiring an integer answer.

    :param question:
    :return:
    """
    while (True):
        print('\nPlease enter answer as an integer.')
        raw_answer = input(question + '\n')

        try:
            answer = int(raw_answer)
        except ValueError:
            print('ERROR: invalid answer.  Please try again.\n')
            continue

        if isinstance(answer, int) and answer >= 0:
            break

    return answer


def boolean_question(question):
    """Ask for a yes/no response and return True or False."""
    valid_answers = {
        "yes": True,
        "no": False,
    }

    while True:
        print('\nPlease answer with yes or no.')
        raw_answer = input(question + ' [yes/no]\n').strip().lower()
        if raw_answer == "":
            return False
        if raw_answer in valid_answers:
            return valid_answers[raw_answer]
        print('ERROR: invalid answer. Please respond with yes or no.\n')

def confirmation_question():
    """
    Ask for user input to confirm they want to proceed.

    :param question:
    :return:
    """
    while (True):
        print('\nYou are about to make DESTRUCTIVE changes to the system.\n')
        print('If you are sure you want to proceed.  Please type: PROCEED\n')
        print('If you want to stop.  Type: exit or press ctrl-c\n')
        answer = input()

        if answer == 'PROCEED':
            break
        if answer == 'exit':
            exit(0)


def get_token():
    """
    Get istio ingress token.
    :return:
    """

    # setup kubernetes client
    config.load_kube_config()
    v1 = client.CoreV1Api()

    # get kubernetes admin secret
    secret = v1.read_namespaced_secret("admin-client-auth", "default").data

    # decode the base64 secret
    token = base64.b64decode(secret['client-secret']).decode('utf-8')

    # create post data to keycloak istio ingress
    token_data = {'grant_type': 'client_credentials', 'client_id': 'admin-client', 'client_secret': token}

    # query keyclock
    token_url = '/keycloak/realms/shasta/protocol/openid-connect/token'
    token_resp = ingress_api('POST', token_url, data=token_data)
    access_token = token_resp.json()['access_token']
    log.debug(f'The bearer access token is: {access_token}')

    return access_token


def get_api_request(url, api_header):
    """
    GET api query
    :param url:
    :param api_header:
    :return:
    """

    resp = ingress_api('GET', url, headers=api_header)

    return resp.json()


def post_api_request(url, api_header, json={}):
    """
    POST api query
    :param url:
    :param api_header:
    :param json:
    :return:
    """
    resp = ingress_api('POST', url, headers=api_header, json=json)

    return resp.json()

def patch_api_request(url, api_header, json={}):
    """
    PATCH api query
    :param url:
    :param api_header:
    :param json:
    :return:
    """
    resp = ingress_api('PATCH', url, headers=api_header, json=json)

    return resp.json()

def put_api_request(url, api_header, data={}):
    """
    POST api query
    :param url:
    :param api_header:
    :param json:
    :return:
    """
    resp = ingress_api('PUT', url, headers=api_header, json=data)

    return resp.json()

def get_network_list(sls_networks):

    network_list = set()

    for network in sls_networks:
        if 'ExtraProperties' in network:
            if 'Subnets' in network['ExtraProperties']:
                for subnet in network['ExtraProperties']['Subnets']:
                    if 'FullName' in subnet and 'Bootstrap' in subnet['FullName']:
                        network_list.add(network['Name'])
    return network_list


def restart_kubernetes_deployment(deployment, namespace):

    # setup kubernetes client
    config.load_kube_config()
    v1 = client.CoreV1Api()
    v1_apps = client.AppsV1Api()


    # get kubernetes admin secret
    secret = v1.read_namespaced_secret("admin-client-auth", "default").data
    now = datetime.utcnow()
    now = str(now.isoformat("T") + "Z")
    body = {
        'spec': {
            'template':{
                'metadata': {
                    'annotations': {
                        'kubectl.kubernetes.io/restartedAt': now
                    }
                }
            }
        }
    }
    try:
        v1_apps.patch_namespaced_deployment(deployment, namespace, body, pretty='true')
    except ApiException as e:
        print("Exception when calling AppsV1Api->read_namespaced_deployment_status: %s\n" % e)


def delete_kea_lease(ip, token):
    """
    delete active leases from Kea via Kea api
    :param token:
    :return:
    """

    kea_url = '/apis/dhcp-kea'
    kea_request_header = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}
    kea_delete_data = {'command': 'lease4-del', 'service': ['dhcp4'], "arguments": {"ip-address": ip}}

    ingress_api('POST', kea_url, headers=kea_request_header, json=kea_delete_data)


def delete_smd_record(smd_id, token):
    """
    delete ethernetInterfaces record from SMD
    :param smd_id:
    :param token:
    :return:
    """

    smd_url = '/apis/smd/hsm/v2/Inventory/EthernetInterfaces/' + smd_id
    smd_request_header = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}

    ingress_api('DELETE', smd_url, headers=smd_request_header)

def required_ip_counts(add_ncn_count, adding_fmns, network):
    """Calculate how many new static IPs are required for a network.

    Returns the number of additional IP reservations needed for the supplied
    network, accounting for whether the nodes being added are Fabric Manager
    NCNs. FMN nodes consume extra addresses for virtual IPs on NMN/HMN
    networks, while non-FMN nodes only require the NCN and its BMC on HMN.
    """
    if adding_fmns:
        if network == "HMN":
            # BMC + NCN + VIP for each node
            return add_ncn_count * 2 + 1
        if network == "NMN":
            # NCN + VIP for each node
            return add_ncn_count + 1
        # other networks only need one IP per NCN
        return add_ncn_count
    # non-FMN
    if network == "HMN":
        return add_ncn_count * 2
    return add_ncn_count

def add_ncn_network_update(add_ncn_count, network_list, api_header, sls_networks, adding_fmns=False):
    """
    Updates SLS networks by expanding static IP range and moving DHCP IP pool.
    :param add_ncn_count:
    :param network_list:
    :param api_header:
    :param sls_networks:
    :return:
    """
    networks_data = {}
    ip_reservation = {}
    ip_dhcp_pool_start = {}
    ip_dhcp_pool_end = {}
    new_ip_dhcp_pool_start = {}
    ips_to_delete_from_smd = {}
    network_has_fmn_vip = {}

    for network in sls_networks:
        if network['Name'] in network_list:
            networks_data[network['Name']] = network

    for name in networks_data:
        for i in range(len(networks_data[name]['ExtraProperties']['Subnets'])):
            if 'Bootstrap' in networks_data[name]['ExtraProperties']['Subnets'][i]['FullName']:
                ip_reservation[name] = []
                ip_reservation[name] = networks_data[name]['ExtraProperties']['Subnets'][i]['IPReservations']
                ip_dhcp_pool_start[name] = networks_data[name]['ExtraProperties']['Subnets'][i]['DHCPStart']
                ip_dhcp_pool_end[name] = networks_data[name]['ExtraProperties']['Subnets'][i]['DHCPEnd']
                network_has_fmn_vip[name] = any(
                    reservation.get('Name') == 'fmn-vip'
                    or 'fmn-vip' in reservation.get('Aliases', [])
                    for reservation in ip_reservation[name]
                )

    for network in network_list:
        ip_set = set()
        sorted_ip_set = set()
        for i in range(len(ip_reservation[network])):
            if ip_reservation[network][i]['IPAddress'] not in ip_set:
                ip_set.add(ip_reservation[network][i]['IPAddress'])

        sorted_ip_set = sorted(ip_set, key=ipaddress.IPv4Address)
        last_ip = len(sorted_ip_set) - 1
        last_reserved_ip = sorted_ip_set[last_ip]
        start_dhcp_pool = ip_dhcp_pool_start[network]
        ip_white_space = int(ipaddress.IPv4Address(str(start_dhcp_pool))) - int(
            ipaddress.IPv4Address(str(last_reserved_ip)))

        print()
        print(f'Checking {network}.')
        print(f'last_reserved_ip: {last_reserved_ip}    start_dhcp_pool:{start_dhcp_pool}')
        if adding_fmns:
            has_fmn_vip = network_has_fmn_vip.get(network, False)
            if has_fmn_vip:
                print(f"{network} already has an existing fmn-vip reservation. Not adding additional VIP")
                adding_fmns = False
            else:
                print(f"{network} does not have an existing fmn-vip reservation. Will add VIP along with FMN NCN(s)")
        if ip_white_space < 0:
            print(f'FATAL last_reserved_ip {last_reserved_ip} exceeds start_dhcp_pool {start_dhcp_pool}')
            print(f'Verify DHCPStart and DHCPEnd are correct for the {network} network in SLS.')
            sys.exit(1)
        print(f'The space between last_reserved_ip and start_dhcp_pool is {ip_white_space} IP.\n')
        log.info(f'Unsorted static ips:'
                  f' {ip_set}')
        log.info(f'Sorted static ips:'
                  f'{sorted_ip_set}')
        log.info(f'Last IP index of sorted static IP: {len(sorted_ip_set)-1}')


        ips_to_delete_from_smd[network] = set()
        new_ip_dhcp_pool_start[network] = ''
        ip_shift = 0
        if add_ncn_count >= ip_white_space-1:
            print('There is not enough static IP space to add an NCN. Adjusting DHCP pool start.')
            ips_needed = required_ip_counts(add_ncn_count, adding_fmns, network)
            for offset in range(1, ips_needed + 1):
                ip = ipaddress.IPv4Address(last_reserved_ip) + offset
                ips_to_delete_from_smd[network].add(str(ip))
            ip_shift = ips_needed

            temp = ipaddress.IPv4Address(start_dhcp_pool) + ip_shift
            new_ip_dhcp_pool_start[network] = str(temp)

        if new_ip_dhcp_pool_start[network] == '':
            new_ip_dhcp_pool_start[network] = start_dhcp_pool
        elif ipaddress.ip_address(new_ip_dhcp_pool_start[network]) >= ipaddress.ip_address(ip_dhcp_pool_end[network]):
            log.error(f'New {network} DHCPStart value {new_ip_dhcp_pool_start[network]} exceeds available DHCP pool capacity.')
            sys.exit(1)
        else:
            new_ip_dhcp_pool_start[network] = str(temp)

            print("IPs to be removed from SMD EthernetInterfaces and Kea active leases:")
            print(ips_to_delete_from_smd)
            print()
            print(f'add_ncn_count: {add_ncn_count}\n'
                  f'ip_dhcp_pool_start:\n{ip_dhcp_pool_start}\n'
                  f'new_ip_dhcp_pool_start: \n{new_ip_dhcp_pool_start}\n')

    for network in networks_data:
        network_update = []
        network_update.append(networks_data[network])
        for i in range(len(network_update[0]['ExtraProperties']['Subnets'])):
            if 'Bootstrap' in network_update[0]['ExtraProperties']['Subnets'][i]['FullName']:
                log.info('Checking for boot strap network')
                log.info(f"Network: {network_update[0]['Name']} dhcp_start: {network_update[0]['ExtraProperties']['Subnets'][i]['DHCPStart']}")
                network_update[0]['ExtraProperties']['Subnets'][i]['DHCPStart'] = new_ip_dhcp_pool_start[network]
                log.info(f"Network: {network_update[0]['Name']} dhcp_end: {network_update[0]['ExtraProperties']['Subnets'][i]['DHCPStart']}")

        # update sls data
        # place holder print out
        log.info(f"sls_network_update = put_api_request('/apis/sls/v1/networks/' + {network}, {api_header}, {json.dumps(network_update[0])}")
        # sls update
        sls_network_update = put_api_request('/apis/sls/v1/networks/' + network, api_header, network_update[0])

    return ips_to_delete_from_smd


def update_smd_and_kea(ips_update_in_smd, api_header, token):
    """
    Update SMD and Kea by remove reservations on conflicting IPs for the additional NCNs
    :param ips_update_in_smd:
    :param api_header:
    :return:
    """

    #print(ips_update_in_smd)
    xname_list = []

    for network in ips_update_in_smd:
        for ip in ips_update_in_smd[network]:
            log.info (f'Checking {ip} in SMD EthernetInterfaces')
            search_result = get_api_request('/apis/smd/hsm/v2/Inventory/EthernetInterfaces?IPAddress=' + ip, api_header)
            log.info (f'Results from searching SMD EthernetInterfaces table:'
                  f'{search_result}')
            log.debug(f'Number of results found: {len(search_result)}')
            if len(search_result) == 1:
                smd_id = search_result[0]['ID']
                smd_xname = search_result[0]['ComponentID']
                post_data = {'IPAddresses': []}
                if smd_xname != '':
                    xname_list.append(smd_xname)
                # placeholder print out
                log.info (f"patch_api_request('/apis/smd/hsm/v2/Inventory/EthernetInterfaces/' + {smd_id}, {api_header}, {json.dumps(post_data)}")
                # smd update
                patch_api_request('/apis/smd/hsm/v2/Inventory/EthernetInterfaces/' + smd_id, api_header, post_data)
                # placeholder print out
                log.warning (f'Deleting {json.dumps(post_data)} from SMD EthernetInterfaces.')
                # delete SMD ethernetInterfaces record
                delete_smd_record(smd_id, token)
                log.warning (f'Deleting {ip} from kea active leases.')
                #kea lease delete
                delete_kea_lease(ip, token)
            if len(search_result) > 1:
                print(f'There are multiple entries for {ip}.\n'
                      f'Exiting now to prevent other issues.\n'
                      f'Please fix duplicate IP manually and verify IP data in SMD EthernetInterfaces\n')
                exit(1)

    return xname_list


def main():
    os.system('clear')

    # backup file location
    timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    backup_folder = '/tmp/ncn_task_backups' + timestamp
    os.mkdir(backup_folder)

    start_log(backup_folder + '/ncn_pre-req.log')

    print('The prerequisite script prepares adding NCNs by adjusting SLS network configurations.\n\n')

    question = 'How many NCNs would you like to add? Do not include NCNs to be removed or moved.'
    add_ncn_count = integer_question(question)
    adding_fmns = boolean_question('Are the NCNs to be added are Fabric Manager Nodes (FMNs)?')

    # get token
    token = get_token()
    os.system(f'export TOKEN={token}')

    api_header = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}

    # get bss boot params
    bss_boot_params = get_api_request('/apis/bss/boot/v1/bootparameters', api_header)
    with open(backup_folder + '/bss_boot_params.json', 'w') as outfile:
        json.dump(bss_boot_params, outfile)

    # get sls dumpstate
    sls_dump = get_api_request('/apis/sls/v1/dumpstate', api_header)
    with open(backup_folder + '/sls_dump.json', 'w') as outfile:
        json.dump(sls_dump, outfile)

    # get sls networks
    sls_networks = get_api_request('/apis/sls/v1/networks', api_header)
    with open(backup_folder + '/sls_networks.json', 'w') as outfile:
        json.dump(sls_networks, outfile)

    # get smd data
    smd_ethernet_interfaces = get_api_request('/apis/smd/hsm/v2/Inventory/EthernetInterfaces', api_header)
    with open(backup_folder + '/smd_ethernet_interfaces.json', 'w') as outfile:
        json.dump(smd_ethernet_interfaces, outfile)

    # list networks we want to check
    network_list = get_network_list(sls_networks)

    log.info(f'sls_networks dump:'
              f'{json.dumps(sls_networks)}')
    log.info(f'smd_ethernet_interfaces dump:'
              f'{json.dumps(smd_ethernet_interfaces)}')
    log.info(f'add_ncn_count: {add_ncn_count}')
    log.info(f'network_list {network_list}')
    log.info(f'adding_fmns: {adding_fmns}')

    # make changes to network data for NCN add
    if add_ncn_count > 0:
        confirmation_question()
        ips_update_in_smd = add_ncn_network_update(add_ncn_count, network_list, api_header, sls_networks, adding_fmns)
        update_smd_and_kea(ips_update_in_smd, api_header, token)
    else:
        stop_log()
        print(f'prerequisite to prepare NCNs for removal, move and add\n'
        f'Network expansion COMPLETED\n'
        f'Log and backup of SLS, BSS and SMD can be found at: {backup_folder}\n')
        sys.exit(0)

    print(f'prerequisite to prepare NCNs for removal, move and add\n'
          f'Network expansion COMPLETED\n'
          f'Log and backup of SLS, BSS and SMD can be found at: {backup_folder}\n')
    print(f'Restarting cray-dhcp-kea')
    restart_kubernetes_deployment('cray-dhcp-kea', 'services')
    stop_log()

if __name__ == '__main__':
    main()
