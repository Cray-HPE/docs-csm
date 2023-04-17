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
This script imports BOS session templates from a JSON list file (or a directory
of such files) and recreates them.
"""

import argparse
import collections
import json
import os
import sys
from typing import Dict, List

from bos_cli import create_session_template, list_session_templates
from bos_session_templates import BosError, \
                                  BosSessionTemplate, \
                                  InvalidBosSessionTemplate, \
                                  get_session_template_name, \
                                  get_session_template_version
from ims_id_maps import ImsIdEtagMaps, \
                        ImsIdMapFileFormatError, \
                        load_ims_id_map, \
                        update_session_template

SessionTemplateRecord = collections.namedtuple('SessionTemplateRecord',
                                               ['template', 'source_file', 'bos_version'])

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

def import_session_template(template_name: str, template_record: SessionTemplateRecord,
                            ims_id_map: ImsIdEtagMaps,
                            current_session_templates: List[BosSessionTemplate]) -> None:
    """
    Creates the BOS session template in BOS. If ims_id_map is specified, it is used to replace any
    IMS IDs found in the template before the import. If a BOS session template already exists with
    the same name, the import will not happen and a message will be printed to that effect.
    Raises BosError if there are problems.
    """
    bos_vstring = f"v{template_record.bos_version}"
    print(f"Processing BOS {bos_vstring} session template '{template_name}'")

    template_to_create = template_record.template
    if ims_id_map:
        print("Updating IMS IDs and S3 etags in template (if any)")
        template_to_create = update_session_template(template_to_create, ims_id_map)
        if template_name != template_to_create["name"]:
            template_name = template_to_create["name"]
            print(f"After IMS ID and S3 etag update, new template name is '{template_name}'")

    for template in current_session_templates:
        if template_name != template["name"]:
            continue
        if template == template_to_create:
            print(f"Session template with name '{template_name}' and identical contents already "
                  "exists in BOS -- skipping import.")
        else:
            print(f"Session template with name '{template_name}' but DIFFERENT contents already "
                  "exists in BOS -- skipping import.")
        return

    print(f"Creating BOS session template '{template_name}'")
    create_session_template(template_to_create, template_record.bos_version)

def validate_and_record_template(session_template_records: Dict[str, SessionTemplateRecord],
                                 session_template: BosSessionTemplate, source_file: str) -> None:
    """
    Helper function which parses a would-be session template, adding it to session_template_records
    mapping if it looks good. Raises BosError if there are any problems.
    """
    try:
        template_name = get_session_template_name(session_template)
    except InvalidBosSessionTemplate as exc:
        raise BosError(
            f"Error with session template in {source_file}: {exc}") from exc
    if template_name in session_template_records:
        # We already have a template with this name. The only way this isn't a problem
        # is if the two templates are identical
        if session_template_records[template_name].template == session_template:
            # They are identical, so just skip it.
            return
        raise BosError(f"Two different session templates in {source_file} and"
            f" {session_template_records[template_name].source_file} both named '{template_name}'")
    # Determine BOS version of this template
    try:
        bos_version = get_session_template_version(session_template)
    except InvalidBosSessionTemplate as exc:
        raise BosError(
            f"{source_file} contains invalid template '{template_name}': {exc}") from exc

    # Add this template to our records
    session_template_records[template_name] = SessionTemplateRecord(
        template=session_template, source_file=source_file, bos_version=bos_version)

def list_json_files_in_directory(dir_name: str) -> List[str]:
    """
    Looks for all .json regular files in the specified directory, and returns
    a list of their paths.
    Raises BosError if none are found.
    """
    json_files = []
    # Find all JSON files in this directory
    for dir_item in os.scandir(dir_name):
        if dir_item.is_file() and dir_item.name[-5:] == ".json":
            json_files.append(dir_item.path)
    if not json_files:
        raise BosError(f"No .json files in directory '{dir_name}'")
    return json_files

def validate_json_file(file_name: str) -> None:
    """
    Verifies that this is a regular file with .json extension.
    Raises BosError if not.
    """
    if file_name[-5:] != ".json":
        raise BosError(
            f"Argument must be directory or .json file. Invalid argument: '{file_name}'")
    if os.path.isfile(file_name):
        return
    if os.path.exists(file_name):
        raise BosError(f"Argument exists but is not a regular file: '{file_name}'")
    raise BosError(f"File does not exist: '{file_name}'")

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    [--ims-id-map-file <ims_id_map_file.json>] { <session_template_records.json> | <directory> }

    - If the argument is a JSON file for a single session template, then that session template
      will be created in BOS.
    - If the argument is a JSON file for a list of session templates, then each session template
      in the list will be created in BOS.
    - If the argument is a directory, then the program does the above for every ".json" file found
      in that directory.

    If an IMS ID map file is specified, then each BOS session template will have any old IMS IDs
    replaced with the new ones (before it is imported).

    Raises BosError if there is an error or if no templates are found to import
    """
    parser = argparse.ArgumentParser(
        description="Reads BOS session templates from an input file and creates them in BOS")
    parser.add_argument("--ims-id-map-file", type=argparse.FileType('r'), required=False,
                        help="JSON file created during IMS import containing map from old to "
                             "new IMS IDs")
    parser.add_argument("file_or_directory",
                        help="JSON file containing session templates or directory containing "
                             "such JSON files")
    parsed_args = parser.parse_args()

    file_or_dir = parsed_args.file_or_directory
    if os.path.isdir(file_or_dir):
        # Find all JSON files in this directory
        json_files = list_json_files_in_directory(file_or_dir)
    else:
        validate_json_file(file_or_dir)
        json_files = [file_or_dir]

    session_template_records = {}
    # session_template_records is a mapping from template names to SessionTemplateRecords

    for json_file in json_files:
        print(f"Reading session templates from {json_file}")
        with open(json_file, "rt") as jfile:
            file_contents = json.load(jfile)
        if isinstance(file_contents, dict):
            validate_and_record_template(session_template_records, file_contents, json_file)
            continue
        if isinstance(file_contents, list):
            for template in file_contents:
                validate_and_record_template(session_template_records, template, json_file)
            continue
        # Not a list or a dict
        raise BosError(
            f"Contents of {json_file} are not a session template or list of templates")

    if not session_template_records:
        raise BosError("No session templates found")

    ims_id_map = {}
    if parsed_args.ims_id_map_file is not None:
        try:
            ims_id_map = load_ims_id_map(parsed_args.ims_id_map_file)
        except ImsIdMapFileFormatError as exc:
            raise BosError(str(exc)) from exc
        print(f"Loaded {len(ims_id_map)} IMS ID mappings from IMS ID map file")

    # Get list of current BOS session templates on system
    current_session_templates = list_session_templates()

    for template_name, record in session_template_records.items():
        import_session_template(template_name, record, ims_id_map, current_session_templates)

if __name__ == '__main__':
    try:
        main()
    except BosError as bos_exc:
        print_err(str(bos_exc))
        sys.exit(1)
