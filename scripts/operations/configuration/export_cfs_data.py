#!/usr/bin/env python3
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

"""
Usage: export_cfs_data.py <output-directory>
This script exports all CFS data to JSON files in the specified directory.
"""

import argparse
import json
import os
from typing import Union

from python_lib.args import readable_directory
from python_lib.cfs_import_export import CFS_RESOURCE_TYPES, CfsResourceTypeData
from python_lib.types import JsonDict, JsonList


def write_data_to_file(output_dir: str, file_name: str, data: Union[JsonDict, JsonList]) -> None:
    """
    Write the specified data in JSON format to a the specified file in the specified directory
    """
    output_file = os.path.join(output_dir, file_name)
    print(f"Writing data to {output_file}")
    with open(output_file, "wt") as outfile:
        json.dump(data, outfile, indent=2)


def export_data(resource_type: str, resource_data: CfsResourceTypeData, output_dir: str) -> None:
    """
    Get all of the data for the specified resource type from CFS, and then write it to a JSON file.
    """
    print(f"Reading {resource_type} data from CFS")
    data = resource_data.list_function()
    write_data_to_file(output_dir, resource_data.json_file_name, data)


def main() -> None:
    """
    Export the CFS data for each CFS data type and write it to JSON files
    """
    parser = argparse.ArgumentParser(
        description="Exports all CFS data to JSON files in the specified directory")
    parser.add_argument(metavar="output_directory", type=readable_directory,
                        dest="output_directory", help="Target directory for CFS data files")
    parsed_args = parser.parse_args()
    output_dir = parsed_args.output_directory
    print(f"Writing CFS data to following directory: {output_dir}")
    for resource_type, resource_data in CFS_RESOURCE_TYPES.items():
        export_data(resource_type, resource_data, output_dir)
    print("Successfully completed writing CFS data to JSON files")

if __name__ == '__main__':
    main()
