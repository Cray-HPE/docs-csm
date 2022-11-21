#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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
"""

import argparse
import crypt
import logging
import sys
import traceback

from python_lib import args
from python_lib import common
from python_lib import logger
from python_lib import vault


# Default values
PRI_KEY_PATH = "/root/.ssh/id_rsa"
PUB_KEY_PATH = "/root/.ssh/id_rsa.pub"


MINIMUM_PW_LENGTH = 8


def log_error_raise_exception(msg: str, parent_exception: Exception = None) -> None:
    """
    1) If a parent exception is passed in, make a debug log entry with its stack trace.
    2) Log an error with the specified message.
    3) Raise a ScriptException with the specified message (from the parent exception, if
       specified)
    """
    if parent_exception is not None:
        logging.debug(traceback.format_exc())
    logging.error(msg)
    if parent_exception is None:
        raise common.ScriptException(msg)
    raise common.ScriptException(msg) from parent_exception


def get_root_hash_from_etc_shadow() -> str:
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
    logging.info(
        f"Reading in plaintext password from {env_var_name} environment variable")
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
    logging.info(
        f"Reading in password hash from {env_var_name} environment variable")
    return args.get_env_var_value(
        env_var_name=env_var_name,
        value_validator=lambda s: args.validate_string(s, min_length=8, required_prefix='$'))


def pri_ssh_key_file(file_name: str) -> str:
    """
    Wrapper for args.get_text_file_contents with appropriate arguments for SSH key files.
    At this point, we just make sure that the files are at least 256 characters long.
    """
    logging.info(
        f"Reading in SSH private key from '{file_name}' file")
    return args.get_text_file_contents(
        file_name=file_name,
        value_validator=lambda s: args.validate_string(s, min_length=256))


def pub_ssh_key_file(file_name: str) -> str:
    """
    Wrapper for args.get_text_file_contents with appropriate arguments for SSH key files.
    At this point, we just make sure that the files are at least 256 characters long.
    """
    logging.info(
        f"Reading in SSH public key from '{file_name}' file")
    return args.get_text_file_contents(
        file_name=file_name,
        value_validator=lambda s: args.validate_string(s, min_length=256))


def main():
    """
    Parses the command line arguments, read in the secrets, write them to Vault.
    """
    logging.debug(f"Command line arguments: {sys.argv}")

    parser = argparse.ArgumentParser(
        description="Update CSM root secrets in Vault with specified SSH keys and password hash")

    # Password source arguments are mutually exclusive
    pw_group = parser.add_mutually_exclusive_group()
    pw_group.add_argument("--pw-env-var", type=pw_env_var,
                          metavar="PASSWORD_ENV_VAR_NAME",
                          help="Read plaintext password from specified variable")
    pw_group.add_argument("--pw-hash-env-var", type=pw_hash_env_var,
                          metavar="PASSWORD_HASH_ENV_VAR_NAME",
                          help="Read shadow password hash string from specified variable")
    pw_group.add_argument("--pw-sys", action='store_true',
                          help="Read password hash from /etc/shadow file on the system (default)")
    pw_group.add_argument("--pw-prompt", action=args.PasswordPromptAction,
                          min_length=MINIMUM_PW_LENGTH,
                          help="Prompt user to enter plaintext password")

    parser.add_argument("--pri-key-file", type=pri_ssh_key_file,
                        metavar='private_key_file', default=PRI_KEY_PATH, dest='pri_key',
                        help=f"Path to private key file (default: {PRI_KEY_PATH})")

    parser.add_argument("--pub-key-file", type=pub_ssh_key_file,
                        metavar='public_key_file', default=PUB_KEY_PATH, dest='pub_key',
                        help=f"Path to public key file (default: {PUB_KEY_PATH})")

    parsed_args = parser.parse_args()

    # Get password hash
    if parsed_args.pw_hash_env_var is not None:
        # Simplest case -- we have already read in the hashed value from the environment variable
        pw_hash = parsed_args.pw_hash_env_var
    elif parsed_args.pw_env_var is not None:
        # Generate the hash
        logging.debug("Generating password hash")
        pw_hash = crypt.crypt(parsed_args.pw_env_var)
    elif parsed_args.pw_prompt is not None:
        # Generate the hash
        logging.debug("Generating password hash")
        pw_hash = crypt.crypt(parsed_args.pw_prompt)
    else:
        pw_hash = get_root_hash_from_etc_shadow()

    vault.write_root_secrets(ssh_private_key=parsed_args.pri_key,
                             ssh_public_key=parsed_args.pub_key,
                             password_hash=pw_hash,
                             verify=True)


if __name__ == '__main__':
    logger.configure_logging(
        filename='/var/log/write_root_secrets_to_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
