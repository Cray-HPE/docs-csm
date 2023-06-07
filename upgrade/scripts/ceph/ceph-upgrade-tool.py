#! /usr/bin/env python3
#
#  MIT License
#
#  (C) Copyright 2023 Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.
#
"""
Module for starting and monitoring a Ceph upgrade.
"""
import subprocess
import json
import rbd
import rados
import sys
import re
from argparse import ArgumentParser
from prettytable import PrettyTable
from packaging import version
import time
import os
from subprocess import Popen, PIPE


class ImagePullException(Exception):
    """
    An exception for a failure to pull image using podman.
    """
    def __init__(self, message) -> None:
        self.message = message
        super().__init__(self.message)

# set global variables
ceph_api = None
upgrade_version = ''
starting_version = ''
print_basic = False

"""
Block for Ceph Api.
"""
class API:

    def __init__(self, conf_file='/etc/ceph/ceph.conf') -> None:
        try:
            self.cluster = rados.Rados(conffile=conf_file)
        except rados.ObjectNotFound as ex:
            raise rados.ObjectNotFound(f'ERROR ceph.conf not found in /etc/ceph. {ex}') from ex
        self.cluster.connect(1)

    def disconnect(self) -> None:
        """
        Close connection to the Ceph cluster.
        """
        self.cluster.shutdown()

    def run_ceph_cmd(self, cmd: dict) -> tuple:
        """
        Executes a ceph command. Runs ceph mon_command function.
        """
        return self.cluster.mon_command(json.dumps(cmd), b'', timeout=5)

    def get_ceph_version(self) -> str:
        """
        Get the version of Ceph currently running.
        """
        cmd = {"prefix":"version", "format":"json"}
        cmd_results = self.run_ceph_cmd(cmd)
        results = json.loads(cmd_results[1])
        for key,value in results.items():
            current_version = str(value.split(' ')[2])
        return current_version

"""
Block of Ceph upgrade functions.
"""
def upgrade_ceph(registry='registry.local', conf_file="") -> bool:
    """
    Upgrade Ceph. This function validates the image format, the upgrade version supplied,
    and that is possible to pull the image being upgraded to. It then executes the upgrade.
    """
    global ceph_api, upgrade_version, starting_version
    if conf_file == "":
        ceph_api = API()
    else:
        ceph_api = API(conf_file)
    # prepare for upgrade
    try:
        upgrade_version = _validate_version_format(upgrade_version)
        starting_version = ceph_api.get_ceph_version()
        should_upgrade = _verify_upgrade_version(starting_version, upgrade_version)
        if not should_upgrade:
            ceph_api.disconnect()
            return False
        upgrade_image = _get_upgrade_image_path(registry, upgrade_version)
        _check_image_pull(upgrade_image)
    except (ValueError, ImagePullException) as error:
        ceph_api.disconnect()
        raise Exception(f'{error}') from error
    # run upgrade
    upgrade_cmd = {"prefix":"orch upgrade start", "image":upgrade_image}
    ceph_api.run_ceph_cmd(upgrade_cmd)
    ceph_api.disconnect()
    return True

def _get_upgrade_image_path(registry: str, upgrade_version:str) -> str:
    """
    Get the path of the image to be upgraded to.
    """
    _validate_registry(registry)
    prefix = ''
    if registry == 'registry.local' or registry == 'localhost:5000':
        prefix = registry + '/'
    if registry == 'localhost':
        prefix = 'localhost:5000/'
    return prefix + 'artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v' \
        + upgrade_version

def _validate_version_format(upgrade_version) -> str:
    """
    Verifies a valid version was provided and that this version
    is higher than the current version.
    """
    matches = re.fullmatch('^v[0-9]+[.][0-9]+[.][0-9]+$', upgrade_version)
    if matches != None:
        # remove first v from the upgrade_version
        return upgrade_version[1:]
    matches = re.fullmatch('^[0-9]+[.][0-9]+[.][0-9]+$', upgrade_version)
    if matches != None:
        return upgrade_version
    raise ValueError(f'Error upgrade version: {upgrade_version} is not a valid format. \
        Valid formats are \'v.X.X.X\' and \'X.X.X\' where X is an integer.')

def _validate_registry(registry: str) -> None:
    """
    Validates that the registry provided is a valid option.
    """
    valid_registries = ['registry.local', 'localhost', 'localhost:5000', 'artifactory.algol60.net']
    if registry not in  valid_registries:
        raise ValueError(f'{registry} is not a valid registry. Valid registries are \
            {valid_registries}.')

def _verify_upgrade_version(starting_version: str, upgrade_version: str) -> bool:
    """
    Checks that the version being run is a greater version than the Ceph version
    that is currently running.
    """
    if version.parse(starting_version) == version.parse(upgrade_version):
        print(f'Ceph version is already {starting_version}. Nothing to upgrade.')
        return False
    if not version.parse(starting_version) < version.parse(upgrade_version):
        raise ValueError(f'Cannot upgrade Ceph. The upgrade version:{upgrade_version} \
        is not greater than the current Ceph version running:{starting_version}.')
    return True

def _check_image_pull(image: str) -> None:
    """
    Checks that an image can be pulled using podman pull.
    """
    p = Popen(['podman', 'pull', image], universal_newlines=True, stdout=PIPE)
    output, error = p.communicate()
    if p.returncode != 0:
        raise ImagePullException(f"Error: failed to pull image from podman. Check that {image} is in nexus.")

"""
Block of monitoring functions for the Ceph upgrade.
"""
# global variable for monitoring functions
ceph_daemon_services = ["mon", "mgr", "osd", "rgw", "crash"]

def monitor_upgrade(conf_file="") -> (bool, str):
    """
    Public methos to monitor the Ceph upgrade until it has completed or failed.
    This gets the upgrade status, checks for failures,
    and checks for upgrade completion.
    """
    global ceph_api
    if conf_file == "":
        ceph_api = API()
    else:
        ceph_api = API(conf_file)

    while True:
        # print status
        _print_upgrade_status()
        # check if there are errors
        error = _check_upgrade_errors()
        if error != "":
            ceph_api.disconnect()
            return (False, error)
        # check if the upgrade is completed
        if _check_upgrade_complete():
            if _check_all_daemons_upgraded():
                ceph_api.disconnect()
                return (True, "")
            else:
                ceph_api.disconnect()
                return (False, "Error: not all Ceph daemons were upgraded")
        time.sleep(45)

def _get_upgrade_status_message() -> str:
    """
    Get the status of the ceph upgrade. Returns a json string.
    """
    upgrade_status_cmd = {"prefix":"orch upgrade status"}
    status = ceph_api.run_ceph_cmd(upgrade_status_cmd)
    return status[1]

def _print_upgrade_status() -> None:
    """
    Checks the current daemons running the old and new Ceph version.
    This prints a readable table of information.
    """
    global print_basic
    table = PrettyTable(['Service', 'Total Original Version', 'Total Upgraded', 'Total Running'])
    for service in ceph_daemon_services:
        orig, upgraded, running = _count_daemons_per_version(service)
        if print_basic:
            print(f"Service: {service},   Total Original Version: {orig},   Total Upgraded: {upgraded},   Total Running: {running}")
        else:
            table.add_row([service, orig, upgraded, running])
    if not print_basic:
        print(table)
    print(json.loads(_get_upgrade_status_message())['message'])
    print()

def _count_daemons_per_version(service: str) -> (int, int, int):
    """
    Count how many daemons are running the original ceph version and how many
    are running the upgraded version
    """
    n_old, n_new, n_running = 0, 0, 0
    cmd = {"prefix":"orch ps", "daemon_type":service, "format":"json"}
    cmd_results = ceph_api.run_ceph_cmd(cmd)
    results = json.loads(cmd_results[1])
    for s in range(len(results)):
        try:
            status = (results[s]["status_desc"])
            if status == "running":
                n_running+=1
            version = (results[s]["version"])
            if version == starting_version:
                n_old+=1
            elif version == upgrade_version:
                n_new+=1
        except KeyError:
            # this error is hit when a daemon is starting and has an <unknown> version
            continue
    return (n_old, n_new, n_running)

def _check_upgrade_errors() -> str:
    """
    Checks if there are any errors during the Ceph upgrade.
    If there is an error it will return a string containing the error.
    If there are no errors, an empty string will be returned.
    """
    status_message = json.loads(_get_upgrade_status_message())['message']
    if "error" in status_message.lower():
        time.sleep(10)
        status_message = json.loads(_get_upgrade_status_message())['message']
        if "error" in status_message.lower():
            return status_message
    return ""

def _check_upgrade_complete() -> bool:
    """
    Checks that the upgrade status shows no upgrade in progress.
    It will check 3 time in 10 seconds before returning because
    there are instances of the upgrade status being empty momentarily.
    """
    status = json.loads(_get_upgrade_status_message())
    if status['in_progress']:
        return False
    # ceph upgrade status will have no target_image or services_completed if 
    # the upgrade has completed
    # check 3 times in 10 seconds to be sure it has completed
    for i in range(3):
        if status['target_image'] != None and services_complete != []:
            return False
        else:
            time.sleep(5)
            status = json.loads(_get_upgrade_status_message())
    return True

def _check_all_daemons_upgraded() -> bool:
    """
    Check that all daemons are running the upgraded Ceph version.
    """
    success = True
    for service in ceph_daemon_services:
        orig, upgraded, running = _count_daemons_per_version(service)
        if orig != 0:
            print(f'Error not all {service} daemons have been upgraded. \
            {orig} is still running the old version')
            success = False
        elif upgraded != running:
            # wait 1 minute to see if it starts
            time.sleep(60)
            orig, upgraded, running = _count_daemons_per_version(service)
            if upgraded != running:
                print(f'Error not all upgraded {service} daemons are running. \
                {service} upgraded:{upgraded}, running:{running}')
                success = False
    return success

"""
Main block for executing and monitoring Ceph upgrade.
"""

def main():
    parser =  ArgumentParser(description='Ceph upgrade script')
    parser.add_argument('--version',
                        required=True,
                        type=str,
                        dest='version',
                        help='The target version to upgrade Ceph to. Format example v15.2.15')
    parser.add_argument('--print_basic',
                        required=False,
                        default=False,
                        action='store_true',
                        dest='print_basic',
                        help='Basic status will be printed in text. A pretty-table will not be printed.')
    args = parser.parse_args()

    global upgrade_version, print_basic

    print_basic = args.print_basic
    # run upgrade
    upgrade_version = args.version
    try:
        upgrading = upgrade_ceph()
    except Exception as error:
        print(f'{error}')
        sys.exit(1)

    # monitor upgrade
    if upgrading:
        success, error = monitor_upgrade()
        if success:
            print('Ceph upgraded succeeded.')
        else:
            print(f'Error: Ceph upgrade failed. {error}')
            sys.exit(1)

if __name__ == '__main__':
    main()
