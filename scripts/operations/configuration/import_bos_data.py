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
import json
import os
import subprocess
import sys
from typing import Dict, List, NamedTuple, Union

from python_lib.bos import BosError, BosOptions, update_options
from python_lib.bos_cli import create_session_template, list_options, list_session_templates
from python_lib.bos_session_templates import BosSessionTemplate, \
                                             InvalidBosSessionTemplate, \
                                             get_session_template_name, \
                                             get_session_template_version
from python_lib.ims_id_maps import ImsIdEtagMaps, \
                                   ImsIdMapFileFormatError, \
                                   load_ims_id_map, \
                                   update_session_template

class SessionTemplateRecord(NamedTuple):
    """
    Record of a BOS session template, the JSON file from which it was imported, and its BOS version
    """
    template: BosSessionTemplate
    source_file: str
    bos_version: int

# Mapping from template name to associated session template record
SessionTemplateRecordMap = Dict[str, SessionTemplateRecord]

BOS_EXPORT_TOOL = "/usr/share/doc/csm/scripts/operations/configuration/export_bos_data.sh"

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

def snapshot_bos_data() -> None:
    """
    Call the BOS exporter tool.
    """
    subprocess.check_call(BOS_EXPORT_TOOL)

def get_template_to_import(template_name: str, template_record: SessionTemplateRecord,
                           ims_id_map: ImsIdEtagMaps,
                           current_templates: List[BosSessionTemplate]) -> Union[BosSessionTemplate,
                                                                                 None]:
    """
    Determines what session template should be created based on the specified template from the
    import data.
    If ims_id_map is specified, it is used to replace any IMS IDs found in the template.
    If a BOS session template already exists with the same name, the import will not happen
    and a message will be printed to that effect.
    """
    bos_vstring = f"v{template_record.bos_version}"
    print(f"Processing BOS {bos_vstring} session template '{template_name}'")

    if ims_id_map:
        print("Updating IMS IDs and S3 etags in template (if any)")
        template_to_create = update_session_template(template_to_create, ims_id_map)
        if template_name != template_to_create["name"]:
            template_name = template_to_create["name"]
            print(f"After IMS ID and S3 etag update, new template name is '{template_name}'")
    else:
        template_to_create = template_record.template

    for template in current_templates:
        if template_name != template["name"]:
            continue
        if template == template_to_create:
            print(f"Session template with name '{template_name}' and identical contents already "
                  "exists in BOS -- skipping import.")
        else:
            print(f"Session template with name '{template_name}' but DIFFERENT contents already "
                  "exists in BOS -- skipping import.")
        return None

    return template_to_create

def get_templates_to_import(session_template_records: SessionTemplateRecordMap,
                            current_templates: List[BosSessionTemplate],
                            ims_id_map: ImsIdEtagMaps) -> Dict[str, SessionTemplateRecord]:
    """
    Returns all of the session templates that should be created on the system based on the templates
    in the imported data, the IMS ID map (if any), and the current session templates on the system.
    """
    template_records_to_import = {}
    for template_name, template_record in session_template_records.items():
        template_to_import = get_template_to_import(template_name, template_record, ims_id_map,
                                                    current_templates)
        if not template_to_import:
            continue
        # There is a possibility (unlikely) that we are already planning to import a template with
        # this name. This would only occur if the name of a template got transformed (by IMS ID/S3
        # etag replacement) in such a way that it collides with another template we are importing.
        # If this happens, we will import neither template, unless they happen to now be identical.
        template_name_to_import = template_to_import["name"]
        if template_name_to_import in template_records_to_import:
            if template_to_import == template_records_to_import[template_name_to_import].template:
                continue
            print("After IMS ID/S3 etag replacement, there are two different session templates "
                  f"named '{template_name_to_import}' planned for import. Skipping import of both.")
            del template_records_to_import[template_name_to_import]
            continue
        # Add this to the import list.
        template_records_to_import[template_name_to_import] = \
            SessionTemplateRecord(template=template_to_import,
                                  source_file=template_record.source_file,
                                  bos_version=template_record.bos_version)
    return template_records_to_import

def get_options_to_change(options_to_import: BosOptions, current_options: BosOptions) -> List[str]:
    """
    Compare the imported option data to the live system option data and determine which changes
    need to be made.

    The import process should modify any BOS options whose values in the imported data differ from
    the live system.

    Returns a list of the names of the options to be changed.
    """
    options_to_change = [ opt_name for opt_name, opt_value in options_to_import.items()
                            if current_options[opt_name] != opt_value ]
    unchanged_options = sorted(list(options_to_import.keys() - options_to_change))
    if unchanged_options:
        print("The following options already have the value from the imported data and will not be"
              " updated:")
        print(", ".join(unchanged_options))
    if options_to_change:
        print("The following options will be updated to match the values in the imported data:")
        print(", ".join(options_to_change))
    return options_to_change

def change_options(option_data: BosOptions, option_names_to_change: List[str]) -> None:
    """
    Create a dicitonary mapping the specified options to be changed to the new values that
    they should have. Then update the BOS options accordingly.
    """
    if not option_names_to_change:
        return
    option_updates = { opt_name: option_data[opt_name] for opt_name in option_names_to_change }
    print("\nSetting the following options:")
    for opt_name in option_names_to_change:
        print(f"{opt_name} = {option_updates[opt_name]}")
    update_options(option_updates)

def validate_and_record_template(session_template_records: SessionTemplateRecordMap,
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

def load_templates_from_import_data(file_or_dir: str) -> SessionTemplateRecordMap:
    """
    Loads session templates from JSON file or directory specified on the command line.
    Returns a mapping from template names to template records.
    """
    if os.path.isdir(file_or_dir):
        # Find all JSON files in this directory
        print(f"Looking for session template JSON files in directory: '{file_or_dir}'")
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
        raise BosError(f"Contents of {json_file} not a session template or list of templates")
    return session_template_records

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    [--ims-id-map-file <ims_id_map_file.json>]
    [--options-file <options_file.json>]
    {<session_template_directory> | <session_template_list.json> }

    - If options-file is specified, the BOS v2 options in that file are imported onto the system
      (for those that differ from the current options)
    - If a JSON file for a single session template is specified, then that session template
      will be created in BOS.
    - If the JSON file contains a list of session templates, then each session template
      in the list will be created in BOS.
    - If a directory is specified, then the program does the above for every ".json" file found
      in that directory.

    If an IMS ID map file is specified, then each BOS session template will have any old IMS IDs
    replaced with the new ones (before it is imported).

    No existing session templates on the system will be overwritten -- in the case that this would
    happen, a message is printed and that template is skipped.

    Raises BosError if there is an error.
    """
    parser = argparse.ArgumentParser(
        description="Reads BOS session templates and options from files and creates them in BOS")
    parser.add_argument("--ims-id-map-file", type=argparse.FileType('r'), required=False,
                        help="JSON file created during IMS import containing map from old to "
                             "new IMS IDs and S3 etags")
    parser.add_argument("--options-file", type=argparse.FileType('r'), required=False,
                        help="JSON file of BOS options")
    parser.add_argument("file_or_directory",
                        help="JSON file containing session templates or directory containing "
                             "such JSON files")
    parsed_args = parser.parse_args()

    session_template_records = load_templates_from_import_data(parsed_args.file_or_directory)

    if parsed_args.options_file is not None:
        print("Reading in BOS options from JSON file")
        # Read in JSON options
        imported_bos_options = json.load(parsed_args.options_file)

        # Get current BOS options on system
        current_bos_options = list_options()
        options_to_change = get_options_to_change(imported_bos_options, current_bos_options)
    else:
        options_to_change = None

    ims_id_map = {}
    if parsed_args.ims_id_map_file is not None:
        try:
            ims_id_map = load_ims_id_map(parsed_args.ims_id_map_file)
        except ImsIdMapFileFormatError as exc:
            raise BosError(str(exc)) from exc
        print(f"Loaded {len(ims_id_map)} IMS ID mappings from IMS ID map file")

    # Get list of current BOS session templates on system
    current_session_templates = list_session_templates()
    templates_to_import = get_templates_to_import(session_template_records,
                                                  current_session_templates, ims_id_map)

    print("")
    # If there are no changes to make, we are already done
    if not options_to_change and not templates_to_import:
        print("No updates to be performed.")
        return

    # Take a snapshot of the BOS data before we begin.
    print("Taking a snapshot of system BOS data before making changes")
    snapshot_bos_data()
    print("")

    if options_to_change:
        change_options(imported_bos_options, options_to_change)
        print("")

    for template_name, template_record in templates_to_import.items():
        print(f"Importing BOS v{template_record.bos_version} session template '{template_name}'")
        create_session_template(template_record.template, template_record.bos_version)

    print("")
    # Take a snapshot of the BOS data after we're done
    print("Taking a snapshot of system BOS data after import")
    snapshot_bos_data()
    print("")

if __name__ == '__main__':
    try:
        main()
        print("SUCCESS")
    except BosError as bos_exc:
        print_err(str(bos_exc))
        sys.exit(1)
