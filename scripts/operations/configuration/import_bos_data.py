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
This script imports BOS session templates from a JSON list file (or a directory
of such files) and recreates them.
"""

import argparse
import json
import os
import subprocess
import sys
from typing import Dict, List

from python_lib.bos import BosError, BosOptions, BosSessionTemplate, \
                           delete_session, delete_session_template, \
                           list_options, list_sessions, \
                           list_session_templates, update_options
from python_lib.bos import BosSessionTemplateUniqueId as TemplateUniqueId
from python_lib.bos import BosSessionUniqueId as SessionUniqueId
from python_lib.bos_cli import create_session_template

# Mapping from template name to associated session template record

SessionTemplateMap = Dict[TemplateUniqueId, BosSessionTemplate]

BOS_EXPORT_TOOL = "/usr/share/doc/csm/scripts/operations/configuration/export_bos_data.sh"

def print_stderr(msg: str) -> None:
    """
    Outputs the specified message to stderr
    """
    sys.stderr.write(f"{msg}\n")

def print_warn(msg: str) -> None:
    """
    Prepends "WARNING: " and outputs the specified message to stderr
    """
    print_stderr(f"WARNING: {msg}")

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

def should_import_template(template_to_create: BosSessionTemplate,
                           current_template_map: SessionTemplateMap) -> bool:
    """
    Determines whether or not this template should be created, based on the specified template from
    the import data.
    If a BOS session template already exists with the same name/tenant, the import will not happen
    and a message will be printed to that effect.
    """
    template_id = template_to_create.unique_id
    print(f"Processing session template {template_id}")
    if template_id not in current_template_map:
        return True

    if template_to_create.contents == current_template_map[template_id].contents:
        print("Session template with identical contents already exists in BOS -- skipping import "
              f"({template_id})")
    else:
        print("Session template already exists in BOS with DIFFERENT contents -- skipping import "
              f"({template_id})")
    return False

def get_templates_to_import(exported_template_map: SessionTemplateMap,
                            current_template_map: SessionTemplateMap) -> SessionTemplateMap:
    """
    Returns all of the session templates that should be created on the system based on the templates
    in the exported data and the current session templates on the system.
    """
    return { template.unique_id: template
             for template in exported_template_map.values()
             if should_import_template(template, current_template_map) }

def get_options_to_change(options_to_import: BosOptions, current_options: BosOptions) -> List[str]:
    """
    Compare the imported option data to the live system option data and determine which changes
    need to be made.

    The import process should modify any BOS options whose values in the imported data differ from
    the live system.

    Returns a list of the names of the options to be changed.
    """
    options_to_change = []
    unchanged_options = []
    for opt_name, opt_value in options_to_import.items():
        try:
            if current_options[opt_name] != opt_value:
                options_to_change.append(opt_name)
            else:
                unchanged_options.append(opt_name)
        except KeyError:
            print_warn(f"Not restoring unknown option found in backup data: {opt_name} = {opt_value}")
    if unchanged_options:
        unchanged_options.sort()
        print("The following options already have the value from the imported data and will not be"
              " updated:")
        print(", ".join(unchanged_options))
    if options_to_change:
        options_to_change.sort()
        print("The following options will be updated to match the values in the imported data:")
        print(", ".join(options_to_change))
    return options_to_change

def change_options(option_data: BosOptions, option_names_to_change: List[str]) -> None:
    """
    Create a dictionary mapping the specified options to be changed to the new values that
    they should have. Then update the BOS options accordingly.
    """
    if not option_names_to_change:
        return
    option_updates = { opt_name: option_data[opt_name] for opt_name in option_names_to_change }
    print("\nSetting the following options:")
    for opt_name in option_names_to_change:
        print(f"{opt_name} = {option_updates[opt_name]}")
    update_options(option_updates)

def validate_and_record_template(template_map: SessionTemplateMap,
                                 source_map: Dict[TemplateUniqueId, str],
                                 template_dict: dict, source_file: str) -> None:
    """
    Helper function which parses a would-be session template, adding it to name_tenant_template_map
    mapping if it looks good. Also adds a corresponding entry in the template_source_map.
    Raises BosError if there are any problems.
    """
    try:
        template = BosSessionTemplate(template_dict)
    except BosError as exc:
        print(f"Error with session template in {source_file}: {exc}")
        raise

    template_id = template.unique_id

    if template_id in template_map:
        # We already have a template with this name/tenant. The only way this isn't a problem
        # is if the two templates are identical
        if template_map[template_id].contents == template.contents:
            # They are identical, so just skip it.
            return
        raise BosError(f"Two different session templates in {source_file} and "
                       f"{source_map[template_id]}, both with {template_id}")

    # Add this template to our records
    template_map[template_id] = template
    source_map[template_id] = source_file

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

def load_current_templates() -> SessionTemplateMap:
    """
    Load current BOS session templates and return a mapping from session template name/tenant
    to each template
    """
    template_map = {}
    for template in list_session_templates():
        template_id = template.unique_id
        if template_id in template_map:
            raise BosError("BOS session template listing includes multiple templates with "
                           f"{template_id}")
        template_map[template_id] = template

    return template_map

def load_templates_from_import_data(file_or_dir: str) -> SessionTemplateMap:
    """
    Loads session templates from JSON file or directory specified on the command line.
    Returns a mapping from template names to templates.
    """

    if os.path.isdir(file_or_dir):
        # Find all JSON files in this directory
        print(f"Looking for session template JSON files in directory: '{file_or_dir}'")
        json_files = list_json_files_in_directory(file_or_dir)
    else:
        validate_json_file(file_or_dir)
        json_files = [file_or_dir]

    # Dict mapping template name to the JSON file from which the template was loaded.
    # Used to provide information in case the same template is found in multiple files.
    source_map = {}

    # Dict mapping template name & tenant to the session template
    template_map = {}

    for json_file in json_files:
        print(f"Reading session templates from {json_file}")
        with open(json_file, "rt") as jfile:
            file_contents = json.load(jfile)
        if isinstance(file_contents, dict):
            validate_and_record_template(template_map, source_map, file_contents, json_file)
            continue
        if isinstance(file_contents, list):
            for template in file_contents:
                validate_and_record_template(template_map, source_map, template, json_file)
            continue
        # Not a list or a dict
        raise BosError(f"Contents of {json_file} not a session template or list of templates")
    return template_map

def delete_all_sessions(session_ids: List[SessionUniqueId]) -> None:
    """
    Deletes the specified list of sessions, and then verifies that none remain
    """
    if not session_ids:
        return

    for session_id in session_ids:
        print(f"Deleting session {session_id}")
        delete_session(session_id)

    if list_sessions():
        raise BosError("Sessions still exist after deleting all of them")

def delete_all_templates(template_ids: List[TemplateUniqueId]) -> None:
    """
    Deletes the specified list of session templates, and then verifies that none remain
    """
    if not template_ids:
        return

    for template_id in template_ids:
        print(f"Deleting session template {template_id}")
        delete_session_template(template_id)

    if list_session_templates():
        raise BosError("Session templates still exist after deleting all of them")

def delete_all_sessions_and_templates(current_template_map: SessionTemplateMap) -> None:
    """
    Deletes all BOS sessions and session templates.
    Then queries BOS to confirm that none remain.
    """
    session_ids = [ session.unique_id for session in list_sessions() ]

    print("Deleting all BOS sessions and session templates")

    delete_all_sessions(session_ids)
    delete_all_templates(list(current_template_map))

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    [--clear-bos]
    [--options-file <options_file.json>]
    {<session_template_directory> | <session_template_list.json> }

    - If --clear-bos is specified, all BOS sessions and session templates will be deleted before
      the import.
    - If options-file is specified, the BOS options in that file are imported onto the system
      (for those that differ from the current options)
    - If a JSON file for a single session template is specified, then that session template
      will be created in BOS.
    - If the JSON file contains a list of session templates, then each session template
      in the list will be created in BOS.
    - If a directory is specified, then the program does the above for every ".json" file found
      in that directory.

    No existing session templates on the system will be overwritten -- in the case that this would
    happen, a message is printed and that template is skipped (keeping in mind that if --clear-bos
    is specified, all templates are first deleted, so some templates may essentially be overwritten
    in that case)

    Raises BosError if there is an error.
    """
    parser = argparse.ArgumentParser(
        description="Reads BOS session templates and options from files and creates them in BOS")
    parser.add_argument("--clear-bos", action='store_true',
                        help="Delete BOS sessions and session templates before importing")
    parser.add_argument("--options-file", type=argparse.FileType('r'), required=False,
                        help="JSON file of BOS options")
    parser.add_argument("file_or_directory",
                        help="JSON file containing session templates or directory containing "
                             "such JSON files")
    parsed_args = parser.parse_args()

    exported_template_map = load_templates_from_import_data(parsed_args.file_or_directory)

    if parsed_args.options_file is not None:
        print("Reading in BOS options from JSON file")
        # Read in JSON options
        imported_bos_options = json.load(parsed_args.options_file)

        # Get current BOS options on system
        current_bos_options = list_options()
        options_to_change = get_options_to_change(imported_bos_options, current_bos_options)
    else:
        options_to_change = None

    # Get list of current BOS session templates on system
    current_template_map = load_current_templates()

    if parsed_args.clear_bos:
        # Take a snapshot of the BOS data before we begin.
        print("Taking a snapshot of system BOS data before clearing BOS")
        snapshot_bos_data()
        print("")

        delete_all_sessions_and_templates(current_template_map)
        current_template_map = {}

    template_import_map = get_templates_to_import(exported_template_map, current_template_map)

    print("")
    # If there are no changes to make, we are already done
    if not options_to_change and not template_import_map:
        print("No updates to be performed.")
        return

    # Take a snapshot if we didn't already
    if not parsed_args.clear_bos:
        # Take a snapshot of the BOS data before we begin.
        print("Taking a snapshot of system BOS data before making changes")
        snapshot_bos_data()
        print("")

    if options_to_change:
        change_options(imported_bos_options, options_to_change)
        print("")

    for template_id, template in template_import_map.items():
        print(f"Importing BOS v{template.version} session template {template_id}")
        create_session_template(template)

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
