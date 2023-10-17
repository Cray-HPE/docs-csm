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

"""
Read in 'data.json' from the directory where the script is located.
Replaces the image, recipe, and public key data files in /var/ims/data with its contents.
"""

import json
import os
import re

mydir = os.path.abspath(os.path.dirname(__file__))
DataFilePath = os.path.join(mydir, "data.json")

# Location of the IMS data files inside the IMS pod (the
# target for this update script)
ImsPodDataDir = os.path.join("/", "var", "ims", "data")

# IMS data files will be named in one of two formats:
# v#_<type>.json (e.g. v2_recipes.json)
# or
# v#.#_<type>.json (e.g. v3.1_recipes.json)
ImsDataTypeRe = {
    data_type: re.compile(f"^v[1-9][0-9]*(?:[.][1-9][0-9]*)?_{data_type}[.]json$")
    for data_type in [ 'images', 'public_keys', 'recipes' ]
}

class ImsDataError(Exception):
    """
    Base custom exception type for the script
    """

def get_data_file_path(data_type: str) -> str:
    """
    data_type must be 'images', 'public_keys', or 'recipes'
    Finds data file for that type in ImsPodDataDir directory and returns its path

    Raises ImsDataError exception if not found or if multiple found
    """
    try:
        file_re = ImsDataTypeRe[data_type]
    except KeyError as exc:
        raise ImsDataError(f"get_data_file_basename: Invalid data_type specified: '{data_type}'") from exc
    matching_files = [ file_name for file_name in os.listdir(ImsPodDataDir) if file_re.match(file_name) ]
    if len(matching_files) > 1:
        raise ImsDataError(f"Multiple {data_type} data files found in directory '{ImsPodDataDir}': "
                           ", ".join(matching_files))
    try:
        return os.path.join(ImsPodDataDir, matching_files[0])
    except IndexError as exc:
        raise ImsDataError(f"No {data_type} data file found in directory '{ImsPodDataDir}'") from exc

def main() -> None:
    """
    1. Loads the exported data file
    2. Identifies the IMS data files for each data type in the target directory
    3. Overwrites each data file with the exported data

    Exceptions are raised if anything goes wrong.
    """
    with open(DataFilePath, "rt") as datafile:
        loaded_ims_data = json.load(datafile)

    # This just serves as a double check that the JSON file has all of these fields
    updated_ims_data = { data_type: loaded_ims_data[data_type] for data_type in ImsDataTypeRe }
    ims_output_file = { data_type: get_data_file_path(data_type) for data_type in ImsDataTypeRe }

    for data_type, updated_data in updated_ims_data.items():
        with open(ims_output_file[data_type], "wt") as outfile:
            json.dump(updated_data, outfile)

    print("IMS data update successful")

if __name__ == "__main__":
    main()
