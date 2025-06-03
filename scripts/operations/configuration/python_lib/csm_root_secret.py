#
# MIT License
#
# (C) Copyright 2022-2025 Hewlett Packard Enterprise Development LP
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
"""Shared Python function library: CSM Root Secret"""

import logging
import traceback
from typing import NoReturn, Union
from typing_extensions import Literal, TypedDict

from . import common
from . import k8s
from . import vault


class CsmUserSecretData(TypedDict, total=False):
    password: str
    ssh_config: str
    ssh_private_key: str
    ssh_public_key: str


class CsmUserSecretUpdateData(TypedDict, total=False):
    """
    A value of None in the update dict means the field should be deleted
    as part of the update
    """
    password: Union[str, None]
    ssh_config: Union[str, None]
    ssh_private_key: Union[str, None]
    ssh_public_key: Union[str, None]


CsmUserSecretFields = Literal['password', 'ssh_config', 'ssh_private_key', 'ssh_public_key']

SSH_CONFIG_FIELD: CsmUserSecretFields = 'ssh_config'
SSH_PRI_KEY_FIELD: CsmUserSecretFields = 'ssh_private_key'
SSH_PUB_KEY_FIELD: CsmUserSecretFields = 'ssh_public_key'
PW_FIELD: CsmUserSecretFields = 'password'


def log_error_raise_exception(msg: str, parent_exception: Exception = None) -> NoReturn:
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


class CsmUserSecret:
    """
    Helper class for doing operations on the CSM root secret in Vault
    """

    CSM_USER_SECRET_PREFIX = "csm/users/"

    def __init__(self, user: str, k8s_client: k8s.CoreV1API = None) -> None:
        self.vault = vault.Vault(k8s_client=k8s_client)
        self.secret_key = f"{self.CSM_USER_SECRET_PREFIX}{user}"

    def delete(self, **delete_secret_kwargs) -> None:
        """
        Wrapper function that supplies the CSM root secret key to delete_secret()

        If verify is set to True, after deleting, attempt to read the secret and
        """
        self.vault.delete_secret(secret_key=self.secret_key, **delete_secret_kwargs)

    def get(self, **get_secret_kwargs) -> Union[CsmUserSecretData, None]:
        """
        Wrapper function that supplies the CSM root secret key to get_secret()
        """
        return self.vault.get_secret(secret_key=self.secret_key, **get_secret_kwargs)

    def write(self, secret_data: CsmUserSecretData, **write_secret_kwargs) -> None:
        """
        Wrapper function that supplies the CSM root secret key to write_secret()
        """
        self.vault.write_secret(secret_key=self.secret_key, secret_data=secret_data,
                                **write_secret_kwargs)

    def update(self, secret_update_data: CsmUserSecretUpdateData, **write_secret_kwargs) -> None:
        """
        Because the CSM version of Vault does not support the PATCH operation, we have to
        implement it ourselves.

        Fields with values of None indicate that the field should be deleted from the secet in
        Vault.

        If the secret does not exist in Vault, just write the specified data.
        Otherwise, reads the specified secret from Vault, patch the data fields,
        and write it back.
        Raises an exception if anything goes wrong.
        """
        if not secret_update_data:
            logging.debug("No update data specified; returning")
            return
        root_secret = self.get(must_exist=False)
        if root_secret is None:
            new_root_secret = CsmUserSecretData()
            # Get the update fields that are not set to None
            for field, value in secret_update_data.items():
                if value is not None:
                    new_root_secret[field] = value
            if not new_root_secret:
                logging.debug("Secret does not exist in Vault, and no data specified to write")
                return
            self.write(new_root_secret, **write_secret_kwargs)
            return

        updated_root_secret = root_secret.copy()
        for field, value in secret_update_data.items():
            if value is None:
                # Remove this field from the root secret, if it exists
                updated_root_secret.pop(field, None)
            else:
                # Update the value of the field
                updated_root_secret[field] = value

        if updated_root_secret == root_secret:
            logging.debug("Root secret in Vault already has specified updates")
            return
        self.write(updated_root_secret, **write_secret_kwargs)

def csm_root_secret(k8s_client: k8s.CoreV1API = None) -> CsmUserSecret:
    """
    Return a CsmUserSecret for the root user
    """
    return CsmUserSecret(user="root", k8s_client=k8s_client)
