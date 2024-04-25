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

"""Shared Python function library: BOS"""

from typing import Dict, List, NamedTuple, Union

from . import api_requests
from . import common
from .types import JsonDict


class BosError(common.ScriptException):
    """ Base module exception class """


class InvalidBosSessionTemplate(BosError):
    """
    Indicates that a session template has some kind of invalid data or format.
    """


class InvalidBosV2Session(BosError):
    """
    Indicates that a v2 session has some kind of invalid data or format.
    """


BosOptions = Dict[str, Union[bool, int, str]]


# Tenant value can be None or a string
Tenant = Union[None, str]


class NameTenantTuple(NamedTuple):
    """
    A name and a tenant, for a session or a session template.
    A None value for the tenant means no tenant.
    """

    name: str
    tenant: Tenant

    def __format__(self, spec: str) -> str:
        return append_tenant(f"name='{self.name}'", self.tenant)

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def create(cls, name: str, tenant: Tenant) -> 'NameTenantTuple':
        if tenant:
            return NameTenantTuple(name=name, tenant=tenant)
        return NameTenantTuple(name=name, tenant=None)


# The 'name' string field uniquely identifies BOS v1 sessions
BosV1SessionUniqueId = str

# A tuple of the 'name' string field and the 'tenant' field value uniquely identifies BOS session
# templates and BOS v2 sessions
BosTemplateOrV2SessionUniqueId = NameTenantTuple
BosV2SessionUniqueId = BosTemplateOrV2SessionUniqueId
BosSessionTemplateUniqueId = BosTemplateOrV2SessionUniqueId

class BosTemplateOrV2Session(dict):
    """
    Base class for session template and v2 session objects (since both
    have a lot of similar and identical features, from the perspective of the
    scripts using this module
    """

    label = "session template or v2 session"
    error = BosError

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Set name, tenant, name_tenant, and unique_id properties
        self.__name = self.__get_name()
        self.__tenant = self.__get_tenant()
        self.__name_tenant = NameTenantTuple.create(name=self.__name, tenant=self.__tenant)

    def __get_name(self) -> str:
        """
        Returns the name of the BOS session template.
        """
        try:
            name = self["name"]
        except KeyError as exc:
            raise self.error(f"No 'name' field found in {self.label}") from exc

        if isinstance(name, str):
            return name
        raise self.error(f"'name' field in {self.label} has unexpected type: {type(name)}")

    def __get_tenant(self) -> Tenant:
        """
        Returns the tenant of this object.
        If the tenant field is present and set to a non-empty string value, use that.
        If it is not present, or is set to None or an empty string, use None.
        """
        try:
            tenant = self["tenant"]
        except KeyError:
            # Field not found -- return None
            return None

        if tenant is None:
            return None
        if not isinstance(tenant, str):
            raise self.error(f"'tenant' field in {self.label} has unexpected type: {type(tenant)}")
        if tenant:
            return tenant

        return None

    @property
    def name(self) -> str:
        """
        Returns the name of the BOS session template.
        """
        return self.__name

    @property
    def tenant(self) -> Tenant:
        """
        Returns the tenant of the BOS session template
        """
        return self.__tenant

    @property
    def name_tenant(self) -> NameTenantTuple:
        """
        Returns the name and tenant of the object
        """
        return self.__name_tenant

    @property
    def unique_id(self) -> BosTemplateOrV2SessionUniqueId:
        """
        Returns a hashable object used to uniquely identify this BosTemplateOrV2Session
        """
        return self.name_tenant

UNSET = object()

class BosSessionTemplate(BosTemplateOrV2Session):
    label = "session template"
    error = InvalidBosSessionTemplate

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.__v1_fields = self.__get_v1_fields()
        self.__v2_fields = self.__get_v2_fields()
        self.__version = self.__get_version()
        self.__contents = UNSET

    def __get_v1_fields(self) -> List[str]:
        """
        Returns list of the v1-specific fields found in the session template.
        List is empty if none are found.

        Per the BOS API spec (https://github.com/Cray-HPE/bos/blob/develop/api/openapi.yaml.in),
        the fields found only in v1 templates are:
        cfs_url
        cfs_branch

        cfs.clone_url
        cfs.branch
        cfs.commit
        cfs.playbook

        boot_sets[].boot_ordinal
        boot_sets[].shutdown_ordinal
        boot_sets[].network
        """
        v1_fields = { "cfs_url", "cfs_branch" }
        v1_cfs_fields = { "clone_url", "branch", "commit", "playbook" }
        v1_bootsets_fields = { "boot_ordinal", "shutdown_ordinal", "network" }

        fields_found = v1_fields.intersection(self)

        if "cfs" in self:
            for field in v1_cfs_fields.intersection(self["cfs"]):
                fields_found.add(f"cfs.{field}")

        if "boot_sets" in self:
            for bootset in self["boot_sets"].values():
                for field in v1_bootsets_fields.intersection(bootset):
                    fields_found.add(f"boot_sets[].{field}")

        return sorted(list(fields_found))

    def __get_v2_fields(self) -> List[str]:
        """
        Returns list of the v2-specific fields in the session template. List is
        empty if none found.
        Per the BOS API spec (https://github.com/Cray-HPE/bos/blob/develop/api/openapi.yaml.in),
        the only v2-specific fields are:
        tenant

        boot_sets[].arch
        boot_sets[].cfs
        """
        v2_fields = { "tenant" }
        v2_bootsets_fields = { "arch", "cfs" }

        fields_found = v2_fields.intersection(self)

        if "boot_sets" in self:
            for bootset in self["boot_sets"].values():
                for field in v2_bootsets_fields.intersection(bootset):
                    fields_found.add(f"boot_sets[].{field}")

        return sorted(list(fields_found))

    def __get_version(self) -> int:
        """
        Returns the highest BOS version this template is compatible with.
        If the session template contains BOS v1-specific fields and no v2-specific fields,
        the version is 1.
        If it contains v2-specific fields and no v1-specific fields, the version is 2.
        If it contains neither, the version is 2.
        If it contains both, raises an exception.
        """
        v1_fields_found = self.v1_fields
        if not v1_fields_found:
            return 2
        v2_fields_found = self.v2_fields
        if v2_fields_found:
            raise InvalidBosSessionTemplate(
                f"Invalid session template; has both v1-exclusive ({', '.join(v1_fields_found)}) "
                f"and v2-exclusive ({', '.join(v2_fields_found)}) fields.")
        return 1

    @property
    def v1_fields(self) -> List[str]:
        return self.__v1_fields

    @property
    def v2_fields(self) -> List[str]:
        return self.__v2_fields

    @property
    def version(self) -> int:
        return self.__version

    @property
    def contents(self) -> JsonDict:
        """
        Returns a dict of the session template but without the tenant or name fields
        """
        if self.__contents is UNSET:
            self.__contents = { key: value for (key, value) in self.items()
                                if key not in { "name", "tenant" } }
        return self.__contents


class BosV2Session(BosTemplateOrV2Session):
    label = "v2 session"
    error = InvalidBosV2Session


def append_tenant(msg: str, tenant: Tenant) -> str:
    if tenant:
        return f"{msg} tenant='{tenant}'"
    return f"{msg} tenant=null"


# BOS API

BOS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/bos"

BOS_V1_BASE_URL = f"{BOS_BASE_URL}/v1"
BOS_V1_SESSIONS_URL = f"{BOS_V1_BASE_URL}/session"
BOS_V1_TEMPLATES_URL = f"{BOS_V1_BASE_URL}/sessiontemplate"

BOS_V2_BASE_URL = f"{BOS_BASE_URL}/v2"
BOS_V2_COMPS_URL = f"{BOS_V2_BASE_URL}/components"
BOS_V2_OPTIONS_URL = f"{BOS_V2_BASE_URL}/options"
BOS_V2_SESSIONS_URL = f"{BOS_V2_BASE_URL}/sessions"
BOS_V2_TEMPLATES_URL = f"{BOS_V2_BASE_URL}/sessiontemplates"


def v1_session_request_kwargs_base(session_id: BosV1SessionUniqueId) -> dict:
    """
    Returns a base set of api_request kwargs for API calls targeting this v1 session
    """
    return {"url": f"{BOS_V1_SESSIONS_URL}/{session_id}",
            "add_api_token": True}

def tenant_header(tenant: Tenant) -> dict:
    if tenant:
        return { "Cray-Tenant-Name": tenant }
    return {}

def v2_session_request_kwargs_base(session_id: BosV2SessionUniqueId) -> dict:
    kwargs = {"url": f"{BOS_V2_SESSIONS_URL}/{session_id.name}",
              "add_api_token": True}
    headers = tenant_header(session_id.tenant)
    if headers:
        kwargs["headers"] = headers
    return kwargs

def v2_template_request_kwargs_base(template_id: BosSessionTemplateUniqueId) -> dict:
    kwargs = {"url": f"{BOS_V2_TEMPLATES_URL}/{template_id.name}",
              "add_api_token": True}
    headers = tenant_header(template_id.tenant)
    if headers:
        kwargs["headers"] = headers
    return kwargs


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

def delete_v1_session(session_id: BosV1SessionUniqueId) -> None:
    """
    Deletes the specified v1 session.
    """
    request_kwargs = v1_session_request_kwargs_base(session_id)
    request_kwargs["expected_status_codes"] = {204}
    api_requests.delete_retry_validate(**request_kwargs)

def list_v1_session_names() -> List[BosV1SessionUniqueId]:
    """
    Queries BOS for a list of all v1 session names, and returns that list.
    """
    request_kwargs = {"url": BOS_V1_SESSIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    return api_requests.get_retry_validate_return_json(**request_kwargs)

# BOS v2 session functions

def delete_v2_session(session_id: BosV2SessionUniqueId) -> None:
    """
    Deletes the specified v2 session.
    """
    request_kwargs = v2_session_request_kwargs_base(session_id)
    request_kwargs["expected_status_codes"] = {204}
    api_requests.delete_retry_validate(**request_kwargs)

def list_v2_sessions(tenant: Tenant = None) -> List[BosV2Session]:
    """
    Queries BOS for a list of all v2 sessions, and returns that list.
    """
    request_kwargs = {"url": BOS_V2_SESSIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    if tenant:
        request_kwargs["headers"] = { "Cray-Tenant-Name": tenant }
    return [ BosV2Session(session)
             for session in api_requests.get_retry_validate_return_json(**request_kwargs) ]

# BOS v2 session template functions

def delete_v2_session_template(template_id: BosSessionTemplateUniqueId) -> None:
    """
    Deletes the specified v2 session template.
    """
    request_kwargs = v2_template_request_kwargs_base(template_id)
    request_kwargs["expected_status_codes"] = {204}
    api_requests.delete_retry_validate(**request_kwargs)

def list_v2_session_templates(tenant: Tenant = None) -> List[BosSessionTemplate]:
    """
    Queries BOS v2 for a list of all session templates, and returns that list.
    """
    request_kwargs = {"url": BOS_V2_TEMPLATES_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    if tenant:
        request_kwargs["headers"] = { "Cray-Tenant-Name": tenant }
    return [ BosSessionTemplate(template)
             for template in api_requests.get_retry_validate_return_json(**request_kwargs) ]
