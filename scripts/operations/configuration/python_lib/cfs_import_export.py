#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
"""Shared Python function library: CFS import/export"""

from typing import Callable, List, NamedTuple

from . import cfs
from . import common
from .types import JsonDict


_BAD_COMPONENT_MD = 'troubleshooting/known_issues/CFS_Component_With_0_Length_ID.md'


def remove_components_with_empty_ids(components: List[JsonDict]) -> List[JsonDict]:
    """
    CASMCMS-9195: Check import data for component IDs with 0-length. If any are
    found, remove them, because they are not valid components (and we could not patch
    them in CFS even if we wanted to)
    """
    filtered_list = [ comp for comp in components if comp["id"] ]
    diff = len(components) - len(filtered_list)
    if diff > 0:
        common.print_warn(f"Skipping {diff} component(s) with empty ID field "
                          f"(see CSM documentation: {_BAD_COMPONENT_MD}")
    return filtered_list


def list_cfs_components() -> List[JsonDict]:
    """
    Wrapper for API call to CFS to list components that also filters out ones with empty IDs
    """
    return remove_components_with_empty_ids(cfs.list_components())


class CfsResourceTypeData(NamedTuple):
    """
    Data needed for import/export work for a given CFS resource type
    (configurations, components, etc)
    """
    list_function: Callable
    json_file_name: str


CFS_RESOURCE_TYPES = {
    "components":     CfsResourceTypeData(list_function=list_cfs_components,
                                          json_file_name="components.json"),
    "configurations": CfsResourceTypeData(list_function=cfs.list_configurations,
                                          json_file_name="configurations.json"),
    "options":        CfsResourceTypeData(list_function=cfs.list_options,
                                          json_file_name="options.json"),
    "sessions":       CfsResourceTypeData(list_function=cfs.list_sessions,
                                          json_file_name="sessions.json"),
    "sources":        CfsResourceTypeData(list_function=cfs.list_sources,
                                          json_file_name="sources.json"),
    "versions":       CfsResourceTypeData(list_function=cfs.list_versions,
                                          json_file_name="versions.json")
}
