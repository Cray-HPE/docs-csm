#
# MIT License
#
# (C) Copyright 2023-2024 Hewlett Packard Enterprise Development LP
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

from typing import Dict, List, Union

from . import api_requests
from . import common
from .types import JsonDict, JsonObject, JSONDecodeError

CFS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/cfs"
CFS_VERSIONS_URL = f"{CFS_BASE_URL}/versions"
CFS_V3_BASE_URL = f"{CFS_BASE_URL}/v3"
CFS_V3_COMPS_URL = f"{CFS_V3_BASE_URL}/components"
CFS_V3_CONFIGS_URL = f"{CFS_V3_BASE_URL}/configurations"
CFS_V3_OPTIONS_URL = f"{CFS_V3_BASE_URL}/options"
CFS_V3_SESSIONS_URL = f"{CFS_V3_BASE_URL}/sessions"
CFS_V3_SOURCES_URL = f"{CFS_V3_BASE_URL}/sources"

CfsOptions = Dict[str, Union[bool, int, str]]

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


# CFS component functions


def __list_and_merge(object_field_name: str, url: str,
                     params: Union[JsonDict, None]=None) -> List[JsonObject]:
    """
    For paginated CFS list endpoints, this repeatedly queries them until all items
    are found, then returns the list.
    """
    request_kwargs = { "url": url,
                       "add_api_token": True,
                       "expected_status_codes": {200} }
    if params is None:
        resp_json = api_requests.get_retry_validate_return_json(**request_kwargs)
    else:
        resp_json = api_requests.get_retry_validate_return_json(params=params, **request_kwargs)
    obj_list = resp_json[object_field_name]
    while resp_json["next"] is not None:
        resp_json = api_requests.get_retry_validate_return_json(params=resp_json["next"],
                                                                **request_kwargs)
        obj_list.extend(resp_json[object_field_name])
    return obj_list


def list_components(id_list: Union[None, List[str], str]=None) -> List[JsonDict]:
    """
    Queries CFS to list all components, and returns the list.
    If an id_list is specified, query CFS for just those components.
    Merges paged responses together
    """
    if id_list is None:
        params = None
    else:
        params = { "ids": id_list if isinstance(id_list, str) else ",".join(id_list) }
    return __list_and_merge("components", CFS_V3_COMPS_URL, params=params)


def update_component(comp_id: str, **update_data: JsonObject) -> JsonObject:
    """
    Updates the specified component using the specified update data.
    Returns the API response (the updated component)
    """
    # Even though it does not follow convention for patch operations,
    # the status code when successful is 200
    request_kwargs = {"url": f"{CFS_V3_COMPS_URL}/{comp_id}",
                      "add_api_token": True,
                      "expected_status_codes": {200},
                      "json": update_data}
    return api_requests.patch_retry_validate_return_json(**request_kwargs)


def update_component_desired_config(comp_id: str, config_name: str) -> JsonObject:
    """
    Updates the specified component to use the specified configuration.
    Returns the updated component.
    """
    return update_component(comp_id, desired_config=config_name)


def update_components_by_ids(comp_ids: List[str], update_data: JsonObject) -> JsonObject:
    """
    Perform a bulk component update on the specified component ID list, with the specified
    update data.
    """
    # Even though it does not follow convention for patch operations,
    # the status code when successful is 200
    request_kwargs = {"url": CFS_V3_COMPS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200},
                      "json": {"patch": update_data, "filters": {"ids": ",".join(comp_ids)}}}
    return api_requests.patch_retry_validate_return_json(**request_kwargs)


# CFS configuration functions

def create_configuration(config_name: str, layers: List[Dict[str, str]]) -> JsonObject:
    """
    Creates or updates a CFS configuration with the specified name and layers.
    The layers should be dictionaries with the following fields set:
        clone_url, commit, name, playbook

    The CFS configuration is returned if successful. Otherwise an exception is raised.
    """
    request_kwargs = {"url": f"{CFS_V3_CONFIGS_URL}/{config_name}",
                      "json": {"layers": layers},
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.put_retry_validate_return_json(**request_kwargs)


def get_configuration(config_name: str, expected_to_exist: bool = True) -> Union[JsonObject, None]:
    """
    Queries CFS for the specified configuration and returns it. Throws an exception if it
    is not found, unless expected_to_exist is set to False, in which case None is
    returned.
    """
    request_kwargs = {"url": f"{CFS_V3_CONFIGS_URL}/{config_name}",
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
        json_object =  resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception("Response from CFS has unexpected format", exc)
    return json_object


def delete_configuration(config_name: str, expected_to_exist: bool = True) -> None:
    """
    Deletes the specified configuration. Throws an exception if it is not found,
    unless expected_to_exist is set to False.
    """
    request_kwargs = {"url": f"{CFS_V3_CONFIGS_URL}/{config_name}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}

    if not expected_to_exist:
        request_kwargs["expected_status_codes"].add(404)

    api_requests.delete_retry_validate(**request_kwargs)


def list_configurations() -> List[JsonObject]:
    """
    Queries CFS to list all configurations, and returns the list.
    """
    return __list_and_merge("configurations", CFS_V3_CONFIGS_URL)


# CFS options functions


def list_options() -> CfsOptions:
    """
    Queries CFS for a dictionary of all options, and returns that dictionary.
    """
    request_kwargs = {"url": CFS_V3_OPTIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)


def update_options(new_options: CfsOptions) -> CfsOptions:
    """
    Updates all of the specified options to the specified values in CFS.
    Returns the new total set of CFS options.
    """
    # Even though it does not follow convention for patch operations,
    # the status code when successful is 200
    request_kwargs = {"url": CFS_V3_OPTIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200},
                      "json": new_options}
    return api_requests.patch_retry_validate_return_json(**request_kwargs)


# CFS session functions


def create_dynamic_session(session_name: str, config_name: str,
                           xname_limit: Union[List[str], None] = None) -> JsonObject:
    """
    Creates a CFS session of dynamic type with the specified name, running the specified
    CFS configuration. By default this will be run on all applicable nodes, based on
    the Ansible inventory and the node types defined in the Ansible play. This can be
    limited by specifying a list of xnames.

    The CFS session entry is returned if successful. Otherwise an exception is raised.
    """
    request_kwargs = {"url": CFS_V3_SESSIONS_URL,
                      "json": {"name": session_name, "configuration_name": config_name},
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    if xname_limit:
        request_kwargs["json"]["ansible_limit"] = ",".join(xname_limit)
    return api_requests.post_retry_validate_return_json(**request_kwargs)


def get_session(session_name: str, expected_to_exist: bool = True) -> Union[JsonObject, None]:
    """
    Queries CFS for the specified session and returns it. Throws an exception if it
    is not found, unless expected_to_exist is set to False, in which case None is
    returned.
    """
    request_kwargs = {"url": f"{CFS_V3_SESSIONS_URL}/{session_name}",
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
        json_object = resp.json()
    except JSONDecodeError as exc:
        log_error_raise_exception("Response from CFS has unexpected format", exc)
    return json_object

def list_sessions() -> List[JsonObject]:
    """
    Queries CFS to list all sessions, and returns the list.
    """
    return __list_and_merge("sessions", CFS_V3_SESSIONS_URL)

# CFS sources functions

def list_sources() -> List[JsonObject]:
    """
    Queries CFS to list all sources, and returns the list.
    """
    return __list_and_merge("sources", CFS_V3_SOURCES_URL)

# CFS versions functions

def list_versions() -> JsonDict:
    """
    Queries CFS for its version and returns the data
    """
    request_kwargs = {"url": CFS_VERSIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)
