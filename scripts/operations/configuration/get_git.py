#! /usr/bin/env python3
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
Retrieves the VCS URI, import_branch, and git commit from the Cray Product Catalog
for a given product version (by default, the latest CSM version). Outputs:
<product version> <VCS URI> <import branch> <git commit>
"""

import argparse
import re

from typing import Tuple

from python_lib.common import ScriptException
from python_lib.product_catalog import ProductCatalog

CLONE_URL_GET_URI_RE = r"^https://[^/]+/(vcs/.*[.]git)$"


def parse_args() -> Tuple[str, str]:
    """
    Parses command-line arguments.
    Returns the name of the product and the desired version (or 'latest')
    """
    parser = argparse.ArgumentParser(
        description="Retrieves the git commit and VCS URI for a product version "
                    "from the Cray Product Catalog")

    parser.add_argument('-n', '--product-name', default='csm',
                        help="The product name (default: csm)")
    parser.add_argument('-v', '--product-version', default='latest',
                        help="The version of the product, or 'latest' (default: latest)")

    args = parser.parse_args()
    return args.product_name, args.product_version


def get_cfs_data(product_name: str, product_version: str) -> Tuple[str, str, str]:
    """
    Returns the product version, VCS clone URI, branch name, and commit from the product
    catalog for the specified product name and version
    """
    prodcat = ProductCatalog()
    if product_version == "latest":
        product_version = prodcat.get_latest_product_version(product_name)
    cfs_info = prodcat.get_product_version_cfs_information(product_name, product_version)
    label = f"{product_name} version {product_version}"
    try:
        clone_url = cfs_info["clone_url"]
        commit = cfs_info["commit"]
        branch = cfs_info["import_branch"]
    except KeyError as exc:
        raise ScriptException(f"No {exc} field found in {label}") from exc
    try:
        clone_uri = re.match(CLONE_URL_GET_URI_RE, clone_url)[1]
    except TypeError as exc:
        raise ScriptException(f"'clone_url' field for {label} has unexpected format: {clone_url}\n") from exc
    if not clone_uri:
        raise ScriptException(f"Blank VCS clone URI found in {label}")
    if not commit:
        raise ScriptException(f"Blank 'commit' field found in {label}")
    if not branch:
        raise ScriptException(f"Blank 'branch' field found in {label}")
    return product_version, clone_uri, branch, commit


def main():
    """ Main function """
    product_name, product_version = parse_args()
    product_version, clone_uri, branch, commit = get_cfs_data(product_name, product_version)
    print(f"{product_version} {clone_uri} {branch} {commit}")


if __name__ == "__main__":
    main()
