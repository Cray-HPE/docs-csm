#!/usr/bin/env python3
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

"""
Reads in:
- the hashed root user password from /etc/shadow
- the root user SSH private key from /root/.ssh/id_rsa
- the root user SSH public key from /root/.ssh/id_rsa.pub

Writes these to the secret/csm/users/root in Vault, and then
reads them back to verify that they match what was written.
"""

import argparse
import copy
import crypt
import logging
import sys
import traceback

from python_lib import args
from python_lib import common
from python_lib import logger
from python_lib.types import JsonObject
from python_lib.vault import Vault


# Default values
PRI_KEY_PATH = "/root/.ssh/id_rsa"
PUB_KEY_PATH = "/root/.ssh/id_rsa.pub"
MINIMUM_PW_LENGTH = 8

# Constants
PASSWORD_HASH_FIELD_NAME = "password"
PRIVATE_KEY_FIELD_NAME = "ssh_private_key"
PUBLIC_KEY_FIELD_NAME = "ssh_public_key"


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


def update_secret_fields(secret: JsonObject, field_changes: JsonObject) -> JsonObject:
    """
    Takes the current CSM root secret values (secret) and determines the desired new CSM root secret
    values. Returns a dictionary of the new values.
    """
    updated_secret = copy.deepcopy(secret)
    for field_name, new_field_value in field_changes.items():
        if new_field_value is None:
            # This means the field should be removed, if it is set
            try:
                del updated_secret[field_name]
                logging.debug(
                    f"CSM root secret {field_name} in Vault will be deleted")
            except KeyError:
                # Not a problem, but let's note it for the log
                logging.debug(
                    f"Asked to delete CSM root secret {field_name} in Vault, but it isn't set")
            continue
        # Record the new value
        updated_secret[field_name] = new_field_value
    return updated_secret


def compare_root_secrets(secret_written: JsonObject, secret_read: JsonObject) -> None:
    """
    Compare the secret we wrote to what we read back. If there are any differences,
    log them and raise an exception.
    """
    secrets_match = True

    # Validate that Vault values match what we wrote
    logging.debug(
        "Validating that Vault contents match what was written to it")

    fields_not_written = secret_written.keys() - secret_read.keys()
    extra_fields = secret_read.keys() - secret_written.keys()
    common_fields = secret_read.keys() & secret_written.keys()

    if fields_not_written:
        secrets_match = False
        logging.error("Fields were written to the CSM root secret, but were not present"
                      f" when it was read back: {fields_not_written}")
    else:
        logging.debug(
            "All written secret fields were present when read back")

    if extra_fields:
        secrets_match = False
        logging.error("Fields were not written to the CSM root secret, but were present"
                      f" when it was read back: {extra_fields}")
    else:
        logging.debug("All read secret fields were present when written")

    for field in common_fields:
        if secret_read[field] == secret_written[field]:
            logging.debug(f"Vault value for {field} matches what was written")
        else:
            secrets_match = False
            logging.error(
                f"Vault value for {field} DOES NOT MATCH what was written")

    if not secrets_match:
        raise common.ScriptException(
            "Secret read back from Vault does not match what was written")

    logging.info("Secrets read back from Vault match desired values")


def update_root_secret_in_vault(field_changes: JsonObject) -> None:
    """
    Write the SSH keys and passwords to the csm root secret in Vault.
    If the result is that the secret no longer contains any data, it is deleted from Vault.
    Then read secret the back to verify it matches what was written (or verify that it
    no longer exists in Vault, if applicable).
    """

    vault = Vault()

    # Get the current CSM root secrets from Vault. It is possible that the secret is not in Vault.
    csm_root_secret_before = vault.get_csm_root_secret(must_exist=False)
    if csm_root_secret_before is None:
        logging.debug("CSM root secret does not currently exist in Vault")
        csm_root_secret_before = dict()

    # Generate the new desired root secret based on the current secret contents and the
    # arguments to this function
    csm_root_secret_to_write = update_secret_fields(secret=csm_root_secret_before,
                                                    field_changes=field_changes)

    if not csm_root_secret_to_write:
        logging.info("Based on inputs, the desired CSM root secret is empty")
        if not csm_root_secret_before:
            logging.info(
                "The CSM root secret in Vault is already empty, so nothing to do.")
            return

        # Vault does not allow empty secrets do be written. Instead, they must be deleted.
        logging.info("Deleting CSM root secret from Vault")
        vault.delete_csm_root_secret()

        # Now attempt to read the CSM root secret from Vault.
        csm_root_secret_after = vault.get_csm_root_secret(must_exist=False)
        if csm_root_secret_after is not None:
            common.log_error_raise_exception(
                "CSM root secret appears to exist in Vault even after deleting it")
        logging.info("CSM root secret deleted from Vault")
        return

    # We are left with the case where we are writing secret data to Vault
    logging.info("Writing updated CSM root secret to Vault")
    vault.write_csm_root_secret(secret_data=csm_root_secret_to_write)

    # Read back CSM root secret from Vault. It should exist, since we just wrote it.
    csm_root_secret_after = vault.get_csm_root_secret(must_exist=True)

    # Compare what we wrote to what we read back
    compare_root_secrets(csm_root_secret_to_write, csm_root_secret_after)
    return


def parse_args() -> JsonObject:
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
    """
    logging.debug(f"Command line arguments: {sys.argv}")

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
    pri_key_group.add_argument("--pri-key-no-change", action='store_true',
                               help="Do not change saved private key (if any) in Vault")
    pri_key_group.add_argument("--pri-key-file", type=pri_ssh_key_file,
                               metavar='private_key_file', default=PRI_KEY_PATH, dest='pri_key',
                               help=f"Path to private key file (default: {PRI_KEY_PATH})")
    pri_key_group.add_argument("--pri-key-remove", action='store_true',
                               help="Remove saved private key (if any) from Vault")

    # Public key source arguments are mutually exclusive
    pub_key_group = parser.add_mutually_exclusive_group()
    pub_key_group.add_argument("--pub-key-no-change", action='store_true',
                               help="Do not change saved public key (if any) in Vault")
    pub_key_group.add_argument("--pub-key-file", type=pub_ssh_key_file,
                               metavar='public_key_file', default=PUB_KEY_PATH, dest='pub_key',
                               help=f"Path to public key file (default: {PUB_KEY_PATH})")
    pub_key_group.add_argument("--pub-key-remove", action='store_true',
                               help="Remove saved public key (if any) from Vault")

    parsed_args = parser.parse_args()

    field_changes = dict()

    if parsed_args.pw_remove:
        # Clear the field in Vault, if it is set
        field_changes[PASSWORD_HASH_FIELD_NAME] = None
    elif parsed_args.pw_hash_env_var is not None:
        # We have already read in the hashed value from the environment variable
        field_changes[PASSWORD_HASH_FIELD_NAME] = parsed_args.pw_hash_env_var
    elif parsed_args.pw_env_var is not None:
        # Generate the hash
        logging.debug("Generating password hash")
        field_changes[PASSWORD_HASH_FIELD_NAME] = crypt.crypt(
            parsed_args.pw_env_var)
    elif parsed_args.pw_prompt is not None:
        # Generate the hash
        logging.debug("Generating password hash")
        field_changes[PASSWORD_HASH_FIELD_NAME] = crypt.crypt(
            parsed_args.pw_prompt)
    elif not parsed_args.pw_no_change:
        # Default is to read it from the system
        field_changes[PASSWORD_HASH_FIELD_NAME] = root_hash_from_etc_shadow()

    if parsed_args.pri_key_remove:
        # Clear the field in Vault, if it is set
        field_changes[PRIVATE_KEY_FIELD_NAME] = None
    elif not parsed_args.pri_key_no_change:
        field_changes[PRIVATE_KEY_FIELD_NAME] = parsed_args.pri_key

    if parsed_args.pub_key_remove:
        # Clear the field in Vault, if it is set
        field_changes[PUBLIC_KEY_FIELD_NAME] = None
    elif not parsed_args.pub_key_no_change:
        field_changes[PUBLIC_KEY_FIELD_NAME] = parsed_args.pub_key

    return field_changes


def main():
    """
    Parses the command line arguments, read in the secrets, write them to Vault.
    """
    field_changes = parse_args()
    update_root_secret_in_vault(field_changes)


if __name__ == '__main__':
    logger.configure_logging(
        filename='/var/log/write_root_secrets_to_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
