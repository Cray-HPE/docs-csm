#!/usr/bin/env python3
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

import argparse
import json
import sys
from typing import Any, Dict, List, Union

BosSessionTemplate = Dict[str, Any]

class InvalidBosSessionTemplate(Exception):
    pass

def get_session_template_v1_fields(session_template: BosSessionTemplate) -> List[str]:
    """
    Returns a list of the v1-specific fields found in the session template. List is empty if none
    are found.

    According to the BOS API spec (https://github.com/Cray-HPE/bos/blob/develop/api/openapi.yaml.in),
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
    Returns a list of the v2-specific fields found in the session template. List is empty is none are found.
    According to the BOS API spec (https://github.com/Cray-HPE/bos/blob/develop/api/openapi.yaml.in),
    the only v2-specified field is:
    boot_sets[].cfs
    """
    fields_found = list()
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

def print_names_versions(session_template_list: List[BosSessionTemplate], template_name_filter: Union[str, None]) -> bool:
    """
    If name not specified, print the name and version of every template in the list.
    If name specified, only do so if the name matches.
    Returns True if no errors. Returns False if errors, or if no matching templates found.
    """
    match_count=0
    error_count=0
    for session_template in session_template_list:
        try:
            template_name = session_template["name"]
        except KeyError:
            print("ERROR: No 'name' field found in session template. Skipping")
            error_count+=1
            continue
        if template_name_filter is not None and template_name_filter != template_name:
            # Skip this one since it does not match the name we were given
            continue
        match_count+=1
        try:
            template_version = get_session_template_version(session_template)
            print(f"Template '{template_name}' is BOS version {template_version}")
        except InvalidBosSessionTemplate as exc:
            print(f"ERROR: {exc}")
            error_count+=1
    return match_count > 0 and error_count == 0

def main() -> bool:
    """
    Parses the command line arguments, does the stuff.
    
    Arguments:
    [--name <session_template_name>] <input.json>

    If the input file contains a single session template, then the script will output its name and version.
    If the input file contains a list of session templates, then the script will output the name and version of each.
    If the name argument is specified, it will filter the output to only the specified session template name (if found).
    Returns True if no errors. Returns False if errors, or if no matching templates found.
    """
    parser = argparse.ArgumentParser(
        description="Display names and BOS versions of BOS session templates contained in a JSON file")
    parser.add_argument("--name", type=str, metavar="session_template_name", required=False, 
                        help="Only output information on specified session template (if found in file)")
    parser.add_argument("json_filename", type=argparse.FileType('r'),
                        help="JSON file containing session template or list of session templates")
    parsed_args = parser.parse_args()

    file_contents = json.load(parsed_args.json_filename)
    if isinstance(file_contents, dict):
        return print_names_versions([file_contents], parsed_args.name)
    return print_names_versions(file_contents, parsed_args.name)
 
if __name__ == '__main__':
    if main():
        sys.exit(0)
    sys.exit(1)
