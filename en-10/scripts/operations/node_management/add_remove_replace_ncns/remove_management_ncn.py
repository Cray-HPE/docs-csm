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

import argparse
import http
import json
import logging
import os
import pathlib
import re
import requests
import shutil
import subprocess
import sys
import urllib3

BASE_URL = ''
BSS_URL = ''
HSM_URL = ''
SLS_URL = ''
KEA_URL = ''

# This is the list of NCNs for which the IPs should not be removed from /etc/hosts
NCN_DO_NOT_REMOVE_IPS = [
    'ncn-m001', 'ncn-m002', 'ncn-m003',
    'ncn-w001', 'ncn-w002', 'ncn-w003',
    'ncn-s001', 'ncn-s002', 'ncn-s003',
]


class Logger:
    def __init__(self):
        self.log_file = None

    def init_logger(self, log_file, verbose=False):
        self.log_file = log_file
        if log_file:
            if verbose:
                logging.basicConfig(filename=log_file, filemode='w', level=logging.DEBUG,
                                    format='%(levelname)s: %(message)s')
            else:
                logging.basicConfig(filename=log_file, filemode='w', level=logging.INFO,
                                    format='%(levelname)s: %(message)s')
            # the encoding argument is not in python 3.6.15
            # logging.basicConfig(filename=log_file, filemode='w', level=logging.INFO, encoding='utf-8',
            #                     format='%(levelname)s: %(message)s')

    def info(self, message):
        print(message)
        if self.log_file:
            logging.info(message)

    def warning(self, message):
        print(f'Warning: {message}')
        if self.log_file:
            logging.warning(message)

    def error(self, message):
        print(f'Error: {message}')
        if self.log_file:
            logging.error(message)


log = Logger()


class State:
    def __init__(self, xname=None, directory=None, dry_run=False, verbose=False):
        self.xname = xname
        self.parent = None
        self.ncn_name = ""
        self.aliases = set()
        self.ip_reservation_aliases = set()
        self.ip_reservation_ips = set()
        self.hsm_macs = set()
        self.workers = set()
        self.remove_ips = True
        self.ifnames = []
        self.bmc_mac = None
        self.verbose = verbose
        self.ipmi_username = None
        self.ipmi_password = None
        self.run_ipmitool = False

        if directory and xname:
            self.directory = os.path.join(directory, xname)
        else:
            self.directory = directory

        if self.directory:
            # todo possibly add check that prevents saved files from being overwritten
            # file_list = os.listdir(self.directory)
            # if 'dry-run' in file_list:
            #     # continue because the previous run was a dry-run
            #     pass
            # elif len(os.listdir(self.directory)) != 0:
            #     print(f'Error: Save directory is not empty: {self.directory}. Use --force option to over write it.')
            #     sys.exit(1)

            dry_run_flag_file = os.path.join(self.directory, 'dry-run')
            # remove directory if previous run was a dry run
            if os.path.exists(dry_run_flag_file):
                shutil.rmtree(self.directory)

            # create the directory
            if not os.path.exists(self.directory):
                os.makedirs(self.directory)

            if dry_run:
                pathlib.Path(dry_run_flag_file).touch()
            else:
                if os.path.exists(dry_run_flag_file):
                    os.remove(dry_run_flag_file)

    def save(self, name, data):
        if self.directory:
            file = os.path.join(self.directory, f'{name}.json')
            with open(file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)


class CommandAction:
    def __init__(self, command, verbose=False):
        self.command = command
        self.has_run = False
        self.return_code = -1
        self.stdout = None
        self.stderr = None
        self.verbose = verbose


class HttpAction:
    def __init__(self, method, url, logs=None, request_body="", response_body="", completed=False, success=False):
        self.method = method
        self.url = url
        self.logs = [] if logs is None else logs
        self.request_body = request_body
        self.response_body = response_body
        self.completed = completed
        self.success = success
        self.response = None

    def log(self, message):
        self.logs.append(message)

    def get_response_body(self, default_value=None):
        if default_value is None:
            return self.response_body
        if self.response_body:
            return self.response_body
        return default_value


def setup_urls(args):
    global BASE_URL
    global BSS_URL
    global HSM_URL
    global SLS_URL
    global KEA_URL

    if args.base_url:
        BASE_URL = args.base_url
    else:
        BASE_URL = 'https://api-gw-service-nmn.local/apis'

    if args.bss_url:
        BSS_URL = args.bss_url
    elif args.test_urls:
        BSS_URL = 'http://localhost:27778/boot/v1'
    else:
        BSS_URL = f'{BASE_URL}/bss/boot/v1'

    if args.hsm_url:
        HSM_URL = args.hsm_url
    elif args.test_urls:
        HSM_URL = 'http://localhost:27779/hsm/v2'
    else:
        HSM_URL = f'{BASE_URL}/smd/hsm/v2'

    if args.sls_url:
        SLS_URL = args.sls_url
    elif args.test_urls:
        SLS_URL = 'http://localhost:8376/v1'
    else:
        SLS_URL = f'{BASE_URL}/sls/v1'

    KEA_URL = f'{BASE_URL}/dhcp-kea'


def print_urls():
    log.info(f'BSS_URL: {BSS_URL}')
    log.info(f'HSM_URL: {HSM_URL}')
    log.info(f'SLS_URL: {SLS_URL}')
    log.info(f'KEA_URL: {KEA_URL}')


def print_summary(state):
    log.info('Summary:')
    log.info(f'    Logs: {state.directory}')
    log.info(f'    xname: {state.xname}')
    log.info(f'    ncn_name: {state.ncn_name}')
    log.info(f'    ncn_macs:')
    log.info(f'        ifnames: {", ".join(state.ifnames)}')
    log.info(f'        bmc_mac: {state.bmc_mac if state.bmc_mac else "Unknown"}')


def print_action(action):
    if action.completed:
        if action.success:
            log.info(f"Called:  {action.method.upper()} {action.url}")
        else:
            log.error(f"Failed:  {action.method.upper()} {action.url}")
            log.info(json.dumps(action.response_body, indent=2))
    else:
        log.info(f"Planned: {action.method.upper()} {action.url}")

    for a_log in action.logs:
        log.info('         ' + a_log)


def print_actions(actions):
    for action in actions:
        print_action(action)


def print_command_action(action):
    if action.has_run:
        log.info(f'Ran:     {" ".join(action.command)}')
        if action.return_code != 0:
            log.error(f'         Failed: {action.return_code}')
            log.info(f'         stdout:\n{action.stdout}')
            log.info(f'         stderr:\n{action.stderr}')
        elif action.verbose:
            log.info(f'         stdout:\n{action.stdout}')
            if action.stderr:
                log.info(f'         stderr:\n{action.stderr}')
    else:
        log.info(f'Planned: {" ".join(action.command)}')


def print_command_actions(actions):
    for action in actions:
        print_command_action(action)


def http_get(session, actions, url, exit_on_error=True):
    r = session.get(url)
    action = HttpAction('get', url, response_body=r.text, completed=True)
    actions.append(action)
    action.response = r
    if r.status_code == http.HTTPStatus.OK:
        action.success = True
    elif exit_on_error:
        log_error_and_exit(actions, str(action))
    return action


def log_error_and_exit(actions, message):
    print_actions(actions)
    log.error(f'{message}')
    sys.exit(1)


def node_bmc_to_enclosure(xname_for_bmc):
    p = re.compile('^(x[0-9]{1,4}c0s[0-9]+)(b)([0-9]+)$')
    if p.match(xname_for_bmc):
        # convert node bmc to enclosure, for example, convert x3000c0s36b0 to x3000c0s36e0
        enclosure = re.sub(p, r'\1e\3', xname_for_bmc)
        return enclosure
    return None


def add_delete_action_if_component_present(actions, state, session, url, save_file):
    action = http_get(session, actions, url, exit_on_error=False)
    if action.success:
        state.save(save_file, json.loads(action.response_body))
        actions.append(HttpAction('delete', url))
    not_found = action.response.status_code == http.HTTPStatus.NOT_FOUND
    if not_found:
        action.success = True
        action.log('The item does not need to be deleted, because it does not exist.')


def validate_ipmi_config(state):
    if state.run_ipmitool:
        if not state.ipmi_password:
            log.error('IPMI_PASSWORD not set')
            log.error('The environment variable IPMI_PASSWORD is required')
            log.error('It should be set to the password of the BMC that is being removed')
            sys.exit(1)
        if not state.ipmi_username:
            log.error('IPMI_USERNAME not set')
            log.error('The environment variable IPMI_USERNAME is required')
            log.error('It should be set to the username of the BMC that is being removed')
            sys.exit(1)


def create_sls_actions(session, state):
    actions = []

    hardware_action = http_get(session, actions, f'{SLS_URL}/hardware')
    networks_action = http_get(session, actions, f'{SLS_URL}/networks')

    # Find xname in hardware and get aliases
    found_hardware_for_xname = False
    hardware_list = json.loads(hardware_action.response_body)
    for hardware in hardware_list:
        extra_properties = hardware.get('ExtraProperties', {})

        if state.xname == hardware['Xname']:
            type_string = hardware.get('TypeString')
            role = extra_properties.get('Role')
            sub_role = extra_properties.get('SubRole')
            if type_string != 'Node' or role != 'Management' or sub_role not in ['Worker', 'Storage', 'Master']:
                log_error_and_exit(
                    actions,
                    f'{state.xname} is Type: {type_string}, Role: {role}, SubRole: {sub_role}. ' +
                    'The node must be Type: Node, Role: Management, SubRole: one of Worker, Storage, or Master.')

            found_hardware_for_xname = True
            state.save(f'sls-hardware-{state.xname}', hardware)

            state.parent = hardware.get('Parent')
            hardware_action.log(
                       f'Found Hardware: Xname: {state.xname}, ' +
                       f'Parent: {state.parent}, ' +
                       f'TypeString: {hardware["TypeString"]}, ' +
                       f'Role: {hardware.get("ExtraProperties").get("Role")}')

            state.aliases.update(extra_properties.get('Aliases', []))
            hardware_action.log(f'Aliases: {state.aliases}')

    alias_count = len(state.aliases)
    if alias_count != 1:
        log.warning(f'Expected to find only one alias. Instead found {state.aliases}')
    if alias_count > 0:
        state.ncn_name = list(state.aliases)[0]
    log.info(f'xname: {state.xname}')
    log.info(f'ncn name: {state.ncn_name}')

    if state.ncn_name in NCN_DO_NOT_REMOVE_IPS:
        state.remove_ips = False

    # Requires that the parent is known.
    # The loop through the hardware_list above finds the given node and parent
    # That is why this must loop through the hardware list again after the loop above.
    hardware_connectors = []
    for hardware in hardware_list:
        extra_properties = hardware.get('ExtraProperties', {})
        # Check for nic connections
        for nic in extra_properties.get("NodeNics", []):
            if nic == state.parent:
                hardware_connectors.append(hardware.get('Xname'))
                state.save(f'sls-hardware-{hardware.get("Xname")}', hardware)
                hardware_action.log(f'Found Connector Hardware: Xname: {hardware.get("Xname")}, NodeNic: {nic}')

        type_string = hardware.get('TypeString')
        role = extra_properties.get('Role')
        sub_role = extra_properties.get('SubRole')
        if type_string == 'Node' and role == 'Management' and sub_role in ['Worker', 'Storage', 'Master']:
            aliases = extra_properties.get('Aliases', [])
            for alias in aliases:
                if alias not in state.aliases:
                    state.workers.add(alias)

    for connector in hardware_connectors:
        actions.append(HttpAction('delete', f'{SLS_URL}/hardware/{connector}'))

    if found_hardware_for_xname:
        actions.append(HttpAction('delete', f'{SLS_URL}/hardware/{state.xname}'))
        state.save('sls-hardware', hardware_list)
    else:
        log_error_and_exit(actions, f'Failed to find sls hardware entry for xname: {state.xname}')

    # Find network references for the aliases and the parent
    networks = json.loads(networks_action.response_body)
    state.save('sls-networks', networks)
    for network in networks:
        network_name = network.get("Name")
        if network_name == 'HSN':
            # Skip the HSN network. This network is owned by slingshot.
            continue

        logs = []
        network_has_changes = False
        extra_properties = network.get('ExtraProperties')
        subnets = extra_properties['Subnets']
        if subnets is None:
            continue
        for subnet in subnets:
            ip_reservations = subnet.get('IPReservations')
            if ip_reservations is None:
                continue
            new_ip_reservations = []
            subnet_has_changes = False
            for ip_reservation in ip_reservations:
                rname = ip_reservation['Name']
                if rname not in state.aliases and rname != state.parent and rname != state.xname:
                    new_ip_reservations.append(ip_reservation)
                else:
                    subnet_has_changes = True
                    a = ip_reservation.get('Aliases')
                    if a:
                        state.ip_reservation_aliases.update(ip_reservation.get('Aliases'))
                    state.ip_reservation_aliases.add(ip_reservation.get('Name'))
                    state.ip_reservation_ips.add(ip_reservation.get('IPAddress'))
                    if state.remove_ips:
                        logs.append(
                            f'Removed IP Reservation in {network["Name"]} ' +
                            f'in subnet {subnet["Name"]} for {ip_reservation["Name"]}')
                    logs.append(
                        'IP Reservation Details: ' +
                        f'Name: {ip_reservation.get("Name")}, ' +
                        f'IPAddress: {ip_reservation.get("IPAddress")}, ' +
                        f'Aliases: {ip_reservation.get("Aliases")}')
                    state.save(f'sls-ip-reservation-{network["Name"]}-{subnet["Name"]}-{ip_reservation["Name"]}',
                               ip_reservation)
            if state.remove_ips and subnet_has_changes:
                network_has_changes = True
                subnet['IPReservations'] = new_ip_reservations
        if state.remove_ips and network_has_changes:
            request_body = json.dumps(network)
            action = HttpAction(
                'put', f'{SLS_URL}/networks/{network["Name"]}', logs=logs, request_body=request_body)
            actions.append(action)
    return actions


def create_hsm_actions(session, state):
    actions = []

    # xname ethernet interfaces
    ethernet_xname_action = http_get(session, actions,
                                     f'{HSM_URL}/Inventory/EthernetInterfaces?ComponentId={state.xname}')

    ethernet_list = json.loads(ethernet_xname_action.response_body)
    for ethernet in ethernet_list:
        ethernet_id = ethernet.get('ID')
        actions.append(HttpAction('delete', f'{HSM_URL}/Inventory/EthernetInterfaces/{ethernet_id}'))
        state.save(f'hsm-ethernet-interface-{ethernet_id}', ethernet)
        mac = ethernet.get('MACAddress')
        if mac:
            state.hsm_macs.add(mac)

    # bmc (parent) ethernet interfaces
    ethernet_parent_action = http_get(session, actions,
                                      f'{HSM_URL}/Inventory/EthernetInterfaces?ComponentId={state.parent}')

    ethernet_list = json.loads(ethernet_parent_action.response_body)
    for ethernet in ethernet_list:
        ethernet_id = ethernet.get('ID')
        actions.append(HttpAction('delete', f'{HSM_URL}/Inventory/EthernetInterfaces/{ethernet_id}'))
        state.save(f'hsm-ethernet-interface-{ethernet_id}', ethernet)
        mac = ethernet.get('MACAddress')
        if mac:
            state.hsm_macs.add(mac)

    # delete parent redfish endpoints
    add_delete_action_if_component_present(
        actions, state, session, f'{HSM_URL}/Inventory/RedfishEndpoints/{state.parent}', f'hsm-redfish-endpoints-{state.parent}')

    # delete xname from component state
    add_delete_action_if_component_present(
        actions, state, session, f'{HSM_URL}/State/Components/{state.xname}', f'hsm-component-{state.xname}')

    # delete parent from component state
    add_delete_action_if_component_present(
        actions, state, session, f'{HSM_URL}/State/Components/{state.parent}', f'hsm-component-{state.parent}')

    # delete node enclosure for parent from component state
    node_enclosure_xname = node_bmc_to_enclosure(state.parent)
    if node_enclosure_xname:
        add_delete_action_if_component_present(
            actions, state, session, f'{HSM_URL}/State/Components/{node_enclosure_xname}', f'hsm-component-{node_enclosure_xname}')
    else:
        log.error(f'failed to create enclosure xname for parent {state.parent}')

    return actions


def bss_params_to_ifnames(params):
    result = []
    arg_list = params.split(' ')
    for arg in arg_list:
        if arg.startswith('ifname='):
            key_value = arg.split('=', 2)
            result.append(key_value[1])
    return result


def create_bss_actions(session, state):
    actions = []

    global_bp_action = http_get(session, actions, f'{BSS_URL}/bootparameters?name=Global')

    global_bp = json.loads(global_bp_action.response_body)
    if len(global_bp) == 0:
        log_error_and_exit(actions, "Failed to find Global bootparameters")
    elif len(global_bp) > 1:
        log.error("unexpectedly found more than one Global bootparameters. Continuing with the only the first entry")

    boot_parameter = global_bp[0]
    state.save('bss-bootparameters-global', boot_parameter)

    # check that ncn being removed is not first master
    first_master = boot_parameter.get('cloud-init', {}).get('meta-data', {}).get('first-master-hostname')
    if first_master == state.ncn_name:
        log_error_and_exit(actions,
                           'Cannot remove the first master. ' +
                           f'xname: {state.xname}, ncn-name: {state.ncn_name}, first-master-hostname: {first_master}')
    else:
        global_bp_action.log(f'first-master-hostname: {first_master}')

    # remove host records from Global boot parameters
    if state.remove_ips:
        host_records = boot_parameter.get('cloud-init').get('meta-data').get('host_records')
        new_host_records = []
        has_changes = False
        for host_record in host_records:
            found_alias_match = False
            for alias in host_record.get('aliases'):
                for alias_prefix in state.aliases:
                    if alias.startswith(alias_prefix):
                        found_alias_match = True
            if found_alias_match:
                has_changes = True
            else:
                new_host_records.append(host_record)

        if has_changes:
            boot_parameter.get('cloud-init').get('meta-data')['host_records'] = new_host_records
            global_request_body = json.dumps(boot_parameter)
            state.save('new-bss-bootparameters-global', boot_parameter)
            actions.append(HttpAction('put', f'{BSS_URL}/bootparameters', request_body=global_request_body))

    # remove boot parameters for xname
    xname_bp_action = http_get(session, actions, f'{BSS_URL}/bootparameters?name={state.xname}')
    if xname_bp_action.success:
        xname_bp_list = json.loads(xname_bp_action.response_body)
        xname_bp = xname_bp_list[0] if len(xname_bp_list) > 0 else {}
        state.save(f'bss-bootparameters-{state.xname}', xname_bp_list)

        # create delete action
        delete_request_body = '{ "hosts" : [ "' + state.xname + '" ] }'
        xname_bp_delete_action = HttpAction('delete', f'{BSS_URL}/bootparameters', request_body=delete_request_body)
        xname_bp_delete_action.log(delete_request_body)
        actions.append(xname_bp_delete_action)

        # save interfaces from params
        params = xname_bp.get('params')
        if params:
            state.ifnames = bss_params_to_ifnames(params)

    return actions


def create_kea_actions(session, state):
    actions = []

    for mac in sorted(state.hsm_macs):
        request_body = '{"command": "lease4-get-by-hw-address", "service": [ "dhcp4" ], "arguments": {"hw-address": "' + mac + '"}}'
        action = HttpAction('post', f'{KEA_URL}', request_body=request_body)
        actions.append(action)
        action.log(f'Request body: {request_body}')
        run_action(session, action)
        if state.verbose:
            action.log(f'Response body: {action.response_body}')
        if action.success:
            response = action.get_response_body('[]')
            response_json = json.loads(response)
            for r in response_json:
                leases = r.get("arguments", {}).get("leases", [])
                for lease in leases:
                    ip = lease.get('ip-address')
                    if ip:
                        if ip not in state.ip_reservation_ips:
                            state.ip_reservation_ips.add(ip)
                            action.log(f'Added {ip} to the list of kea leases to remove')

    for ip in sorted(state.ip_reservation_ips):
        request_body = '{"command": "lease4-del", "service": [ "dhcp4" ], "arguments": {"ip-address": "' + ip + '"}}'
        action = HttpAction('post', f'{KEA_URL}', request_body=request_body)
        actions.append(action)
        action.log(f'Request body: {request_body}')

    return actions


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


def check_for_running_pods_on_ncn(state):
    for alias in state.aliases:
        command_wide = ['kubectl', 'get', 'pods', '--all-namespaces', '--field-selector', f'spec.nodeName={alias}', '-o', 'wide']
        command = ['kubectl', 'get', 'pods', '--all-namespaces', '--field-selector', f'spec.nodeName={alias}', '-o', 'json']
        return_code, stdout, stderr = run_command(command)
        log.info("Ran:     " + ' '.join(command))

        if return_code != 0:
            log.error('kubectl command failed')
            log.info(f'Return code: {return_code}')
            log.info(f'Standard out:\n{stdout}')
            log.info(f'Standard err:\n{stderr}')
            sys.exit(1)

        if stdout:
            response = json.loads(stdout)
            items = response.get('items')
            if items is not None:
                if len(items) != 0:
                    log.info(' '.join(command_wide))
                    _, wide_stdout, wide_stderr = run_command(command_wide)
                    log.info(wide_stdout)
                    if wide_stderr:
                        log.info(wide_stderr)
                    log.error(f'there are pods on {alias}.')
                    sys.exit(1)
            else:
                print(
                    f'Warning: Could not determine if {alias} is running services. Command did not return the expected json')
        else:
            print(f'Warning: Could not determine if {alias} is running services. Command returned no output.')


def create_restart_bss_restart_actions():
    return [
        CommandAction(['kubectl', '-n', 'services', 'rollout', 'restart', 'deployment', 'cray-bss']),
    ]


def create_restart_bss_wait_actions():
    return [
        CommandAction(['kubectl', '-n', 'services', 'rollout', 'status', 'deployment', 'cray-bss', '--timeout=600s']),
    ]


def create_update_etc_hosts_actions(state):
    command_actions = []

    if state.remove_ips:
        sorted_workers = sorted(state.workers)
        for worker in sorted_workers:
            scp_action = CommandAction(['scp', f'{worker}:/etc/hosts', f'{state.directory}/etc-hosts-{worker}'])
            command_actions.append(scp_action)

        hosts = ','.join(sorted_workers)
        cp_backup_action = CommandAction(['pdsh', '-w', hosts,
                                          'cp', '/etc/hosts', f'/tmp/hosts.backup.{state.xname}.{state.ncn_name}'])
        command_actions.append(cp_backup_action)

        for ip in sorted(state.ip_reservation_ips):
            sed_action = CommandAction(['pdsh', '-w', hosts,
                                        'sed', '-i', f'/^{ip}[[:blank:]]/d', f'/etc/hosts'])
            command_actions.append(sed_action)
    else:
        print('Leaving /etc/hosts unchanged')

    return command_actions


def create_ipmitool_set_bmc_to_dhcp_actions(state):
    command_actions = []
    if not state.run_ipmitool:
        return command_actions

    if not state.ncn_name or not state.ipmi_password or not state.ipmi_username:
        # hitting this case is a programming error.
        # these values should have been checked by calling validate_ipmi_config(state)
        log.error('Unexpected state. Missing one of these values: ncn_name: ' +
                  f'"{state.ncn_name}", ipmi_username: "{state.ipmi_username}", ipmi_password: "****"')
        return command_actions

    mc_info_action = CommandAction([
        'ipmitool', '-I', 'lanplus', '-U', state.ipmi_username, '-E', '-H', f'{state.ncn_name}-mgmt',
        'mc', 'info'],
        verbose=state.verbose)
    command_actions.append(mc_info_action)
    run_command_action(mc_info_action)

    lan = '1'
    if mc_info_action.stdout:
        manufacturer_lines = [line for line in mc_info_action.stdout.split('\n') if 'manufacturer name' in line.lower()]
        for line in manufacturer_lines:
            if 'intel' in line.lower():
                lan = '3'

    # Set the BMC to DHCP
    change_dhcp_action = CommandAction([
        'ipmitool', '-I', 'lanplus', '-U', state.ipmi_username, '-E', '-H', f'{state.ncn_name}-mgmt',
        'lan', 'set', lan, "ipsrc", "dhcp"],
        verbose=state.verbose)
    command_actions.append(change_dhcp_action)

    # Restart BMC
    restart_bmc_action = CommandAction([
        'ipmitool', '-I', 'lanplus', '-U', state.ipmi_username, '-E', '-H', f'{state.ncn_name}-mgmt',
        'mc', 'reset', "cold"],
        verbose=state.verbose)
    command_actions.append(restart_bmc_action)

    return command_actions


def create_ipmitool_bmc_mac_actions(state):
    command_actions = []
    if not state.run_ipmitool:
        return command_actions

    if not state.ncn_name or not state.ipmi_password or not state.ipmi_username:
        # hitting this case is a programming error.
        # these values should have been checked by calling validate_ipmi_config(state)
        log.error('Unexpected state. Missing one of these values: ncn_name: ' +
                  f'"{state.ncn_name}", ipmi_username: "{state.ipmi_username}", ipmi_password: "****"')
        return command_actions

    mc_info_action = CommandAction([
        'ipmitool', '-I', 'lanplus', '-U', state.ipmi_username, '-E', '-H', f'{state.ncn_name}-mgmt',
        'mc', 'info'],
        verbose=state.verbose)
    command_actions.append(mc_info_action)
    run_command_action(mc_info_action)

    lan = '1'
    if mc_info_action.stdout:
        manufacturer_lines = [line for line in mc_info_action.stdout.split('\n') if 'manufacturer name' in line.lower()]
        for line in manufacturer_lines:
            if 'intel' in line.lower():
                lan = '3'
    mac_action = CommandAction([
        'ipmitool', '-I', 'lanplus', '-U', state.ipmi_username, '-E', '-H', f'{state.ncn_name}-mgmt',
        'lan', 'print', lan],
        verbose=state.verbose)
    command_actions.append(mac_action)
    run_command_action(mac_action)

    if mac_action.return_code == 0 and mac_action.stdout:
        mac_lines = [line for line in mac_action.stdout.split('\n') if 'mac address' in line.lower()]
        for line in mac_lines:
            key_value = line.split(':', 1)
            if len(key_value) == 2:
                state.bmc_mac = key_value[1].strip()

    return command_actions


def is_2xx(http_status):
    return http_status // 200 == 1


def run_action(session, action):
    method = action.method
    url = action.url
    r = None
    if method == 'get':
        r = session.get(url)
    elif method == 'delete':
        r = session.delete(url, data=action.request_body)
    elif method == 'put':
        r = session.put(url, action.request_body)
    elif method == 'post':
        r = session.post(url, action.request_body)
    else:
        print(f"Unknown method {method}")
        print("FAILED")
        sys.exit(1)

    if r:
        action.response_body = r.text
        action.completed = True
        action.success = is_2xx(r.status_code)


def run_actions(session, actions):
    for action in actions:
        if action.completed:
            print_action(action)
        else:
            run_action(session, action)
            print_action(action)


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--xname', help='The xname of the ncn to remove', required=True)
    parser.add_argument('--dry-run', action='store_true', help='Do a dry run where nothing is modified')
    parser.add_argument('--log-dir', '-l', default='/tmp/remove_management_ncn',
                        help='Directory where to log and save current state.')
    parser.add_argument("-v", action="store_true", help="Print verbose output")

    # hidden arguments used for testing
    parser.add_argument('--base-url', help=argparse.SUPPRESS)  # Base url.
    parser.add_argument('--sls-url', help=argparse.SUPPRESS)  # Base url for sls. Overrides --base-url
    parser.add_argument('--hsm-url', help=argparse.SUPPRESS)  # Base url for hsm. Overrides --base-url
    parser.add_argument('--bss-url', help=argparse.SUPPRESS)  # Base url for bss. Overrides --base-url
    parser.add_argument('-t', '--test-urls', action='store_true', help=argparse.SUPPRESS)  # Use test urls
    parser.add_argument('--skip-kea', action='store_true', help=argparse.SUPPRESS)  # skip kea actions
    parser.add_argument('--skip-etc-hosts', action='store_true', help=argparse.SUPPRESS)  # skip /etc/hosts actions
    parser.add_argument('--force', action='store_true', help=argparse.SUPPRESS)  # skip asking 'are you sure' question

    args = parser.parse_args()

    state = State(xname=args.xname, directory=args.log_dir, dry_run=args.dry_run, verbose=args.v)
    log.init_logger(os.path.join(state.directory, 'log'), verbose=state.verbose)

    setup_urls(args)
    print_urls()

    with requests.Session() as session:
        session.verify = False
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        token = os.environ.get('TOKEN')
        if token is not None:
            session.headers.update({'Authorization': f'Bearer {token}'})
        elif not args.test_urls and token is None:
            log.error('The TOKEN environment variable is not set.')
            log.info('Run the following to set the TOKEN:')
            log.info('''export TOKEN=$(curl -s -S -d grant_type=client_credentials \\
    -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \\
    -o jsonpath='{.data.client-secret}' | base64 -d` \\
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \\
    | jq -r '.access_token')
            ''')
            sys.exit(1)

        session.headers.update({'Content-Type': 'application/json'})

        state.ipmi_password = os.environ.get('IPMI_PASSWORD')
        state.ipmi_username = os.environ.get('IPMI_USERNAME')
        if not state.ipmi_username:
            state.ipmi_username = 'root'
            log.info(f'Using the default IPMI username. Set the IPMI_USERNAME environment variable to change this.')
        log.info(f'ipmi username: {state.ipmi_username}')

        sls_actions = create_sls_actions(session, state)
        print_actions(sls_actions)

        # ncn-m001 does not use DHCP. It is assigned a static IP.
        state.run_ipmitool = state.ncn_name != 'ncn-m001'
        validate_ipmi_config(state)

        bss_actions = create_bss_actions(session, state)
        print_actions(bss_actions)

        hsm_actions = create_hsm_actions(session, state)
        print_actions(hsm_actions)

        kea_actions = []
        if not args.skip_kea:
            kea_actions = create_kea_actions(session, state)
            print_actions(kea_actions)

        restart_bss_restart_actions = create_restart_bss_restart_actions()
        print_command_actions(restart_bss_restart_actions)
        restart_bss_wait_actions = create_restart_bss_wait_actions()
        print_command_actions(restart_bss_wait_actions)

        etc_hosts_actions = []
        if not args.skip_etc_hosts:
            etc_hosts_actions = create_update_etc_hosts_actions(state)
            print_command_actions(etc_hosts_actions)

        ipmitool_bmc_mac_actions = create_ipmitool_bmc_mac_actions(state)
        print_command_actions(ipmitool_bmc_mac_actions)

        ipmitool_set_dhcp_actions = create_ipmitool_set_bmc_to_dhcp_actions(state)
        print_command_actions(ipmitool_set_dhcp_actions)

        check_for_running_pods_on_ncn(state)

        log.info('')
        print_summary(state)

        if not args.dry_run:
            if not args.force:
                print()
                response = input(f'Permanently remove {state.xname} - {state.ncn_name} (y/n)? ')
                if response.lower() != 'y':
                    log.info('Operation aborted. Nothing was removed.')
                    exit(0)
            print()
            log.info(f'Removing {args.xname}')
            run_actions(session, bss_actions)
            run_actions(session, hsm_actions)
            run_actions(session, sls_actions)

            run_actions(session, kea_actions)

            log.info('Restarting cray-bss')
            run_command_actions(restart_bss_restart_actions)
            log.info('Waiting for cray-bss to start.')
            log.info('Do not kill this script. The wait will timeout in 10 minutes if bss does not fully start up.')
            run_command_actions(restart_bss_wait_actions)

            # Set the BMC to DHCP
            run_command_actions(ipmitool_set_dhcp_actions)

            run_command_actions(etc_hosts_actions)

            log.info('')
            print_summary(state)

        if not args.dry_run:
            log.info('')
            log.info(f'Successfully removed {state.xname} - {state.ncn_name}')


if __name__ == "__main__":
    sys.exit(main(sys.argv))
