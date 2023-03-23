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

################################################################################
# This script imports BOS session templates from a JSON list file and
# recreates them.
#
# For backwards compatability reasons, it also supports being passed a TGZ
# file containing individual session templates.
################################################################################

import argparse
import collections
import json
import os
import subprocess
import sys
import tempfile
from typing import Dict, List

from bos_session_template_version import BosSessionTemplate, \
                                         InvalidBosSessionTemplate, \
                                         get_session_template_version

class ImportBosSessionTemplateError(Exception):
    pass

SessionTemplateRecord = collections.namedtuple('SessionTemplateRecord', ['template', 'source_file', 'bos_version'])

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

def import_session_template(template_name: str, template_record: SessionTemplateRecord) -> None:
    """
    Creates the BOS session template in BOS. Raises ImportBosSessionTemplateError if there
    are problems.
    """
    bos_vstring = f"v{template_record.bos_version}"
    print(f"Creating BOS {bos_vstring} session template '{template_name}'")
    template_to_create = template_record.template.copy()
    # Delete the name field (since it is specified on the command line of the create command)
    del template_to_create["name"]
    # Write template to a temporary file and create the record
    with tempfile.NamedTemporaryFile(mode="wt", suffix=".json", prefix="session_template") as fp:
        json.dump(template_to_create, fp)
        fp.flush()
        if template_record.bos_version == 1:
            command_list = ["cray", "bos", bos_vstring, "sessiontemplate", "create",
                            "--file", fp.name, "--name", template_name, "--format", "json"]
        else:
            command_list = ["cray", "bos", bos_vstring, "sessiontemplates", "create",
                            "--file", fp.name, template_name, "--format", "json"]
        proc = subprocess.run(command_list, stdout=subprocess.PIPE)
    if proc.returncode == 0:
        return
    raise ImportBosSessionTemplateError(
        f"CLI command to create BOS {bos_vstring} session template '{template_name}' failed "
        f"with return code {proc.returncode}")

def validate_and_record_template(session_template_records: Dict[str, SessionTemplateRecord],
                                 session_template: dict, source_file: str) -> None:
    """
    Helper function which parses a would-be session template, adding it to session_template_records
    mapping if it looks good. Raises ImportBosSessionTemplateError if there are any problems.
    """
    try:
        template_name = session_template["name"]
    except KeyError:
        raise ImportBosSessionTemplateError(
            f"Session template in {source_file} has no 'name' field.")
    if template_name in session_template_records:
        # We already have a template with this name. The only way this isn't a problem
        # is if the two templates are identical
        if session_template_records[template_name].template == session_template:
            # They are identical, so just skip it.
            return
        raise ImportBosSessionTemplateError(f"Two different session templates in {source_file} and"
            f" {session_template_records[template_name].source_file} both named '{template_name}'")
    # Determine BOS version of this template
    try:
        bos_version = get_session_template_version(session_template)
    except InvalidBosSessionTemplate as exc:
        raise ImportBosSessionTemplateError(
            f"{source_file} contains invalid template '{template_name}': {exc}") from exc

    # Add this template to our records
    session_template_records[template_name] = SessionTemplateRecord(
        template=session_template, source_file=source_file, bos_version=bos_version)

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    { <session_template_records.json> | <directory> }

    - If the argument is a JSON file for a single session template, then that session template
      will be created in BOS.
    - If the argument is a JSON file for a list of session templates, then each session template
      in the list will be created in BOS.
    - If the argument is a directory, then the program does the above for every ".json" file found
      in that directory.

    Raises ImportBosSessionTemplateError if there is an error or if no templates are found to import
    """
    parser = argparse.ArgumentParser(
        description="Reads BOS session templates from an input file and creates them in BOS")
    parser.add_argument("file_or_directory", 
                        help="JSON file containing session templates or directory containing such JSON files")
    parsed_args = parser.parse_args()

    file_or_dir = parsed_args.file_or_directory
    json_files = list()
    if os.path.isdir(file_or_dir):
        # Find all JSON files in this directory
        for dir_item in os.scandir(file_or_dir):
            if dir_item.is_file() and dir_item.name[-5:] == ".json":
                json_files.append(dir_item.path)
        if not json_files:
            raise ImportBosSessionTemplateError(f"No .json files in directory '{file_or_dir}'")
    elif file_or_dir[-5:] == ".json":
        if os.path.isfile(file_or_dir):
            json_files.append(file_or_dir)
        elif os.path.exists(file_or_dir):
            raise ImportBosSessionTemplateError(
                f"Argument exists but is not a regular file: '{file_or_dir}'")
        else:
            raise ImportBosSessionTemplateError(f"File does not exist: '{file_or_dir}'")
    else:
        # file_or_dir[-5:] != ".json"
        raise ImportBosSessionTemplateError(
            f"Argument must be directory or .json file. Invalid argument: '{file_or_dir}'")

    session_template_records = dict()
    # session_template_records is a mapping from template names to SessionTemplateRecords

    for json_file in json_files:
        print(f"Reading session templates from {json_file}")
        with open(json_file, "rt") as fp:
            file_contents = json.load(fp)
        if isinstance(file_contents, dict):
            validate_and_record_template(session_template_records, file_contents, json_file)
            continue
        elif isinstance(file_contents, list):
            for template in file_contents:
                validate_and_record_template(session_template_records, template, json_file)
            continue
        # Not a list or a dict
        raise ImportBosSessionTemplateError(
            f"Contents of {json_file} are not a session template or list of templates")

    if not session_template_records:
        raise ImportBosSessionTemplateError("No session templates found")

    for template_name, record in session_template_records.items():
        import_session_template(template_name, record)

if __name__ == '__main__':
    try:
        main()
    except ImportBosSessionTemplateError as exc:
        print_err(f"{exc}")
        sys.exit(1)
