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
import traceback

TEST_PLAN = None
SSH_TARGETS = None
FROM_APPLICABLE_NODE_TYPES = ["ncn_master", "uan", "cn", "spine_switch"]
TO_APPLICABLE_NODE_TYPES = ["ncn_master", "uan", "cn", "spine_switch"]
APPLICABLE_NETWORK_TYPES = ["can", "chn", "cmn", "nmn", "hmn", "hmnlb", "nmnlb"]

TOTAL_PASS = 0

def start_test(from_types, to_types, networks):
    global FROM_APPLICABLE_NODE_TYPES
    global TO_APPLICABLE_NODE_TYPES
    global APPLICABLE_NETWORK_TYPES

    FROM_APPLICABLE_NODE_TYPES = from_types
    TO_APPLICABLE_NODE_TYPES = to_types
    APPLICABLE_NETWORK_TYPES = networks

    load_test_plan()
    execute_test_plan()


def load_test_plan():
    global TEST_PLAN
    global SSH_TARGETS

    if csm_api_utils.is_bican_chm():
        print("BICAN:CHN detected.")
        filename = "chn_toggle_tests.yaml"
    else:
        print("BICAN:CAN detected.")
        filename = "can_toggle_tests.yaml"

    path = os.path.abspath(os.path.join(os.path.dirname(__file__), filename))
    f = open(path, "r")
    TEST_PLAN = yaml.safe_load(f.read())["tests"]

    SSH_TARGETS = SshTargets()
    SSH_TARGETS.refresh()

def execute_test_plan():
    for from_node_type in TEST_PLAN:
        if from_node_type in FROM_APPLICABLE_NODE_TYPES:
            collect_passwords_from_node_type(from_node_type, TEST_PLAN[from_node_type])

    total_ran = 0
    start_time = time.time()

    for from_node_type in TEST_PLAN:
        if from_node_type in FROM_APPLICABLE_NODE_TYPES:
            total_ran += test_from_node_type(from_node_type, TEST_PLAN[from_node_type])

    total_time = time.time() - start_time

    print(f"\n\nRan {total_ran} tests in {total_time:0.3f}s. Overall status: %s (Passed: {TOTAL_PASS}, Failed: {total_ran - TOTAL_PASS})" % ("PASSED" if TOTAL_PASS == total_ran else "FAILED"))

def collect_passwords_from_node_type(from_node_type, config):
    for network in config:
        if network in APPLICABLE_NETWORK_TYPES:
            collect_passwords_from_node_type_over_network(from_node_type, network, config[network])

def test_from_node_type(from_node_type, config):
    total_ran = 0
    for network in config:
        if network in APPLICABLE_NETWORK_TYPES:
            total_ran += test_from_node_type_over_network(from_node_type, network, config[network])

    return total_ran

def collect_passwords_from_node_type_over_network(from_node_type, network, config):
    for to_node_type in config:
        if to_node_type in TO_APPLICABLE_NODE_TYPES:
            from_node = get_ssh_host_for_node_type(from_node_type, ["ncn-m001"])

            if not from_node:
                continue

            from_node.get_password() # this will ask for the password and cache it

            collect_passwords_from_node_type_to_node_type_over_network(from_node_type, from_node, to_node_type, network)

def test_from_node_type_over_network(from_node_type, network, config):
    total_ran = 0
    network_suffix = "{}.{}".format(network, csm_api_utils.get_system_domain())

    for to_node_type in config:
        if to_node_type in TO_APPLICABLE_NODE_TYPES:
            from_node = get_ssh_host_for_node_type(from_node_type, ["ncn-m001"])

            if not from_node:
                print("""\nTesting SSH access:
        From node type {}
        Over network {} ({})""".format(
                    from_node_type, network, network_suffix))

                print("\t\t^^^^ SKIPPED: Cannot find a suitable node for node type {} ^^^^".format(from_node_type))
                continue

            from_node = from_node.with_domain_suffix(None)

            if from_node_type == "spine_switch" or from_node_type == "leaf_switch" or from_node_type == "leaf_BMC" or from_node_type == "CDU":
                from_node.vrf = "Customer"
                from_node.use_extra_params = False

            fromNodeSshConnection = SshConnection(from_node)

            total_ran += test_from_node_type_to_node_type_over_network(from_node_type, from_node, fromNodeSshConnection, to_node_type, network, config[to_node_type])

    return total_ran

def collect_passwords_from_node_type_to_node_type_over_network(from_node_type, from_node, to_node_type, network):
    to_node = get_ssh_host_for_node_type(to_node_type, ["ncn-m001", from_node.hostname])

    if to_node:
        to_node.get_password()

def test_from_node_type_to_node_type_over_network(from_node_type, from_node, fromNodeSshConnection, to_node_type, network, expected):
    global TOTAL_PASS

    network_suffix = "{}.{}".format(network, csm_api_utils.get_system_domain())

    to_node = get_ssh_host_for_node_type(to_node_type, ["ncn-m001", from_node.hostname])

    if not to_node:
        print("""\nTesting SSH access:
        From node type {}, using {}
        Over network {} ({})
        To node type {}
        Expected to work: {}""".format(
            from_node_type, from_node.get_full_domain_name(), network, network_suffix, to_node_type, expected))

        print("\t\t^^^^ SKIPPED: Cannot find a suitable node for node type {} ^^^^".format(to_node_type))
        return 0

    to_node = to_node.with_domain_suffix(network_suffix)

    if network == "nmn" and to_node.is_mellanox_switch():
        print("""\nTesting SSH access:
        From node type {}, using {}
        Over network {} ({})
        To node type {}
        Expected to work: {}""".format(
            from_node_type, from_node.get_full_domain_name(), network, network_suffix, to_node_type, expected))

        print("\t\t^^^^ SKIPPED: Please see CASMNET-787 ^^^^")
        return 0

    print("""\nTesting SSH access:
        From node type {}, using {}
        Over network {} ({})
        To node type {}, using {}
        Expected to work: {}""".format(
        from_node_type, from_node.get_full_domain_name(), network, network_suffix, to_node_type, to_node.get_full_domain_name(), expected))

    toNodeSshConnection = None

    try:
        toNodeSshConnection = SshConnection(to_node, fromNodeSshConnection)
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
            print(traceback.format_exc())
    finally:
        if toNodeSshConnection:
            toNodeSshConnection.close_connection(False)

    return 1

def get_ssh_host_for_node_type(node_type, excluded_hostnames):
    target_list = SSH_TARGETS.__dict__[node_type]
    for i in target_list:
        if not i.hostname in excluded_hostnames and i.is_ready():
            return i
