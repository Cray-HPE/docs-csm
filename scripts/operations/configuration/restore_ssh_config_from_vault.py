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
Reads in the SSH configuration from Vault and writes it to /root/.ssh/config (or the
user-specified path)
"""

import argparse
import logging
import os
import os.path
import sys
from typing import NamedTuple, Union

from python_lib import common
from python_lib import logger
from python_lib.csm_root_secret import csm_root_secret, SSH_CONFIG_FIELD
from python_lib.root_ssh_config import CONFIG_DIR, CONFIG_NAME


OVERWRITE_ARG = "--overwrite"
IN_VAULT_ARG = "--fail-if-not-in-vault"

class ScriptArgs(NamedTuple):
    filename: str
    overwrite: bool
    must_be_in_vault: bool

    @property
    def filepath(self) -> str:
        return os.path.join(CONFIG_DIR, self.filename)


def file_basename(file_name: str) -> str:
    """
    Validate that the specified file_name is not empty, does not contain any '/' characters,
    and contains at least one character that is not .
    """
    if not file_name:
        raise argparse.ArgumentTypeError("File name may not be blank")
    if '/' in file_name:
        raise argparse.ArgumentTypeError("File name may not contain '/' characters")
    if all(c == '.' for c in file_name):
        raise argparse.ArgumentTypeError("File name must contain non-. character")
    return file_name


def write_ssh_config_file(args: ScriptArgs, ssh_config: str) -> None:
    """
    Validate that the target file and directory do not present any problems, either on
    their own or due to the arguments we've been passed. If not, then write the config
    to the file.
    """
    validate_target(args)
    logging.info("Writing SSH configuration to %s", args.filepath)
    with open(args.filepath, "wt") as configfile:
        num_bytes = configfile.write(ssh_config)
    logging.info("Wrote %d bytes to %s", num_bytes, args.filepath)
    logging.info("Setting 644 file permissions to %s", args.filepath)
    os.chmod(args.filepath, 0o644)
    logging.info("Set 644 file permissions to %s", args.filepath)


def validate_target(args: ScriptArgs):
    """
    Verify that:
    1. CONFIG_DIR exists
    2. CONFIG_DIR is a directory
    3. If the target file exists, make sure it is a regular file and we are allowed to
       overwrite it
    """
    if not os.path.exists(CONFIG_DIR):
        common.log_error_raise_exception(f"Directory '{CONFIG_DIR}' does not exist")

    # Make sure it is actually a directory
    if not os.path.isdir(CONFIG_DIR):
        common.log_error_raise_exception(f"'{CONFIG_DIR}' exists but is not a directory")

    if not os.path.exists(args.filepath):
        return

    # It exists, so make sure it is a regular file
    if not os.path.isfile(args.filepath):
        common.log_error_raise_exception(f"'{args.filepath}' exists but is not a regular file")

    # Finally, since it exists, make sure we are allowed to overwrite it
    if args.overwrite:
        return

    common.log_error_raise_exception(f"File '{args.filepath}' already exists; call script with "
                                     f"{OVERWRITE_ARG} to overwrite it")


def get_ssh_config_from_vault(args: ScriptArgs) -> Union[str, None]:
    """
    Return the SSH config from Vault.
    If it is not in Vault, return None, unless we were called with --fail-if-not-in-vault, in
    which case reaise an Exception
    """
    root_secret = csm_root_secret().get(must_exist=False)
    if root_secret is None:
        # The CSM root secret is not in Vault
        if not args.must_be_in_vault:
            logging.info("CSM root secret is not in Vault")
            return None
        common.log_error_raise_exception("No CSM root secret in Vault, and script "
                                         f"called with {IN_VAULT_ARG}")

    try:
        return root_secret[SSH_CONFIG_FIELD]
    except KeyError as exc:
        if not args.must_be_in_vault:
            logging.info("No %s field in CSM root secret in Vault", SSH_CONFIG_FIELD)
            return None
        common.log_error_raise_exception(f"No {SSH_CONFIG_FIELD} field in CSM root secret in "
                                         f"Vault, and script called with {IN_VAULT_ARG}", exc)


def parse_args() -> ScriptArgs:
    """
    Parses the command line arguments.

    [--file FILENAME] [--overwrite] [--fail-if-not-in-vault]
    """
    logging.debug("Command line arguments: %s", sys.argv)

    parser = argparse.ArgumentParser(
        description="Update root SSH config file from value in Vault")

    parser.add_argument("--file", type=file_basename, metavar="filename", dest="filename",
                        default=CONFIG_NAME, help=f"Name of file in {CONFIG_DIR} to write SSH "
                                                  f"configuration into (default: {CONFIG_NAME})")
    parser.add_argument(OVERWRITE_ARG, action='store_true', dest='overwrite', default=False,
                        help="Overwrite the configuration file if it already exists "
                             "(default: fail if it already exists)")
    parser.add_argument(IN_VAULT_ARG, action='store_true', dest='must_be_in_vault',
                        default=False, help="Fail if the SSH configuration is not found in Vault")
    parsed_args = parser.parse_args()

    return ScriptArgs(filename=parsed_args.filename,
                      overwrite=parsed_args.overwrite,
                      must_be_in_vault=parsed_args.must_be_in_vault)


def main():
    """
    Parses the command line arguments, read the info from Vault, and write it to the target file
    """
    script_args = parse_args()
    ssh_config = get_ssh_config_from_vault(script_args)
    if ssh_config is None:
        return
    write_ssh_config_file(script_args, ssh_config)


if __name__ == '__main__':
    logger.configure_logging(
        filename='/var/log/restore_ssh_config_from_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
