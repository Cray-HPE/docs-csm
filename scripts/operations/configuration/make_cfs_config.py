#! /usr/bin/env python3
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

"""
Create a simple CFS configurations.
"""

import argparse
import json

from typing import Tuple

from get_git import get_cfs_data
from python_lib.api_requests import API_GW_BASE_URL
from python_lib.cfs import create_configuration

def parse_args() -> Tuple[str, str]:
    """
    Parses command-line arguments.
    """
    parser = argparse.ArgumentParser(
        description="Create a simple single-layer CFS configuration")

    parser.add_argument('configuration_name', help="The name of the CFS configuration")
    parser.add_argument('playbook_file', nargs='+', help="The names of the playbook files")

    args = parser.parse_args()

    return args.configuration_name, args.playbook_file


def main():
    """ Main function """
    config_name, playbook_names = parse_args()
    _, clone_uri, _, commit = get_cfs_data("csm", "latest")
    layers = [ { "cloneUrl": f"{API_GW_BASE_URL}/{clone_uri}",
                 "playbook": playbook_name,
                 "commit": commit } for playbook_name in playbook_names ]
    json_resp = create_configuration(config_name=config_name, layers=layers)
    print(json.dumps(json_resp, indent=2))


if __name__ == "__main__":
    main()
