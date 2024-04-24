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

import json
import logging
import os
import string
import tempfile
from typing import Dict, Iterable, List, NamedTuple, Tuple, Union

from python_lib import common, ims, s3
from python_lib.s3 import S3UrlList, S3UrlSet
from python_lib.types import JsonDict

from .defs import S3_EXPORTED_ARTIFACTS_DIRNAME
from .exceptions import S3ArtifactNotFound
from .ims_data import ImsData
from .s3_bucket_listings import S3BucketListings
from .s3_helper import S3TransferRequest
from .s3_helper import download_s3_artifacts as parallel_download_s3_artifacts

S3ArtifactMap = Dict[s3.S3Url, JsonDict]


class S3DataLoadOptions:
    """
    A helper class for the S3Data class.
    """
    def __init__(self, outdir: str, ims_data: ImsData,
                 extra_s3_urls: Union[None, S3UrlList],
                 base_size_in_bytes: int,
                 create_tarfile: bool):

        logging.info("Loading data from S3")
        image_s3_urls, recipe_s3_urls = get_image_recipe_s3_urls(ims_data, extra_s3_urls)
        s3_artifacts = download_manifests(outdir, image_s3_urls)

        # Reading manifests to extract the S3 links they contain
        indirect_s3_urls = get_child_urls_from_manifests(outdir, s3_artifacts)

        undownloaded_s3_urls = recipe_s3_urls.union(indirect_s3_urls).difference(image_s3_urls)
        all_s3_urls = undownloaded_s3_urls.union(image_s3_urls)

        # Get listings of all S3 buckets
        s3_buckets = S3BucketListings.load_from_system()

        base_size_in_bytes += len(json.dumps(S3Data.format_json(None, s3_buckets)))

        # Overestimate and assume 1k space needed per artifact (just for the JSON data, not the downloaded artifact)
        base_size_in_bytes += 1024*len(all_s3_urls)

        self.__additional_space_required, \
        self.__total_space_required = estimate_required_space(
            all_s3_urls=all_s3_urls,
            undownloaded_s3_urls=undownloaded_s3_urls,
            base_size_in_bytes=base_size_in_bytes,
            s3_buckets=s3_buckets,
            create_tarfile=create_tarfile)

        self.__outdir = outdir
        self.__image_s3_urls = image_s3_urls
        self.__undownloaded_s3_urls = undownloaded_s3_urls
        self.__s3_artifacts = s3_artifacts
        self.__s3_buckets = s3_buckets

    @property
    def additional_space_required(self) -> int:
        return self.__additional_space_required

    @property
    def total_space_required(self) -> int:
        return self.__total_space_required

    @property
    def outdir(self) -> str:
        return self.__outdir

    @property
    def image_s3_urls(self) -> S3UrlSet:
        return self.__image_s3_urls

    @property
    def undownloaded_s3_urls(self) -> S3UrlSet:
        return self.__undownloaded_s3_urls

    @property
    def s3_artifacts(self) -> S3ArtifactMap:
        return self.__s3_artifacts

    @property
    def s3_buckets(self) -> S3BucketListings:
        return self.__s3_buckets


class S3Data(NamedTuple):
    artifacts: S3ArtifactMap
    buckets: S3BucketListings

    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls, **s3_data_load_options_kwargs) -> "S3Data":
        """
        For all S3 artifacts associated with the specified IMS data (directly or indirectly), download
        the artifacts to the specified directory and store S3 metadata about the artifacts and their buckets.
        Return an S3Data object populated with this information.
        """
        options = S3DataLoadOptions(**s3_data_load_options_kwargs)

        # The creation of the S3DataLoadOptions has already downloaded some of the data from S3.
        # Before downloading the rest of the artifacts, since we now have the complete list, let's make sure
        # we have enough free space
        common.verify_free_space_in_dir(options.outdir, options.additional_space_required)

        # Describe the manifest S3 URLs
        for s3_url in options.image_s3_urls:
            options.s3_artifacts[s3_url]["describe"] = s3.describe_artifact(s3_url)

        # For all other links, download them and describe them
        for s3_url, relpath in download_s3_artifacts(options.outdir,
                                                     options.undownloaded_s3_urls).items():
            describe = s3.describe_artifact(s3_url)
            options.s3_artifacts[s3_url] = { "relpath": relpath, "describe": describe }

        return cls(artifacts=options.s3_artifacts, buckets=options.s3_buckets)


    @classmethod
    def estimate_size(cls, **s3_data_load_options_kwargs) -> int:
        """
        Return an estimated size in bytes of the S3 data, if it were downloaded
        """
        return S3DataLoadOptions(**s3_data_load_options_kwargs).total_space_required


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


    @classmethod
    def format_json(cls, artifacts: dict, buckets: S3BucketListings) -> JsonDict:
        return { "artifacts": artifacts, "buckets": buckets }


    @property
    def jsondict(self) -> JsonDict:
        """
        Return a JSON dict representation of this object
        """
        return self.format_json(self.artifacts, self.buckets)


    def verify_artifact_files_exist(self, basedir: str, s3_urls: Iterable[s3.S3Url]):
        """
        Verifies the existence of every artifact file associated (directly or indirectly) with an IMS image or recipe
        in the data to be imported
        """
        for s3_url in s3_urls:
            common.validate_file_readable(self.downloaded_artifact_path(s3_url, basedir))

def get_image_recipe_s3_urls(ims_data: ImsData,
                             extra_s3_urls: Union[None, S3UrlList]) -> Tuple[S3UrlSet, S3UrlSet]:
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

    return image_s3_urls, recipe_s3_urls


def download_manifests(outdir: str, image_s3_urls: S3UrlSet) -> S3ArtifactMap:
    if not image_s3_urls:
        return {}
    s3_urls_to_relpaths = download_s3_artifacts(outdir, image_s3_urls)
    return { s3_url: {  "relpath": relpath } for s3_url, relpath in s3_urls_to_relpaths.items() }


def get_child_urls_from_manifests(outdir: str, s3_artifacts: S3ArtifactMap) -> S3UrlSet:
    indirect_s3_urls = set()
    for s3_artifact_data in s3_artifacts.values():
        relpath = s3_artifact_data["relpath"]
        child_urls = ims.get_child_urls_from_manifest_file(os.path.join(outdir,relpath))
        s3_artifact_data["manifest_links"] = child_urls
        indirect_s3_urls.update(child_urls)
    return indirect_s3_urls


def estimate_required_space(all_s3_urls: S3UrlSet, undownloaded_s3_urls: S3UrlSet,
                            base_size_in_bytes: int, s3_buckets: S3BucketListings,
                            create_tarfile: bool) -> Tuple[int, int]:
    largest_size, overall_size, additional_size = [ base_size_in_bytes ] * 3
    for s3_link in all_s3_urls:
        try:
            artifact_size = s3_buckets[s3_link.bucket].get_artifact_size(s3_link)
        except S3ArtifactNotFound as exc:
            msg = f"Artifact key {s3_link.key} not found in listing of S3 bucket {s3_link.bucket}"
            logging.error(msg)
            raise common.ScriptException(msg) from exc
        largest_size = max(artifact_size, largest_size)
        overall_size += artifact_size
        if s3_link in undownloaded_s3_urls:
            additional_size += artifact_size

    # For the total required space, we need enough for all of the artifacts...

    if create_tarfile:
        # ... plus overhead to add the largest into the archive
        overall_size += largest_size
        additional_size += largest_size

    # plus we add in an additional 10MB of space as general overhead.
    overall_size+=10*1024*1024
    additional_size+=10*1024*1024

    return additional_size, overall_size


ARTIFACT_BASENAME_CHARS = string.ascii_letters + string.digits + '._-'

def generate_artifact_local_path(outdir: str, s3_url: s3.S3Url) -> Tuple[str, str]:
    """
    Return the full path for the artifact file in outdir, and its relative path
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
    return artifact_file_path, os.path.join(artifact_subdir, artifact_basename)


def download_s3_artifact(outdir: str, s3_url: s3.S3Url) -> str:
    """
    Downloads the specified S3 URL to a subdirectory of the specified artifact directory.
    Returns the relative path to the downloaded artifact in outdir
    """
    artifact_file_path, artifact_file_relpath = generate_artifact_local_path(outdir, s3_url)
    logging.info("Downloading %s to '%s'", s3_url, artifact_file_path)
    s3.get_artifact(s3_url, artifact_file_path)
    return artifact_file_relpath


def download_s3_artifacts(outdir: str, s3_urls: Iterable[s3.S3Url]) -> Dict[s3.S3Url, str]:
    """
    Downloads the specified S3 URLs to a subdirectory of the specified artifact directory.
    Returns a mapping from each S3 URL to the relative path of the downloaded artifact in outdir
    """
    s3_download_requests = []
    url_relpath_map = {}
    for s3_url in s3_urls:
        artifact_file_path, artifact_file_relpath = generate_artifact_local_path(outdir, s3_url)
        url_relpath_map[s3_url] = artifact_file_relpath
        logging.debug("Add %s to list of required S3 downloads", s3_url)
        s3_download_requests.append(S3TransferRequest(url=s3_url, filepath=artifact_file_path))

    if s3_download_requests:
        logging.info("Starting parallel S3 downloads for %d artifacts", len(s3_download_requests))
        parallel_download_s3_artifacts(s3_download_requests)
        logging.info("Parallel S3 download complete")
    else:
        logging.debug("Nothing to download from S3")
    return url_relpath_map
