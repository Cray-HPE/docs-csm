#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
Prompts the user to enter (and confirm) the switch admin password.
Writes this password to secret/net-creds/switch_admin in Vault, and reads it
back to verify that it matches what was written.
"""

import getpass
import logging
import sys

from python_lib import common
from python_lib import logger
from python_lib.vault import Vault


def update_password_in_vault(pw_string: str) -> None:
    """
    Writes the switch admin password to Vault.
    Then read it back to verify it matches what was written
    """

    vault = Vault()

    logging.info("Writing switch admin password to Vault")
    vault.write_sw_admin_password(pw_string)

    # Read back PW from Vault.
    pw_from_vault = vault.get_sw_admin_password()

    # Compare what we wrote to what we read back
    if pw_string != pw_from_vault:
        msg = "Password read back from Vault does NOT match what was written to Vault"
        logging.error(msg)
        raise common.ScriptException(msg)

    logging.info("Password read from Vault matches what was written")
    return


def prompt_user_for_password() -> str:
    """
    Get the password from the user, verify it is not blank, and get them
    to enter it a second time to make sure it matches. Return password
    string.
    """
    while True:
        pw1 = getpass.getpass("Enter switch admin password: ")
        if not pw1:
            sys.stderr.write("Password may not be blank\n\n")
            continue
        pw2 = getpass.getpass("Retype password: ")
        if pw1 == pw2:
            break
        sys.stderr.write("Passwords do not match\n\n")
    return pw1


def main():
    """
    Prompt the user for the password, write it to Vault.
    """
    admin_pw = prompt_user_for_password()
    update_password_in_vault(admin_pw)


if __name__ == '__main__':
    logger.configure_logging(filename='/var/log/write_sw_admin_pw_to_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
