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
import string
import tempfile
from typing import Dict, Iterable, List, NamedTuple, Set, Union

from . import bos, bss, common, ims, s3

from .product_catalog import ProductCatalog
from .types import JsonDict


S3UrlList = List[s3.S3Url]

EXPORTED_DATA_FILENAME = "export.json"
S3_EXPORTED_ARTIFACTS_DIRNAME = "s3_artifacts"

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

class ImsImportExportError(common.ScriptException):
    """
    Base exception class
    """

class ImsJobsRunning(ImsImportExportError):
    """
    Exception raised if trying to do an export or import when IMS jobs are
    underway (and no appropriate override has been specified)
    """

class S3ArtifactNotFound(ImsImportExportError):
    """
    When an S3 artifact is not found
    """

class S3BucketInfo(dict):
    """
    Parsed response to a 'cray artifacts list <bucket>' query
    """

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, bucket_name: str) -> "S3BucketInfo":
        """
        Given an S3 bucket name, queries S3 to list its contents. Returns the
        response as S3BucketInfo object, after validating that it has the format that we expect.
        """
        logging.info("Listing contents of S3 bucket %s", bucket_name)
        bucket_info = s3.list_artifacts(bucket_name)

        # What we get back should be a dict with an 'artifacts' key, which maps to a list of dicts, each
        # of which has data on an S3 artifact in this bucket. This data should include 'Key' and 'Size' fields,
        # where key is a non-empty string and size is a non-negative integer
        bucket_listing=f"listing of '{bucket_name}' S3 bucket"
        common.expected_format(bucket_info, f"Artifact {bucket_listing}", dict)
        try:
            bucket_artifact_list = bucket_info["artifacts"]
        except KeyError as exc:
            msg = f"No '{exc}' field found in {bucket_listing}"
            logging.error(msg, exc_info=exc)
            raise common.ScriptException(msg) from exc
        common.expected_format(bucket_artifact_list, f"'artifact' field value in {bucket_listing}", list)

        all_keys = set()
        for artifact in bucket_artifact_list:
            common.expected_format(artifact, f"Artifact in {bucket_listing}", dict)
            try:
                artifact_key = artifact["Key"]
                artifact_size = artifact["Size"]
            except KeyError as exc:
                msg = f"No '{exc}' field found in artifact from {bucket_listing}"
                logging.error(msg, exc_info=exc)
                raise common.ScriptException(msg) from exc
            common.expected_format(artifact_key, f"'Key' field in artifact from {bucket_listing}", str)
            if not artifact_key:
                msg = f"Empty 'Key' field in artifact from {bucket_listing}"
                logging.error(msg)
                raise common.ScriptException(msg)
            common.expected_format(artifact_size, f"'Size' field of '{artifact_key}' artifact from {bucket_listing}", int)
            if artifact_size < 0:
                msg = f"Negative Size({artifact_size}) found for '{artifact_key}' artifact from {bucket_listing}"
                logging.error(msg)
                raise common.ScriptException(msg)
            all_keys.add(artifact_key)

        # Also make sure that all Keys are unique, because otherwise that could cause us problems
        if len(all_keys) != len(bucket_artifact_list):
            msg = f"Duplicate Keys found in artifact {bucket_listing}"
            logging.error(msg)
            raise common.ScriptException(msg)

        return S3BucketInfo(bucket_info)

    def get_artifact(self, s3_url: s3.S3Url) -> JsonDict:
        """
        Returns artifact listing for specified artifact.
        Raises KeyError if not found.
        """
        for artifact in self["artifacts"]:
            if artifact["Key"] == s3_url.key:
                return artifact
        raise S3ArtifactNotFound()


    def has_artifact(self, s3_url: s3.S3Url) -> bool:
        """
        Returns True if artifact is in bucket.
        Returns False otherwise.
        """
        try:
            self.get_artifact(s3_url)
        except S3ArtifactNotFound:
            return False
        return True


    def get_artifact_size(self, s3_url: s3.S3Url) -> int:
        """
        Returns the size of the artifact.
        Raises an exception if not found
        """
        return self.get_artifact(s3_url)["Size"]


class S3BucketListings(dict):
    """
    Mapping from bucket names (str) to S3BucketInfo for that bucket
    """
    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls) -> "S3BucketListings":
        return S3BucketListings({ bucket_name: S3BucketInfo.load_from_system(bucket_name)
                                  for bucket_name in s3.list_buckets() })


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "S3BucketListings":
        """
        Returns a S3BucketListings object populated with the data from json_dict
        """
        return S3BucketListings({ bucket_name: S3BucketInfo(bucket_info)
                                  for bucket_name, bucket_info in json_dict.items() })


    def artifact_exists(self, s3_url: Union[s3.S3Url, None], load_if_needed: bool) -> bool:
        """
        If s3_url is None, return False.

        If a listing for the bucket for the specified s3_url does not exist in our dict, then:
        * If load_if_needed is False, raise a KeyError. Otherwise query S3 to get the listing for
          the bucket and proceed.

        Call has_artifact for the specified s3_url on the bucket listing
        """
        # Check to see if there is an associated S3 artifact
        if s3_url is None:
            return False
        # Check to see if this S3 artifact actually exists
        try:
            s3_bucket_listing = self[s3_url.bucket]
        except KeyError:
            if not load_if_needed:
                raise
            # Need to get this listing
            s3_bucket_listing = S3BucketInfo.load_from_system(s3_url.bucket)
            self[s3_url.bucket] = s3_bucket_listing
        return s3_bucket_listing.has_artifact(s3_url)


class ImsDeletedData(NamedTuple):
    images: ims.ImsObjectMap
    public_keys: ims.ImsObjectMap
    recipes: ims.ImsObjectMap

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls) -> "ImsDeletedData":
        """
        Collects the information on the deleted resources in IMS and returns an ImsDeletedData
        object populated with it.
        """
        logging.info("Recording list of deleted IMS images")
        deleted_images = ims.list_deleted_images()
        logging.info("Recording list of deleted IMS public keys")
        deleted_public_keys = ims.list_deleted_public_keys()
        logging.info("Recording list of deleted IMS recipes")
        deleted_recipes = ims.list_deleted_recipes()
        return ImsDeletedData(
            images=ims.ImsObjectMap.from_list("IMS deleted image list", deleted_images),
            public_keys=ims.ImsObjectMap.from_list("IMS deleted public key list", deleted_public_keys),
            recipes=ims.ImsObjectMap.from_list("IMS deleted recipe list", deleted_recipes)
        )

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "ImsDeletedData":
        """
        Returns an ImsDeletedData object populated with the data from json_dict
        """
        return ImsDeletedData(images=ims.ImsObjectMap(json_dict["images"]),
                              public_keys=ims.ImsObjectMap(json_dict["public_keys"]),
                              recipes=ims.ImsObjectMap(json_dict["recipes"]))

    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return { "images": self.images, "public_keys": self.public_keys, "recipes": self.recipes }


class ImsData(NamedTuple):
    deleted: Union[None, ImsDeletedData]
    images: ims.ImsObjectMap
    jobs: ims.ImsObjectMap
    public_keys: ims.ImsObjectMap
    recipes: ims.ImsObjectMap

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, include_deleted: bool, ignore_running_jobs: bool = True) -> "ImsData":
        """
        Collects the information on the resources in IMS and returns an ImsData
        object populated with it.
        If ignore_running_jobs is False, then raise ImsJobsRunning exception if any IMS jobs are currently running.
        """
        logging.info("Recording list of IMS jobs")
        jobs = ims.list_jobs()
        if not ignore_running_jobs:
            jobs_running = False
            for msg in get_running_jobs(jobs):
                jobs_running = True
                logging.error(msg)
            if jobs_running:
                raise ImsJobsRunning()
        logging.info("Recording list of IMS images")
        images = ims.list_images()
        logging.info("Recording list of IMS public keys")
        public_keys = ims.list_public_keys()
        logging.info("Recording list of IMS recipes")
        recipes = ims.list_recipes()
        return ImsData(
            deleted=ImsDeletedData.load_from_system() if include_deleted else None,
            images=ims.ImsObjectMap.from_list("IMS image list", images),
            jobs=ims.ImsObjectMap.from_list("IMS job list", jobs),
            public_keys=ims.ImsObjectMap.from_list("IMS public key list", public_keys),
            recipes=ims.ImsObjectMap.from_list("IMS recipe list", recipes)
        )

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "ImsData":
        """
        Returns an ImsData object populated with the data from json_dict
        """
        return ImsData(
            deleted = None if json_dict["deleted"] is None else ImsDeletedData.load_from_json(json_dict["deleted"]),
            images=ims.ImsObjectMap(json_dict["images"]), jobs=ims.ImsObjectMap(json_dict["jobs"]),
            public_keys=ims.ImsObjectMap(json_dict["public_keys"]), recipes=ims.ImsObjectMap(json_dict["recipes"])
        )

    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return { "deleted": None if self.deleted is None else self.deleted.jsondict,
                 "images": self.images, "jobs": self.jobs, "public_keys": self.public_keys, "recipes": self.recipes }

    @property
    def any_images_keys_recipes(self) -> bool:
        """
        Returns True if any images, recipes, or public keys (not counting deleted ones) are in this object
        """
        return bool(self.images) or bool(self.public_keys) or bool(self.recipes)


    def running_jobs(self) -> bool:
        """
        Returns False if no jobs exist whose status is something other than 'error' or 'success'.
        Returns True otherwise, and also logs errors with details on the applicable jobs.
        """
        # Make sure no jobs are currently running
        jobs_running = False
        for msg in get_running_jobs(self.jobs.values()):
            jobs_running = True
            logging.error(msg)
        return jobs_running


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    def update_with_exported_data(self, exported_ims_data: "ImsData") -> None:
        """
        Update the current IMS data with the exported IMS data.
        Note that this only applies to non-deleted images, public keys, and recipes.
        Non-deleted jobs and all deleted resources are ignored in the exported data
        and left unchanged in the current data.
        """
        self.images.update(exported_ims_data.images)
        self.public_keys.update(exported_ims_data.public_keys)
        self.recipes.update(exported_ims_data.recipes)


class S3Data(NamedTuple):
    artifacts: Dict[s3.S3Url, JsonDict]
    buckets: S3BucketListings

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, outdir: str, ims_data: ImsData,
                         extra_s3_urls: Union[None, S3UrlList] = None) -> "S3Data":
        """
        For all S3 artifacts associated with the specified IMS data (directly or indirectly), download
        the artifacts to the specified directory and store S3 metadata about the artifacts and their buckets.
        Return an S3Data object populated with this information.
        """
        logging.info("Loading data from S3")
        recipe_s3_urls = ims_data.recipes.get_s3_urls()
        image_s3_urls = ims_data.images.get_s3_urls()
        if ims_data.deleted is not None:
            logging.debug("Importing S3 data for deleted IMS resources as well")
            recipe_s3_urls.update(ims_data.deleted.recipes.get_s3_urls())
            image_s3_urls.update(ims_data.deleted.images.get_s3_urls())
        # For any BOS, BSS, or product catalog links, if they end in 'manifest.json', we consider them
        # to be image links. Otherwise we consider them recipe links (which in this context really just
        # means not manifests)
        if extra_s3_urls:
            for s3_url in extra_s3_urls:
                if s3_url[-13:] == "manifest.json":
                    image_s3_urls.add(s3_url)
                else:
                    recipe_s3_urls.add(s3_url)

        return S3Data._export_s3(outdir=outdir, image_s3_urls=image_s3_urls, recipe_s3_urls=recipe_s3_urls)


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "S3Data":
        """
        Converts S3 URL strings in JSON dict to s3.S3Url objects.
        Converts buckets field from JSON dict to S3BucketListings object.
        Creates and returns S3Data object populated with the result.
        """
        new_artifacts = {}
        for s3_url, artifact_data in json_dict["artifacts"].items():
            if "manifest_links" in artifact_data:
                new_manifest_links = [ s3.S3Url(mlink) for mlink in artifact_data["manifest_links"] ]
                artifact_data["manifest_links"] = new_manifest_links
            new_artifacts[s3.S3Url(s3_url)] = artifact_data
        return S3Data(artifacts=new_artifacts, buckets=S3BucketListings.load_from_json(json_dict["buckets"]))


    @property
    def downloaded_artifact_relpaths(self) -> List[str]:
        """
        Return the relative paths to all downloaded S3 artifacts
        """
        return [artifact_data["relpath"] for artifact_data in self.artifacts.values()]


    def downloaded_artifact_relpath(self, s3_url: s3.S3Url) -> str:
        """
        Returns the relative path for the downloaded artifact for the specified S3 url
        """
        return self.artifacts[s3_url]["relpath"]


    def downloaded_artifact_path(self, s3_url: s3.S3Url, basedir: str) -> str:
        """
        Returns the full path to the downloaded artifact file.
        """
        return os.path.join(basedir, self.downloaded_artifact_relpath(s3_url))


    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return { "artifacts": self.artifacts, "buckets": self.buckets }


    def verify_artifact_files_exist(self, basedir: str, s3_urls: Iterable[s3.S3Url]):
        """
        Verifies the existence of every artifact file associated (directly or indirectly) with an IMS image or recipe
        in the data to be imported
        """
        for s3_url in s3_urls:
            common.validate_file_readable(self.downloaded_artifact_path(s3_url, basedir))


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def _export_s3(cls, outdir: str, image_s3_urls: Iterable[s3.S3Url],
                   recipe_s3_urls: Iterable[s3.S3Url]) -> "S3Data":
        """
        Download the linked S3 artifacts (and indirectly linked artifacts in the manifests) into
        the output directory.
        Return an S3Data object populated with the associated data.
        """
        s3_artifacts = {}

        # Start by downloading the manifests and reading them to extract the S3 links they contain
        indirect_s3_urls = set()
        for s3_url in image_s3_urls:
            relpath = download_s3_artifact(outdir, s3_url)
            child_urls = ims.get_child_urls_from_manifest_file(os.path.join(outdir,relpath))
            s3_artifacts[s3_url] = { "relpath": relpath, "manifest_links": child_urls }
            indirect_s3_urls.update(child_urls)

        undownloaded_s3_urls = recipe_s3_urls.union(indirect_s3_urls).difference(image_s3_urls)

        # Get listings of all S3 buckets
        s3_buckets = S3BucketListings.load_from_system()

        # Before downloading the rest of the artifacts, since we now have the complete list, let's make sure
        # we have enough free space
        verify_free_space(outdir, undownloaded_s3_urls, s3_buckets)

        # Describe the manifest S3 URLs
        for s3_url in image_s3_urls:
            s3_artifacts[s3_url]["describe"] = s3.describe_artifact(s3_url)

        # For all other links, download them and describe them
        for s3_url in undownloaded_s3_urls:
            relpath = download_s3_artifact(outdir, s3_url)
            describe = s3.describe_artifact(s3_url)
            s3_artifacts[s3_url] = { "relpath": relpath, "describe": describe }

        return S3Data(artifacts=s3_artifacts, buckets=s3_buckets)


class ExportedData(NamedTuple):
    bos: Union[None, S3UrlList]
    bss: Union[None, S3UrlList]
    created: str
    ims_data: ImsData
    product_catalog: Union[None, S3UrlList]
    s3_data: Union[None, S3Data]

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, include_deleted: bool, include_bos: bool, include_bss: bool,
                         include_product_catalog: bool, ignore_running_jobs: bool = True,
                         s3_directory: Union[str, None] = None) -> "ExportedData":
        """
        Loads data from IMS (including deleted items, if specified).
        If S3 directory is specified, also download associated S3 artifacts to that directory and collect S3 data.
        """
        created = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
        logging.info("Loading data from IMS")
        ims_data = ImsData.load_from_system(ignore_running_jobs=ignore_running_jobs, include_deleted=include_deleted)
        bos_links = get_all_s3_links_from_bos_session_templates() if include_bos else None
        bss_links = get_all_s3_links_from_bss_boot_parameters() if include_bss else None
        prodcat_links = get_all_s3_links_from_product_catalog() if include_product_catalog else None

        extra_s3_urls = []
        if bos_links:
            extra_s3_urls.extend(bos_links)
        if bss_links:
            extra_s3_urls.extend(bss_links)
        if prodcat_links:
            extra_s3_urls.extend(prodcat_links)

        s3_data = None if s3_directory is None else S3Data.load_from_system(outdir=s3_directory,
                                                                            ims_data=ims_data,
                                                                            extra_s3_urls=extra_s3_urls)
        return ExportedData(created=created, ims_data=ims_data, s3_data=s3_data, bos=bos_links,
                            bss=bss_links, product_catalog=prodcat_links)


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
            return [ s3.S3Url(s3_url) for s3_url in json_list ]

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


    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return { "bos": self.bos, "bss": self.bss, "created": self.created,
                 "ims_data": self.ims_data.jsondict, "product_catalog": self.product_catalog,
                 "s3_data": None if self.s3_data is None else self.s3_data.jsondict }


    @property
    def all_s3_urls(self) -> Set[s3.S3Url]:
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
            logging.info("Uploading %s to S3", s3_url)
            s3.create_artifact(s3_url, self.s3_data.downloaded_artifact_path(s3_url, basedir))


def get_running_jobs(jobs: ims.ImsObjectList) -> List[str]:
    """
    Return a list of strings, one describing each job whose status is something other than error or success/
    Returns an empty list if there are no such jobs.
    """
    running_jobs = []
    for job in jobs:
        try:
            if job["status"] in { "error", "success" }:
                continue
            running_jobs.append(f"Job {job['id']} is not complete (status = {job['status']})")
        except KeyError:
            running_jobs.append(f"Job {job['id']} is not complete (no 'status' field found)")
    return running_jobs


def verify_free_space(outdir: str, remaining_s3_links: Set[s3.S3Url],
                      bucket_info: S3BucketListings) -> None:
    """
    Looks at how much free space is in the specified directory, adds up the total size of the remaining
    artifacts to be downloaded, and raises an exception if we're too close to the limit.
    All sizes used are in bytes, unless otherwise indicated.
    """
    largest_size = 0
    total_size = 0
    for s3_link in remaining_s3_links:
        try:
            artifact_size = bucket_info[s3_link.bucket].get_artifact_size(s3_link)
        except S3ArtifactNotFound as exc:
            msg = f"Artifact key {s3_link.key} not found in listing of S3 bucket {s3_link.bucket}"
            logging.error(msg)
            raise common.ScriptException(msg) from exc
        largest_size = max(artifact_size, largest_size)
        total_size += artifact_size

    # For the total required space, we need enough for all of the artifacts, plus overhead to add the largest into
    # the archive, plus we add in an additional 10MB of space as general overhead.
    required_space = total_size + largest_size + 10*1024*1024
    common.verify_free_space_in_dir(outdir, required_space)


ARTIFACT_BASENAME_CHARS = string.ascii_letters + string.digits + '._-'


def download_s3_artifact(outdir: str, s3_url: s3.S3Url) -> str:
    """
    Downloads the specified S3 URL to a subdirectory of the specified artifact directory.
    Returns the relative path to the downloaded artifact in outdir
    """

    # Convert the key portion of the S3 URL to a filename consisting of
    # only letters, numbers, periods, underscores, or dashes
    # Do this by:
    # 1) Replace all / with _
    # 2) Remove all characters other than letters, numbers, or . _ -
    artifact_basename = ''.join([c for c in s3_url.key.replace('/','_') if c in ARTIFACT_BASENAME_CHARS])
    if not artifact_basename:
        # In this unlikely event, just give a generic name
        artifact_basename = "artifact"
    artifact_subdir = os.path.join(S3_EXPORTED_ARTIFACTS_DIRNAME, s3_url.bucket)
    artifact_dir = os.path.join(outdir, artifact_subdir)
    os.makedirs(artifact_dir, exist_ok=True)
    artifact_file_path = os.path.join(artifact_dir, artifact_basename)
    if os.path.exists(artifact_file_path):
        # Need to choose a different name
        artifact_file_path = tempfile.mkstemp(prefix=artifact_basename, dir=artifact_dir)[1]
        artifact_basename = os.path.basename(artifact_file_path)
    logging.info("Downloading %s to '%s'", s3_url, artifact_file_path)
    s3.get_artifact(s3_url, artifact_file_path)
    return os.path.join(artifact_subdir, artifact_basename)


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
    return [ s3.S3Url(s3_url) for s3_url in set(kp_re_prog.findall(param_string)) ]


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
    for template in bos.list_v2_session_templates():
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
            s3_url = s3.S3Url(bs_path)
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
            s3_url = s3.S3Url(bss_bootparam_entry[field])
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
                s3_url = s3.S3Url.from_bucket_and_key(bucket, key)
                logging.debug("Found S3 artifact listed for product '%s' version '%s' in the "
                            "product catalog: %s", product_name, product_version, s3_url)
                if s3_url in s3_links:
                    logging.debug("S3 artifact %s has already been found elsewhere in the product "
                                 "catalog", s3_url)
                    continue
                s3_links.append(s3_url)

    return strip_nonexistent_artifacts(s3_links)
