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

from pyscripts.core.ssh.ssh_targets import SshTargets
from pyscripts.core.ssh.ssh_connection import SshConnection
from pyscripts.core import csm_api_utils
import yaml
import time
import logging
import sys
import os

TEST_PLAN = None
SSH_TARGETS = None
APPLICABLE_NETWORK_TYPES = ["can", "chn", "cmn", "nmn", "hmn", "hmnlb", "nmnlb"]
APPLICABLE_NODE_TYPES = ["ncn_master", "uan", "cn", "spine_switch"]

TOTAL_PASS = 0

def start_test(system_domain, admin_client_secret, to_node_types, networks):
    global APPLICABLE_NETWORK_TYPES
    global APPLICABLE_NODE_TYPES

    APPLICABLE_NETWORK_TYPES = networks
    APPLICABLE_NODE_TYPES = to_node_types


    csm_api_utils.set_system_domain(system_domain)
    csm_api_utils.set_admin_secret(admin_client_secret)

    load_test_plan()
    execute_test_plan()


def load_test_plan():
    global TEST_PLAN
    global SSH_TARGETS

    if csm_api_utils.is_bican_chm():
        print("BICAN:CHN detected.")
        filename = "chn_toggle_tests_external.yaml"
    else:
        print("BICAN:CAN detected.")
        filename = "can_toggle_tests_external.yaml"

    path = os.path.abspath(os.path.join(os.path.dirname(__file__), filename))
    f = open(path, "r")
    TEST_PLAN = yaml.safe_load(f.read())["tests"]

    SSH_TARGETS = SshTargets()
    SSH_TARGETS.refresh()

def execute_test_plan():
    for network in TEST_PLAN:
        if network in APPLICABLE_NETWORK_TYPES:
            config = TEST_PLAN[network]
            for to_node_type in config:
                if to_node_type in APPLICABLE_NODE_TYPES:
                    collect_passwords_from_node_type(to_node_type, network)

    total_ran = 0
    start_time = time.time()

    for network in TEST_PLAN:
        if network in APPLICABLE_NETWORK_TYPES:
            config = TEST_PLAN[network]
            for to_node_type in config:
                if to_node_type in APPLICABLE_NODE_TYPES:
                    total_ran += execute_test(to_node_type, network, config[to_node_type])

    total_time = time.time() - start_time

    print(f"\n\nRan {total_ran} tests in {total_time:0.3f}s. Overall status: %s (Passed: {TOTAL_PASS}, Failed: {total_ran - TOTAL_PASS})" % ("PASSED" if TOTAL_PASS == total_ran else "FAILED"))

def collect_passwords_from_node_type(from_node_type, network):
    from_node = get_ssh_host_for_node_type(from_node_type, [])

    if not from_node:
        return

    from_node.get_password() # this will ask for the password and cache it

def execute_test(to_node_type, network, expected):
    global TOTAL_PASS

    network_suffix = "{}.{}".format(network, csm_api_utils.get_system_domain())
    to_node = get_ssh_host_for_node_type(to_node_type, [])

    if not to_node:
        print("""\nTesting SSH access:
To node type {}
Over network {} ({})""".format(
            to_node_type, network, network_suffix))

        print("\t\t^^^^ SKIPPED: Cannot find a suitable node for node type {} ^^^^".format(to_node_type))
        return 0

    to_node = to_node.with_domain_suffix(network_suffix)

    toNodeSshConnection = SshConnection(to_node)

    print("""\nTesting SSH access:
        To node type {}, using {}
        Over network {} ({})
        Expected to work: {}""".format(
        to_node_type, to_node.get_full_domain_name(), network, network_suffix, expected))

    try:
        toNodeSshConnection = SshConnection(to_node)
        toNodeSshConnection.connect()

        if "switch" in to_node.type:
            toNodeSshConnection.run_test_command("show vlan", "CMN")
        else:
            toNodeSshConnection.run_test_command("echo hello", "hello")

        if expected:
            print("""\t\t^^^^ PASSED ^^^^""")
            TOTAL_PASS += 1
        else:
            print(f"\t\t^^^^ FAILED: accessible but SHOULD NOT have been accessible ^^^^")
    except Exception as err:
        if not expected:
            print("""\t\t^^^^ PASSED ^^^^""")
            TOTAL_PASS += 1
        else:
            print("\t\t^^^^ FAILED: not accessible but SHOULD have been accessible ^^^^\n")
            print("{}".format(str(err)))
    finally:
        toNodeSshConnection.close_connection(False)

    return 1

def get_ssh_host_for_node_type(node_type, excluded_hostnames):
    target_list = SSH_TARGETS.__dict__[node_type]
    for i in target_list:
        if not i.hostname in excluded_hostnames and i.is_ready():
            return i
