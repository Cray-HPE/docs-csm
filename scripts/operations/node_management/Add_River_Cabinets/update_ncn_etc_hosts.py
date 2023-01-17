#! /usr/bin/env python3
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

import argparse
import datetime
import json
import http
import os
import requests
import subprocess
import sys
import urllib3

SLS_URL = None

#
# HTTP Action stuff
#
def print_action(action):
    if action['error'] is not None:
        print(f"Failed:  {action['method'].upper()} {action['url']}. {action['error']}")
    elif action['status'] is not None:
        print(f"Called:  {action['method'].upper()} {action['url']} with params {action['params']}")
    else:
        print(f"Planned: {action['method'].upper()} {action['url']}")

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

#
# SLS
#
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

def create_update_etc_hosts_actions(management_ncns, log_dir, switch_ip_reservations):
    command_actions = []

    ncn_aliases = list(map(lambda ncn: ncn["ExtraProperties"]["Aliases"][0], management_ncns))
    for alias in ncn_aliases:
        scp_action = CommandAction(['scp', f'{alias}:/etc/hosts', f'{log_dir}/etc-hosts-{alias}'])
        command_actions.append(scp_action)

    hosts = ','.join(ncn_aliases)
    cp_backup_action = CommandAction(['pdsh', '-w', hosts,
                                        'cp', '/etc/hosts', f'/tmp/hosts.backup']) # TODO add timestamp
    command_actions.append(cp_backup_action)

    # Added Switch IPs
    for ip_reservation_change in switch_ip_reservations:
        switch_name = ip_reservation_change["IPReservation"]["Name"]
        if not switch_name.startswith("sw-"):
            # This is not a switch IP address reservation
            continue

        network_name = ip_reservation_change["NetworkName"].lower()
        ip_address = ip_reservation_change["IPReservation"]["IPAddress"]

        # Build the line for /etc/hosts file line
        line = f'{ip_address:15} {switch_name}.{network_name}'

        # The pdsh command
        sed_action = CommandAction(['pdsh', '-w', hosts,
                                    'sed', '-i', f"'$a{line}'", '/etc/hosts'])
        command_actions.append(sed_action)


    return command_actions

def main():
    global SLS_URL

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    token = os.environ.get('TOKEN')
    if token is None or token == "":
        print("Error environment variable TOKEN was not set")
        sys.exit(1)

    # Parse CLI Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("topology_changes", help="Path to the topology_changes.json file generated by the hardware-topology-assistant")
    parser.add_argument("--perform-changes", action="store_true", help="Allow modification of SLS, HSM, and BSS. When this option is not specified a dry run is performed")
    parser.add_argument("--url-sls", type=str, required=False, default="https://api-gw-service-nmn.local/apis/sls/v1")
    parser.add_argument("--log-dir", help="Directory where to log and save current state.", default='/tmp/add_management_ncn')

    args = parser.parse_args()
    SLS_URL = args.url_sls

    # Read in topology changes file
    topology_changes = None
    with open(args.topology_changes) as f:
        topology_changes = json.load(f)


    # Create log directory
    timestamp = (datetime.datetime.utcnow().isoformat("T") + "Z").replace(":", "-")
    print(timestamp)

    log_directory = os.path.join(".", f"update_ncn_etc_hosts_{timestamp}")
    if not os.path.exists(log_directory):
        os.makedirs(log_directory)

    # Setup requests sessions to include our token
    with requests.Session() as session:
        session.verify = False
        if token is not None:
            session.headers.update({'Authorization': f'Bearer {token}'})
        session.headers.update({'Content-Type': 'application/json'})

        # Retrieve all Management NCNs from SLS
        print("Retrieving management NCNs from SLS")
        action, existing_management_ncns = get_sls_management_ncns(session)
        print_action(action)

        print("Updating /etc/hosts with new switch IPs")
        etc_hosts_actions = create_update_etc_hosts_actions(existing_management_ncns, log_directory, topology_changes["IPReservationsAdded"])
        print_command_actions(etc_hosts_actions)

        if args.perform_changes:
            run_command_actions(etc_hosts_actions)

if __name__ == "__main__":
    sys.exit(main())
