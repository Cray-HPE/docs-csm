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

import datetime
import json
import logging
from typing import Dict, List
from urllib.parse import urlparse
import warnings

import boto3
import botocore.exceptions

from . import api_requests
from . import common
from .types import JsonDict


STS_TOKEN_URL = f"{api_requests.API_GW_BASE_URL}/apis/sts/token"

# Mapping from the STS Credentials field names to the boto3 client kwargs names
CREDS_TO_KWARGS = {
    "AccessKeyId": "aws_access_key_id",
    "SecretAccessKey": "aws_secret_access_key",
    "SessionToken": "aws_session_token",
    "EndpointURL": "endpoint_url" }


def s3_client_kwargs() -> JsonDict:
    """
    Decode the S3 credentials from the Kubernetes secret, and return
    the kwargs needed to initialize the boto3 client.
    """
    logging.debug("Contacting STS to obtain S3 credentials")
    resp = api_requests.put_retry_validate_return_json(url=STS_TOKEN_URL, expected_status_codes=201,
                                                       add_api_token=True)
    creds = resp["Credentials"]
    kwargs = { kname: creds[cname] for cname, kname in CREDS_TO_KWARGS.items() }
    # The Cray CLI sets the following field to an empty string, and if it's good enough for the
    # Cray CLI, then it's good enough for me
    kwargs["region_name"] = ""
    return kwargs


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

    @classmethod
    def from_bucket_and_key(cls, bucket: str, key: str) -> "S3Url":
        """
        Create a new S3 URL object from the bucket and key
        """
        return cls(f"s3://{bucket}/{key}")


class S3Client:
    """
    Wrapper for the boto3 S3 client
    """

    def __init__(self):
        client_kwargs = s3_client_kwargs()
        logging.debug("Getting boto3 S3 client")
        with warnings.catch_warnings():
            warnings.filterwarnings('ignore', category=boto3.compat.PythonDeprecationWarning)
            self.s3_cli = boto3.client('s3', **client_kwargs)


    def list_artifacts(self, bucket_name: str) -> list:
        """
        Queries S3 to list contents of the specified bucket. Makes additional queries if
        response is truncated. Returns a combined list of the artifacts.
        """
        logging.debug("Quering S3 for contents of '%s' bucket", bucket_name)
        resp = self.s3_cli.list_objects_v2(Bucket=bucket_name)
        logging.debug("S3 returned list of %d artifacts in '%s' bucket", resp["KeyCount"],
                      bucket_name)
        artifact_list = []
        if resp["KeyCount"] > 0:
            artifact_list.extend(resp["Contents"])
        page_num=1
        while resp["IsTruncated"]:
            page_num+=1
            logging.debug("Quering S3 for contents of '%s' bucket (page %d)", bucket_name, page_num)
            resp = self.s3_cli.list_objects_v2(Bucket=bucket_name,
                                               ContinuationToken=resp["NextContinuationToken"])
            logging.debug("S3 returned list of %d artifacts in '%s' bucket", resp["KeyCount"],
                          bucket_name)
            if resp["KeyCount"] > 0:
                artifact_list.extend(resp["Contents"])

        logging.debug("Returning combined list of %d artifacts", len(artifact_list))
        return artifact_list


    def list_buckets(self) -> list:
        """
        Queries S3 for a list of all buckets, and returns this list.
        
        Technically this is all of the buckets belonging to the authenticated user.
        In the case of CSM, all buckets should be created by this user. If any other
        buckets exist, they are not our concern.
        """
        logging.debug("Quering S3 for list of buckets")
        resp = self.s3_cli.list_buckets()
        logging.debug("S3 returned list of %d buckets", len(resp["Buckets"]))
        return resp["Buckets"]


    def artifact_exists(self, bucket_name: str, key: str) -> bool:
        """
        Returns True if the artifact exists in S3 and we have access to it.
        Returns False otherwise
        """
        try:
            self.s3_cli.head_object(Bucket=bucket_name, Key=key)
        except botocore.exceptions.ClientError:
            return False
        return True


def create_artifact(s3_url: S3Url, source_path: str) -> JsonDict:
    """
    Uploads the specified S3 artifact from the specified path
    """
    command = ['cray', 'artifacts', 'create', s3_url.bucket, s3_url.key, source_path, '--format',
               'json']
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


def list_buckets() -> List[str]:
    """
    Return the list of names of all S3 buckets.
    """
    # Generate the bucket list. Sadly, it will not include skydiving.
    return [ bucket["Name"] for bucket in S3Client().list_buckets() ]


def bucket_artifact_map(list_artifacts_response: JsonDict) -> Dict[str, JsonDict]:
    """
    list_artifacts_response is the response from the "list_artifacts" function on a bucket
    Returns a map from artifact keys to each corresponding entry in its artifacts list
    """
    return { a["Key"]: a for a in list_artifacts_response["artifacts"] }
