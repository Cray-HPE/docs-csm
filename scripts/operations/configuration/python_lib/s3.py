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
"""Shared Python function library: S3"""

import json
import os
from typing import Dict
from urllib.parse import urlparse

from . import common
from .types import JsonDict


class S3Url(str):
    """
    A string class whose value is standardized through URLparser, and with extra properties
    to display S3 bucket, key, etc

    https://stackoverflow.com/questions/42641315/s3-urls-get-bucket-name-and-path/42641363
    """

    def __new__(cls, url):
        return super().__new__(cls, urlparse(url, allow_fragments=False).geturl())

    def __init__(self, url):
        parsed = urlparse(url, allow_fragments=False)
        self.key = parsed.path.lstrip('/') + '?' + parsed.query if parsed.query else parsed.path.lstrip('/')
        self.bucket = parsed.netloc


def create_artifact(s3_url: S3Url, source_path: str) -> JsonDict:
    """
    Uploads the specified S3 artifact from the specified path
    """
    command = ['cray', 'artifacts', 'create', s3_url.bucket, s3_url.key, source_path, '--format', 'json']
    return json.loads(common.run_command(command))


def delete_artifact(s3_url: S3Url) -> None:
    """
    Deletes the specified S3 artifact
    """
    command = ['cray', 'artifacts', 'delete', s3_url.bucket, s3_url.key]
    common.run_command(command)


def describe_artifact(s3_url: S3Url) -> JsonDict:
    """
    Queries S3 to describe an artifact and returns the response
    """
    command = ['cray', 'artifacts', 'describe', s3_url.bucket, s3_url.key, '--format', 'json']
    return json.loads(common.run_command(command))


def get_artifact(s3_url: S3Url, target_path: str) -> None:
    """
    Downloads the specified S3 artifact to the specified path
    """
    command = ['cray', 'artifacts', 'get', s3_url.bucket, s3_url.key, target_path]
    common.run_command(command)


def list_artifacts(bucket_name: str) -> JsonDict:
    """
    Queries S3 to list contents of the specified bucket and returns the response
    """
    command = ['cray', 'artifacts', 'list', bucket_name, '--format', 'json']
    return json.loads(common.run_command(command))


def bucket_artifact_map(list_artifacts_response: JsonDict) -> Dict[str, JsonDict]:
    """
    list_artifacts_response is the response from the "list_artifacts" function on a bucket
    Returns a map from artifact keys to each corresponding entry in its artifacts list
    """
    return { a["Key"]: a for a in list_artifacts_response["artifacts"] }
