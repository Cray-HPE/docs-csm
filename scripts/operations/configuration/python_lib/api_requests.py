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
"""Shared Python function library: API requests"""

import logging
import time
import traceback
from typing import Callable, Container, Union

import requests

from . import common


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


def make_api_request_with_retries(request_method: Callable,
                                  url: str,
                                  **request_kwargs) -> requests.models.Response:
    """
    Makes request with specified method to specified URL with specified keyword arguments (if any).
    If a 5xx status code is returned, the request will be retried after a brief wait, a limited
    number of times. If this persists, an exception is raised. Otherwise, the response is returned.
    """
    try:
        method_name = request_method.__name__.upper()
    except Exception as exc:
        log_error_raise_exception(
            "Unexpected error determining API request method name", exc)

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
                                  **kwargs_to_make_api_request_with_retries
                                 ) -> requests.models.Response:
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
