#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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
"""Shared Python function library: CFS"""

import traceback

import logging

from typing import Dict, List

from . import api_requests
from . import common
from .types import JSONDecodeError

CFS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/cfs"
CFS_V2_BASE_URL = f"{CFS_BASE_URL}/v2"
CFS_V2_CONFIGS_URL = f"{CFS_V2_BASE_URL}/configurations"
CFS_V2_SESSIONS_URL = f"{CFS_V2_BASE_URL}/sessions"


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


def get_session(session_name: str, expected_to_exist: bool = True) -> dict:
    """
    Queries CFS for the specified session and returns it. Throws an exception if it
    is not found, unless expected_to_exist is set to False, in which case None is
    returned.
    """
    request_kwargs = {"url": f"{CFS_V2_SESSIONS_URL}/{session_name}",
                      "add_api_token": True,
                      "expected_status_codes": {200}}

    if not expected_to_exist:
        request_kwargs["expected_status_codes"].add(404)

    resp = api_requests.get_retry_validate(**request_kwargs)
    if resp.status_code == 404:
        # This will only happen if expected_to_exist is set to False and the session
        # was not found. In this case, return None.
        return None

    try:
        return resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception("Response from CFS has unexpected format", exc)


def create_dynamic_session(session_name: str, config_name: str,
                           xname_limit: List[str] = None) -> dict:
    """
    Creates a CFS session of dynamic type with the specified name, running the specified
    CFS configuration. By default this will be run on all applicable nodes, based on
    the Ansible inventory and the node types defined in the Ansible play. This can be
    limited by specifying a list of xnames.

    The CFS session entry is returned if successful. Otherwise an exception is raised.
    """
    request_kwargs = {"url": CFS_V2_SESSIONS_URL,
                      "json": {"name": session_name, "configurationName": config_name},
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    if xname_limit:
        request_kwargs["json"]["ansibleLimit"] = ",".join(xname_limit)

    resp = api_requests.post_retry_validate(**request_kwargs)

    try:
        return resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception("Response from CFS has unexpected format", exc)


def get_configuration(config_name: str, expected_to_exist: bool = True) -> dict:
    """
    Queries CFS for the specified configuration and returns it. Throws an exception if it
    is not found, unless expected_to_exist is set to False, in which case None is
    returned.
    """
    request_kwargs = {"url": f"{CFS_V2_CONFIGS_URL}/{config_name}",
                      "add_api_token": True,
                      "expected_status_codes": {200}}

    if not expected_to_exist:
        request_kwargs["expected_status_codes"].add(404)

    resp = api_requests.get_retry_validate(**request_kwargs)
    if resp.status_code == 404:
        # This will only happen if expected_to_exist is set to False and it
        # was not found. In this case, return None.
        return None

    try:
        return resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception("Response from CFS has unexpected format", exc)


def create_configuration(config_name: str, layers: List[Dict[str, str]]) -> dict:
    """
    Creates a CFS configuration with the specified name and layers.
    The layers should be dictionaries with the following fields set:
        cloneUrl, commit, name, playbook

    The CFS configuration is returned if successful. Otherwise an exception is raised.
    """
    request_kwargs = {"url": f"{CFS_V2_CONFIGS_URL}/{config_name}",
                      "json": {"layers": layers},
                      "add_api_token": True,
                      "expected_status_codes": {200}}

    resp = api_requests.put_retry_validate(**request_kwargs)

    try:
        return resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception("Response from CFS has unexpected format", exc)
