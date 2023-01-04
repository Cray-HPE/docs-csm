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
"""Shared Python function library: VCS"""

import traceback

import base64
import logging

from typing import Tuple

from . import common
from . import k8s


K8S_NAMESPACE = "services"
K8S_SECRET_NAME = "vcs-user-credentials"


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


def get_vcs_credentials(k8s_client: k8s.CoreV1API = None) -> Tuple[str, str]:
    """
    Retrieve and decode the vcs_username and vcs_password from the VCS Kubernetes secret
    """
    if k8s_client is None:
        k8s_client = k8s.Client()
    secret_label = f"{K8S_NAMESPACE}/{K8S_SECRET_NAME} Kubernetes secret"
    vcs_secret = k8s_client.get_secret(
        name=K8S_SECRET_NAME, namespace=K8S_NAMESPACE)
    try:
        vcs_secret_data = vcs_secret.data
    except AttributeError as exc:
        log_error_raise_exception(
            f"{secret_label} has an unexpected format", exc)
    try:
        encoded_username = vcs_secret_data["vcs_username"]
        logging.debug("Encoded VCS username obtained")
        encoded_password = vcs_secret_data["vcs_password"]
        logging.debug("Encoded VCS password obtained")
    except (KeyError, TypeError) as exc:
        log_error_raise_exception(
            f"{secret_label} has an unexpected format", exc)
    # decode bytes to strings
    try:
        decoded_username = base64.standard_b64decode(encoded_username).decode()
        logging.debug("VCS username decoded")
        decoded_password = base64.standard_b64decode(encoded_password).decode()
        logging.debug("VCS password decoded")
    except Exception as exc:
        log_error_raise_exception(
            f"Error decoding credentials in {secret_label}", exc)
    return decoded_username, decoded_password
