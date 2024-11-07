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

from typing import Callable, NamedTuple

from . import cfs

class CfsResourceTypeData(NamedTuple):
    """
    Data needed for import/export work for a given CFS resource type
    (configurations, components, etc)
    """
    list_function: Callable
    json_file_name: str

CFS_RESOURCE_TYPES = {
    "components":     CfsResourceTypeData(list_function=cfs.list_components,
                                          json_file_name="components.json"),
    "configurations": CfsResourceTypeData(list_function=cfs.list_configurations,
                                          json_file_name="configurations.json"),
    "options":        CfsResourceTypeData(list_function=cfs.list_options,
                                          json_file_name="options.json"),
    "sessions":       CfsResourceTypeData(list_function=cfs.list_sessions,
                                          json_file_name="sessions.json"),
    "versions":       CfsResourceTypeData(list_function=cfs.list_versions,
                                          json_file_name="versions.json")
}
