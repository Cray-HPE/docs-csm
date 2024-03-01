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

import logging

from python_lib import common, s3
from python_lib.types import JsonDict

from .exceptions import S3ArtifactNotFound


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
