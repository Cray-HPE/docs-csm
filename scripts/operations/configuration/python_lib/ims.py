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
"""Shared Python function library: IMS"""

import json
import logging

from typing import List, NewType, Union

from . import api_requests
from . import s3

from .common import ScriptException, expected_format
from .types import JsonDict

IMS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/ims"
IMS_V2_BASE_URL = f"{IMS_BASE_URL}/v2"

IMS_V2_URLS = {
    "images": f"{IMS_V2_BASE_URL}/images",
    "jobs": f"{IMS_V2_BASE_URL}/jobs",
    "keys": f"{IMS_V2_BASE_URL}/public-keys",
    "recipes": f"{IMS_V2_BASE_URL}/recipes"
}

IMS_V3_BASE_URL = f"{IMS_BASE_URL}/v3"
IMS_V3_DELETED_BASE_URL = f"{IMS_V3_BASE_URL}/deleted"

IMS_V3_URLS = {
    "deleted": {
        "images": f"{IMS_V3_DELETED_BASE_URL}/images",
        "keys": f"{IMS_V3_DELETED_BASE_URL}/public-keys",
        "recipes": f"{IMS_V3_DELETED_BASE_URL}/recipes"
    },
    "images": f"{IMS_V3_BASE_URL}/images",
    "jobs": f"{IMS_V3_BASE_URL}/jobs",
    "keys": f"{IMS_V3_BASE_URL}/public-keys",
    "recipes": f"{IMS_V3_BASE_URL}/recipes"
}

# IMS ID
ImsObjectId = NewType('ImsObjectId', str)

# Responses to a GET to list IMS resources
ImsObjectList = NewType('ImsObjectList', List[JsonDict])

# Mapping from IMS ID to member of ImsObjectList
class ImsObjectMap(dict):
    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def from_list(cls, obj_desc: str, ims_object_list: ImsObjectList) -> "ImsObjectMap":
        """
        Validate that ims_object_list is a list of dictionaries that meet the following requirements:
        1) Has key "id" mapped to non-empty value that is unique within this list of dicts
        2) Has key "created" mapped to non-empty value

        Raises an exception if this is not the case (using obj_desc as the string to describe the
        list being verified).

        Parses the list and returns a map from IMS ID to the IMS objects
        """
        expected_format(ims_object_list, obj_desc, list)
        ims_object_map = {}
        for ims_object in ims_object_list:
            expected_format(ims_object, f"Item in {obj_desc}", dict)
            try:
                object_id = ims_object["id"]
                object_created = ims_object["created"]
            except KeyError as exc:
                raise ScriptException(f"At least one item in {obj_desc} is missing required field '{exc}'") from exc
            if not object_id:
                raise ScriptException(f"At least one item in {obj_desc} has empty value for 'id' field")
            if not object_created:
                raise ScriptException(f"At least one item in {obj_desc} has empty value for 'created' field")
            if object_id in ims_object_map:
                raise ScriptException(f"At least two items in {obj_desc} have duplicate 'id' value: '{object_id}'")
            ims_object_map[object_id] = ims_object
        return ImsObjectMap(ims_object_map)


    def get_s3_urls(self) -> s3.S3UrlSet:
        """
        Extract the S3 URLs from all of the objects, and return the set of these URLs
        """
        s3_urls = set()
        for ims_obj in self.values():
            s3_url = get_s3_url(ims_obj)
            if s3_url is not None:
                s3_urls.add(s3_url)
        return s3_urls


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    def remove_ids(self, to_remove: "ImsObjectMap") -> None:
        """
        For all IDs in to_remove object map, remove those IDs from this object map, if they exist.
        """
        for ims_id in to_remove:
            try:
                del self[ims_id]
            except KeyError:
                pass


    @property
    def ims_object_list(self) -> ImsObjectList:
        """
        Return the list of IMS objects that are the target of this mapping,
        sorted by their 'created' fields.

        Deep copies of the IMS objects are NOT done.
        """
        return sorted(list(self.values()), key=lambda obj: obj["created"])


def get_s3_url(ims_obj: JsonDict) -> Union[None, s3.S3Url]:
    """
    Given an IMS object, look at the link field and return the S3 URL within it.
    Return None if no link field or empty/no path subfield
    """
    try:
        link_field = ims_obj["link"]
    except KeyError:
        # No linked object
        return None
    if not link_field:
        return None
    try:
        s3_path = link_field["path"]
    except KeyError:
        # Skip if no path field
        return None
    if s3_path:
        return s3.S3Url(s3_path)
    return None


def get_child_urls_from_manifest_file(manifest_file_path: str) -> s3.S3UrlList:
    """
    Return list of unique S3 URLs in manifest file
    """
    child_urls = set()
    with open(manifest_file_path, "rt") as mfile:
        manifest_data = json.load(mfile)
    expected_format(manifest_data, "Manifest file contents", dict)
    try:
        artifact_list = manifest_data["artifacts"]
    except KeyError as exc:
        msg = f"No 'artifacts' field found in image manifest file '{manifest_file_path}'"
        logging.error(msg, exc_info=exc)
        raise ScriptException(msg) from exc
    expected_format(artifact_list, f"'artifacts' field in manifest file '{manifest_file_path}'", list)
    for artifact in artifact_list:
        expected_format(artifact, f"List item in 'artifacts' field of manifest file '{manifest_file_path}'", dict)
        child_url = get_s3_url(artifact)
        if child_url is not None:
            child_urls.add(child_url)
    return list(child_urls)


# API calls

# IMS image functions


def delete_image(ims_id: str) -> None:
    """
    Soft deletes the specified IMS image (moving it to deleted category and renaming S3 artifacts)
    """
    request_kwargs = {"url": IMS_V3_URLS["images"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def hard_delete_image(ims_id: str, remove_s3: Union[bool, None]=None) -> None:
    """
    Hard deletes the specified IMS image (and associated S3 artifacts, if specified)
    """
    request_kwargs = {"url": IMS_V2_URLS["images"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    if remove_s3 is not None:
        request_kwargs["params"] = { "cascade": remove_s3 }
    return api_requests.delete_retry_validate(**request_kwargs)


def delete_deleted_image(ims_id: str) -> None:
    """
    Deletes the specified deleted IMS image (and associated S3 artifacts)
    """
    request_kwargs = {"url": IMS_V3_URLS["deleted"]["images"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def list_images() -> ImsObjectList:
    """
    Queries IMS to list all images and returns the list
    """
    request_kwargs = {"url": IMS_V3_URLS["images"],
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)

def list_deleted_images() -> ImsObjectList:
    """
    Queries IMS to list all deleted images and returns the list
    """
    request_kwargs = {"url": IMS_V3_URLS["deleted"]["images"],
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)


# IMS jobs functions

def delete_job(ims_id: str) -> None:
    """
    Deletes the specified IMS job. There is no such thing as a soft delete for jobs.
    """
    request_kwargs = {"url": IMS_V3_URLS["jobs"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def list_jobs() -> ImsObjectList:
    """
    Queries IMS to list all jobs and returns the list
    """
    request_kwargs = {"url": IMS_V3_URLS["jobs"],
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)

# IMS public keys functions

def delete_public_key(ims_id: str) -> None:
    """
    Soft deletes the specified IMS public key (moving it to deleted category)
    """
    request_kwargs = {"url": IMS_V3_URLS["keys"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def hard_delete_public_key(ims_id: str) -> None:
    """
    Hard deletes the specified IMS public_key
    """
    request_kwargs = {"url": IMS_V2_URLS["keys"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def delete_deleted_public_key(ims_id: str) -> None:
    """
    Deletes the specified deleted IMS public key
    """
    request_kwargs = {"url": IMS_V3_URLS["deleted"]["keys"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def list_public_keys() -> ImsObjectList:
    """
    Queries IMS to list all public keys and returns the list
    """
    request_kwargs = {"url": IMS_V3_URLS["keys"],
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)


def list_deleted_public_keys() -> ImsObjectList:
    """
    Queries IMS to list all deleted public keys and returns the list
    """
    request_kwargs = {"url": IMS_V3_URLS["deleted"]["keys"],
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)


# IMS recipes functions

def delete_recipe(ims_id: str) -> None:
    """
    Soft deletes the specified IMS recipe (moving it to deleted category and renaming S3 artifacts)
    """
    request_kwargs = {"url": IMS_V3_URLS["recipes"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def hard_delete_recipe(ims_id: str, remove_s3: Union[bool, None]=None) -> None:
    """
    Hard deletes the specified IMS recipe (and associated S3 artifacts, if specified)
    """
    request_kwargs = {"url": IMS_V2_URLS["recipes"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    if remove_s3 is not None:
        request_kwargs["params"] = { "cascade": remove_s3 }
    return api_requests.delete_retry_validate(**request_kwargs)


def delete_deleted_recipe(ims_id: str) -> None:
    """
    Deletes the specified deleted IMS recipe
    """
    request_kwargs = {"url": IMS_V3_URLS["deleted"]["recipes"] + f"/{ims_id}",
                      "add_api_token": True,
                      "expected_status_codes": {204}}
    return api_requests.delete_retry_validate(**request_kwargs)


def list_recipes() -> ImsObjectList:
    """
    Queries IMS to list all recipes and returns the list
    """
    request_kwargs = {"url": IMS_V3_URLS["recipes"],
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)


def list_deleted_recipes() -> ImsObjectList:
    """
    Queries IMS to list all deleted recipes and returns the list
    """
    request_kwargs = {"url": IMS_V3_URLS["deleted"]["recipes"],
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)
