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

# Location of IMS app.py file with names of IMS data files in it
ImsAppPyPath = os.path.join("/", "app", "src", "server", "app.py")

# IMS data files will be named in one of two formats:
# v#_<type>.json (e.g. v2_recipes.json)
# or
# v#.#_<type>.json (e.g. v3.1_recipes.json)
BaseImsDataTypePattern = {
    data_type: fr"v[1-9][0-9]*(?:[.][1-9][0-9]*)?_{data_type}[.]json"
    for data_type in [ 'images', 'public_keys', 'recipes' ]
}

# In the app.py file, they will be surrounded by quotes
ImsDataTypePattern = {
    data_type: fr"'{regex}'|\"{regex}\""
    for data_type, regex in BaseImsDataTypePattern.items()
}

ImsDataTypeRe = {
    data_type: re.compile(regex)
    for data_type, regex in ImsDataTypePattern.items()
}


class ImsDataError(Exception):
    """
    Base custom exception type for the script
    """


def get_data_file_path(data_type: str, ims_app_py_text: str) -> str:
    """
    data_type must be 'images', 'public_keys', or 'recipes'
    Looks up the name for that file in the IMS app Python file
    Finds that data file in ImsPodDataDir directory and returns its path

    Raises ImsDataError exception if not found (in app.py or in actual directory)
    or if multiple found (in app.py)
    """
    try:
        file_re = ImsDataTypeRe[data_type]
    except KeyError as exc:
        raise ImsDataError(
            f"get_data_file_path: Invalid data_type specified: '{data_type}'") from exc
    # Strip away surrounding quotes from the names, and discard duplicates
    matching_filenames = list({ file_name[1:-1] for file_name in file_re.findall(ims_app_py_text) })
    if len(matching_filenames) > 1:
        raise ImsDataError(f"Multiple {data_type} data files found in {ImsAppPyPath}: " +
                           ", ".join(matching_filenames))
    try:
        data_file_path = os.path.join(ImsPodDataDir, matching_filenames[0])
    except IndexError as exc:
        raise ImsDataError(
            f"No filename found for data type {data_type} in {ImsAppPyPath}") from exc
    if os.path.isfile(data_file_path):
        return data_file_path
    if os.path.exists(data_file_path):
        raise ImsDataError(f"Data file exists but is not a regular file: {data_file_path}")
    raise ImsDataError(f"Data file does not exist: {data_file_path}")


def main() -> None:
    """
    1. Loads the exported data file
    2. Identifies the IMS data files for each data type in the target directory
    3. Overwrites each data file with the exported data

    Exceptions are raised if anything goes wrong.
    """
    # Read in the data to be imported
    with open(DataFilePath, "rt") as datafile:
        loaded_ims_data = json.load(datafile)

    # Read in the contents of the app.py file (needed to know the correct names for the IMS data files)
    # Strip away leading/trailing whitespace and discard commented lines
    ims_app_py_text_lines = []
    with open(ImsAppPyPath, "rt") as appfile:
        for line in appfile:
            stripped_line = line.strip()
            if not stripped_line.startswith('#'):
                ims_app_py_text_lines.append(stripped_line)
    ims_app_py_text = '\n'.join(ims_app_py_text_lines)

    # This just serves as a double check that the JSON file has all of these fields
    updated_ims_data = { data_type: loaded_ims_data[data_type] for data_type in ImsDataTypeRe }
    ims_output_file = { data_type: get_data_file_path(data_type, ims_app_py_text)
                        for data_type in ImsDataTypeRe }

    for data_type, updated_data in updated_ims_data.items():
        with open(ims_output_file[data_type], "wt") as outfile:
            json.dump(updated_data, outfile)

    print("IMS data update successful")


if __name__ == "__main__":
    main()
