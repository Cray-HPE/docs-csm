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
import re
import requests
import subprocess
import sys
import urllib3
import collections

BASE_URL = ''
BSS_URL = ''
HSM_URL = ''
SLS_URL = ''
KEA_URL = ''

log = logging


def _append_str(lines, name, value):
    if value:
        lines.append(f'{name}: {value}')


def _append_str_bool(lines, name, value):
    if value is not None:
        lines.append(f'{name}: {value}')


class Component:
    def __init__(self, xname):
        self.xname = xname
        self.name = None
        self.parent = None
        self.type = ''
        self.role = ''
        self.subrole = ''
        self.sources = set()
        self.connectors = []
        self.ip_reservations = {}
        self.redfish_endpoint_enabled = None
        self.ifnames = []

    def in_sls(self):
        self.sources.add('sls')

    def in_hsm(self):
        self.sources.add('hsm')

    def in_bss(self):
        self.sources.add('bss')

    def add_ip_reservation(self, ip, name='', aliases=None, mac=''):
        if aliases is None:
            aliases = []
        preferred_name = aliases[0] if aliases else name

        if ip in self.ip_reservations:
            current_value = self.ip_reservations[ip]
            if name:
                current_value[1] = name
            if aliases:
                current_value[2] = aliases
            if not current_value[3]:
                current_value[3] = preferred_name
            if mac:
                current_value[4] = mac
        else:
            self.ip_reservations[ip] = ([ip, name, aliases, preferred_name, mac])

    def to_str(self, indent=0):
        tab = " " * indent
        lines = []

        _append_str(lines, 'xname', self.xname)
        _append_str(lines, 'name', self.name)
        _append_str(lines, 'parent', self.parent)
        _append_str(lines, 'type', ', '.join([self.type, self.role, self.subrole]))
        _append_str(lines, 'sources', ', '.join(sorted(self.sources)))
        _append_str(lines, 'connectors', ', '.join(sorted(self.connectors)))

        ips = list(self.ip_reservations.values())
        ips.sort(key=lambda x: x[0])
        _append_str(lines, 'ip_reservations', ', '.join([v[0] for v in ips]))
        _append_str(lines, 'ip_reservations_name', ', '.join([v[3] for v in ips]))
        _append_str(lines, 'ip_reservations_mac', ', '.join([v[4] for v in ips]))
        _append_str_bool(lines, 'redfish_endpoint_enabled', self.redfish_endpoint_enabled)
        _append_str_bool(lines, 'ifnames', ', '.join(self.ifnames))

        return tab + f'\n{tab}'.join(lines)


class Ncns:
    def __init__(self):
        self.first_master_hostname = ''
        self.workers = []
        self.masters = []
        self.storage = []

    def add_worker(self, name, xname):
        self.workers.append((name, xname))

    def add_master(self, name, xname):
        self.masters.append((name, xname))

    def add_storage(self, name, xname):
        self.storage.append((name, xname))

    def to_str(self, indent=0):
        tab = " " * indent
        second_tab = " " * (4 if indent == 0 else indent * 2)
        lines = []

        _append_str(lines, 'first_master_hostname', self.first_master_hostname)

        masters = sorted(self.masters)
        workers = sorted(self.workers)
        storage = sorted(self.storage)

        indented_lines = []
        for m in masters:
            indented_lines.append(second_tab + ' '.join([m[0], m[1], 'master']))
        for w in workers:
            indented_lines.append(second_tab + ' '.join([w[0], w[1], 'worker']))
        for s in storage:
            indented_lines.append(second_tab + ' '.join([s[0], s[1], 'storage']))
        lines.append('ncns:\n' + '\n'.join(indented_lines))

        return tab + f'\n{tab}'.join(lines)


class State:
    def __init__(self, xname=None, verbose=False):
        self.xname = xname
        self.verbose = verbose
        self.parent = None
        self.ncn_name = ""
        self.aliases = set()
        self.ip_reservation_ips = set()
        self.ip_reservation_aliases = set()
        self.workers = set()
        self.remove_ips = True
        self.ncns = Ncns()
        self.components = collections.OrderedDict()
        self.ipmi_password = None
        self.ipmi_username = None
        self.run_ipmitool = False
        self.bmc_mac = None

    def add_ip_reservation(self, ip, name, aliases):
        self.ip_reservation_ips.add(ip)
        self.ip_reservation_aliases.add(name)
        self.ip_reservation_aliases.update(aliases)

        for key in self.components:
            component = self.components[key]
            if component.xname == name or component.name == name:
                component.add_ip_reservation(ip, name, aliases)
                return
        log.debug(f'Failed to find component for ip reservation: {(ip, name, aliases)}')

    def create_component(self, name):
        component = self.components.get(name)
        if component is None:
            component = Component(name)
            self.components[name] = component
        return component

    def get_component_for_ip(self, ip):
        for key in self.components:
            c = self.components[key]
            if ip in c.ip_reservations:
                return c
        return None

    def to_dict(self):
        d = collections.OrderedDict()
        d['ncn_name'] = self.ncn_name
        d['xname'] = self.xname
        d['parent'] = self.parent
        # d[self.xname] = dict(collections.OrderedDict())
        d[self.xname] = dict()
        return d

    def to_str(self, args):
        lines = []

        if args.all:
            lines.append(f'{self.ncns.to_str(indent=0)}')

        if self.xname and len(self.components) == 0:
            lines.append(f'Not found: {self.xname}')
        else:
            for key in self.components:
                component = self.components[key]
                if component.xname != self.xname:  # skip the xname that was asked for so that it can be printed last
                    lines.append(f'{component.xname}:')
                    lines.append(component.to_str(indent=4))
            asked_for_component = self.components.get(self.xname)
            if asked_for_component:
                lines.append(f'{asked_for_component.xname}:')
                lines.append(asked_for_component.to_str(indent=4))

                # The following info is needed by add_management_ncn.py when adding the given hardware as an ncn
                lines.append('ncn_macs:')
                lines.append(f'    ifnames: {", ".join(asked_for_component.ifnames)}')
                if self.run_ipmitool:
                    if self.ipmi_password and self.ipmi_username:
                        if self.bmc_mac:
                            lines.append(f'    bmc_mac: {self.bmc_mac}')
                        else:
                            lines.append('    bmc_mac: # Unknown. Something unexpected happened running ipmitool. ' +
                                         'Rerun ncn_sts.py with the option -v')
                    else:
                        lines.append('    bmc_mac: # Unknown. To get this value set the environment variable, ' +
                                     'IPMI_PASSWORD, with the password for the BMC')
                else:
                    lines.append(f'    bmc_mac: # Unknown. This script is always unable to collect this for ncn-m001')

        return '\n'.join(lines)


class CommandAction:
    def __init__(self, command, verbose=False):
        self.command = command
        self.has_run = False
        self.return_code = -1
        self.stdout = None
        self.stderr = None
        self.verbose = verbose


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
    log.debug(f'BSS_URL: {BSS_URL}')
    log.debug(f'HSM_URL: {HSM_URL}')
    log.debug(f'SLS_URL: {SLS_URL}')
    log.debug(f'KEA_URL: {KEA_URL}')


def print_action(action):
    if action['completed']:
        if action['success']:
            log.debug(f"Called:  {action['method'].upper()} {action['url']}")
        else:
            log.debug(f"Failed:  {action['method'].upper()} {action['url']}")
            log.debug(json.dumps(action.get('response_body'), indent=2))
    else:
        log.debug(f"Planned: {action['method'].upper()} {action['url']}")

    # if action.get('body'):
    #     print(json.dumps(action.get('body'), indent=2))
    for a_log in action.get('logs'):
        log.debug('         ' + a_log)


def print_actions(actions):
    for action in actions:
        print_action(action)


def print_command_action(action):
    if action.has_run:
        log.debug(f'Ran:     {" ".join(action.command)}')
        if action.return_code != 0:
            log.error(f'         Failed: {action.return_code}')
            log.info(f'         stdout:\n{action.stdout}')
            log.info(f'         stderr:\n{action.stderr}')
        elif action.verbose:
            log.info(f'         stdout:\n{action.stdout}')
            if action.stderr:
                log.info(f'         stderr:\n{action.stderr}')

    else:
        log.debug(f'Planned: {" ".join(action.command)}')


def print_command_actions(actions):
    for action in actions:
        print_command_action(action)


def action_create(method, url, logs=None, request_body="", response_body="", completed=False, success=False):
    if logs is None:
        logs = []

    return {
        "method": method,
        "url": url,
        "logs": logs,
        "request_body": request_body,
        "response_body": response_body,
        "completed": completed,
        "success": success,
    }


def action_set(action, name, value):
    action[name] = value


def action_log(action, message):
    action.get('logs').append(message)


def http_get(session, actions, url, exit_on_error=False):
    r = session.get(url)
    action = action_create('get', url, response_body=r.text, completed=True)
    actions.append(action)
    action_set(action, 'response', r)
    if r.status_code == http.HTTPStatus.OK:
        action_set(action, 'success', True)
    elif exit_on_error:
        log_error_and_exit(actions, str(action))
    return action


def log_error_and_exit(actions, message):
    print_actions(actions)
    log.error(f'{message}')
    sys.exit(1)


def node_bmc_to_enclosure(xname_for_bmc):
    p = re.compile('^(x[0-9]{1,4}c0s[0-9]+)(b)([0-9]+)$')
    if xname_for_bmc and p.match(xname_for_bmc):
        # convert node bmc to enclosure, for example, convert x3000c0s36b0 to x3000c0s36e0
        enclosure = re.sub(p, r'\1e\3', xname_for_bmc)
        return enclosure
    return None


def create_sls_actions(session, state):
    actions = []

    hardware_action = http_get(session, actions, f'{SLS_URL}/hardware')
    networks_action = http_get(session, actions, f'{SLS_URL}/networks')

    # Find xname in hardware and get aliases
    hardware_list = json.loads(hardware_action.get('response_body'))
    if state.xname:
        for hardware in hardware_list:
            extra_properties = hardware.get('ExtraProperties', {})

            if state.xname == hardware['Xname']:
                type_string = hardware.get('TypeString', '')
                role = extra_properties.get('Role', '')
                sub_role = extra_properties.get('SubRole', '')
                xname_component = state.create_component(state.xname)
                xname_component.in_sls()
                xname_component.type = type_string
                xname_component.role = role
                xname_component.subrole = sub_role
                if type_string != 'Node' or role != 'Management' or sub_role not in ['Worker', 'Storage', 'Master']:
                    log_error_and_exit(
                        actions,
                        f'{state.xname} is Type: {type_string}, Role: {role}, SubRole: {sub_role}. ' +
                        'The node must be Type: Node, Role: Management, SubRole: one of Worker, Storage, or Master.')

                state.parent = hardware.get('Parent')
                xname_component.parent = state.parent
                state.create_component(state.parent)

                state.aliases.update(extra_properties.get('Aliases', []))
                action_log(hardware_action, f'Aliases: {state.aliases}')

        alias_count = len(state.aliases)
        if alias_count == 0:
            pass  # todo
        elif alias_count != 1:
            log.warning(f'Expected to find only one alias. Instead found {state.aliases}')
        if alias_count > 0:
            state.ncn_name = list(state.aliases)[0]
            state.components[state.xname].name = list(state.aliases)[0]
        log.debug(f'xname: {state.xname}')
        log.debug(f'ncn name: {state.ncn_name}')

    # Requires that the parent is known.
    # The loop through the hardware_list above finds the given node and parent
    # That is why this must loop through the hardware list again after the loop above.
    hardware_connectors = []
    for hardware in hardware_list:
        extra_properties = hardware.get('ExtraProperties', {})
        if state.parent:
            # Check for nic connections
            for nic in extra_properties.get("NodeNics", []):
                if nic == state.parent:
                    hardware_connectors.append(hardware.get('Xname'))
                    state.components[state.parent].connectors.append(hardware.get('Xname'))

        type_string = hardware.get('TypeString')
        role = extra_properties.get('Role')
        sub_role = extra_properties.get('SubRole')
        if type_string == 'Node' and role == 'Management' and sub_role in ['Worker', 'Storage', 'Master']:
            aliases = extra_properties.get('Aliases', [])
            for alias in aliases:
                state.workers.add(alias)
                h_xname = hardware.get('Xname')
                if sub_role == 'Worker':
                    state.ncns.add_worker(alias, h_xname)
                elif sub_role == 'Storage':
                    state.ncns.add_storage(alias, h_xname)
                elif sub_role == 'Master':
                    state.ncns.add_master(alias, h_xname)

    for hardware in hardware_list:
        xn = hardware.get('Xname')
        if xn in hardware_connectors:
            extra_properties = hardware.get('ExtraProperties', {})
            c = state.create_component(xn)
            c.type = hardware.get('TypeString', '')
            c.role = extra_properties.get('Role', '')
            c.subrole = extra_properties.get('SubRole', '')
            c.in_sls()

    # Find network references to aliases and parent
    networks = json.loads(networks_action.get('response_body'))
    for network in networks:
        if state.xname:
            extra_properties = network.get('ExtraProperties')
            subnets = extra_properties['Subnets']
            if subnets is None:
                continue
            for subnet in subnets:
                ip_reservations = subnet.get('IPReservations')
                if ip_reservations is None:
                    continue
                new_ip_reservations = []
                for ip_reservation in ip_reservations:
                    rname = ip_reservation['Name']
                    if rname not in state.aliases and rname != state.parent and rname != state.xname:
                        new_ip_reservations.append(ip_reservation)
                    else:
                        state.add_ip_reservation(
                            ip_reservation.get('IPAddress', ''),
                            ip_reservation.get('Name', ''),
                            ip_reservation.get('Aliases', []))
    return actions


def set_hsm_ethernet(state, xname, action):
    if action.get('success'):
        ethernet_list = json.loads(action.get('response_body'))
        if ethernet_list:
            component = state.create_component(xname)
            component.in_hsm()
            for ethernet in ethernet_list:
                mac = ethernet.get('MACAddress')
                ip_addresses = ethernet.get('IPAddresses', [])
                for i in ip_addresses:
                    ip = i.get('IPAddress')
                    if ip:
                        component.add_ip_reservation(ip, mac=mac)


def set_hsm_redfish(state, xname, action):
    if action.get('success'):
        component = state.create_component(xname)
        component.in_hsm()
        response = json.loads(action.get('response_body'))
        t = response.get('Type', '')
        if t:
            component.type = t
        component.redfish_endpoint_enabled = response.get('Enabled')


def set_hsm_component(state, xname, action):
    if action.get('success'):
        component_list = json.loads(action.get('response_body'))
        for c in component_list:
            component = state.create_component(xname)
            component.in_hsm()
            response = json.loads(action.get('response_body'))
            t = response.get('Type', '')
            if t:
                component.type = t


def create_hsm_actions(session, state):
    actions = []

    # -------------------------------------------
    # ethernet interfaces
    if state.xname:
        xname_ethernet_action = http_get(session, actions,
                                         f'{HSM_URL}/Inventory/EthernetInterfaces?ComponentId={state.xname}')
        set_hsm_ethernet(state, state.xname, xname_ethernet_action)

    if state.parent:
        parent_ethernet_action = http_get(session, actions,
                                          f'{HSM_URL}/Inventory/EthernetInterfaces?ComponentId={state.parent}')
        set_hsm_ethernet(state, state.parent, parent_ethernet_action)

    # -------------------------------------------
    # redfish endpoints
    if state.parent:
        parent_redfish_action = http_get(session, actions, f'{HSM_URL}/Inventory/RedfishEndpoints/{state.parent}')
        set_hsm_redfish(state, state.parent, parent_redfish_action)

    # -------------------------------------------
    # components
    if state.xname:
        xname_component_action = http_get(session, actions, f'{HSM_URL}/State/Components/{state.xname}')
        set_hsm_component(state, state.xname, xname_component_action)

    if state.parent:
        parent_component_action = http_get(session, actions, f'{HSM_URL}/State/Components/{state.parent}')
        set_hsm_component(state, state.parent, parent_component_action)

    node_enclosure_xname = node_bmc_to_enclosure(state.parent)
    if node_enclosure_xname:
        enclosure_component_action = http_get(session, actions, f'{HSM_URL}/State/Components/{node_enclosure_xname}')
        set_hsm_component(state, node_enclosure_xname, enclosure_component_action)

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

    # -------------------------------------------
    # Global
    global_bp_action = http_get(session, actions, f'{BSS_URL}/bootparameters?name=Global')

    global_bp = json.loads(global_bp_action.get('response_body'))
    if len(global_bp) == 0:
        log_error_and_exit(actions, "Failed to find Global bootparameters")
    elif len(global_bp) > 1:
        log.error("unexpectedly found more than one Global bootparameters. Continuing with the only the first entry")

    boot_parameter = global_bp[0]
    first_master = boot_parameter.get('cloud-init', {}).get('meta-data', {}).get('first-master-hostname', '')
    state.ncns.first_master_hostname = first_master
    host_records = boot_parameter.get('cloud-init', {}).get('meta-data', {}).get('host_records')
    for host_record in host_records:
        ip = host_record.get('ip')
        if ip:
            component = state.get_component_for_ip(ip)
            if component:
                component.in_bss()

    # -------------------------------------------
    # xname
    if state.xname:
        xname_bp_action = http_get(session, actions, f'{BSS_URL}/bootparameters?name={state.xname}')
        if xname_bp_action.get('success'):
            bss_component = state.create_component(state.xname)
            bss_component.in_bss()

            xname_bp_list = json.loads(xname_bp_action.get('response_body'))
            xname_bp = xname_bp_list[0] if len(xname_bp_list) > 0 else {}

            # save interfaces from params
            params = xname_bp.get('params')
            if params:
                bss_component.ifnames = bss_params_to_ifnames(params)

    return actions


def run_command(command):
    log.debug(f'Running: {" ".join(command)}')
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
        log.debug("Ran:     " + ' '.join(command))

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
                    log.debug(' '.join(command_wide))
                    _, wide_stdout, wide_stderr = run_command(command_wide)
                    log.debug(wide_stdout)
                    if wide_stderr:
                        log.debug(wide_stderr)
                    log.error(f'there are pods on {alias}.')
                    sys.exit(1)
            else:
                log.warning(
                    f'Warning: Could not determine if {alias} is running services. ' +
                    'Command did not return the expected json')
        else:
            log.warning(f'Warning: Could not determine if {alias} is running services. Command returned no output.')


def create_ipmitool_actions(state):
    command_actions = []
    if not state.run_ipmitool:
        return command_actions

    if state.ncn_name and state.ipmi_password and state.ipmi_username:
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
    elif state.ncn_name:
        # a specific ncn was requested and found, but the ipmi password and username were not set.
        log.debug(f'Not running the ipmitool. This command supplies the bmc_mac information.')
        if not state.ipmi_username:
            log.debug(f'         Environment variable IPMI_USERNAME was not set. The ipmitool requires this.')
        if not state.ipmi_password:
            log.debug(f'         Environment variable IPMI_PASSWORD was not set. The ipmitool requires this.')

    return command_actions


def is_2xx(http_status):
    return http_status // 200 == 1


def run_action(session, action):
    method = action.get('method')
    url = action.get('url')
    r = None
    if method == 'get':
        r = session.get(url)
    elif method == 'post':
        r = session.post(url, action.get('request_body'))
    else:
        log.error(f"Unimplemented method {method}")
        sys.exit(1)

    if r:
        action_set(action, 'response_body', r.text)
        action_set(action, 'completed', True)
        action_set(action, 'success', is_2xx(r.status_code))


def run_actions(session, actions):
    for action in actions:
        if action.get('completed'):
            print_action(action)
        else:
            run_action(session, action)
            print_action(action)


def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--xname", help="The xname of the ncn to remove")
    parser.add_argument("--all", action="store_true", help="List all NCNs")
    parser.add_argument("-v", action="store_true", help="Print verbose output")

    # hidden arguments used for testing
    parser.add_argument("--base-url", help=argparse.SUPPRESS)  # Base url.
    parser.add_argument("--sls-url", help=argparse.SUPPRESS)  # Base url for sls. Overrides --base-url
    parser.add_argument("--hsm-url", help=argparse.SUPPRESS)  # Base url for hsm. Overrides --base-url
    parser.add_argument("--bss-url", help=argparse.SUPPRESS)  # Base url for bss. Overrides --base-url
    parser.add_argument("-t", "--test-urls", action="store_true", help=argparse.SUPPRESS)  # Use test urls

    args = parser.parse_args()
    if args.v:
        log.basicConfig(stream=sys.stdout, level=logging.DEBUG, format='%(message)s')
    else:
        log.basicConfig(stream=sys.stdout, level=logging.INFO, format='%(message)s')

    if not args.all and not args.xname:
        parser.print_help()
        print('Bad arguments: Must have specify either --all or --xname')
        sys.exit(1)

    state = State(xname=args.xname, verbose=args.v)
    setup_urls(args)
    print_urls()

    with requests.Session() as session:
        session.verify = False
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        token = os.environ.get('TOKEN')
        if token is not None:
            session.headers.update({'Authorization': f'Bearer {token}'})
        elif not args.test_urls and token is None:
            log.error('Error: The TOKEN environment variable is not set.')
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

        sls_actions = create_sls_actions(session, state)
        print_actions(sls_actions)

        hsm_actions = create_hsm_actions(session, state)
        print_actions(hsm_actions)

        bss_actions = create_bss_actions(session, state)
        print_actions(bss_actions)

        # ncn-m001 does not use DHCP. It is assigned a static IP.
        state.run_ipmitool = state.ncn_name != 'ncn-m001'

        ipmitool_actions = create_ipmitool_actions(state)
        print_command_actions(ipmitool_actions)

        log.info(state.to_str(args))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
