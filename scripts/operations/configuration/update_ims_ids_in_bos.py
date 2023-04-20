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
This script updates BOS session templates by replacing old IMS IDs with new
ones, based on an IMS ID map file specifieed as input. This file is created
during the IMS import process.
"""

import argparse
import sys
from typing import NamedTuple

from python_lib.bos import BosError
from python_lib.bos_cli import create_session_template, \
                               delete_session_template, \
                               list_session_templates
from python_lib.bos_session_templates import BosSessionTemplate, \
                                             get_session_template_name, \
                                             get_session_template_version
from python_lib.ims_id_maps import ImsIdEtagMaps, \
                                   ImsIdMapFileFormatError, \
                                   load_ims_id_map, \
                                   update_session_template

class TemplateNameVersion(NamedTuple):
    template: BosSessionTemplate
    name: str
    bos_version: int

def print_stderr(msg: str) -> None:
    """
    Outputs the specified message to stderr
    """
    sys.stderr.write(f"{msg}\n")

def print_err(msg: str) -> None:
    """
    Prepends "ERROR: " and outputs the specified message to stderr
    """
    print_stderr(f"ERROR: {msg}")

def update_session_template_in_bos(session_template: BosSessionTemplate, template_name: str,
                                   bos_version: int, ims_id_map: ImsIdEtagMaps) -> None:
    """
    Makes a copy of the session template with the updated IMS ID values.
    If this has resulted in no changes to the template, then do nothing and return.
    If changes have been made but the name of the template is unchanged (that is, if the name
    does not itself contain an IMS ID that was replaced), then the template is updated in BOS.
    If changes have been made including changing the name of the template, then a new template
    is created in BOS using the new name, and the old template is deleted from BOS.
    Raises BosError on error.
    """
    print(f"Processing BOS session template '{template_name}'")
    template_to_create = update_session_template(session_template, ims_id_map)
    if session_template == template_to_create:
        print("No old IMS IDs or S3 etags found in template.")
        return

    new_template_name = template_to_create["name"]
    if new_template_name == template_name:
        print("Updating template in BOS")
        create_session_template(template_to_create, bos_version)
        return
    print(f"After IMS ID and S3 etag update, new template name is '{new_template_name}'")
    print(f"Creating '{new_template_name}' template in BOS")
    create_session_template(template_to_create, bos_version)
    print(f"Deleting '{template_name}' template in BOS")
    delete_session_template(template_name)
    return

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    <ims_id_map_file.json>

    Queries BOS for all session templates. Based on the specified IMS ID mapping file, any old IMS
    IDs found in a BOS session template are replaced with the new ones, and that session template
    is updated in BOS.

    Raises BosError if there is an error
    """
    parser = argparse.ArgumentParser(description="Gets all session templates from BOS and updates "
                "any IMS IDs within them, based on the specified IMS ID map file")
    parser.add_argument("ims-id-map-file", type=argparse.FileType('r'),
                        help="JSON file created during IMS import containing map from "
                             "old to new IMS IDs")
    parsed_args = parser.parse_args()

    try:
        ims_id_map = load_ims_id_map(parsed_args.ims_id_map_file)
    except ImsIdMapFileFormatError as exc:
        raise BosError(str(exc)) from exc
    print(f"Loaded {len(ims_id_map)} IMS ID mappings from IMS ID map file")

    # Create this list first so that if there are any unexpected format errors in the BOS
    # templates, we catch them before we start updating BOS.
    template_name_version_list = [
        TemplateNameVersion(template=template, name=get_session_template_name(template),
                            bos_version=get_session_template_version(template))
        for template in list_session_templates() ]
    for tnv in template_name_version_list:
        update_session_template_in_bos(session_template=tnv.template, template_name=tnv.name,
                                       bos_version=tnv.bos_version, ims_id_map=ims_id_map)

if __name__ == '__main__':
    try:
        main()
    except BosError as bos_exc:
        print_err(str(bos_exc))
        sys.exit(1)
