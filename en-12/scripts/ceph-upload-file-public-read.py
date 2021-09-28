#! /usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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


import os
import sys
from argparse import ArgumentParser
import json
import subprocess
from base64 import b64decode
import boto3
import botocore
from botocore.config import Config
S3_CONNECT_TIMEOUT=60
S3_READ_TIMEOUT=1



def main():

    parser = ArgumentParser(description='Creates a bucket')
    parser.add_argument('--bucket-name',
                        dest='bucket_name',
                        action='store',
                        required=True,
                        help='the name of the bucket to create')
    parser.add_argument('--key-name',
                        dest='key_name',
                        action='store',
                        required=True,
                        help='the objects key name')
    parser.add_argument('--file-name',
                        dest='file_name',
                        action='store',
                        required=True,
                        help='the file to upload')
    args = parser.parse_args()

    s3_config = Config(connect_timeout=S3_CONNECT_TIMEOUT,
                           read_timeout=S3_READ_TIMEOUT)

    #
    # These bucket names have K8S secrets with non-standard names
    #
    non_std_bucket_map = {'ssm': 'ssm-swm-s3-credentials',
                          'boot-images': 'ims-s3-credentials',
                          'install-artifacts': 'artifacts-s3-credentials',
                          'ncn-images': 'sts-s3-credentials'}
    if args.bucket_name in non_std_bucket_map:
        secret_name = non_std_bucket_map[args.bucket_name]
    else:
        secret_name = "%s-%s" % (args.bucket_name, "s3-credentials")

    # get credentials
    a_key = b64decode(subprocess.check_output(
        ['kubectl', 'get', 'secret', secret_name, '-o', "jsonpath='{.data.access_key}'"])).decode()
    s_key = b64decode(subprocess.check_output(
        ['kubectl', 'get', 'secret', secret_name, '-o', "jsonpath='{.data.secret_key}'"])).decode()
    credentials = {'endpoint_url': 'http://rgw-vip',
                   'access_key': a_key, 'secret_key': s_key}
    s3 = boto3.resource('s3',
                        endpoint_url=credentials['endpoint_url'],
                        aws_access_key_id=credentials['access_key'],
                        aws_secret_access_key=credentials['secret_key'],
                        config=s3_config)

    bucket = s3.Bucket(args.bucket_name)

    bucket.upload_file(Filename=args.file_name,
                       Key=args.key_name,
                       ExtraArgs={'ACL': 'public-read'})


if __name__ == '__main__':
    main()
