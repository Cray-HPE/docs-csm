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
"""Shared Python function library: BSS"""

import traceback

import logging

from typing import Dict, List, Union

from . import api_requests
from . import common
from .types import JSONDecodeError

BSS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/bss"
BSS_BOOTPARAMS_URL = f"{BSS_BASE_URL}/boot/v1/bootparameters"


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


def get_bootparameters(xname_list: Union[List[str], None] = None,
                       expected_to_exist: bool = True) -> List[dict]:
    """
    Queries BSS for all bootparameters for the specified xnames (or all bootparameters, if
    no xnames are specified). Returns the list of these bootparameters.
    common.ScriptException is raised on error.

    By default, if any xnames are specified, and bootparameters are not found for one or more of
    them, then an exception is raised. This behavior can be overridden with the expected_to_exist
    argument. If no xnames are specified, then the expected_to_exist argument has no effect.
    """
    request_kwargs = {"url": BSS_BOOTPARAMS_URL, "add_api_token": True,
                      "expected_status_codes": {200}}

    if xname_list:
        request_kwargs["json"] = {"hosts": xname_list}
        if not expected_to_exist:
            request_kwargs["expected_status_codes"].add(404)

    resp = api_requests.get_retry_validate(**request_kwargs)
    if resp.status_code == 404:
        # This will only happen if expected_to_exist is set to False and no host entries
        # were found for the query. In this case, return an empty list.
        return []

    try:
        bootparams_list = list(resp.json())
    except (JSONDecodeError, TypeError) as exc:
        log_error_raise_exception("Response from BSS has unexpected format", exc)

    if not xname_list or not expected_to_exist:
        # If no xnames were specified, or if we are not validating that the xnames all were found,
        # then whatever list we got back is what we return
        return bootparams_list

    # Reaching here means that we did specify xname(s) and we do expect them to exist. We
    # got a 200 status code from the request, but this does NOT ensure that every xname
    # was found. It means that at least one was found. In this case, we must manually check
    # that all xnames were found.

    logging.debug("Validating that all specified xnames are present in BSS response")
    missing_xnames = set(xname_list)
    for bootparam in bootparams_list:
        try:
            missing_xnames.difference_update(bootparam["hosts"])
        except (KeyError, TypeError) as exc:
            # KeyError - if bootparam does not have a hosts field. This should always be the case,
            #   since we sent a request with an explicit host list.
            # TypeError - To cover the case where bootparam is not a mapping-type object, or where
            #   bootparam["hosts"] is not a list, both of which should be the case.
            log_error_raise_exception("Response from BSS has unexpected format", exc)

    if missing_xnames:
        missing_xnames_str = ", ".join(sorted(list(missing_xnames)))
        log_error_raise_exception("One or more queried xnames were not found in BSS"
                                  f" bootparameters: {missing_xnames_str}")

    logging.debug("No xnames missing from BSS response")
    return bootparams_list


def get_bootparameters_map(xname_list: List[str]) -> Dict[str, dict]:
    """
    Queries BSS for all bootparameters for the specified xnames. Returns a dictionary mapping
    every xname to its corresponding bootparameters. An exception is raised if bootparameters
    are not found for any of the xnames. common.ScriptException is raised on error.
    """
    bootparams_list = get_bootparameters(xname_list=xname_list, expected_to_exist=True)
    bootparams_map = {}
    for xname in xname_list:
        for bootparam in bootparams_list:
            # Not protecting the following with try...except because that is handled inside
            # get_bootparameters()
            if xname in bootparam["hosts"]:
                bootparams_map[xname] = bootparam
                break

    if len(bootparams_map) != len(xname_list):
        log_error_raise_exception(f"Number of xnames {len(xname_list)} does not match corresponding"
                                  f" number of BSS bootparameters {len(bootparams_map)}")
    return bootparams_map


def update_bootparameters_artifacts(xname_list: List[str], kernel: str, initrd: str,
                                    rootfs: str) -> None:
    """
    For the specified host xnames, updates the BSS bootparameters to use the specified kernel,
    initrd, and rootfs artifacts. The artifacts are expected to be full S3 paths (i.e.
    "s3://boot-images/k8s/0.3.49/rootfs").
    The rootfs artifact is updated in the "params" string field.
    The kernel and initrd artifacts are updated in their corresponding string fields.
    Nothing is returned on success.
    common.ScriptException is raised on error.
    """
    bootparameters_map = get_bootparameters_map(xname_list)
    # In order to avoid leaving BSS in an inconsistent state, first we make sure that all of the
    # specified xnames have "params" fields and that we can find a metal.server link in them. While
    # we're at it, go ahead and generate the updated params field.
    updated_params_field = {}
    for xname in xname_list:
        logging.debug(f"Generating updated params string for {xname}")
        try:
            current_params = bootparameters_map[xname]["params"]
        except KeyError as exc:
            # The KeyError should be from "params", since the get_bootparameters_map function should
            # have raised an exception if the xname itself was not found.
            log_error_raise_exception(f"No 'params' field found in BSS bootparameters for {xname}",
                                      exc)

        new_params_list = []
        found = False
        for current_param in current_params.split():
            if current_param.find("metal.server=") == 0:
                new_params_list.append(f"metal.server={rootfs}")
                found = True
                continue
            new_params_list.append(current_param)
        if not found:
            log_error_raise_exception("No metal.server string found in 'params' field of BSS"
                                      f" bootparameters for {xname}")
        updated_params = " ".join(new_params_list)
        logging.debug(f"Updated BSS bootparameters 'params' field for {xname}: {updated_params}")
        updated_params_field[xname] = updated_params

    # Now do the updates for each xname
    request_kwargs = {"url": BSS_BOOTPARAMS_URL, "add_api_token": True,
                      "expected_status_codes": 200}

    for xname, updated_params in updated_params_field.items():
        logging.info(f"Updating BSS bootparameters for {xname} with kernel '{kernel}', initrd "
                     f"{initrd}, and rootfs {rootfs}")
        request_json = {"hosts": [xname], "params": updated_params, "kernel": kernel,
                        "initrd": initrd}
        api_requests.patch_retry_validate(json=request_json, **request_kwargs)

    logging.info("BSS bootparameters updated for all specified xnames")
