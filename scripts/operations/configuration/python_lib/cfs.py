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

import logging
import traceback
from typing import Dict, List, NamedTuple, Union
import urllib.parse

from . import api_requests
from . import common
from .types import JsonDict, JsonObject, JSONDecodeError

CFS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/cfs"
CFS_VERSIONS_URL = f"{CFS_BASE_URL}/versions"
# CASMCMS-9204: The v2 options URL is needed to be able to set the default_playbook option,
# which is read-only in v3
CFS_V2_BASE_URL = f"{CFS_BASE_URL}/v2"
CFS_V2_OPTIONS_URL = f"{CFS_V2_BASE_URL}/options"
CFS_V3_BASE_URL = f"{CFS_BASE_URL}/v3"
CFS_V3_COMPS_URL = f"{CFS_V3_BASE_URL}/components"
CFS_V3_CONFIGS_URL = f"{CFS_V3_BASE_URL}/configurations"
CFS_V3_OPTIONS_URL = f"{CFS_V3_BASE_URL}/options"
CFS_V3_SESSIONS_URL = f"{CFS_V3_BASE_URL}/sessions"
CFS_V3_SOURCES_URL = f"{CFS_V3_BASE_URL}/sources"

CfsOptions = Dict[str, Union[bool, int, str]]

class CfsVersion(NamedTuple):
    """
    The CFS version major, minor, and patch
    """
    major: int
    minor: int
    patch: int

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def from_api(cls) -> "CfsVersion":
        """
        Loads the CFS version data from the API
        """
        cfs_version_data = list_versions()
        return cls(major=int(cfs_version_data["major"]),
                   minor=int(cfs_version_data["minor"]),
                   patch=int(cfs_version_data["patch"]))

    def __str__(self) -> str:
        """
        Return version as major.minor.patch
        """
        return f"{self.major}.{self.minor}.{self.patch}"

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

def create_configuration(config_name: str, layers: List[Dict[str, str]], **config_fields) -> JsonObject:
    """
    Creates or updates a CFS configuration with the specified name and layers.
    The layers should be dictionaries with the following fields set:
        clone_url, commit, name, playbook

    The CFS configuration is returned if successful. Otherwise an exception is raised.
    """
    config_fields["layers"] = layers
    request_kwargs = {"url": f"{CFS_V3_CONFIGS_URL}/{config_name}",
                      "json": config_fields,
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


def update_options_v2(new_options: CfsOptions) -> CfsOptions:
    """
    Updates all of the specified options to the specified values in CFS,
    using the v2 endpoint.
    Returns the new total set of CFS options (with the v2 names).
    """
    # Even though it does not follow convention for patch operations,
    # the status code when successful is 200
    request_kwargs = {"url": CFS_V2_OPTIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200},
                      "json": new_options}
    return api_requests.patch_retry_validate_return_json(**request_kwargs)


def update_options(new_options: CfsOptions) -> CfsOptions:
    """
    Updates all of the specified options to the specified values in CFS,
    using the v3 endpoint (except for setting the default_playbook
    option, if applicable).
    Returns the new total set of CFS options (with v3 names).
    """
    # CASMCMS-9204: If we are updating the default_playbook option, we have to
    # use the v2 API for that, because it is read-only in CFS v3
    if "default_playbook" in new_options:
        # In CFS v2, the option is named defaultPlaybook
        v2_new_options = { "defaultPlaybook": new_options.pop("default_playbook") }
        update_options_v2(v2_new_options)
        if not new_options:
            # This was the only option we were asked to set, so we won't be making
            # a patch request to the V3 endpoint. But we still want the response from
            # this function to be the same as though we had only used the V3 endpoint.
            # Therefore, we call list_options and return the data from that.
            return list_options()

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

def _encode_source_name(source_name: str) -> str:
    """
    Encode the source name for use in API calls that include the source name as a path parameter
    """
    # Quote twice.  One level of decoding is automatically done the API framework,
    # so one level of encoding produces the same problems as not encoding at all.
    for _ in range(2):
        source_name = urllib.parse.quote_plus(source_name)
    return source_name

def list_sources() -> List[JsonObject]:
    """
    Queries CFS to list all sources, and returns the list.
    """
    return __list_and_merge("sources", CFS_V3_SOURCES_URL)

def delete_source(source_name: str, expected_to_exist: bool = True) -> None:
    """
    Deletes the specified source. Throws an exception if it is not found,
    unless expected_to_exist is set to False.
    """
    request_kwargs = {"url": f"{CFS_V3_SOURCES_URL}/{_encode_source_name(source_name)}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}

    if not expected_to_exist:
        request_kwargs["expected_status_codes"].add(404)

    api_requests.delete_retry_validate(**request_kwargs)

def restore_source(source_name: str, **source_data) -> JsonDict:
    """
    Restores the specified source
    """
    request_kwargs = {"url": f"{CFS_V3_SOURCES_URL}/{_encode_source_name(source_name)}",
                      "add_api_token": True,
                      "expected_status_codes": {201},
                      "json": source_data}
    return api_requests.post_retry_validate_return_json(**request_kwargs)

def restore_source_supported(cfs_version: CfsVersion) -> bool:
    """
    Returns True if the restore_source operation in supported on the specified CFS version.
    Returns False otherwise.
    """
    if cfs_version.major == 1 and cfs_version.minor == 18:
        # For CFS 1.18, support was added in 1.18.10
        min_version = CfsVersion(major=1, minor=18, patch=10)
    else:
        # Otherwise, support is available starting in 1.23.0
        min_version = CfsVersion(major=1, minor=23, patch=0)
    return cfs_version >= min_version

# CFS versions functions

def list_versions() -> JsonDict:
    """
    Queries CFS for its version and returns the data
    """
    request_kwargs = {"url": CFS_VERSIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)
