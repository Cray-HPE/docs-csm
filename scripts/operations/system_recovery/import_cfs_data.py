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
This script imports CFS configurations, component desired states, and options from
JSON files in a specified directory. If a component already has a desired state, or
if a configuration with the same name already exists, then it is skipped.
"""

import argparse
import json
import os
import subprocess
import sys
from typing import Dict, List, NamedTuple, Union

# Ugly temporary hack to get the args module from a different path.
# This will go away as the helper modules make their way into libcsm
sys.path.insert(1, os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","configuration"))
from python_lib import args, cfs
from python_lib.types import JsonDict, JSONDecodeError

NameObjectMap = Dict[str,JsonDict]

CMP_JSON = "components.json"
CFG_JSON = "configurations.json"
OPT_JSON = "options.json"
CFS_EXPORT_TOOL = "/usr/share/doc/csm/scripts/operations/system_recovery/export_cfs_data.sh"


class CfsData(NamedTuple):
    """
    A collection of CFS components, CFS configurations, and CFS options.
    """

    # Components is a mapping from component id to the component object
    components: NameObjectMap
    # Configurations is a mapping from config name to config object
    configurations: NameObjectMap
    # Options is a mapping from option name to option value
    options: cfs.CfsOptions

    @classmethod
    def component_list_to_map(cls, cfs_component_list: List[JsonDict]) -> NameObjectMap:
        """
        Convert a list of CFS components (such as returned by the API) into a dict
        mapping component IDs to the components.
        """
        return { cfs_comp["id"]: cfs_comp for cfs_comp in cfs_component_list }

    @classmethod
    def config_list_to_map(cls, cfs_config_list: List[JsonDict]) -> NameObjectMap:
        """
        Convert a list of CFS configurations (such as returned by the API) into a dict
        mapping config names to the configs.
        """
        return { cfs_config["name"]: cfs_config for cfs_config in cfs_config_list }

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def from_api(cls, cfs_component_list: List[JsonDict], cfs_config_list: List[JsonDict],
                 cfs_options_map: cfs.CfsOptions) -> 'CfsData':
        """
        For populating the CfsData tuple with input in the form it is given from the CFS
        API (lists of objects in the case of components and configurations).
        """
        return cls(components=cls.component_list_to_map(cfs_component_list),
                   configurations=cls.config_list_to_map(cfs_config_list),
                   options=cfs_options_map)

class CfsError(Exception):
    pass

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

def snapshot_cfs_data() -> None:
    """
    Call the CFS exporter tool.
    """
    subprocess.check_call(CFS_EXPORT_TOOL)

def json_data_from_file(filepath: str) -> Union[cfs.CfsOptions, List[JsonDict]]:
    """
    Given a path to a JSON file, read it, parse its contents as JSON,
    and return the result. The type hint return types in the function
    definition are what should be in the files.
    """
    try:
        with open(filepath, "rt") as filehandle:
            return json.load(filehandle)
    except OSError as exc:
        raise argparse.ArgumentTypeError(f"Error reading file '{filepath}': {exc}") from exc
    except JSONDecodeError as exc:
        raise argparse.ArgumentTypeError(
            f"Error parsing JSON in file '{filepath}': {exc}") from exc

def json_data_from_directory(directory_string: str) -> CfsData:
    """
    Given a directory path, read in the contents of the three necessary
    JSON files and return it.
    """
    # First make sure it's a readable directory
    dirpath = args.readable_directory(directory_string)

    # Next make sure that it contains the 3 necessary JSON files and that they're readable
    comps_file = args.readable_file(os.path.join(dirpath, CMP_JSON))
    configs_file = args.readable_file(os.path.join(dirpath, CFG_JSON))
    options_file = args.readable_file(os.path.join(dirpath, OPT_JSON))

    # Finally, read in their JSON data and return it
    return CfsData.from_api(cfs_component_list=json_data_from_file(comps_file),
                            cfs_config_list=json_data_from_file(configs_file),
                            cfs_options_map=json_data_from_file(options_file))

def load_cfs_data() -> CfsData:
    """
    Make API calls to list the CFS components, configurations, and options on the live system.
    """
    return CfsData.from_api(cfs_component_list=cfs.list_components(),
                            cfs_config_list=cfs.list_configurations(),
                            cfs_options_map=cfs.list_options())

def get_configs_to_create(configs_to_import: NameObjectMap,
                          current_configs: NameObjectMap) -> List[str]:
    """
    Compare the configurations in the import data and on the live system. Return
    a list of configuration names that should be created during the import.

    The import should be creating any which do not already exist, so this function
    just identifies those.
    """

    # The intersection of these dictionary keys represents the names of configurations which
    # exist in both the imported data and also the live system
    configs_already_exist = sorted(list(
        configs_to_import.keys() & current_configs.keys()))
    if configs_already_exist:
        print("Configurations with the following names exist in CFS and will not be imported:")
        print(", ".join([ f"'{config_name}'" for config_name in configs_already_exist]))
    # The difference of these dictionary keys represents the names of configurations which
    # are in our imported data but not the live system:
    configs_to_create = sorted(list(
        configs_to_import.keys() - current_configs.keys()))
    if configs_to_create:
        print("The following configurations will be imported:")
        print(", ".join([ f"'{config_name}'" for config_name in configs_to_create]))
    return configs_to_create

def get_comps_to_update(comps_to_import: NameObjectMap, current_comps: NameObjectMap,
                        current_configs: NameObjectMap,
                        config_names_to_create: List[str]) -> List[str]:
    """
    Compare the components from the import data to the current system data and the list of
    configuration names being imported. From this, return the list of components that should be
    updated as part of the import process.

    The import should update the desired configuration for any components where all of the
    following criteria are met:
    1) The component exists in CFS on the live system
    2) The imported component has a desired configuration set
    3) The component on the live system does not have a desired configuration set
    4) The desired configuration from the imported component either already exists on the live
       system or is one that we are going to be importing.
    """
    # The difference of these dictionary keys represents the ids of components which
    # are in our imported data but not the live system:
    comps_do_not_exist = sorted(list(
        comps_to_import.keys() - current_comps.keys()))
    if comps_do_not_exist:
        print("The following components do not exist in CFS and cannot be updated:")
        print(", ".join(comps_do_not_exist))

    comps_to_update = []
    comps_have_config_set = []
    comps_no_desired_config = []
    # The intersection therefore represents the components which exist in both.
    # For these, we must then check if there is already a desired configuration set on the live
    # system.
    for comp_id in sorted(list(comps_to_import.keys() & current_comps.keys())):
        imported_desired_config_name = comps_to_import[comp_id]["desiredConfig"]
        if not imported_desired_config_name:
            comps_no_desired_config.append(comp_id)
            continue
        # Check for the new config name in the union of the configs on the live system and the
        # ones being imported.
        if imported_desired_config_name not in current_configs.keys() | config_names_to_create:
            print(f"Component {comp_id} will not be updated because its import data specifies"
                  f" a nonexistent desired configuration: '{imported_desired_config_name}'")
            continue
        if current_comps[comp_id]["desiredConfig"]:
            comps_have_config_set.append(comp_id)
        else:
            comps_to_update.append(comp_id)
    if comps_no_desired_config:
        print("The following components have no desired configurations set in the import data and "
              "will not be updated:")
        print(", ".join(comps_no_desired_config))
    if comps_have_config_set:
        print("The following components already have desired configurations set in CFS and will "
              "not be updated:")
        print(", ".join(comps_have_config_set))
    if comps_to_update:
        print("The desired configuration for the following components will be imported:")
        print(", ".join(comps_to_update))
    return comps_to_update

def get_options_to_change(options_to_import: cfs.CfsOptions,
                          current_options: cfs.CfsOptions) -> List[str]:
    """
    Compare the imported option data to the live system option data and determine which changes
    need to be made.

    The import process should modify any CFS options whose values in the imported data differ from
    the live system.
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

def change_options(option_data: cfs.CfsOptions, option_names_to_change: List[str]) -> None:
    """
    Create a dictionary mapping the specified options to be changed to the new values that
    they should have. Then update the CFS options accordingly.
    """
    if not option_names_to_change:
        return
    option_updates = { opt_name: option_data[opt_name] for opt_name in option_names_to_change }
    print("\nSetting the following options:")
    for opt_name in option_names_to_change:
        print(f"{opt_name} = {option_updates[opt_name]}")
    cfs.update_options(option_updates)

def create_configs(configs_map: NameObjectMap, config_names_to_create: List[str]) -> None:
    """
    Loop through the specified configuration names one at a time, and create them in CFS with
    the layers specified in the configs map data.
    """
    if not config_names_to_create:
        return
    print("")
    for config_name in config_names_to_create:
        print(f"Importing configuration '{config_name}'")
        cfs.create_configuration(config_name, configs_map[config_name]["layers"])

def update_components(comps_map: NameObjectMap, comp_ids_to_update: List[str]) -> None:
    """
    Loop through the specified component names one at a time, and update them in CFS with
    the desired configuration specified in the components map data.
    """
    if not comp_ids_to_update:
        return
    print("")
    for comp_id in comp_ids_to_update:
        desired_config_name = comps_map[comp_id]["desiredConfig"]
        print(f"Updating component {comp_id} to desired configuration '{desired_config_name}'")
        cfs.update_component_desired_config(comp_id, desired_config_name)

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    <directory containing JSON files>

    Raises CfsError if there is an error or if no data is found to import
    """
    parser = argparse.ArgumentParser(
        description="Reads CFS data from JSON files and imports the data info CFS")
    parser.add_argument(metavar="json_directory", type=json_data_from_directory, dest="json_data",
                        help=f"Directory containing {CMP_JSON}, {CFG_JSON}, and {OPT_JSON}")
    parsed_args = parser.parse_args()

    cfs_data_to_import = parsed_args.json_data

    print("Reading current data from CFS")
    current_cfs_data = load_cfs_data()

    # Determine the necessary updates
    print("\nExamining CFS configurations...")
    configs_to_create = get_configs_to_create(cfs_data_to_import.configurations,
                                              current_cfs_data.configurations)
    
    print("\nExamining CFS components...")
    comps_to_update = get_comps_to_update(cfs_data_to_import.components,
                                          current_cfs_data.components,
                                          current_cfs_data.configurations, configs_to_create)

    print("\nExamining CFS options...")
    options_to_change = get_options_to_change(cfs_data_to_import.options, current_cfs_data.options)

    print("")
    # If there are no changes to make, we are already done
    if not configs_to_create and not comps_to_update and not options_to_change:
        print("No updates to be performed.")
        return

    # Take a snapshot of the CFS data before we begin.
    print("Taking a snapshot of system CFS data before making changes")
    snapshot_cfs_data()

    change_options(cfs_data_to_import.options, options_to_change)
    create_configs(cfs_data_to_import.configurations, configs_to_create)
    update_components(cfs_data_to_import.components, comps_to_update)

    print("")

    # Take a snapshot of the CFS data after we're done
    print("Taking a snapshot of system CFS data after import")
    snapshot_cfs_data()
    print("")

if __name__ == '__main__':
    try:
        main()
        print("SUCCESS")
    except CfsError as cfs_exc:
        print_err(str(cfs_exc))
        sys.exit(1)
