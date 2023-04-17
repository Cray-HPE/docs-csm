#! /usr/bin/env python3
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
Search the Cray Product Catalog for specified IMS IDs and replace them with specified new IDs.
Used both as a standalone script and as a module imported by other modules.
"""

import argparse
import logging
from typing import Dict, Tuple

from python_lib import product_catalog
from python_lib.types import JsonObject

LOGGER = logging.getLogger(__name__)
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
LOGGER.addHandler(ch)

IdChangeMap = Dict[str, str]

class UpdateProductCatalogImsIdsBaseError(Exception):
    pass

def parse_args() -> Tuple[IdChangeMap, IdChangeMap]:
    """
    Parses the command line arguments.
    Returns a tuple of IMS image ID old-to-new map and IMS recipe ID old-to-new map
    """
    parser = argparse.ArgumentParser(description="Searches Cray Product Catalog for instances of "
        "specified old IMS image or recipe ID and replaces them with the specified new ID.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-i', '--image-id', dest='ims_type', action='store_const', const='image',
                       help='Replace IMS image IDs')
    group.add_argument('-r', '--recipe-id', dest='ims_type', action='store_const', const='recipe',
                       help='Replace IMS recipe IDs')
    parser.add_argument('old_ims_id', type=str, help='Old IMS ID to be replaced')
    parser.add_argument('new_ims_id', type=str, help='New IMS ID to replace the old one with')
    parsed_args = parser.parse_args()
    old_new_map = { parsed_args.old_ims_id: parsed_args.new_ims_id }
    if parsed_args.ims_type == 'image':
        return old_new_map, {}
    if parsed_args.ims_type == 'recipe':
        return {}, old_new_map
    # This should never happen, but just in case
    raise UpdateProductCatalogImsIdsBaseError(
        "PROGRAMMING LOGIC ERROR: Unable to determine type of IMS ID to replace")

def get_name_id_replacements(product_name: str, product_version: str,
                             product_version_details: JsonObject, images_or_recipes: str,
                             id_change_map: IdChangeMap) -> product_catalog.NameIdTupleList:
    """
    Looks at the specified product version entry from the Cray Product Catalog.
    Based on the 'images_or_recipes' parameter, looks at the 'images' or 'recipes' field of the
    entry. If no such field exists, then there are no IDs to be updated. If the field exists,
    its contents are scanned for IDs that match ones in the specified id_change_map.
    Returns a list of tuples: (image_or_recipe_name, new_ims_id_for_this_image_or_recipe)
    """
    name_id_list = []
    if not id_change_map:
        # Nothing to do
        return name_id_list
    if not images_or_recipes in product_version_details:
        # No field for images or recipes
        return name_id_list
    prod_ver_imgrec_map = product_version_details[images_or_recipes]

    # The contents of this field should be a dictionary
    if not isinstance(prod_ver_imgrec_map, dict):
        LOGGER.debug("Product catalog entry for '%s' version '%s' contains '%s' field which is "
                     "type %s instead of dict", product_name, product_version, images_or_recipes,
                     str(type(prod_ver_imgrec_map)))
        return name_id_list

    # This dictionary should map image/recipe names to another dictionary, and that
    # second dictionary should include an id field, which maps to the IMS ID for that image/recipe
    # So parse through this and look for any IDs that need to be replaced.

    for imgrec_name, imgrec_data in prod_ver_imgrec_map.items():
        if not isinstance(imgrec_data, dict):
            LOGGER.debug("Product catalog entry for '%s' version '%s' contains %s '%s' with "
                         "unexpected data format: %s", product_name, product_version,
                         images_or_recipes, imgrec_name, str(imgrec_data))
            continue
        if "id" not in imgrec_data:
            LOGGER.debug("Product catalog entry for '%s' version '%s' contains %s '%s' with no "
                         "'id' data: %s", product_name, product_version, images_or_recipes,
                         imgrec_name, str(imgrec_data))
            continue
        imgrec_id = imgrec_data["id"]
        if imgrec_id in id_change_map:
            # This means that this ID was changed during the import
            name_id_list.append((imgrec_name, id_change_map[imgrec_id]))

    return name_id_list

def update_product_catalog(image_id_change_map: IdChangeMap,
                           recipe_id_change_map: IdChangeMap) -> None:
    """
    Update the Cray Product Catalog configmap, replacing any old IMS image or recipe IDs with the
    corresponding new ones.

    This function is intended to be used by other modules that import this one, as well as being
    used within this module.
    """
    if not image_id_change_map and not recipe_id_change_map:
        # No ID changes, so nothing to do
        return
    cpc = product_catalog.ProductCatalog()
    for product_name, product_version_map in cpc.get_installed_products().items():
        for product_version, product_version_details in product_version_map.items():
            image_name_ids = get_name_id_replacements(product_name, product_version,
                                                      product_version_details, "images",
                                                      image_id_change_map)
            recipe_name_ids = get_name_id_replacements(product_name, product_version,
                                                       product_version_details, "recipes",
                                                       recipe_id_change_map)
            # If no IDs changed, we're done with this product version
            if not image_name_ids and not recipe_name_ids:
                continue
            # Update the product catalog accordingly.
            cpc.update_product_images_recipes(product_name=product_name,
                                              product_version=product_version,
                                              image_name_ids=image_name_ids,
                                              recipe_name_ids=recipe_name_ids)

def main() -> None:
    """ Main function """
    image_id_map, recipe_id_map = parse_args()
    update_product_catalog(image_id_map, recipe_id_map)
    LOGGER.info('DONE!')

if __name__ == "__main__":
    main()
