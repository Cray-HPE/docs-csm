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

import logging
import traceback

from python_lib import common
from python_lib import logger
from python_lib import vault


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
    except Exception as e:
        common.log_error_raise_exception(
            "Unexpected error parsing /etc/shadow file contents", e)
    common.print_err_exit("No root user line found in /etc/shadow file")


def main() -> None:
    """
    1. Read in the SSH keys and hashed root password from the system.
    2. Initialize the Kubernetes API client.
    3. Get the Vault token from the cray-vault-unseal-keys secret in Kubernetes.
    4. Write the SSH keys and hashed password into Vault.
    5. Read the SSH keys and hashed password from Vault.
    6. Verify that what was read matches what was written.
    """

    # Read in secrets from the system
    try:
        ssh_private_key = common.read_file("/root/.ssh/id_rsa")
        ssh_public_key = common.read_file("/root/.ssh/id_rsa.pub")
        password_hash = get_root_hash_from_etc_shadow()
        vault.write_root_secrets(ssh_private_key=ssh_private_key,
                                 ssh_public_key=ssh_public_key,
                                 password_hash=password_hash,
                                 verify=True)
    except common.ScriptException as e:
        common.print_err_exit(f"{e}")

    print("SUCCESS", flush=True)


if __name__ == '__main__':
    logger.configure_logging(
        filename='/var/log/write_root_secrets_to_vault.log')
    main()
