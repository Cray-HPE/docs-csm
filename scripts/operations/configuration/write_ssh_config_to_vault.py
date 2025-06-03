#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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

"""
Reads in the SSH configuration from /root/.ssh/config (or the user-specified path),
writes it to secret csm/ssh-config/root in Vault, and then
reads it back to verify that it matches what was written.
"""

import argparse
import logging
import sys

from python_lib import common
from python_lib import logger
from python_lib.csm_root_secret import (csm_root_secret,
                                        CsmUserSecretUpdateData,
                                        SSH_CONFIG_FIELD)
from python_lib.root_ssh_config import CONFIG_PATH, ssh_config_file


def parse_args() -> CsmUserSecretUpdateData:
    """
    Parses the command line arguments.

    [--file FILEPATH | --delete]
    """
    logging.debug("Command line arguments: %s", sys.argv)

    parser = argparse.ArgumentParser(
        description="Update or delete CSM root SSH config in Vault")

    # Sentinel value
    DELETE = object()

    # The two possible arguments to this script are mutually exclusive
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--delete", action='store_const', dest='ssh_config', const=DELETE,
                       default=argparse.SUPPRESS,
                       help="Delete CSM root SSH config from Vault")
    group.add_argument("--file", type=ssh_config_file, metavar="ssh-config-file",
                       dest='ssh_config', default=CONFIG_PATH,
                       help=f"Path to root SSH config file (default: {CONFIG_PATH})")
    parsed_args = parser.parse_args()
    update = CsmUserSecretUpdateData()
    update[SSH_CONFIG_FIELD] = None if parsed_args.ssh_config is DELETE else parsed_args.ssh_config
    return update


def main():
    """
    Parses the command line arguments, read in the secrets, write them to Vault.
    """
    root_secret_update_data = parse_args()
    csm_root_secret().update(root_secret_update_data, verify=True)


if __name__ == '__main__':
    logger.configure_logging(
        filename='/var/log/write_ssh_config_to_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
