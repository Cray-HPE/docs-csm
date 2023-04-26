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
"""Shared Python function library: API requests"""

import base64
import copy
import logging
import time
import traceback
from typing import Callable, Container, Union

import requests

from . import common
from . import k8s
from .types import JsonObject, JSONDecodeError


ADMIN_CLIENT_SECRET_NAME = "admin-client-auth"
ADMIN_CLIENT_SECRET_NAMESPACE = "default"
API_GW_BASE_URL = "https://api-gw-service-nmn.local"
AUTH_TOKEN_URL = f"{API_GW_BASE_URL}/keycloak/realms/shasta/protocol/openid-connect/token"

# For type hints
ApiResponse = requests.models.Response


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


def get_admin_client_token(k8s_client: k8s.CoreV1API) -> str:
    """
    Return the token string needed to get API token
    """
    secret_label = f"{ADMIN_CLIENT_SECRET_NAMESPACE}/{ADMIN_CLIENT_SECRET_NAME} Kubernetes secret"
    admin_client_secret_data = k8s_client.get_secret_data(name=ADMIN_CLIENT_SECRET_NAME,
                                                          namespace=ADMIN_CLIENT_SECRET_NAMESPACE)
    try:
        encoded_client_secret = admin_client_secret_data["client-secret"]
    except (KeyError, TypeError) as exc:
        log_error_raise_exception(
            f"{secret_label} has an unexpected format", exc)
    # return decoded bytes as a string
    try:
        return base64.standard_b64decode(encoded_client_secret).decode()
    except Exception as exc:
        log_error_raise_exception(
            f"Error decoding token in {secret_label}", exc)


def get_api_token(k8s_client: k8s.CoreV1API = None) -> str:
    """
    Return the token needed for API calls
    """
    if k8s_client is None:
        k8s_client = k8s.Client()

    token = get_admin_client_token(k8s_client)
    request_data = {"grant_type": "client_credentials", "client_id": "admin-client",
                    "client_secret": token}
    # Explicitly set add_api_token to False. It's the default, but best to be paranoid when it
    # comes to infinite loops.
    resp = post_retry_validate(expected_status_codes=200, url=AUTH_TOKEN_URL, data=request_data,
                               add_api_token=False)
    if not resp.text:
        log_error_raise_exception(
            "Keycloak request for API token succeeded but got empty response")
    try:
        resp_body = resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception(
            "Error decoding JSON in keycloak API token response", exc)
    try:
        return resp_body["access_token"]
    except (KeyError, TypeError) as exc:
        log_error_raise_exception(
            "Keycloak API token request response in unexpected format", exc)


def make_api_request_with_retries(request_method: Callable, url: str, add_api_token: bool = False,
                                  k8s_client: k8s.CoreV1API = None,
                                  **request_kwargs) -> ApiResponse:
    """
    Makes request with specified method to specified URL with specified keyword arguments (if any).
    If a 5xx status code is returned, the request will be retried after a brief wait, a limited
    number of times. If this persists, an exception is raised. Otherwise, the response is returned.

    If add_api_token is true, then an API authentication token is added to the request header.
    """
    try:
        method_name = request_method.__name__.upper()
    except Exception as exc:
        log_error_raise_exception(
            "Unexpected error determining API request method name", exc)

    if add_api_token:
        logging.debug("Adding API token to API request")
        try:
            headers = copy.deepcopy(request_kwargs["headers"])
        except KeyError:
            headers = dict()
        token = get_api_token(k8s_client)
        headers["Authorization"] = f"Bearer {token}"
        request_kwargs["headers"] = headers

    count = 0
    max_attempts = 6
    while count < max_attempts:
        count += 1
        logging.info(f"Making {method_name} request to {url}")
        try:
            resp = request_method(url, **request_kwargs)
        except Exception as exc:
            log_error_raise_exception(
                f"Error making {method_name} request to {url}", exc)
        logging.debug(f"Response status code = {resp.status_code}")
        if not 500 <= resp.status_code <= 599:
            return resp
        logging.debug(f"Response reason = {resp.reason}")
        logging.debug(f"Response text = {resp.text}")
        if count >= max_attempts:
            log_error_raise_exception(
                f"API request unsuccessful even after {max_attempts} attempts")
        logging.info("Sleeping 3 seconds before retrying..")
        time.sleep(3)
    log_error_raise_exception(
        "PROGRAMMING LOGIC ERROR: make_api_request_with_retries function should get here")


def retry_request_validate_status(expected_status_codes: Union[int, Container[int]],
                                  **kwargs_to_make_api_request_with_retries) -> ApiResponse:
    """
    Wrapper function for make_api_request_with_retries that validates the status code of the
    response.
    expected_status_codes specifies the expected status code(s) for the API request.
    It can be a single int, or a collection of ints. If the response status code does not match,
    an exception is raised. Otherwise, the response is returned.
    """
    if isinstance(expected_status_codes, int):
        expected_status_codes = {expected_status_codes}
    response = make_api_request_with_retries(
        **kwargs_to_make_api_request_with_retries)
    if response.status_code not in expected_status_codes:
        log_error_raise_exception(f"Response status code ({response.status_code}) does not match"
                                  f" any expected status codes ({expected_status_codes})")
    return response


def delete_retry_validate(**kwargs) -> ApiResponse:
    """
    Wrapper function for retry_request_validate_status for DELETE requests.
    """
    return retry_request_validate_status(request_method=requests.delete, **kwargs)


def get_retry_validate(**kwargs) -> ApiResponse:
    """
    Wrapper function for retry_request_validate_status for GET requests.
    """
    return retry_request_validate_status(request_method=requests.get, **kwargs)


def patch_retry_validate(**kwargs) -> ApiResponse:
    """
    Wrapper function for retry_request_validate_status for PATCH requests.
    """
    return retry_request_validate_status(request_method=requests.patch, **kwargs)


def post_retry_validate(**kwargs) -> ApiResponse:
    """
    Wrapper function for retry_request_validate_status for POST requests.
    """
    return retry_request_validate_status(request_method=requests.post, **kwargs)


def put_retry_validate(**kwargs) -> ApiResponse:
    """
    Wrapper function for retry_request_validate_status for PUT requests.
    """
    return retry_request_validate_status(request_method=requests.put, **kwargs)


def retry_request_validate_status_return_json(**kwargs) -> JsonObject:
    """
    Wrapper function for retry_request_validate_status that returns the decoded
    JSON instead of the response itself
    """
    resp = retry_request_validate_status(**kwargs)
    try:
        return resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception("Response from API had unexpected format", exc)


def get_retry_validate_return_json(**kwargs) -> JsonObject:
    """
    Wrapper function for retry_request_validate_status_return_json for GET requests.
    """
    return retry_request_validate_status_return_json(request_method=requests.get, **kwargs)


def patch_retry_validate_return_json(**kwargs) -> JsonObject:
    """
    Wrapper function for retry_request_validate_status_return_json for PATCH requests.
    """
    return retry_request_validate_status_return_json(request_method=requests.patch, **kwargs)


def post_retry_validate_return_json(**kwargs) -> JsonObject:
    """
    Wrapper function for retry_request_validate_status_return_json for POST requests.
    """
    return retry_request_validate_status_return_json(request_method=requests.post, **kwargs)


def put_retry_validate_return_json(**kwargs) -> JsonObject:
    """
    Wrapper function for retry_request_validate_status_return_json for PUT requests.
    """
    return retry_request_validate_status_return_json(request_method=requests.put, **kwargs)
