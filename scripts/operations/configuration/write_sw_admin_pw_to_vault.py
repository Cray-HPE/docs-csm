#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2023-2025 Hewlett Packard Enterprise Development LP
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

SW_ADMIN_PW_KEY = "net-creds/switch_admin"
SW_ADMIN_PW_FIELD = "admin"


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
    logging.info("Writing switch admin password to Vault")
    Vault().write_secret(secret_key=SW_ADMIN_PW_KEY,
                         secret_data={ SW_ADMIN_PW_FIELD: admin_pw },
                         verify=True)


if __name__ == '__main__':
    logger.configure_logging(filename='/var/log/write_sw_admin_pw_to_vault.log')
    try:
        main()
    except common.ScriptException as script_exc:
        common.print_err_exit(f"{script_exc}")
    print("SUCCESS", flush=True)
