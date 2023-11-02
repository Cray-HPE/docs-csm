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

"""Shared Python function library: BOS"""

import traceback
import logging

from typing import Dict, List, Union

from . import api_requests
from . import common
from .bos_session_templates import BosSessionTemplate
from .types import JsonObject

BosOptions = Dict[str, Union[bool, int, str]]
BosV2Session = Dict[str, JsonObject]

BOS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/bos"

BOS_V1_BASE_URL = f"{BOS_BASE_URL}/v1"
BOS_V1_SESSIONS_URL = f"{BOS_V1_BASE_URL}/session"
BOS_V1_TEMPLATES_URL = f"{BOS_V1_BASE_URL}/sessiontemplate"

BOS_V2_BASE_URL = f"{BOS_BASE_URL}/v2"
BOS_V2_COMPS_URL = f"{BOS_V2_BASE_URL}/components"
BOS_V2_OPTIONS_URL = f"{BOS_V2_BASE_URL}/options"
BOS_V2_SESSIONS_URL = f"{BOS_V2_BASE_URL}/sessions"
BOS_V2_TEMPLATES_URL = f"{BOS_V2_BASE_URL}/sessiontemplates"

class BosError(Exception):
    pass

def log_error_raise_exception(msg: str, parent_exception: Union[Exception, None] = None) -> None:
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

# BOS options functions

def list_options() -> BosOptions:
    """
    Queries BOS for a dictionary of all options, and returns that dictionary.
    """
    request_kwargs = {"url": BOS_V2_OPTIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)


def update_options(new_options: BosOptions) -> BosOptions:
    """
    Updates all of the specified options to the specified values in BOS.
    Returns the new total set of BOS options.
    """
    # Even though it does not follow convention for patch operations,
    # the status code when successful is 200
    request_kwargs = {"url": BOS_V2_OPTIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200},
                      "json": new_options}
    return api_requests.patch_retry_validate_return_json(**request_kwargs)

# BOS v1 session functions

def delete_v1_session(session_name: str) -> None:
    """
    Deletes the specified v1 session.
    """
    request_kwargs = {"url": f"{BOS_V1_SESSIONS_URL}/{session_name}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    api_requests.delete_retry_validate(**request_kwargs)

def list_v1_session_names() -> List[str]:
    """
    Queries BOS for a list of all v1 session names, and returns that list.
    """
    request_kwargs = {"url": BOS_V1_SESSIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)

# BOS v2 session functions

def delete_v2_session(session_name: str) -> None:
    """
    Deletes the specified v2 session.
    """
    request_kwargs = {"url": f"{BOS_V2_SESSIONS_URL}/{session_name}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    api_requests.delete_retry_validate(**request_kwargs)

def list_v2_sessions() -> List[BosV2Session]:
    """
    Queries BOS for a list of all v1 session names, and returns that list.
    """
    request_kwargs = {"url": BOS_V2_SESSIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)

# BOS v2 session template functions

def delete_v2_session_template(template_name: str) -> None:
    """
    Deletes the specified v2 session template.
    """
    request_kwargs = {"url": f"{BOS_V2_TEMPLATES_URL}/{template_name}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    api_requests.delete_retry_validate(**request_kwargs)

def list_v2_session_templates() -> List[BosSessionTemplate]:
    """
    Queries BOS v2 for a list of all session templates, and returns that list.
    """
    request_kwargs = {"url": BOS_V2_TEMPLATES_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)
