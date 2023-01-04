#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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
"""Shared Python function library: Cray product catalog"""

import traceback
from typing import Dict, ItemsView

import logging
import packaging.version
import yaml

from . import common
from . import k8s

from .types import JSONObject

K8S_NAMESPACE = "services"
K8S_CONFIG_MAP_NAME = "cray-product-catalog"

# Used for type hinting
ProductVersionMap = Dict[str, JSONObject]
ProductCatalogMap = Dict[str, ProductVersionMap]


def log_error_raise_exception(msg: str, parent_exception: Exception = None) -> None:
    """
    1) If a parent exception is passed in, make a debug log entry with its stack trace.
    2) Log an error with the specified message.
    3) Raise a ScriptException with the specified message (from the parent exception, if
       specified)
    """
    if parent_exception is not None:
        logging.debug(traceback.format_exc())
    logging.error(msg)
    if parent_exception is None:
        raise common.ScriptException(msg)
    raise common.ScriptException(msg) from parent_exception


def parse_product_yaml(label: str, yaml_string: str) -> JSONObject:
    """
    Converts the YAML string for a product catalog product entry into its
    dictionary form. Raises an exception if there are problems.
    """
    try:
        decoded_yaml = yaml.safe_load(yaml_string)
    except (AttributeError, yaml.scanner.ScannerError) as exc:
        log_error_raise_exception(
            f"Error decoding YAML data from {label}", exc)
    # Ensure that we are actually returning a dictionary
    try:
        return {key: value for key, value in decoded_yaml.items()}
    except (AttributeError, TypeError) as exc:
        # Attribute error if 'items' attribute does not exist
        # Type error if 'items' is not callable
        log_error_raise_exception(
            f"YAML data from {label} has an unexpected format", exc)


def get_latest_version(product_version_map: ProductVersionMap,
                       strict_versioning: bool = False,
                       ignore_invalid_versions: bool = True) -> str:
    """
    Given a product version map from the product catalog, sort the version strings
    and return the latest one.

    If strict_versioning is false, then the generic packaging.version.parse() function will be
    used to parse the version strings. Otherwise the packaging.versions.Version() constructor will
    be used. The latter is more strict about what it considers to be a valid version.

    If ignore_invalid_versions is true, any version string keys that are not valid will be excluded
    from the sorting. Otherwise, invalid version strings will raise an exception.

    Returns None if there are no valid version strings.
    """
    all_version_strings = list(product_version_map.keys())
    logging.debug("get_latest_version: strict_versioning = %s, ignore_invalid_versions=%s, "
                  "all_version_strings=%s", strict_versioning, ignore_invalid_versions,
                  all_version_strings)
    version_object_to_string = dict()
    for version_string in all_version_strings:
        try:
            if strict_versioning:
                version_object = packaging.version.Version(version_string)
            else:
                version_object = packaging.version.parse(version_string)
            version_object_to_string[version_object] = version_string
        except packaging.version.InvalidVersion as exc:
            if ignore_invalid_versions:
                logging.debug("get_latest_version: Ignoring invalid version string '%s'",
                              version_string)
                continue
            log_error_raise_exception(
                f"Invalid product version string in Cray product catalog: '{version_string}'", exc)
    if not version_object_to_string:
        logging.debug("get_latest_version: No valid version strings found")
        return None
    sorted_version_objects = sorted(version_object_to_string.keys())
    latest_version_object = sorted_version_objects[-1]
    # return corresponding string
    latest_version_string = version_object_to_string[latest_version_object]
    logging.debug(
        "get_latest_version: latest_version_string = '%s'", latest_version_string)
    return latest_version_string


class ProductCatalog:
    """
    A snapshot of the current Cray product catalog configmap in Kubernetes.
    """
    def __init__(self, k8s_client: k8s.CoreV1API = None):
        """
        Retrieves the Cray Product Catalog configmap and returns its data field.
        """
        if k8s_client is None:
            k8s_client = k8s.Client()
        self.data = k8s_client.get_config_map_data(name=K8S_CONFIG_MAP_NAME,
                                                   namespace=K8S_NAMESPACE)

    def get_items(self) -> ItemsView:
        """
        Returns an item listing of the data field.
        Raises an exception if there are any problems.
        """
        try:
            return self.data.items()
        except (AttributeError, TypeError) as exc:
            # Attribute error if 'items' attribute does not exist
            # Type error if 'items' is not callable
            log_error_raise_exception(f"{K8S_NAMESPACE}/{K8S_CONFIG_MAP_NAME} Kubernetes configmap"
                                      " has an unexpected format", exc)

    def get_installed_products(self) -> ProductCatalogMap:
        """
        Returns the product mapping from the Cray Product Catalog configmap.
        Parses the YAML of each product listing. Raises an exception if there
        are any problems.
        """
        label = f"{K8S_NAMESPACE}/{K8S_CONFIG_MAP_NAME} Kubernetes configmap"
        # This could be done in a single return / dictionary construction, but the following is
        # more readable for those unfamiliar with the code, I think.
        installed_products_map = dict()
        for product_name, product_yaml in self.get_items():
            installed_products_map[product_name] = parse_product_yaml(
                label=f"'{product_name}' entry in {label}", yaml_string=product_yaml)
        return installed_products_map

    def get_installed_product_versions(self, requested_product_name: str) -> ProductVersionMap:
        """
        Returns just the specified product entry from the Cray Product Catalog configmap,
        after parsing its YAML. Raises an exception if there are any problems.
        Note that this will not examine other product entries in the configmap (if there
        are any).
        """
        label = f"{K8S_NAMESPACE}/{K8S_CONFIG_MAP_NAME} Kubernetes configmap"
        for product_name, product_yaml in self.get_items():
            if product_name == requested_product_name:
                return parse_product_yaml(label=f"'{requested_product_name}' entry in {label}",
                                          yaml_string=product_yaml)
        # Return an empty mapping if no versions are installed
        return dict()

    def get_installed_csm_versions(self) -> ProductVersionMap:
        """
        CSM-specific wrapper for get_installed_product_versions
        """
        return self.get_installed_product_versions("csm")

    def get_latest_cfs_information(self, product_name: str) -> Dict[str, str]:
        """
        Returns the configuration data mapping from the latest installed version of the specified
        product
        """
        label = (f"'{product_name}' entry in {K8S_NAMESPACE}/{K8S_CONFIG_MAP_NAME} "
                 "Kubernetes configmap")
        installed_version_map = self.get_installed_product_versions(
            product_name)
        latest_version_string = get_latest_version(installed_version_map)
        try:
            return installed_version_map[latest_version_string]["configuration"]
        except KeyError as exc:
            log_error_raise_exception(
                f"No 'configuration' field found in {label}", exc)

    def get_latest_csm_cfs_information(self) -> Dict[str, str]:
        """
        CSM-specific wrapper for get_latest_cfs_information
        """
        return self.get_latest_cfs_information("csm")
