#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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
import argparse
import json
import requests
import os
import boto3

class Artifact:

    def __init__(self, obj):
        self.key = obj['Key']
        self.size = obj['Size']
        self.id = None
        self._is_ims = None

    # determine if this is a non-deleted ims artifact
    def is_active_ims_artifact(self) -> bool:
        # if already computed, use it
        if self._is_ims is not None:
            return self._is_ims

        # we expect the first part of the key to be the IMS id which is a
        # hash in in the format of 'fdca156c-19b2-4453-983d-45f8ee96fbcb'
        self._is_ims = False
        parts = self.key.split('/')
        if len(parts) > 0 and len(parts[0])==36 and len(parts[0].split('-'))==5:
            self._is_ims = True
            self.id = parts[0]

        return self._is_ims


def get_token() -> str:
    token_file = os.getenv("CRAY_CREDENTIALS")
    token = None
    if token_file is None:
        print("CRAY_CREDENTIALS environment variable must be set prior to use.")
        exit(1)
    with open(token_file) as token_file_json:
        contents = json.load(token_file_json)
        token = contents['access_token']
    if token is None:
        print(f"Unable to read access token from {token_file}")
        exit(1)
    return token

def get_ims_images(token):
    images_url = "https://api-gw-service-nmn.local/apis/ims/images"
    headers = {"Authorization" : f"Bearer {token}"}
    r = requests.get(images_url, headers=headers)
    ims_image_ids = []
    for image in r.json():
        ims_image_ids.append(image['id'])
    r.close()
    return ims_image_ids

def get_s3_client(token):
    # get the S3 creds / information and create the boto3 client
    s3_info_url = "https://api-gw-service-nmn.local/apis/sts/token"
    s3_info_header = {"Authorization" : f"Bearer {token}", "Accept":"application/json"}
    r = requests.put(s3_info_url, headers=s3_info_header)
    s3_info_json = r.json()
    s3_client_kwargs = {
        'aws_access_key_id':s3_info_json['Credentials']['AccessKeyId'],
        'aws_secret_access_key':s3_info_json['Credentials']['SecretAccessKey'],
        'aws_session_token':s3_info_json['Credentials']['SessionToken'],
        'endpoint_url':s3_info_json['Credentials']['EndpointURL']
    }
    r.close()
    return boto3.client('s3', **s3_client_kwargs), boto3.resource('s3', **s3_client_kwargs)

def get_s3_artifacts(s3_client):
    s3_r = s3_client.list_objects_v2(Bucket='boot-images')
    artifacts = []
    if s3_r['KeyCount'] > 0:
        for artifact in s3_r['Contents']:
           artifacts.append(Artifact(artifact))
    page=1
    while s3_r['IsTruncated']:
        page+=1
        s3_r = s3_client.list_objects_v2(Bucket='boot-images', ContinuationToken=s3_r['NextContinuationToken'])

        if s3_r['KeyCount'] > 0:
            for artifact in s3_r['Contents']:
               artifacts.append(Artifact(artifact))
    return artifacts

# https://stackoverflow.com/a/15485265
def sizeof_fmt(num):
    """
    Given a number of bytes, returns a human-friendly string
    representation of the size.
    """
    suffix="b"
    for unit in ("", "K", "M", "G", "T"):
        if abs(num) < 1024.0:
            return f"{num:3.3f}{unit}{suffix}"
        num /= 1024.0
    return f"{num:.3f} peta{suffix}"

def options():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', required=False, help="Only find orphans, don't delete them", action='store_true')
    args = parser.parse_args()
    return args

def main():
    # read any command line arguments
    args = options()

    # get the auth token
    token = get_token()

    # get the defined images in IMS and set up a lookup table with the ids
    ims_image_ids = get_ims_images(token)

    # get the boto3 client to interact with S3
    s3_client, s3_resource = get_s3_client(token)

    # get the items in the S3 'boot-images' bucket
    artifacts = get_s3_artifacts(s3_client)

    # process the artifacts to find the ones that don't belong to an IMS record
    byte_count = 0
    for artifact in artifacts:
        if artifact.is_active_ims_artifact() and not artifact.id in ims_image_ids:
            byte_count += artifact.size
            action = ""
            if args.dry_run is True:
                action = "Found"
            else:
                action = "Deleted"
                s3_resource.Object('boot-images', artifact.key).delete()

            print(f"{action}: {artifact.key}, size: {sizeof_fmt(artifact.size)}")

    print(f"Total orphaned: {sizeof_fmt(byte_count)}")

if __name__ == '__main__':
    main()