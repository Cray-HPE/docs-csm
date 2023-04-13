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

import subprocess
import traceback
from typing import Dict, ItemsView, List, Tuple

import logging
import packaging.version
import yaml

from . import api_requests
from . import common
from . import k8s

from .types import JsonObject

K8S_NAMESPACE = "services"
K8S_CONFIG_MAP_NAME = "cray-product-catalog"
CPC_UPDATE_IMAGE = "artifactory.algol60.net/csm-docker/stable/cray-product-catalog-update"

# Used for type hinting
ProductVersionMap = Dict[str, JsonObject]
ProductCatalogMap = Dict[str, ProductVersionMap]
NameIdTupleList = List[Tuple[str, str]]

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


def parse_product_yaml(label: str, yaml_string: str) -> JsonObject:
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


def get_latest_version_from_list(version_string_list: List[str],
                                 strict_versioning: bool = False,
                                 ignore_invalid_versions: bool = True) -> str:
    """
    Given a list of version strings, sort them and return the latest one.

    If strict_versioning is false, then the generic packaging.version.parse() function will be
    used to parse the version strings. Otherwise the packaging.versions.Version() constructor will
    be used. The latter is more strict about what it considers to be a valid version.

    If ignore_invalid_versions is true, any version string keys that are not valid will be excluded
    from the sorting. Otherwise, invalid version strings will raise an exception.

    Returns None if there are no valid version strings.
    """
    logging.debug("get_latest_version_from_list: strict_versioning = %s, "
                  "ignore_invalid_versions=%s, version_string_list=%s", strict_versioning,
                  ignore_invalid_versions, version_string_list)
    version_object_to_string = {}
    for version_string in version_string_list:
        try:
            if strict_versioning:
                version_object = packaging.version.Version(version_string)
            else:
                version_object = packaging.version.parse(version_string)
            version_object_to_string[version_object] = version_string
        except packaging.version.InvalidVersion as exc:
            if ignore_invalid_versions:
                logging.debug("get_latest_version_from_list: Ignoring invalid version string '%s'",
                              version_string)
                continue
            log_error_raise_exception(f"Invalid product version string: '{version_string}'", exc)
    if not version_object_to_string:
        logging.debug("get_latest_version_from_list: No valid version strings found")
        return None
    sorted_version_objects = sorted(version_object_to_string.keys())
    latest_version_object = sorted_version_objects[-1]
    # return corresponding string
    latest_version_string = version_object_to_string[latest_version_object]
    logging.debug(
        "get_latest_version_from_list: latest_version_string = '%s'", latest_version_string)
    return latest_version_string


def get_latest_version(product_version_map: ProductVersionMap, *args, **kwargs) -> str:
    """
    Given a product version map from the product catalog, sort the version strings
    and return the latest one, using the get_latest_version_from_list function.
    All additional arguments are passed on to the get_latest_version_from_list function.
    """
    return get_latest_version_from_list(version_string_list=list(product_version_map.keys()),
                                        *args, **kwargs)


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
        self.k8s_client = k8s_client
        self.refresh_data()


    def refresh_data(self):
        """
        Load the config map data from K8s
        """
        self.data = self.k8s_client.get_config_map_data(name=K8S_CONFIG_MAP_NAME,
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
        installed_products_map = {}
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
        return {}

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


    def update_product_images_recipes(self, product_name: str, product_version: str,
                                      image_name_ids: NameIdTupleList = None,
                                      recipe_name_ids: NameIdTupleList = None) -> None:
        """
        Verifies that the specified product and version are in the product catalog.
        Updates the 'images' and 'recipes' fields of the specified version of the specified product,
        using the latest version of the cray-product-catalog-update tool.
        """
        installed_product_map = self.get_installed_products()
        if product_name not in installed_product_map:
            log_error_raise_exception(
                f"update_product_images_recipes: Product '{product_name}' not in product catalog")
        if product_version not in installed_product_map[product_name]:
            log_error_raise_exception(f"update_product_images_recipes: Version '{product_version}'"
                                      f" of product '{product_name}' not in product catalog")
        latest_cpc_update_version = get_latest_cpc_update_version()
        update_content = {}
        if image_name_ids:
            update_content["images"] = { image_name: { "id": image_id }
                                       for image_name, image_id in image_name_ids }
        if recipe_name_ids:
            update_content["recipes"] = { recipe_name: { "id": recipe_id }
                                       for recipe_name, recipe_id in recipe_name_ids }
        # rstrip is to remove trailing newline that yaml adds
        yaml_content_string = yaml.dump(update_content, default_flow_style=True).rstrip()
        podman_cmd = ("podman run --rm --name ncn-cpc --user root -e KUBECONFIG=/.kube/admin.conf "
                      "-e VALIDATE_SCHEMA=true -v /etc/kubernetes:/.kube:ro").split()
        podman_cmd.extend(["-e", f"PRODUCT={product_name}",
                           "-e", f"PRODUCT_VERSION={product_version}",
                           "-e", f"YAML_CONTENT_STRING={yaml_content_string}",
                           f"registry.local/{CPC_UPDATE_IMAGE}:{latest_cpc_update_version}"])
        subprocess.run(podman_cmd, check=True)
        self.refresh_data()


def get_latest_cpc_update_version() -> str:
    """
    Queries Nexus to find the latest version of the following Docker image:
    artifactory.algol60.net/csm-docker/stable/cray-product-catalog-update

    Returns a string with the latest version.
    Returns None if no versions are found.
    Raises an exception if there are errors.
    """
    nexus_search_url = "https://packages.local/service/rest/v1/search"
    search_params = { "repository": "registry", "format": "docker", "name": CPC_UPDATE_IMAGE }
    version_list = []

    while True:
        resp = api_requests.get_retry_validate(expected_status_codes=200, url=nexus_search_url,
                                               add_api_token=False, params=search_params)
        if not resp.text:
            log_error_raise_exception("Nexus search response had 200 status but empty body")
        response_object = resp.json()
        try:
            items = response_object["items"]
        except KeyError as exc:
            log_error_raise_exception(
                f"Nexus search response had 200 status but no 'items' field: {response_object}",
                exc)
        except TypeError as exc:
            log_error_raise_exception(
                f"Nexus search response had 200 status but unexpected type: {exc}", exc)
        if not isinstance(items, list):
            log_error_raise_exception("Nexus search response had 200 status but 'items' field is "
                                      f"type {type(items)}, not list")

        for item in items:
            try:
                item_version = item["version"]
            except KeyError as exc:
                log_error_raise_exception(f"Nexus component has no 'version' field: {item}", exc)
            if not isinstance(item_version, str):
                log_error_raise_exception(
                    f"Nexus component has non-string (type {type(item)}) 'version' field: {item}",
                    exc)
            version_list.append(item_version)

        try:
            continuation_token = response_object["continuationToken"]
        except KeyError:
            continuation_token = None
        if continuation_token:
            # Make another request to get the next page of responses
            search_params["continuationToken"] = continuation_token
            continue
        # Continuation token is None or not set, so no more responses to get
        break

    if not version_list:
        # No versions found
        return None
    return get_latest_version_from_list(version_list)
