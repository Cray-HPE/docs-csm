#!/usr/bin/env python3
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

"""
This module takes a JSON file containing session templates and reports their BOS versions.
A template name can be specified to filter the results to just the specified template.
If a template name is specified, it assumes that there is no tenant, since otherwise that
necessarily implies BOS v2.
"""

import argparse
import json
import sys
from typing import List, Union

from python_lib.bos import BosError, BosSessionTemplate

def print_names_versions(session_template_list: List[dict],
                         template_name_filter: Union[str, None]) -> bool:
    """
    If name not specified, print the name and version of every template in the list.
    If name specified, only do so if the name matches.
    Returns True if no errors. Returns False if errors, or if no matching templates found.
    """
    match_count=0
    error_count=0
    for session_template_dict in session_template_list:
        try:
            template = BosSessionTemplate(session_template_dict)
        except BosError as exc:
            print(f"ERROR: {exc}")
            error_count+=1
            continue
        if template_name_filter is not None:
            if template_name_filter != template.name:
                # Skip this one since it does not match the name we were given
                continue
            if template.tenant is not None:
                # Skip this one because if we are looking for a specific template, we assume it
                # does not belong to a tenant
                continue
        match_count+=1
        print(f"Template {template.name_tenant} is BOS version {template.version}")
    return match_count > 0 and error_count == 0

def main() -> bool:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    [--name <session_template_name>] <input.json>

    If the input file contains a single session template, then the script will output its name and
    version.
    If the input file contains a list of session templates, then the script will output the name
    and version of each.
    If the name argument is specified, it will filter the output to only the specified session
    template name (if found).
    Returns True if no errors. Returns False if errors, or if no matching templates found.
    """
    parser = argparse.ArgumentParser(description="Display names and BOS versions of BOS session"
                                                 " templates contained in a JSON file")
    parser.add_argument("--name", type=str, metavar="session_template_name", required=False,
                        help="Only output information on specified session template "
                             "(if found in file)")
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
