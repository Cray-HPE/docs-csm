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
"""Shared Python function library: Vault"""

import traceback

import base64
import logging
import requests

from . import api_requests
from . import common
from . import k8s

SECRET_FIELD_NAMES = ["password", "ssh_private_key", "ssh_public_key"]

K8S_NAMESPACE = "vault"
K8S_SECRET_NAME = "cray-vault-unseal-keys"
K8S_SERVICE_NAME = "cray-vault"

TOKEN_STRING = None
API_URL = None


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


def get_token_string() -> str:
    """
    Retrieve the Vault Kubernetes secret, extract the token string from it,
    decode it from base-64, and return it as a string.
    """
    global TOKEN_STRING
    if TOKEN_STRING is None:
        # Obtain Vault token string from Kubernetes secret
        secret_label = f"{K8S_NAMESPACE}/{K8S_SECRET_NAME} Kubernetes secret"
        logging.info(f"Getting Vault token from {secret_label}")
        vault_secret = k8s.get_secret(
            name=K8S_SECRET_NAME, namespace=K8S_NAMESPACE)
        try:
            encoded_vault_token = vault_secret.data["vault-root"]
        except (AttributeError, KeyError, TypeError) as e:
            log_error_raise_exception(
                f"{secret_label} has an unexpected format", e)
        # return decoded bytes as a string
        try:
            TOKEN_STRING = base64.standard_b64decode(
                encoded_vault_token).decode()
        except Exception as e:
            log_error_raise_exception(
                f"Error decoding token in {secret_label}", e)
    return TOKEN_STRING


def get_api_url() -> str:
    """
    1. Looks up the vault/cray-vault service in Kubernetes
    2. Retrieves the cluster IP address of the service
    3. Retrieves the port list of the service
    4. Finds the API port.
    5. Assembles the base URL for the Vault API
    """
    global API_URL
    if API_URL is None:
        logging.debug("Finding Vault API URL")
        service_label = f"{K8S_NAMESPACE}/{K8S_SERVICE_NAME} Kubernetes service"
        vault_service = k8s.get_service(
            name=K8S_SERVICE_NAME, namespace=K8S_NAMESPACE)

        try:
            vault_ip = vault_service.spec.cluster_ip
            for vault_port in vault_service.spec.ports:
                if vault_port.name == 'http-api-port':
                    API_URL = f"http://{vault_ip}:{vault_port.port}"
                    break
        except (AttributeError, KeyError, TypeError) as e:
            log_error_raise_exception(
                f"{service_label} has an unexpected format", e)

        if API_URL is None:
            log_error_raise_exception(
                f"No 'http-api-port' port found for {service_label}")
        logging.debug(f"API_URL = {API_URL}")
    return API_URL


def get_csm_root_secret_api_url() -> str:
    """
    Returns the Vault API endpoint URL for the secret/csm/users/root Vault entry
    """
    api_url_base = get_api_url()
    return f"{api_url_base}/v1/secret/csm/users/root"


def write_root_secrets(ssh_private_key: str,
                       ssh_public_key: str,
                       password_hash: str,
                       verify: bool = True) -> None:
    """
    Write the SSH keys and passwords to the csm root secret in Vault.
    If verify is true, read them back to verify that they were set to the desired values.
    """

    secrets_to_write = {
        "ssh_private_key": ssh_private_key,
        "ssh_public_key": ssh_public_key,
        "password": password_hash}

    csm_root_secret_url = get_csm_root_secret_api_url()
    logging.debug(f"csm_root_secret_url = {csm_root_secret_url}")
    request_headers = {
        "X-Vault-Request": "true",
        "X-Vault-Token": get_token_string()}

    # Create API request session
    with requests.Session() as session:
        # The same headers are used for all requests we'll be making
        session.headers.update(request_headers)

        # Write secrets to Vault
        logging.info(
            "Writing SSH keys and root password hash to secret/csm/users/root in Vault")
        # We do not expect or care about any output of the write request,
        # so no need to save the function return
        try:
            api_requests.make_api_request_with_retries(request_method=session.post,
                                                       url=csm_root_secret_url,
                                                       expected_status_code=204,
                                                       json=secrets_to_write)
        except Exception as e:
            log_error_raise_exception(
                f"Error making POST request to {csm_root_secret_url}", e)

        if not verify:
            logging.info("Vault write completed successfully")
            return

        # Read secrets back from Vault
        logging.info(
            "Read back secrets from Vault to verify that the values were correctly saved")
        try:
            resp_body = api_requests.make_api_request_with_retries(request_method=session.get,
                                                                   url=csm_root_secret_url,
                                                                   expected_status_code=200)
        except Exception as e:
            log_error_raise_exception(
                f"Error making GET request to {csm_root_secret_url}", e)

        if resp_body is None:
            log_error_raise_exception(
                "Empty body in response to Vault API read request")

        try:
            retrieved_vault_secrets = {
                field: resp_body["data"][field] for field in SECRET_FIELD_NAMES}
        except (KeyError, TypeError) as e:
            log_error_raise_exception(
                "Vault API read response has unexpected format", e)

    # Validate that Vault values match what we wrote
    logging.debug(
        "Validating that Vault contents match what was written to it")
    if retrieved_vault_secrets == secrets_to_write:
        logging.info(
            "Secrets read back from Vault match desired values -- "
            "all secrets successfully written to Vault")
        return

    # Print summary of differences
    for field in SECRET_FIELD_NAMES:
        if secrets_to_write[field] == retrieved_vault_secrets[field]:
            logging.debug(f"Vault value for {field} matches what was written")
        else:
            logging.error(
                f"Vault value for {field} DOES NOT MATCH what was written")
    raise common.ScriptException(
        "Secrets read back from Vault do not all match what was written")
