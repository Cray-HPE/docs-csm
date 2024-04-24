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


class InvalidBosSession(BosError):
    """
    Indicates that a session has some kind of invalid data or format.
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


# A tuple of the 'name' string field and the 'tenant' field value uniquely identifies BOS session
# templates and sessions
BosTemplateOrSessionUniqueId = NameTenantTuple
BosSessionUniqueId = BosTemplateOrSessionUniqueId
BosSessionTemplateUniqueId = BosTemplateOrSessionUniqueId

class BosTemplateOrSession(dict):
    """
    Base class for session template and session objects (since both
    have a lot of similar and identical features, from the perspective of the
    scripts using this module
    """

    label = "session template or session"
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
    def unique_id(self) -> BosTemplateOrSessionUniqueId:
        """
        Returns a hashable object used to uniquely identify this BosTemplateOrSession
        """
        return self.name_tenant

UNSET = object()

class BosSessionTemplate(BosTemplateOrSession):
    label = "session template"
    error = InvalidBosSessionTemplate

    # The highest BOS version this template is compatible with. As of CSM 1.6, this is always 2.
    version = 2

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.__contents = UNSET

    @property
    def contents(self) -> JsonDict:
        """
        Returns a dict of the session template but without the tenant or name fields
        """
        if self.__contents is UNSET:
            self.__contents = { key: value for (key, value) in self.items()
                                if key not in { "name", "tenant" } }
        return self.__contents


class BosSession(BosTemplateOrSession):
    label = "session"
    error = InvalidBosSession


def append_tenant(msg: str, tenant: Tenant) -> str:
    if tenant:
        return f"{msg} tenant='{tenant}'"
    return f"{msg} tenant=null"


# BOS API

BOS_BASE_URL = f"{api_requests.API_GW_BASE_URL}/apis/bos"

BOS_V2_BASE_URL = f"{BOS_BASE_URL}/v2"
BOS_V2_COMPS_URL = f"{BOS_V2_BASE_URL}/components"
BOS_V2_OPTIONS_URL = f"{BOS_V2_BASE_URL}/options"
BOS_V2_SESSIONS_URL = f"{BOS_V2_BASE_URL}/sessions"
BOS_V2_TEMPLATES_URL = f"{BOS_V2_BASE_URL}/sessiontemplates"


def tenant_header(tenant: Tenant) -> dict:
    if tenant:
        return { "Cray-Tenant-Name": tenant }
    return {}

def v2_session_request_kwargs_base(session_id: BosSessionUniqueId) -> dict:
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

# BOS session functions

def delete_session(session_id: BosSessionUniqueId) -> None:
    """
    Deletes the specified session.
    """
    request_kwargs = v2_session_request_kwargs_base(session_id)
    request_kwargs["expected_status_codes"] = {204}
    api_requests.delete_retry_validate(**request_kwargs)

def list_sessions(tenant: Tenant = None) -> List[BosSession]:
    """
    Queries BOS for a list of all sessions, and returns that list.
    """
    request_kwargs = {"url": BOS_V2_SESSIONS_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    if tenant:
        request_kwargs["headers"] = { "Cray-Tenant-Name": tenant }
    return [ BosSession(session)
             for session in api_requests.get_retry_validate_return_json(**request_kwargs) ]

# BOS session template functions

def delete_session_template(template_id: BosSessionTemplateUniqueId) -> None:
    """
    Deletes the specified session template.
    """
    request_kwargs = v2_template_request_kwargs_base(template_id)
    request_kwargs["expected_status_codes"] = {204}
    api_requests.delete_retry_validate(**request_kwargs)

def list_session_templates(tenant: Tenant = None) -> List[BosSessionTemplate]:
    """
    Queries BOS for a list of all session templates, and returns that list.
    """
    request_kwargs = {"url": BOS_V2_TEMPLATES_URL,
                      "add_api_token": True,
                      "expected_status_codes": {200}}
    if tenant:
        request_kwargs["headers"] = { "Cray-Tenant-Name": tenant }
    return [ BosSessionTemplate(template)
             for template in api_requests.get_retry_validate_return_json(**request_kwargs) ]
