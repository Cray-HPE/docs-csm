#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2022-2026 Hewlett Packard Enterprise Development LP
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
Reads in:
- the hashed root user password from /etc/shadow
- the root user SSH private key from /root/.ssh/id_rsa
- the root user SSH public key from /root/.ssh/id_rsa.pub

Writes these to the secret/csm/users/root in Vault, and then
reads them back to verify that they match what was written.

The user can optionally include the SSH config file as well.
"""

import argparse
import crypt
import logging
import sys

from python_lib import args
from python_lib import common
from python_lib import logger
from python_lib.csm_root_secret import (csm_root_secret,
                                        CsmUserSecretUpdateData,
                                        PW_FIELD,
                                        SSH_CONFIG_FIELD,
                                        SSH_PRI_KEY_FIELD,
                                        SSH_PUB_KEY_FIELD)
from python_lib.root_ssh_config import CONFIG_PATH, ssh_config_file

# Default values
PRI_KEY_PATH = "/root/.ssh/id_rsa"
PUB_KEY_PATH = "/root/.ssh/id_rsa.pub"
MINIMUM_PW_LENGTH = 8


def root_hash_from_etc_shadow() -> str:
    """
    Find the line in /etc/shadow for the root user and return the
    hashed password field from that line.
    """
    etc_shadow_lines = common.read_file("/etc/shadow")

    try:
        for etc_shadow_line in etc_shadow_lines.splitlines():
            line_fields = etc_shadow_line.split(":")
            if line_fields[0] != "root":
                continue
            logging.info("Found root user line in /etc/shadow")
            # Hash is in the second field of this line
            root_password_hash = line_fields[1]
            if not root_password_hash:
                common.print_err_exit(
                    "No password hash found on root user line")
            return root_password_hash
    except Exception as exc:
        common.log_error_raise_exception(
            "Unexpected error parsing /etc/shadow file contents", exc)
    common.log_error_raise_exception(
        "No root user line found in /etc/shadow file")


def pw_env_var(env_var_name: str) -> str:
    """
    Wrapper for args.get_env_var_value with appropriate arguments for password environment
    variables. This will require passwords to be at least 8 characters long.
    """
    logging.info("Reading in plaintext password from %s environment variable", env_var_name)
    return args.get_env_var_value(
        env_var_name=env_var_name,
        value_validator=lambda s: args.validate_string(s, min_length=MINIMUM_PW_LENGTH))


def pw_hash_env_var(env_var_name: str) -> str:
    """
    Wrapper for args.get_env_var_value with appropriate arguments for password hash
    environment variables.

    The minimum length of the password hash will depend on the algorithm that is used.
    For our purposes, we will look for an 8 character minimum, and make sure that it
    begins with a $ character.
    """
    logging.info("Reading in password hash from %s environment variable", env_var_name)
    return args.get_env_var_value(
        env_var_name=env_var_name,
        value_validator=lambda s: args.validate_string(s, min_length=8, required_prefix='$'))


def pri_ssh_key_file(file_name: str) -> str:
    """
    Wrapper for args.get_text_file_contents with appropriate arguments for SSH key files.
    At this point, we just make sure that the files are at least 256 characters long.
    """
    logging.info("Reading in SSH private key from '%s' file", file_name)
    return args.get_text_file_contents(
        file_name=file_name,
        value_validator=lambda s: args.validate_string(s, min_length=256))


def pub_ssh_key_file(file_name: str) -> str:
    """
    Wrapper for args.get_text_file_contents with appropriate arguments for SSH key files.
    At this point, we just make sure that the files are at least 256 characters long.
    """
    logging.info("Reading in SSH public key from '%s' file", file_name)
    return args.get_text_file_contents(
        file_name=file_name,
        value_validator=lambda s: args.validate_string(s, min_length=256))


def parse_args() -> CsmUserSecretUpdateData:
    """
    Parses the command line arguments.
    Returns a dictionary mapping secret field names to the value they should be
    set to, or None if they should be deleted from Vault. Any fields not
    included in the dictionary will be left unchanged from their current value
    in Vault (if any).

    [--pw-env-var VAR_NAME | --pw-hash-env-var VAR_NAME | --pw-no-change |
     --pw-prompt | --pw-remove | --pw-sys]
    [--pri-key-file FILEPATH | --pri-key-no-change | --pri-key-remove]
    [--pub-key-file FILEPATH | --pub-key-no-change | --pub-key-remove]
    [--config-file [FILEPATH] | --config-no-change | --config-remove]
    """
    logging.debug("Command line arguments: %s", sys.argv)

    # Sentinel values
    NO_CHANGE = object()
    REMOVE = object()

    parser = argparse.ArgumentParser(
        description="Update CSM root secrets in Vault with specified SSH keys and password hash")

    # Password source arguments are mutually exclusive
    pw_group = parser.add_mutually_exclusive_group()
    pw_group.add_argument("--pw-env-var", type=pw_env_var,
                          metavar="VAR_NAME",
                          help="Read plaintext password from specified variable")
    pw_group.add_argument("--pw-hash-env-var", type=pw_hash_env_var,
                          metavar="VAR_NAME",
                          help="Read shadow password hash string from specified variable")
    pw_group.add_argument("--pw-no-change", action='store_true',
                          help="Do not change saved password (if any) in Vault")
    pw_group.add_argument("--pw-prompt", action=args.PasswordPromptAction,
                          min_length=MINIMUM_PW_LENGTH,
                          help="Prompt user to enter plaintext password")
    pw_group.add_argument("--pw-remove", action='store_true',
                          help="Remove saved password (if any) from Vault")
    pw_group.add_argument("--pw-sys", action='store_true',
                          help="Read password hash from /etc/shadow file on the system (default)")

    # Private key source arguments are mutually exclusive
    pri_key_group = parser.add_mutually_exclusive_group()
    # Have to use argparse.SUPPRESS to avoid a default value being set
    pri_key_group.add_argument("--pri-key-no-change", action='store_const', const=NO_CHANGE,
                               dest='pri_key', default=argparse.SUPPRESS,
                               help="Do not change saved private key (if any) in Vault")
    pri_key_group.add_argument("--pri-key-file", type=pri_ssh_key_file,
                               metavar='private_key_file', dest='pri_key', default=PRI_KEY_PATH,
                               help=f"Read key from private_key_file (default: {PRI_KEY_PATH})")
    pri_key_group.add_argument("--pri-key-remove", action='store_const', const=REMOVE,
                               dest='pri_key', default=argparse.SUPPRESS,
                               help="Remove saved private key (if any) from Vault")

    # Public key source arguments are mutually exclusive
    pub_key_group = parser.add_mutually_exclusive_group()
    pub_key_group.add_argument("--pub-key-no-change", action='store_const', const=NO_CHANGE,
                               dest='pub_key', default=argparse.SUPPRESS,
                               help="Do not change saved public key (if any) in Vault")
    pub_key_group.add_argument("--pub-key-file", type=pub_ssh_key_file,
                               metavar='public_key_file', dest='pub_key', default=PUB_KEY_PATH,
                               help=f"Read key from public_key_file (default: {PUB_KEY_PATH})")
    pub_key_group.add_argument("--pub-key-remove", action='store_const', const=REMOVE,
                               dest='pub_key', default=argparse.SUPPRESS,
                               help="Remove saved public key (if any) from Vault")

    # SSH config source arguments are mutually exclusive
    config_group = parser.add_mutually_exclusive_group()
    config_group.add_argument("--config-no-change", action='store_const', const=NO_CHANGE,
                              dest='ssh_config', default=NO_CHANGE,
                              help="Do not change saved SSH config (if any) in Vault (default)")
    config_group.add_argument("--config-file", nargs='?', type=ssh_config_file, const=CONFIG_PATH,
                              default=argparse.SUPPRESS, metavar='ssh_config_file',
                              dest='ssh_config',
                              help=f"Read key from ssh_config_file or {CONFIG_PATH}")
    config_group.add_argument("--config-remove", action='store_const', const=REMOVE,
                              dest='ssh_config', default=argparse.SUPPRESS,
                              help="Remove saved SSH config (if any) from Vault")

    parsed_args = parser.parse_args()

    field_changes: CsmUserSecretUpdateData = dict()

    if parsed_args.pw_remove:
        # Clear the field in Vault, if it is set
        field_changes[PW_FIELD] = None
    elif parsed_args.pw_hash_env_var is not None:
        # We have already read in the hashed value from the environment variable
        field_changes[PW_FIELD] = parsed_args.pw_hash_env_var
    elif parsed_args.pw_env_var is not None:
        # Generate the hash
        logging.debug("Generating password hash")
        field_changes[PW_FIELD] = crypt.crypt(
            parsed_args.pw_env_var)
    elif parsed_args.pw_prompt is not None:
        # Generate the hash
        logging.debug("Generating password hash")
        field_changes[PW_FIELD] = crypt.crypt(
            parsed_args.pw_prompt)
    elif not parsed_args.pw_no_change:
        # Default is to read it from the system
        field_changes[PW_FIELD] = root_hash_from_etc_shadow()

    if parsed_args.pri_key is REMOVE:
        # Clear the field in Vault, if it is set
        field_changes[SSH_PRI_KEY_FIELD] = None
    elif parsed_args.pri_key is not NO_CHANGE:
        # Use file contents
        field_changes[SSH_PRI_KEY_FIELD] = parsed_args.pri_key

    if parsed_args.pub_key is REMOVE:
        # Clear the field in Vault, if it is set
        field_changes[SSH_PUB_KEY_FIELD] = None
    elif parsed_args.pub_key is not NO_CHANGE:
        # Use file contents
        field_changes[SSH_PUB_KEY_FIELD] = parsed_args.pub_key

    if parsed_args.ssh_config is REMOVE:
        # Clear the field in Vault, if it is set
        field_changes[SSH_CONFIG_FIELD] = None
    elif parsed_args.ssh_config is not NO_CHANGE:
        # Use file contents
        field_changes[SSH_CONFIG_FIELD] = parsed_args.ssh_config

    return field_changes


def main():
    """
    Parses the command line arguments, read in the secrets, write them to Vault.
    """
    field_changes = parse_args()
    csm_root_secret().update(field_changes, verify=True)


if __name__ == '__main__':
    logger.configure_logging(
        filename='/var/log/write_root_secrets_to_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
