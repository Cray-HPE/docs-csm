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
"""Shared Python function library: HSM"""

import traceback

import logging

from typing import List

from . import api_requests
from . import common
from .types import JSONDecodeError

SMD_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/smd"
SMD_HSM_COMPONENTS_URL = f"{SMD_BASE_URL}/hsm/v2/State/Components"


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


def get_management_ncn_xnames() -> List[str]:
    """
    Return a sorted list of the xnames of the management NCNs
    """
    params = {"type": "Node", "role": "Management"}
    resp = api_requests.get_retry_validate(url=SMD_HSM_COMPONENTS_URL, expected_status_codes=200,
                                           add_api_token=True, params=params)
    try:
        component_list = resp.json()["Components"]
        return sorted([comp["ID"] for comp in component_list])
    except (JSONDecodeError, KeyError, TypeError) as exc:
        log_error_raise_exception("Response from SMD has unexpected format", exc)
