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
"""Shared Python function library: IMS import/export"""

import datetime
import json
import logging
import os
import string
import tempfile
from typing import Dict, Iterable, List, NamedTuple, Set, Union

from . import common
from . import ims
from . import s3

from .types import JsonDict


EXPORTED_DATA_FILENAME = "export.json"
S3_EXPORTED_ARTIFACTS_DIRNAME = "s3_artifacts"

# Format of EXPORTED_DATA_FILENAME
# {
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
#   "s3": {
#     "artifacts": {
#       <S3Url>: {
#         "describe": <result of "cray artifacts describe" on the S3Url>,
#         "relpath": <relative path to downloaded artifact file>,
#         "manifest_links": <List of S3URLs contained in this manifest -- field only present for manifest artifacts>
#       } for all S3Url associated with IMS
#     },
#     "buckets": <mapping from S3 bucket name to result of "cray artifacts list" on it>
#   }
# }
#
# ims.deleted field may map to None, for cases where deleted IMS objects not backed update
# s3 field may map to None, for cases where only IMS data is backed up

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

# Parsed response to a 'cray artifacts list <bucket>' query
class S3BucketInfo(dict):
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
    buckets: Dict[str, S3BucketInfo]

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, outdir: str, ims_data: ImsData) -> "S3Data":
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
        return S3Data._export_s3(outdir=outdir, image_s3_urls=image_s3_urls, recipe_s3_urls=recipe_s3_urls)


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "S3Data":
        """
        Converts S3 URL strings in JSON dict to s3.S3Url objects.
        Creates and returns S3Data object populated with the result.
        """
        new_artifacts = {}
        for s3_url, artifact_data in json_dict["artifacts"].items():
            if "manifest_links" in artifact_data:
                new_manifest_links = [ s3.S3Url(mlink) for mlink in artifact_data["manifest_links"] ]
                artifact_data["manifest_links"] = new_manifest_links
            new_artifacts[s3.S3Url(s3_url)] = artifact_data
        return S3Data(artifacts=new_artifacts, buckets=json_dict["buckets"])


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
        all_s3_urls = undownloaded_s3_urls.union(image_s3_urls)

        # Get listings of buckets for all S3 links we're concerned with
        buckets_names = { s3_link.bucket for s3_link in all_s3_urls }
        s3_buckets = { bucket_name: S3BucketInfo.load_from_system(bucket_name) for bucket_name in buckets_names }

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
    created: str
    ims_data: ImsData
    s3_data: Union[None, S3Data]

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, include_deleted: bool, ignore_running_jobs: bool = True,
                         s3_directory: Union[str, None] = None) -> "ExportedData":
        """
        Loads data from IMS (including deleted items, if specified).
        If S3 directory is specified, also download associated S3 artifacts to that directory and collect S3 data.
        """
        created = datetime.datetime.now().strftime("%Y%m%d%H%M%S.%f")
        logging.info("Loading data from IMS")
        ims_data = ImsData.load_from_system(ignore_running_jobs=ignore_running_jobs, include_deleted=include_deleted)
        s3_data = None if s3_directory is None else S3Data.load_from_system(outdir=s3_directory, ims_data=ims_data)
        return ExportedData(created=created, ims_data=ims_data, s3_data=s3_data)


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_directory(cls, tarfile_dir: str) -> "ExportedData":
        """
        Validate that exported data file exists in the specified directory.
        Load the JSON data from it and uses it to instantiate a new ExportData object.
        Return that object
        """
        data_file = os.path.join(tarfile_dir, EXPORTED_DATA_FILENAME)
        common.validate_file_readable(data_file)
        logging.info("Reading in JSON data from '%s'", data_file)
        with open(data_file, "rt") as dfile:
            json_data = json.load(dfile)
        return ExportedData(
            created=json_data["created"], ims_data=ImsData.load_from_json(json_data["ims_data"]),
            s3_data=None if json_data["s3_data"] is None else S3Data.load_from_json(json_data["s3_data"])
        )


    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return { "created": self.created, "ims_data": self.ims_data.jsondict,
                 "s3_data": None if self.s3_data is None else self.s3_data.jsondict }


    @property
    def all_s3_urls(self) -> Set[s3.S3Url]:
        """
        Returns the S3 URLs for all artifacts associated (directly or indirectly) with non-deleted
        IMS images and recipes
        """
        image_urls = self.ims_data.images.get_s3_urls()
        all_urls = image_urls.union(self.ims_data.recipes.get_s3_urls())
        # Parse the manifest links
        for s3_url in image_urls:
            all_urls.update(self.s3_data.artifacts[s3_url]["manifest_links"])
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
                      bucket_info: Dict[str, S3BucketInfo]) -> None:
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
