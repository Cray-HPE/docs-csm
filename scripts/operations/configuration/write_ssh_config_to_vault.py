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
from typing import Union

from python_lib import args
from python_lib import common
from python_lib import logger
from python_lib.vault import Vault


# Default values
CONFIG_PATH = "/root/.ssh/config"


def ssh_config_file(file_name: str) -> str:
    """
    Wrapper for args.get_text_file_contents with appropriate arguments for SSH config files.
    """
    logging.info("Reading in SSH config from '%s' file", file_name)
    file_contents = args.get_text_file_contents(file_name=file_name)
    logging.info("Read %d characters from '%s' file", len(file_contents), file_name)
    return file_contents


def update_ssh_config_in_vault(ssh_config: str) -> None:
    """
    Write the specified text to the CSM root SSH config key in Vault.
    Then read it back to verify it matches what was written
    """
    vault = Vault()

    logging.info("Writing CSM root SSH configuration to Vault")
    vault.write_csm_root_ssh_config(ssh_config)

    # Read back CSM root secret from Vault. It should exist, since we just wrote it.
    csm_root_ssh_config = vault.get_csm_root_ssh_config(must_exist=True)

    # Compare what we wrote to what we read back
    if csm_root_ssh_config == ssh_config:
        return
    common.log_error_raise_exception("CSM root SSH configuration in Vault does not match "
                                     "what we just wrote")


def delete_ssh_config_in_vault() -> None:
    """
    Try to get the SSH config from Vault.
    If this fails because the config does not exist, report this as a warning, but do not fail.
    Attempts to delete the SSH config in Vault.
    If the delete succeeds, try to do a get on it, to make sure it's actually gone.
    """
    vault = Vault()

    ssh_config = vault.get_csm_root_ssh_config(must_exist=False)
    if ssh_config is None:
        logging.warning("Cannot delete CSM root SSH configuration in Vault because it "
                        "does not exist in Vault")
        return
    logging.info("Deleting CSM root SSH configuration from Vault")
    vault.delete_csm_root_ssh_config()
    logging.debug("Attempting to read CSM root SSH configuration from Vault, to verify it "
                  "was deleted")
    if vault.get_csm_root_ssh_config(must_exist=False) is None:
        logging.info("CSM root SSH configuration deleted from Vault")
        return
    common.log_error_raise_exception("CSM root SSH configuration appears to exist in Vault even "
                                     "after deleting it")


def parse_args() -> Union[str, None]:
    """
    Parses the command line arguments.

    [--file FILEPATH | --delete]
    
    Returns None if --delete was specified
    Otherwise, returns the contents of the SSH config file
    """
    logging.debug(f"Command line arguments: {sys.argv}")

    parser = argparse.ArgumentParser(
        description="Update or delete CSM root SSH config in Vault")

    # The two possible arguments to this script are mutually exclusive
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--delete", action='store_true', dest='delete',
                       help="Delete CSM root SSH config from Vault")
    group.add_argument("--file", type=ssh_config_file, metavar="ssh-config-file",
                       dest='ssh_config',
                       help=f"Path to root SSH config file (default: {CONFIG_PATH})")
    parsed_args = parser.parse_args()
    if parsed_args.delete:
        return None
    if parsed_args.ssh_config is None:
        parsed_args = parser.parse_args(['--file', CONFIG_PATH])
    return parsed_args.ssh_config


def main():
    """
    Parses the command line arguments, read in the secrets, write them to Vault.
    """
    new_ssh_config = parse_args()
    if new_ssh_config is None:
        delete_ssh_config_in_vault()
    else:
        update_ssh_config_in_vault(new_ssh_config)


if __name__ == '__main__':
    logger.configure_logging(
        filename='/var/log/write_ssh_config_to_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
