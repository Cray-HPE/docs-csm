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
"""Shared Python function library: S3"""

import base64
import datetime
import json
import logging
import os
from typing import Dict
from urllib.parse import urlparse
import warnings

import boto3

from . import common
from . import k8s
from .types import JsonDict

S3_CREDS_SECRET_NAME = "ims-s3-credentials"

# Mapping from the boto3 client kwargs field names to the Kubernetes secret field names
S3_CREDS_SECRET_FIELDS = {
    "endpoint_url": "s3_endpoint",
    "aws_access_key_id": "access_key",
    "aws_secret_access_key": "secret_key",
    "verify": "ssl_validate" }


def s3_client_kwargs() -> JsonDict:
    """
    Decode the S3 credentials from the Kubernetes secret, and return
    the kwargs needed to initialize the boto3 client.
    """
    secret_data = k8s.Client().get_secret_data(name=S3_CREDS_SECRET_NAME, namespace="default")
    logging.debug("Reading fields from Kubernetes secret '%s'", S3_CREDS_SECRET_NAME)
    encoded_s3_secret_fields = { field: secret_data[secret_field]
                                 for field, secret_field in S3_CREDS_SECRET_FIELDS.items() }
    logging.debug("Decoding fields from Kubernetes secret '%s'", S3_CREDS_SECRET_NAME)
    kwargs = { field: base64.b64decode(encoded_field).decode()
               for field, encoded_field in encoded_s3_secret_fields.items() }
    # Need to convert the 'verify' field to boolean if it is false
    if not kwargs["verify"] or kwargs["verify"].lower() in ('false', 'off', 'no', 'f', '0'):
        kwargs["verify"] = False

    # And if Verify is false, then we need to make sure that our endpoint isn't https, since
    # it will use SSL verification regardless if the endpoint is https
    if kwargs["verify"] is False and kwargs["endpoint_url"][:6] == "https:":
        kwargs["endpoint_url"] = f"http:{kwargs['endpoint_url'][6:]}"

    return kwargs


def s3_client():
    """
    Initialize the boto3 client and return it
    """
    client_kwargs = s3_client_kwargs()
    logging.debug("Getting boto3 S3 client")
    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', category=boto3.compat.PythonDeprecationWarning)
        bclient = boto3.client('s3', **client_kwargs)
    return bclient


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
    s3_cli = s3_client()
    logging.debug("Quering S3 for contents of '%s' bucket", bucket_name)
    resp = s3_cli.list_objects_v2(Bucket=bucket_name)
    logging.debug("S3 returned list of %d artifacts in '%s' bucket", len(resp["Contents"]),
                  bucket_name)
    artifact_list = resp["Contents"]
    page_num=1
    while resp["IsTruncated"]:
        page_num+=1
        logging.debug("Quering S3 for contents of '%s' bucket (page %d)", bucket_name, page_num)
        resp = s3_cli.list_objects_v2(Bucket=bucket_name,
                                      ContinuationToken=resp["NextContinuationToken"])
        logging.debug("S3 returned list of %d artifacts in '%s' bucket", len(resp["Contents"]),
                      bucket_name)
        artifact_list.extend(resp["Contents"])

    # Convert the datetime fields in the artifacts to strings, since we need them to be
    # JSON serializable
    for art in artifact_list:
        if "LastModified" in art and isinstance(art["LastModified"], datetime.datetime):
            art["LastModified"] = str(art["LastModified"])
        if "RestoreStatus" not in art:
            continue
        if "RestoreExpiryDate" not in art["RestoreStatus"]:
            continue
        if isinstance(art["RestoreStatus"]["RestoreExpiryDate"], datetime.datetime):
            art["RestoreStatus"]["RestoreExpiryDate"] = str(art["RestoreStatus"]["RestoreExpiryDate"])

    # Return a response in the same format as the Cray CLI would
    return { "artifacts": artifact_list }


def bucket_artifact_map(list_artifacts_response: JsonDict) -> Dict[str, JsonDict]:
    """
    list_artifacts_response is the response from the "list_artifacts" function on a bucket
    Returns a map from artifact keys to each corresponding entry in its artifacts list
    """
    return { a["Key"]: a for a in list_artifacts_response["artifacts"] }
