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
"""Shared Python function library: IMS import/export"""

import datetime
import json
import logging
import os
import re
from typing import NamedTuple, Union

from python_lib import bos, bss, common, s3
from python_lib.s3 import S3Url, S3UrlList, S3UrlSet
from python_lib.product_catalog import ProductCatalog
from python_lib.types import JsonDict

from .defs import EXPORTED_DATA_FILENAME
from .ims_data import ImsData
from .s3_data import S3Data
from .s3_helper import S3TransferRequest, create_s3_artifacts

# Format of EXPORTED_DATA_FILENAME
# {
#   "bos": [ all S3Url found in BOS session templates ],
#   "bss": [ all S3Url found in BSS boot parameters ],
#   "created": <timestamp>,
#   "ims": {
#     "images": <Map from IMS ID to associated object from result of GET to v3/images>,
#     "jobs": <Map from IMS ID to associated object from result of GET to v3/jobs>,
#     "public_keys": <Map from IMS ID to associated object from result of GET to v3/public_keys>,
#     "recipes": <Map from IMS ID to associated object from result of GET to v3/recipes>
#     "deleted": {
#       "images": <Map from IMS ID to associated object from result of GET to v3/deleted/images>,
#       "public_keys": <Map from IMS ID to associated object from result of GET to v3/deleted/public_keys>,
#       "recipes": <Map from IMS ID to associated object from result of GET to v3/deleted/recipes>
#     }
#   },
#   "product_catalog": [ all S3Url found in product catalog ],
#   "s3": {
#     "artifacts": {
#       <S3Url>: {
#         "describe": <result of "cray artifacts describe" on the S3Url>,
#         "relpath": <relative path to downloaded artifact file-- field only present for artifacts found in
#                     IMS, BOS, BSS, or the product catalog, or included in manifests of such artifacts>,
#         "manifest_links": <List of S3URLs contained in this manifest -- field only present for manifest artifacts
#                            found in IMS, BOS, BSS, or the product catalog>
#       } for S3Urls in S3
#     },
#     "buckets": <mapping from S3 bucket name to result of "cray artifacts list" on it>
#   }
# }
# bos field may map to None or be absent, for cases where its S3 links were not backed up
# bss field may map to None or be absent, for cases where its S3 links were not backed up
# ims.deleted field may map to None, for cases where deleted IMS objects not backed up
# product_catalog field may map to None or be absent, for cases where its S3 links were not backed up
# s3 field may map to None, for cases where only IMS data is backed up
#
# bos, bss, and product_catalog fields are only populated if the s3 field is also populated


class ExportedData(NamedTuple):
    bos: Union[None, S3UrlList]
    bss: Union[None, S3UrlList]
    created: str
    ims_data: ImsData
    product_catalog: Union[None, S3UrlList]
    s3_data: Union[None, S3Data]

    @staticmethod
    def extra_s3_urls(*s3_url_lists: Union[None, S3UrlList]) -> Union[None, S3UrlList]:
        """
        Merge the specified URL lists and return the combined list (or None, if empty)
        """
        extra_s3_urls = []
        for s3_urls in s3_url_lists:
            if s3_urls:
                extra_s3_urls.extend(s3_urls)
        return extra_s3_urls if extra_s3_urls else None


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, create_tarfile: bool, include_deleted: bool, include_bos: bool,
                         include_bss: bool, include_product_catalog: bool,
                         ignore_running_jobs: bool = True,
                         s3_directory: Union[str, None] = None) -> "ExportedData":
        """
        Loads data from IMS (including deleted items, if specified).
        If S3 directory is specified, also download associated S3 artifacts to that directory and collect S3 data.
        """
        created = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
        ims_data = ImsData.load_from_system(ignore_running_jobs=ignore_running_jobs, include_deleted=include_deleted)
        bos_links = get_all_s3_links_from_bos_session_templates() if include_bos else None
        bss_links = get_all_s3_links_from_bss_boot_parameters() if include_bss else None
        prodcat_links = get_all_s3_links_from_product_catalog() if include_product_catalog else None
        extra_s3_urls = ExportedData.extra_s3_urls(bos_links, bss_links, prodcat_links)

        size_in_bytes = len(json.dumps(cls.format_json(bos_links=bos_links, bss_links=bss_links, created=created,
                                                       ims_data=ims_data, product_catalog_links=prodcat_links,
                                                       s3_data=None)))

        s3_data = None if s3_directory is None else S3Data.load_from_system(outdir=s3_directory,
                                                                            ims_data=ims_data,
                                                                            extra_s3_urls=extra_s3_urls,
                                                                            create_tarfile=create_tarfile,
                                                                            base_size_in_bytes=size_in_bytes)

        return cls(created=created, ims_data=ims_data, s3_data=s3_data, bos=bos_links,
                   bss=bss_links, product_catalog=prodcat_links)


    @classmethod
    def estimate_size(cls, create_tarfile: bool, include_deleted: bool, include_bos: bool,
                      include_bss: bool, include_product_catalog: bool,
                      ignore_running_jobs: bool = True,
                      s3_directory: Union[str, None] = None) -> int:
        """
        Does basically the same thing as load_from_system, up to the point where it knows the total
        size of the S3 artifacts to be included in the export. At that point, return the estimated
        total size (in bytes) of the exported data, and then return.
        """
        created = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
        ims_data = ImsData.load_from_system(ignore_running_jobs=ignore_running_jobs, include_deleted=include_deleted)
        bos_links = get_all_s3_links_from_bos_session_templates() if include_bos else None
        bss_links = get_all_s3_links_from_bss_boot_parameters() if include_bss else None
        prodcat_links = get_all_s3_links_from_product_catalog() if include_product_catalog else None

        size_in_bytes = len(json.dumps(cls.format_json(bos_links=bos_links, bss_links=bss_links, created=created,
                                                       ims_data=ims_data, product_catalog_links=prodcat_links,
                                                       s3_data=None)))

        # If we are not going to be including any S3 artifacts, we're done
        if s3_directory is None:
            return size_in_bytes

        extra_s3_urls = cls.extra_s3_urls(bos_links, bss_links, prodcat_links)
        return S3Data.estimate_size(outdir=s3_directory, ims_data=ims_data,
                                    extra_s3_urls=extra_s3_urls, create_tarfile=create_tarfile,
                                    base_size_in_bytes=size_in_bytes)


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_directory(cls, tarfile_dir: str) -> "ExportedData":
        """
        Validate that exported data file exists in the specified directory.
        Load the JSON data from it and uses it to instantiate a new ExportData object.
        Return that object
        """
        def load_s3url_list(json_list) -> S3UrlList:
            return [ S3Url(s3_url) for s3_url in json_list ]

        data_file = os.path.join(tarfile_dir, EXPORTED_DATA_FILENAME)
        common.validate_file_readable(data_file)
        logging.info("Reading in JSON data from '%s'", data_file)
        with open(data_file, "rt") as dfile:
            json_data = json.load(dfile)
        exported_data_kwargs = {
            "created": json_data["created"],
            "ims_data": ImsData.load_from_json(json_data["ims_data"]),
            "bos": None, "bss": None, "product_catalog": None, "s3_data": None
        }
        for field in [ "bos", "bss", "product_catalog" ]:
            if field in json_data and json_data[field]:
                exported_data_kwargs[field] = load_s3url_list(json_data[field])
        if "s3_data" in json_data and json_data["s3_data"]:
            exported_data_kwargs["s3_data"] = S3Data.load_from_json(json_data["s3_data"])

        return ExportedData(**exported_data_kwargs)


    @classmethod
    def format_json(cls, bos_links: Union[None, S3UrlList], bss_links: Union[None, S3UrlList],
                    created: str, ims_data: ImsData, product_catalog_links: Union[None, S3UrlList],
                    s3_data: Union[None, S3Data]) -> JsonDict:
        return { "bos": bos_links, "bss": bss_links, "created": created,
                 "ims_data": ims_data.jsondict, "product_catalog": product_catalog_links,
                 "s3_data": None if s3_data is None else s3_data.jsondict }


    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return self.format_json(bos_links=self.bos, bss_links=self.bss, created=self.created,
                                ims_data=self.ims_data, product_catalog_links=self.product_catalog,
                                s3_data=self.s3_data)


    @property
    def all_s3_urls(self) -> S3UrlSet:
        """
        Returns the S3 URLs for all artifacts associated (directly or indirectly) with non-deleted
        IMS images and recipes
        """
        all_urls = self.ims_data.recipes.get_s3_urls()

        def add_urls(s3_url_list: Union[None, S3UrlList]) -> None:
            if not s3_url_list:
                return
            all_urls.update(s3_url_list)
            for s3_url in s3_url_list:
                if "manifest_links" in self.s3_data.artifacts[s3_url]:
                    all_urls.update(self.s3_data.artifacts[s3_url]["manifest_links"])

        add_urls(self.ims_data.images.get_s3_urls())
        add_urls(self.bos)
        add_urls(self.bss)
        add_urls(self.product_catalog)

        return all_urls


    def verify_artifact_files_exist(self, basedir: str) -> None:
        """
        Verifies the existence of every artifact file associated (directly or indirectly) with an undeleted
        IMS image or recipe
        """
        if self.s3_data is None:
            # Nothing to do
            return
        self.s3_data.verify_artifact_files_exist(basedir, self.all_s3_urls)


    def update_s3(self, basedir: str) -> None:
        """
        For all images and recipes in exported IMS data, upload the associated S3 artifacts (if needed).
        This does not include deleted images and recipes.
        If there are any S3 links included for BOS, BSS, and/or the product catalog, upload those if needed.
        """
        current_s3_bucket_artifact_maps = {}
        s3_upload_requests = []
        for s3_url in self.all_s3_urls:
            try:
                bucket_map = current_s3_bucket_artifact_maps[s3_url.bucket]
            except KeyError:
                bucket_listing = s3.list_artifacts(s3_url.bucket)
                bucket_map = s3.bucket_artifact_map(bucket_listing)
                current_s3_bucket_artifact_maps[s3_url.bucket] = bucket_map
            # Does this artifact already exist in this bucket?
            if s3_url.key in bucket_map:
                logging.debug("%s already exists in S3", s3_url)
                continue
            logging.debug("Add %s to list of required S3 uploads", s3_url)
            s3_upload_requests.append(
                S3TransferRequest(
                    url=s3_url,
                    filepath=self.s3_data.downloaded_artifact_path(s3_url,
                                                                   basedir)))
        if not s3_upload_requests:
            logging.debug("Nothing to upload to S3")
            return
        logging.info("Starting parallel S3 uploads for %d artifacts", len(s3_upload_requests))
        create_s3_artifacts(s3_upload_requests)
        logging.info("Parallel S3 upload complete")


# Bucket names must be between 3 (min) and 63 (max) characters long.
# Bucket names can consist only of lowercase letters, numbers, dots (.), and hyphens (-).
# Bucket names must begin and end with a letter or number.
# (source: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)

# There are a few additional restrictions on bucket names, but we won't worry about them
# for the purposes of making this regex pattern
S3_BUCKET_NAME_REGEX_PATTERN = "[a-z0-9][-.a-z0-9]+[a-z0-9]"

# There are almost no restrictions on legal key names, beyond being 1-1024 bytes in length
# But since we are extracting the S3 path from a kernel parameter string, we will assume that the
# key does not contain a comma, colon, or horizontal whitespace.
S3_ARTIFACT_KEY_REGEX_PATTERN = "[^,: \t]{1,1024}"

KERNEL_PARAMETERS_S3_URL_REGEX_PATTERN = f"[,:=](s3://{S3_BUCKET_NAME_REGEX_PATTERN}/{S3_ARTIFACT_KEY_REGEX_PATTERN})(?:$|[,: \t])"
kp_re_prog = re.compile(KERNEL_PARAMETERS_S3_URL_REGEX_PATTERN)


def s3_links_in_kernel_param_string(param_string: str) -> S3UrlList:
    """
    Returns a list of S3 URLs from the specified kernel parameter string
    """
    return [ S3Url(s3_url) for s3_url in set(kp_re_prog.findall(param_string)) ]


def strip_nonexistent_artifacts(s3_links: S3UrlList) -> S3UrlList:
    """
    For each URL in the list, check if it exists. If not, log a warning.
    Return a list of those that exist.
    """
    s3_client = s3.S3Client()
    s3_links_that_exist = []
    for s3_url in s3_links:
        if not s3_client.artifact_exists(s3_url.bucket, s3_url.key):
            logging.warning("Skipping nonexistent S3 artifact %s", s3_url)
            continue
        s3_links_that_exist.append(s3_url)

    return s3_links_that_exist


def get_all_s3_links_from_bos_session_templates() -> S3UrlList:
    """
    Searches BOS session templates for all S3 links.
    For all that are found, check if they exist in S3, and print
    a warning if they do not.
    Return a list of all that do.
    """
    logging.info("Loading S3 links from BOS session templates")

    s3_links = []
    def found_link(s3_url):
        """
        Append a link to our list, if we haven't found it already
        """
        if s3_url in s3_links:
            logging.debug("S3 artifact %s has already been found elsewhere in a BOS "
                          "session template", s3_url)
            return
        s3_links.append(s3_url)

    logging.info("Scanning BOS session templates for S3 artifact links")
    for template in bos.list_session_templates():
        template_name = template["name"]
        try:
            boot_sets = template["boot_sets"]
        except KeyError:
            logging.warning("Skipping malformed session template '%s' (missing 'boot_sets' field)",
                            template_name)
            logging.debug("Full template: %s", template)
            continue
        if not isinstance(boot_sets, dict):
            logging.warning("Skipping malformed session template '%s' ('boot_sets' should map to "
                            "a dict, but does not)", template_name)
            logging.debug("Full template: %s", template)
            continue
        for bs_name, bs in boot_sets.items():
            if "kernel_parameters" in bs:
                for s3_url in s3_links_in_kernel_param_string(bs["kernel_parameters"]):
                    logging.debug("Found S3 artifact in kernel parameter string of boot set '%s' "
                                 "in session template '%s': %s", bs_name, template_name, s3_url)
                    found_link(s3_url)
            try:
                bs_type = bs["type"]
                bs_path = bs["path"]
            except KeyError as exc:
                logging.warning("Skipping malformed boot set '%s' in session template '%s' "
                                "(missing required '%s' field)", bs_name, template_name, exc)
                logging.debug("Full boot set: %s", bs)
                logging.debug("Full template: %s", template)
                continue
            if bs_type != "s3":
                continue
            s3_url = S3Url(bs_path)
            logging.debug("Found S3 artifact in 'path' field of boot set '%s' in session "
                         "template '%s': %s", bs_name, template_name, s3_url)
            found_link(s3_url)

    return strip_nonexistent_artifacts(s3_links)


def get_all_s3_links_from_bss_boot_parameters() -> S3UrlList:
    """
    Searches BSS boot parameters for all S3 links.
    For all that are found, check if they exist in S3, and print
    a warning if they do not.
    Return a list of all that do.
    """
    logging.info("Loading S3 links from BSS boot parameters")

    s3_links = []
    def found_link(s3_url):
        """
        Append a link to our list, if we haven't found it already
        """
        if s3_url in s3_links:
            logging.debug("S3 artifact %s has already been found elsewhere in a BSS "
                          "boot parameters entry", s3_url)
            return
        s3_links.append(s3_url)

    logging.info("Scanning BSS boot parameters for S3 artifact links")
    for bss_bootparam_entry in bss.get_bootparameters():
        for field in [ "initrd", "kernel" ]:
            if field not in bss_bootparam_entry:
                continue
            s3_url = S3Url(bss_bootparam_entry[field])
            logging.debug("Found S3 link in '%s' field of BSS bootparameter entry: %s", field,
                          s3_url)
            found_link(s3_url)
        if "params" not in bss_bootparam_entry:
            continue
        for s3_url in s3_links_in_kernel_param_string(bss_bootparam_entry["params"]):
            logging.debug("Found S3 link in 'params' field of BSS bootparameter entry: %s", s3_url)
            found_link(s3_url)

    return strip_nonexistent_artifacts(s3_links)


def get_all_s3_links_from_product_catalog() -> S3UrlList:
    """
    Searches the Product Catalog for all S3 links.
    For all that are found, check if they exist in S3, and print
    a warning if they do not.
    Return a list of all that do.
    """
    logging.info("Loading S3 links from Cray product catalog")

    s3_links = []
    logging.debug("Scanning product catalog for S3 artifact links")
    for product_name, product_version_map in ProductCatalog().get_installed_products().items():
        for product_version, product_data in product_version_map.items():
            try:
                s3_artifacts = product_data["component_versions"]["s3"]
            except KeyError:
                logging.debug("No S3 links for product '%s' version '%s' in the product catalog",
                             product_name, product_version)
                continue
            if not isinstance(s3_artifacts, list):
                logging.warning("Skipping malformed 's3' field for product '%s' version '%s' in "
                               "the product catalog (it should be a list, but is not): %s",
                               product_name, product_version, s3_artifacts)
                continue
            for s3_artifact in s3_artifacts:
                if not isinstance(s3_artifact, dict):
                    logging.warning("Skipping malformed 's3' list item for product '%s' version "
                                   "'%s' in the product catalog (it should be a dict, but is "
                                   "not): %s", product_name, product_version, s3_artifact)
                    continue
                try:
                    bucket = s3_artifact["bucket"]
                    key = s3_artifact["key"]
                except KeyError as exc:
                    logging.warning("Skipping malformed 's3' list item for product '%s' version "
                                   "'%s' in the product catalog (missing '%s' field): %s",
                                   product_name, product_version, exc, s3_artifact)
                    continue
                s3_url = S3Url.from_bucket_and_key(bucket, key)
                logging.debug("Found S3 artifact listed for product '%s' version '%s' in the "
                            "product catalog: %s", product_name, product_version, s3_url)
                if s3_url in s3_links:
                    logging.debug("S3 artifact %s has already been found elsewhere in the product "
                                 "catalog", s3_url)
                    continue
                s3_links.append(s3_url)

    return strip_nonexistent_artifacts(s3_links)
