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

"""
Module to provide BOS session template functions
"""

from typing import Dict, List

from .types import JsonObject

BosSessionTemplate = Dict[str, JsonObject]
BosSessionTemplateBootSets = Dict[str, JsonObject]

class BosError(Exception):
    pass

class InvalidBosSessionTemplate(BosError):
    pass

def get_session_template_name(session_template: BosSessionTemplate) -> str:
    """
    Returns the name of the BOS session template.
    Raises InvalidBosSessionTemplate on error.
    """
    try:
        template_name = session_template["name"]
    except KeyError as exc:
        raise InvalidBosSessionTemplate("No 'name' field found in session template") from exc
    except TypeError as exc:
        raise InvalidBosSessionTemplate(
            f"Session template is of unexpected type: {type(session_template)}") from exc
    if isinstance(template_name, str):
        return template_name
    raise InvalidBosSessionTemplate(
        f"Session template 'name' field is of unexpected type: {type(template_name)}") from exc

def get_session_template_v1_fields(session_template: BosSessionTemplate) -> List[str]:
    """
    Returns a list of the v1-specific fields found in the session template. List is empty if none
    are found.

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

    fields_found = v1_fields.intersection(session_template.keys())
    if "cfs" in session_template:
        for field in v1_cfs_fields.intersection(session_template["cfs"].keys()):
            fields_found.add(f"cfs.{field}")
    if "boot_sets" in session_template:
        for bootset in session_template["boot_sets"].values():
            for field in v1_bootsets_fields.intersection(bootset.keys()):
                fields_found.add(f"boot_sets[].{field}")

    return sorted(list(fields_found))

def get_session_template_v2_fields(session_template: BosSessionTemplate) -> List[str]:
    """
    Returns list of the v2-specific fields in the session template. List is empty if none found.
    Per the BOS API spec (https://github.com/Cray-HPE/bos/blob/develop/api/openapi.yaml.in),
    the only v2-specified field is:
    boot_sets[].cfs
    """
    fields_found = []
    if "boot_sets" in session_template:
        if any("cfs" in bootset for bootset in session_template["boot_sets"].values()):
            fields_found.append("boot_sets[].cfs")
    return fields_found

def get_session_template_version(session_template: BosSessionTemplate) -> int:
    """
    If the specified session template contains BOS v1-specific fields and no v2-specific fields,
    returns 1.
    If it contains v2-specific fields and no v1-specific fields, returns 2.
    If it contains neither, returns 2.
    If it contains both, raises an exception.
    """
    try:
        v1_fields_found = get_session_template_v1_fields(session_template)
        if not v1_fields_found:
            return 2
        v2_fields_found = get_session_template_v2_fields(session_template)
        if v2_fields_found:
            raise InvalidBosSessionTemplate(
                f"Invalid session template; has both v1-exclusive ({', '.join(v1_fields_found)}) "
                f"and v2-exclusive ({', '.join(v2_fields_found)}) fields.")
    except TypeError as exc:
        raise InvalidBosSessionTemplate(f"Session template has invalid format: {exc}") from exc
    return 1
