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
from typing import Dict, List, Union

from python_lib.bos import BosError, BosOptions, delete_v1_session, delete_v2_session, \
                           delete_v2_session_template, list_options, list_v1_session_names, \
                           list_v2_sessions, list_v2_session_templates, update_options
from python_lib.bos_cli import create_session_template
from python_lib.bos_session_templates import BosSessionTemplate, \
                                             InvalidBosSessionTemplate, \
                                             get_session_template_name, \
                                             get_session_template_version

# Mapping from template name to associated session template record
SessionTemplateMap = Dict[str, BosSessionTemplate]

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

def get_template_to_import(template_name: str, template_to_create: BosSessionTemplate,
                           current_templates: List[BosSessionTemplate]) -> Union[BosSessionTemplate,
                                                                                 None]:
    """
    Determines what session template should be created based on the specified template from the
    import data.
    If a BOS session template already exists with the same name, the import will not happen
    and a message will be printed to that effect.
    """
    print(f"Processing session template '{template_name}'")

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

def get_templates_to_import(template_name_map: SessionTemplateMap,
                            current_templates: List[BosSessionTemplate]) -> SessionTemplateMap:
    """
    Returns all of the session templates that should be created on the system based on the templates
    in the imported data and the current session templates on the system.
    """
    template_import_map = {}
    for template_name, template in template_name_map.items():
        template_to_import = get_template_to_import(template_name, template, current_templates)
        if not template_to_import:
            continue
        # Add this to the import list.
        template_name_to_import = template_to_import["name"]
        template_import_map[template_name_to_import] = template_to_import
    return template_import_map

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

def validate_and_record_template(name_template_map: SessionTemplateMap,
                                 template_source_map: Dict[str, str],
                                 session_template: BosSessionTemplate, source_file: str) -> None:
    """
    Helper function which parses a would-be session template, adding it to name_template_map
    mapping if it looks good. Also adds a corresponding entry in the template_source_map.
    Raises BosError if there are any problems.
    """
    try:
        template_name = get_session_template_name(session_template)
    except InvalidBosSessionTemplate as exc:
        raise BosError(f"Error with session template in {source_file}: {exc}") from exc
    if template_name in name_template_map:
        # We already have a template with this name. The only way this isn't a problem
        # is if the two templates are identical
        if name_template_map[template_name] == session_template:
            # They are identical, so just skip it.
            return
        raise BosError(f"Two different session templates in {source_file} and"
            f" {template_source_map[template_name]} both named '{template_name}'")
    # Make sure the BOS version of this template can be determined. We don't care what the version
    # is yet -- this is just validating that the template isn't so malformed that making this call
    # provokes an error.
    try:
        get_session_template_version(session_template)
    except InvalidBosSessionTemplate as exc:
        raise BosError(f"{source_file} contains invalid template '{template_name}': {exc}") from exc

    # Add this template to our records
    name_template_map[template_name] = session_template
    template_source_map[template_name] = source_file

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
    template_source_map = {}

    # Dict mapping template name to the session template
    name_template_map = {}

    for json_file in json_files:
        print(f"Reading session templates from {json_file}")
        with open(json_file, "rt") as jfile:
            file_contents = json.load(jfile)
        if isinstance(file_contents, dict):
            validate_and_record_template(name_template_map, template_source_map, file_contents,
                                         json_file)
            continue
        if isinstance(file_contents, list):
            for template in file_contents:
                validate_and_record_template(name_template_map, template_source_map, template,
                                             json_file)
            continue
        # Not a list or a dict
        raise BosError(f"Contents of {json_file} not a session template or list of templates")
    return name_template_map

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    [--clear-bos]
    [--options-file <options_file.json>]
    {<session_template_directory> | <session_template_list.json> }

    - If --clear-bos is specified, all BOS sessions and session templates will be deleted before the import.
    - If options-file is specified, the BOS v2 options in that file are imported onto the system
      (for those that differ from the current options)
    - If a JSON file for a single session template is specified, then that session template
      will be created in BOS.
    - If the JSON file contains a list of session templates, then each session template
      in the list will be created in BOS.
    - If a directory is specified, then the program does the above for every ".json" file found
      in that directory.

    No existing session templates on the system will be overwritten -- in the case that this would
    happen, a message is printed and that template is skipped (keeping in mind that if --clear-bos is
    specified, all templates are first deleted, so some templates may essentially be overwritten in
    that case)

    Raises BosError if there is an error.
    """
    parser = argparse.ArgumentParser(
        description="Reads BOS session templates and options from files and creates them in BOS")
    parser.add_argument("--clear-bos", action='store_true', help="Delete BOS sessions and session templates before importing")
    parser.add_argument("--options-file", type=argparse.FileType('r'), required=False,
                        help="JSON file of BOS options")
    parser.add_argument("file_or_directory",
                        help="JSON file containing session templates or directory containing "
                             "such JSON files")
    parsed_args = parser.parse_args()

    template_name_map = load_templates_from_import_data(parsed_args.file_or_directory)

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
    current_session_templates = list_v2_session_templates()

    if parsed_args.clear_bos:
        # Take a snapshot of the BOS data before we begin.
        print("Taking a snapshot of system BOS data before clearing BOS")
        snapshot_bos_data()
        print("")

        v1_session_names = list_v1_session_names()
        v2_session_names = [ session["name"] for session in list_v2_sessions() ]
        template_names = [ template["name"] for template in current_session_templates ]

        print("Deleting all BOS sessions and session templates")
        for session in v1_session_names:
            print(f"Deleting v1 session '{session}'")
            delete_v1_session(session)

        # If we deleted any, make sure they are now gone
        if v1_session_names and list_v1_session_names():
            raise BosError("V1 sessions still exist after deleting all of them")

        for session in v2_session_names:
            print(f"Deleting v2 session '{session}'")
            delete_v2_session(session)

        if v2_session_names and list_v2_sessions():
            raise BosError("V2 sessions still exist after deleting all of them")

        for template in template_names:
            print(f"Deleting session template '{template}'")
            delete_v2_session_template(template)

        if current_session_templates:
            current_session_templates = list_v2_session_templates()
            if current_session_templates:
                raise BosError("Session templates still exist after deleting all of them")

    template_import_map = get_templates_to_import(template_name_map, current_session_templates)

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

    for template_name, template in template_import_map.items():
        bos_version = get_session_template_version(template)
        print(f"Importing BOS v{bos_version} session template '{template_name}'")
        create_session_template(template, bos_version)

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
