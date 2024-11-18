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
This script imports CFS configurations, component desired states, and options from
JSON files in a specified directory. If a component already has a desired state, or
if a configuration with the same name already exists, then it is skipped.
"""

import argparse
from functools import lru_cache
import json
import os
import subprocess
import sys
from typing import Dict, Generator, List, NamedTuple, Union

from python_lib import args, cfs
from python_lib.cfs_import_export import CFS_RESOURCE_TYPES, list_cfs_components, \
                                         remove_components_with_empty_ids
from python_lib.common import print_err
from python_lib.types import JsonDict, JSONDecodeError

NameObjectMap = Dict[str,JsonDict]

CFS_EXPORT_TOOL = "/usr/share/doc/csm/scripts/operations/configuration/export_cfs_data.sh"

CFG_JSON = CFS_RESOURCE_TYPES["configurations"].json_file_name
CMP_JSON = CFS_RESOURCE_TYPES["components"].json_file_name
OPT_JSON = CFS_RESOURCE_TYPES["options"].json_file_name
SRC_JSON = CFS_RESOURCE_TYPES["sources"].json_file_name


def dict_list_to_map(dict_list: List[JsonDict], id_field_name: str) -> NameObjectMap:
    """
    Convert a list of dict objects into a dict mapping from the id field value of each dict object
    to the corresponding dict object.
    """
    return { dict_obj[id_field_name]: dict_obj for dict_obj in dict_list }


class CfsData(NamedTuple):
    """
    A collection of CFS components, CFS configurations, and CFS options.
    """

    # components is a mapping from component id to the component object
    components: NameObjectMap
    # configurations is a mapping from config name to config object
    configurations: NameObjectMap
    # options is a mapping from option name to option value
    options: cfs.CfsOptions
    # sources is a mapping from source name to source object
    sources: NameObjectMap

    @classmethod
    def component_list_to_map(cls, cfs_component_list: List[JsonDict]) -> NameObjectMap:
        """
        Convert a list of CFS components (such as returned by the API) into a dict
        mapping component IDs to the components.
        """
        return dict_list_to_map(cfs_component_list, "id")

    @classmethod
    def config_list_to_map(cls, cfs_config_list: List[JsonDict]) -> NameObjectMap:
        """
        Convert a list of CFS configurations (such as returned by the API) into a dict
        mapping config names to the configs.
        """
        return dict_list_to_map(cfs_config_list, "name")

    @classmethod
    def source_list_to_map(cls, cfs_source_list: List[JsonDict]) -> NameObjectMap:
        """
        Convert a list of CFS sources (such as returned by the API) into a dict
        mapping source names to the sources.
        """
        return dict_list_to_map(cfs_source_list, "name")

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def from_api(cls, cfs_component_list: List[JsonDict],
                 cfs_config_list: List[JsonDict],
                 cfs_options_map: cfs.CfsOptions,
                 cfs_source_list: List[JsonDict]) -> 'CfsData':
        """
        For populating the CfsData tuple with input in the form it is given from the CFS
        API (lists of objects in the case of components, configurations, and sources).
        """
        return cls(components=cls.component_list_to_map(cfs_component_list),
                   configurations=cls.config_list_to_map(cfs_config_list),
                   options=cfs_options_map,
                   sources=cls.source_list_to_map(cfs_source_list))


class CfsError(Exception):
    pass


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

    # Next make sure that it contains the 4 necessary JSON files and that they're readable
    comps_file = args.readable_file(os.path.join(dirpath, CMP_JSON))
    configs_file = args.readable_file(os.path.join(dirpath, CFG_JSON))
    options_file = args.readable_file(os.path.join(dirpath, OPT_JSON))
    sources_file = args.readable_file(os.path.join(dirpath, SRC_JSON))

    print("Reading CFS component data from JSON file")
    cfs_component_list=remove_components_with_empty_ids(json_data_from_file(comps_file))

    print("Reading CFS configuration data from JSON file")
    cfs_config_list=json_data_from_file(configs_file)

    print("Reading CFS option data from JSON file")
    cfs_options_map=json_data_from_file(options_file)

    print("Reading CFS source data from JSON file")
    cfs_source_list=json_data_from_file(sources_file)

    # Finally, read in their JSON data and return it
    return CfsData.from_api(cfs_component_list=cfs_component_list,
                            cfs_config_list=cfs_config_list,
                            cfs_options_map=cfs_options_map,
                            cfs_source_list=cfs_source_list)

def load_cfs_data() -> CfsData:
    """
    Make API calls to list the CFS components, configurations, and options on the live system.
    """
    print("Reading component data from CFS")
    cfs_component_list=list_cfs_components()

    print("Reading configuration data from CFS")
    cfs_config_list=cfs.list_configurations()

    print("Reading option data from CFS")
    cfs_options_map=cfs.list_options()

    print("Reading source data from CFS")
    cfs_source_list=cfs.list_sources()

    return CfsData.from_api(cfs_component_list=cfs_component_list,
                            cfs_config_list=cfs_config_list,
                            cfs_options_map=cfs_options_map,
                            cfs_source_list=cfs_source_list)

def get_resources_to_create(resource_type: str,
                            exported_resources: NameObjectMap,
                            current_resources: NameObjectMap) -> List[str]:
    """
    Looks at the exported resources and current resources.
    Returns a list of item names which exist in the exported_resources list but
    not the current resources.
    """
    # The intersection of these dictionary keys represents the names which
    # exist in both the imported data and also the live system:
    resources_already_exist = sorted(list(exported_resources.keys() & current_resources.keys()))

    if resources_already_exist:
        print(f"{resource_type} with the following names exist in CFS and will not be imported:")
        print(", ".join([ f"'{resource_name}'" for resource_name in resources_already_exist]))

    # The difference of these dictionary keys represents the names which
    # are in our exported data but not the live system:
    resources_to_create = sorted(list(exported_resources.keys() - current_resources.keys()))

    if resources_to_create:
        print(f"The following {resource_type} will be imported:")
        print(", ".join([ f"'{resource_name}'" for resource_name in resources_to_create]))

    return resources_to_create

def get_sources_to_restore(sources_to_import: NameObjectMap,
                           current_sources: NameObjectMap) -> List[str]:
    """
    Compare the sources in the import data and on the live system. Return
    a list of source names that should be restored during the import.

    The import should be restoring any which do not already exist, so this function
    just identifies those.
    """
    return get_resources_to_create("sources", sources_to_import, current_sources)

def get_configs_to_create(configs_to_import: NameObjectMap,
                          current_configs: NameObjectMap) -> List[str]:
    """
    Compare the configurations in the import data and on the live system. Return
    a list of configuration names that should be created during the import.

    The import should be creating any which do not already exist, so this function
    just identifies those.
    """
    return get_resources_to_create("configurations", configs_to_import, current_configs)

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
        imported_desired_config_name = comps_to_import[comp_id]["desired_config"]
        if not imported_desired_config_name:
            comps_no_desired_config.append(comp_id)
            continue
        # Check for the new config name in the union of the configs on the live system and the
        # ones being imported.
        if imported_desired_config_name not in current_configs.keys() | config_names_to_create:
            print(f"Component {comp_id} will not be updated because its import data specifies"
                  f" a nonexistent desired configuration: '{imported_desired_config_name}'")
            continue
        if current_comps[comp_id]["desired_config"]:
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

def scrub_layer(layer: JsonDict) -> None:
    """
    Check if the layer contains both "branch" and "commit" fields. It is not legal to
    specify both for a layer when creating a configuration. In these cases, we remove the
    "commit" field when recreating the layer, as it will be automatically populated by CFS.
    The alternative (omitting the "branch" field) means that information is lost, since the
    "branch" field is only present if it is specified when creating the configuration.
    """
    if "commit" in layer and "branch" in layer:
        del layer["commit"]

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
        config_data = configs_map[config_name]
        for layer in config_data["layers"]:
            scrub_layer(layer)
        # If an additional inventory layer is present, the same procedure must be done for it
        if "additional_inventory" in config_data:
            scrub_layer(config_data["additional_inventory"])
        # When creating a CFS configuration, the 'name' and 'last_updated' fields cannot be specified
        for field in [ 'name', 'last_updated' ]:
            config_data.pop(field, None)
        cfs.create_configuration(config_name, **config_data)

def restore_sources(sources_map: NameObjectMap, source_names_to_restore: List[str]) -> None:
    """
    Loop through the specified source names one at a time, and restore them in CFS
    """
    if not source_names_to_restore:
        return
    print("")
    for source_name in source_names_to_restore:
        print(f"Restoring source '{source_name}'")
        source_data = sources_map[source_name]
        # Remove name and last_updated fields, as those are not used in the restore request
        for field in [ 'name', 'last_updated' ]:
            source_data.pop(field, None)
        cfs.restore_source(source_name, **source_data)

def chunk_list(items: list, max_batch_size: int=500) -> Generator[list, None, None]:
    """
    Break a given list into chunks with size <= the specified maximum, and yield
    them one at a time.
    """
    chunk_size = max_batch_size if max_batch_size > 0 else len(items)
    while items:
        yield items[:chunk_size]
        items = items[chunk_size:]

def update_components(comps_map: NameObjectMap, comp_ids_to_update: List[str]) -> None:
    """
    Loop through the specified component names one at a time, and update them in CFS with
    the desired configuration specified in the components map data.
    """
    if not comp_ids_to_update:
        return
    print("")
    comps_to_update_by_desired_config = {}
    for comp_id in comp_ids_to_update:
        desired_config_name = comps_map[comp_id]["desired_config"]
        if desired_config_name in comps_to_update_by_desired_config:
            comps_to_update_by_desired_config[desired_config_name].append(comp_id)
        else:
            comps_to_update_by_desired_config[desired_config_name] = [comp_id]

    for desired_config_name, comp_id_list in comps_to_update_by_desired_config.items():
        update_data = { "desired_config": desired_config_name }
        for comp_sublist in chunk_list(comp_id_list):
            print(f"Updating desired configuration to '{desired_config_name}' for components: {comp_sublist}")
            cfs.update_components_by_ids(comp_ids=comp_sublist, update_data=update_data)


@lru_cache(maxsize=1)
def source_restore_supported() -> bool:
    """
    Check the CFS version and see if source restore is supported.
    """
    print("Checking CFS version on system")
    cfs_version = cfs.CfsVersion.from_api()
    print(f"CFS version is {cfs_version}")
    return cfs.restore_source_supported(cfs_version)

def clear_cfs(current_cfs_data: CfsData) -> None:
    """
    Clear select CFS data
    """
    for config_name in list(current_cfs_data.configurations):
        print(f"Deleting configuration '{config_name}'")
        cfs.delete_configuration(config_name)
        del current_cfs_data.configurations[config_name]

    comp_clear_data = {"error_count": 0, "state": [], "desired_config": "", "tags": {}}
    for comp_sublist in chunk_list(list(current_cfs_data.components)):
        print("Clearing error count, desired configuration, state, and tags for components: "
              f"'{comp_sublist}'")
        updated_comp_response = cfs.update_components_by_ids(comp_ids=comp_sublist,
                                                             update_data=comp_clear_data)
        for comp_id in updated_comp_response['component_ids']:
            current_cfs_data.components[comp_id].update(comp_clear_data)

    if current_cfs_data.sources:
        # No sources to clear
        return

    if not source_restore_supported():
        print("Source restore not supported at this CFS version -- will not clear source data")
        return

    for source_name in list(current_cfs_data.sources):
        print(f"Deleting source '{source_name}'")
        cfs.delete_source(source_name)
        del current_cfs_data.sources[source_name]

def main() -> None:
    """
    Parses the command line arguments, does the stuff.

    Arguments:
    [--clear-cfs] <directory containing JSON files>

    Raises CfsError if there is an error or if no data is found to import
    """
    parser = argparse.ArgumentParser(
        description="Reads CFS data from JSON files and imports the data info CFS")
    parser.add_argument("--clear-cfs", action='store_true',
                        help="Delete CFS configurations and clear CFS components before importing")
    parser.add_argument(metavar="json_directory", type=json_data_from_directory, dest="json_data",
                        help=f"Directory containing {CMP_JSON}, {CFG_JSON}, and {OPT_JSON}")
    parsed_args = parser.parse_args()

    cfs_data_to_import = parsed_args.json_data

    # Call this up front just to make sure we're able to get the CFS version
    source_restore_supported()

    print("Reading current data from CFS")
    current_cfs_data = load_cfs_data()

    if parsed_args.clear_cfs:
        # Take a snapshot of the CFS data before clearing it
        print("Taking a snapshot of system CFS data before clearing it")
        snapshot_cfs_data()
        clear_cfs(current_cfs_data)

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

    print("\nExamining CFS sources...")
    sources_to_restore = get_sources_to_restore(cfs_data_to_import.sources,
                                                current_cfs_data.sources)
    if sources_to_restore and not source_restore_supported():
        print("Source restore not supported at this CFS version -- will not restore source data")
        sources_to_restore = []

    print("")
    # If there are no changes to make, we are already done
    if not any([configs_to_create, comps_to_update, options_to_change, sources_to_restore]):
        print("No updates to be performed.")
        return

    if not parsed_args.clear_cfs:
        # Only need to do this if we didn't clear CFS earlier
        # Take a snapshot of the CFS data before we begin.
        print("Taking a snapshot of system CFS data before making changes")
        snapshot_cfs_data()

    change_options(cfs_data_to_import.options, options_to_change)
    restore_sources(cfs_data_to_import.sources, sources_to_restore)
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
