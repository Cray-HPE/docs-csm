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
Module relating to mapping old IMS IDs and S3 etags to new ones
"""

import copy
import json

from collections import ChainMap
from typing import Dict, IO, NamedTuple

from .bos_session_templates import BosSessionTemplate, BosSessionTemplateBootSets

StringMap = Dict[str, str]

class ImsIdEtagMaps(NamedTuple):
    etags: StringMap
    image_ids: StringMap
    recipe_ids: StringMap

class ImsIdMapFileFormatError(Exception):
    pass

def apply_string_replacements(target_string: str, *replacements: StringMap) -> str:
    """
    Applies the specified replacements to the target string, and returns the result (which
    may just be the original string, in the case that no matches were found). The replacements
    are applied in order by length of the source pattern (the one being replaced), from longest
    to shortest. This is to ensure that the longest possible matches are replaced first, to handle
    the case where one source pattern is a substring of another source pattern.

    No care is taken to ensure that new matches are not created as the replacements are
    underway -- the assumption is that the strings being replaced will not run afoul of this.
    If they do, behavior is not predictable.
    """
    all_replacements = ChainMap(*replacements)
    new_string = target_string
    # Do replacements starting with longest strings first, in case some are substrings of others
    for key, value in sorted(all_replacements.items(), key=lambda kv: len(kv[0]), reverse=True):
        new_string = new_string.replace(key, value)
    return new_string

def update_session_template(session_template: BosSessionTemplate,
                            replacements: ImsIdEtagMaps) -> BosSessionTemplate:
    """
    Return a copy of the BOS session template with the specified replacements made to the
    fields which could feasibly contain either an IMS ID or S3 etag value.

    See the apply_string_replacements function for details and caveats about how the replacements
    are done.
    """
    def update_boot_sets(boot_sets: BosSessionTemplateBootSets) -> BosSessionTemplateBootSets:
        """
        Return a copy of the BOS session template boot sets with the specified replacements made to
        the fields which could feasibly contain either an IMS ID or S3 etag value.
        """
        new_boot_sets = {}
        for bs_name, bs_data in boot_sets.items():
            # For a boot set, it is possible that the name of the boot set itself contains
            # an IMS ID or S3 etag.
            new_bs_name = apply_string_replacements(bs_name, replacements.etags,
                                                    replacements.image_ids,
                                                    replacements.recipe_ids)

            # For the boot set data, the fields which may require replacement are:
            # path (image IDs only), etag (etag only), kernel_parameters (image IDs only)
            new_bs_data = copy.deepcopy(bs_data)
            for bs_key, bs_value in bs_data.items():
                # Only need to do replacements if the value is non-empty
                if not bs_value:
                    continue
                if bs_key == "etag":
                    new_bs_data["etag"] = apply_string_replacements(bs_value, replacements.etags)
                    continue
                if bs_key not in { "path", "kernel_parameters" }:
                    continue
                new_bs_data[bs_key] = apply_string_replacements(bs_value,
                                                                replacements.image_ids)
            new_boot_sets[new_bs_name] = new_bs_data
        return new_boot_sets

    new_session_template = copy.deepcopy(session_template)
    # The fields which may require replacements are:
    # name, description, and boot_sets
    for st_key, st_value in session_template.items():
        # Only need to worry about replacements in the case where the value is non-empty
        if not st_value:
            continue
        if st_key == "boot_sets":
            new_session_template["boot_sets"] = update_boot_sets(st_value)
            continue
        if not st_key in { "description", "name" }:
            continue
        new_session_template[st_key] = apply_string_replacements(st_value, replacements.etags,
                                                                 replacements.image_ids,
                                                                 replacements.recipe_ids)

    return new_session_template

def load_ims_id_map(input_file_stream: IO) -> ImsIdEtagMaps:
    """
    Loads the specified file as JSON and extracts the IMS image and recipe ID maps from it,
    as well as the S3 etag map.
    Returns a named tuple containing 3 dictionaries:
    1) A mapping from old S3 etags to new S3 etags
    2) A mapping from old IMS image IDs to new IMS image IDs
    3) A mapping from old IMS recipe IDs to new IMS recipe IDs
    Raises ImsIdMapFileFormatError on error.
    """
    map_file_name = input_file_stream.name
    ims_id_map_file_contents = json.load(input_file_stream)
    try:
        etag_map = ims_id_map_file_contents["etag_map"]
    except KeyError as exc:
        raise ImsIdMapFileFormatError(
            f"No 'etag_map' field found in IMS ID map file '{map_file_name}'") from exc
    except TypeError as exc:
        raise ImsIdMapFileFormatError(
            f"Data in IMS ID map file '{map_file_name}' is of unexpected type: {exc}") from exc

    if not isinstance(etag_map, dict):
        raise ImsIdMapFileFormatError("Data in 'etag_map' field of IMS ID map file "
            f"'{map_file_name}' is of unexpected type: {type(etag_map)}")

    try:
        id_maps = ims_id_map_file_contents["id_maps"]
    except KeyError as exc:
        raise ImsIdMapFileFormatError(
            f"No 'id_maps' field found in IMS ID map file '{map_file_name}'") from exc

    def get_id_map(key: str) -> StringMap:
        """
        Gets the specified ID map from id_maps
        """
        try:
            key_map = id_maps[key]
        except KeyError as exc:
            raise ImsIdMapFileFormatError(f"No '{key}' field found in 'id_maps' field of IMS ID "
                f"map file '{map_file_name}'") from exc
        except TypeError as exc:
            raise ImsIdMapFileFormatError("Data in 'id_maps' field of IMS ID map file "
                f"'{map_file_name}' is of unexpected type:  {exc}") from exc
        if isinstance(key_map, dict):
            return key_map
        raise ImsIdMapFileFormatError(f"Data in ['id_maps']['{key}'] field of IMS ID map file "
            f"'{map_file_name}' is of unexpected type: {type(key_map)}")

    return ImsIdEtagMaps(etags=etag_map, image_ids=get_id_map("images"),
                         recipe_ids=get_id_map("recipes"))
