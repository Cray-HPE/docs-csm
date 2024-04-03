#
# MIT License
#
# (C) Copyright 2022-2024 Hewlett Packard Enterprise Development LP
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

from . import api_requests
from . import common
from . import k8s

from .types import JSONDecodeError, JsonObject

K8S_NAMESPACE = "vault"
K8S_SECRET_NAME = "cray-vault-unseal-keys"
K8S_SERVICE_NAME = "cray-vault"

CSM_ROOT_SECRET_KEY = "csm/users/root"
SW_ADMIN_PW_KEY = "net-creds/switch_admin"
SW_ADMIN_PW_FIELD = "admin"

API_STATUS_OK_WITH_DATA = 200
API_STATUS_OK_EMPTY = 204
API_STATUS_NOT_FOUND = 404


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


def get_token_string(k8s_client: k8s.CoreV1API) -> str:
    """
    Retrieve the Vault Kubernetes secret, extract the token string from it,
    decode it from base-64, and return it as a string.
    """
    # Retrieve the Vault Kubernetes secret
    secret_label = f"{K8S_NAMESPACE}/{K8S_SECRET_NAME} Kubernetes secret"
    logging.debug("Getting Vault token from %s", secret_label)
    vault_secret_data = k8s_client.get_secret_data(
        name=K8S_SECRET_NAME, namespace=K8S_NAMESPACE)

    # Extract the token string from it,
    try:
        encoded_vault_token = vault_secret_data["vault-root"]
    except (KeyError, TypeError) as exc:
        log_error_raise_exception(
            f"{secret_label} has an unexpected format", exc)

    # Decode it from base-64
    try:
        token_bytes = base64.standard_b64decode(encoded_vault_token)
    except Exception as exc:
        log_error_raise_exception(
            f"Error decoding token in {secret_label}", exc)

    # Return it as a string.
    return token_bytes.decode()


def get_api_url(k8s_client: k8s.CoreV1API) -> str:
    """
    1. Looks up the vault/cray-vault service in Kubernetes
    2. Retrieves the cluster IP address of the service
    3. Retrieves the port list of the service
    4. Finds the API port.
    5. Assembles the base URL for the Vault API
    """
    logging.debug("Finding Vault API URL")
    service_label = f"{K8S_NAMESPACE}/{K8S_SERVICE_NAME} Kubernetes service"
    vault_service = k8s_client.get_service(name=K8S_SERVICE_NAME, namespace=K8S_NAMESPACE)

    try:
        vault_ip = vault_service.spec.cluster_ip
        for vault_port in vault_service.spec.ports:
            if vault_port.name == 'http-api-port':
                api_url = f"http://{vault_ip}:{vault_port.port}"
                logging.debug(f"API URL = {api_url}")
                return api_url
    except (AttributeError, KeyError, TypeError) as exc:
        log_error_raise_exception(
            f"{service_label} has an unexpected format", exc)

    log_error_raise_exception(
        f"No 'http-api-port' port found for {service_label}")


def get_secret_data_from_response(api_response: api_requests.ApiResponse) -> JsonObject:
    """
    This is used to parse an API response to a Vault read request and extract the
    secret data (a JSON object). That data is returned. An exception is raised if
    anything goes wrong with this. The status code of the response is not validated.
    """
    if not api_response.text:
        log_error_raise_exception(
            "Vault response to read secret request has empty body")
    try:
        resp_body = api_response.json()
    except JSONDecodeError as exc:
        log_error_raise_exception(
            "Error decoding JSON in Vault response to read secret request", exc)
    try:
        return resp_body["data"]
    except (KeyError, TypeError) as exc:
        log_error_raise_exception(
            "Vault response to read secret request is not in expected format", exc)


class Vault():
    """
    Used as an interface into Vault.
    This object assumes that the Vault secret token is not
    being changed over the lifetime of this object. If that becomes a problem, changes
    will need to be made to handle it. The same is true of the service IP addresses and ports.
    """

    def __init__(self, k8s_client: k8s.CoreV1API = None):
        """
        Obtains and stores the Vault token from the Kubernetes secret.
        Obtains and stores the service IP address and port from Kubernetes, and saves
        the API base URL constructed from them.
        """
        if k8s_client is None:
            k8s_client = k8s.Client()
        self.token_string = get_token_string(k8s_client)
        self.api_url = get_api_url(k8s_client)

    def get_secret_api_url(self, secret_key: str) -> str:
        """
        Given the key for a Vault secret, returns the API URL for that secret.
        Essentially this is just appending the secret key to the base API URL.
        """
        return f"{self.api_url}/v1/secret/{secret_key}"

    def get_api_request_headers(self, additional_headers: JsonObject = None) -> JsonObject:
        """
        Return the headers to use for Vault API requests. If additional_headers are
        provided, the function returns a dictionary of the default headers updated using
        the additional headers.
        """
        headers = {"X-Vault-Request": "true",
                   "X-Vault-Token": self.token_string}
        if additional_headers is not None:
            headers.update(additional_headers)
        return headers

    def api_delete(self, **kwargs) -> api_requests.ApiResponse:
        """
        Just a function wrapper to simplify making DELETE requests to Vault
        using api_requests.retry_request_validate_status()
        It specifies the request_method argument. If the caller
        specifies headers, the default headers (from delete_api_request_headers())
        will be updated with those values.
        """

        # Get additional headers, if any, and remove them from the keyword arguments
        additional_headers = kwargs.pop("headers", None)
        # Generate request headers, combining additional ones, if any
        request_headers = self.get_api_request_headers(additional_headers)
        return api_requests.delete_retry_validate(headers=request_headers, **kwargs)

    def api_get(self, **kwargs) -> api_requests.ApiResponse:
        """
        Just a function wrapper to simplify making GET requests to Vault
        using api_requests.retry_request_validate_status()
        It specifies the request_method argument. If the caller
        specifies headers, the default headers (from get_api_request_headers())
        will be updated with those values.
        """

        # Get additional headers, if any, and remove them from the keyword arguments
        additional_headers = kwargs.pop("headers", None)
        # Generate request headers, combining additional ones, if any
        request_headers = self.get_api_request_headers(additional_headers)
        return api_requests.get_retry_validate(headers=request_headers, **kwargs)

    def api_post(self, **kwargs) -> api_requests.ApiResponse:
        """
        Just a function wrapper to simplify making POST requests to Vault
        using api_requests.retry_request_validate_status()
        It specifies the request_method argument. If the caller
        specifies headers, the default headers (from post_api_request_headers())
        will be updated with those values.
        """

        # Get additional headers, if any, and remove them from the keyword arguments
        additional_headers = kwargs.pop("headers", None)
        # Generate request headers, combining additional ones, if any
        request_headers = self.get_api_request_headers(additional_headers)
        return api_requests.post_retry_validate(headers=request_headers, **kwargs)

    def delete_secret(self, secret_key: str) -> None:
        """
        Deletes the specified secret key from Vault. This is also required in the case where the
        last field of data in a secret is being removed, because Vault does not allow for empty
        secrets.
        Raises an exception if anything goes wrong.
        """
        secret_url = self.get_secret_api_url(secret_key)
        logging.debug(f"{secret_key} secret URL = {secret_url}")
        logging.debug(f"Deleting {secret_key} secret from Vault")
        self.api_delete(
            url=secret_url, expected_status_codes=API_STATUS_OK_EMPTY)

    def get_secret(self, secret_key: str, must_exist: bool = False) -> JsonObject:
        """
        Retrieves the Vault secret with the specified key and returns its contents.
        The must_exist argument governs whether a 404 response status code results
        in an exception or not. If must_exist is False and the response is 404, then
        None is returned.
        An exception is raised if any problems occur
        """
        secret_url = self.get_secret_api_url(secret_key)
        logging.debug(f"{secret_key} secret URL = {secret_url}")
        if must_exist:
            expected_status_codes = {API_STATUS_OK_WITH_DATA}
        else:
            expected_status_codes = {
                API_STATUS_OK_WITH_DATA, API_STATUS_NOT_FOUND}

        logging.debug(f"Reading {secret_key} secret from Vault")
        resp = self.api_get(
            url=secret_url, expected_status_codes=expected_status_codes)
        if resp.status_code == API_STATUS_NOT_FOUND:
            # Since an exception was not raised, this must mean we are in the case where
            #  this is okay. So return None.
            return None
        # Return the secret data from the response
        return get_secret_data_from_response(resp)

    def write_secret(self, secret_key: str, secret_data: JsonObject) -> None:
        """
        Writes the specified secret data to Vault using the specified secret key.
        Raises an exception if anything goes wrong.
        """
        secret_url = self.get_secret_api_url(secret_key)
        logging.debug(f"{secret_key} secret URL = {secret_url}")
        logging.debug(f"Writing {secret_key} secret to Vault")
        self.api_post(
            url=secret_url, expected_status_codes=API_STATUS_OK_EMPTY, json=secret_data)

    def delete_csm_root_secret(self) -> None:
        """
        Wrapper function that supplies the CSM root secret key to delete_secret()
        """
        self.delete_secret(secret_key=CSM_ROOT_SECRET_KEY)

    def get_csm_root_secret(self, **kwargs) -> JsonObject:
        """
        Wrapper function that supplies the CSM root secret key to get_secret()
        """
        return self.get_secret(secret_key=CSM_ROOT_SECRET_KEY, **kwargs)

    def get_sw_admin_password(self) -> str:
        """
        Wrapper function that supplies the switch admin password key to get_secret(),
        and extracts the SW_ADMIN_PW_FIELD field from the result
        """
        return self.get_secret(secret_key=SW_ADMIN_PW_KEY, must_exist=True)[SW_ADMIN_PW_FIELD]

    def write_csm_root_secret(self, **kwargs) -> None:
        """
        Wrapper function that supplies the CSM root secret key to write_secret()
        """
        self.write_secret(secret_key=CSM_ROOT_SECRET_KEY, **kwargs)

    def write_sw_admin_password(self, pw_string: str) -> None:
        """
        Wrapper function that supplies the switch admin password key to write_secret()
        """
        self.write_secret(secret_key=SW_ADMIN_PW_KEY, secret_data={ SW_ADMIN_PW_FIELD: pw_string })
