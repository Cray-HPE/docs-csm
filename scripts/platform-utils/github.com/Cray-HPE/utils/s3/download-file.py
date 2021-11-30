#! /usr/bin/env python3
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

import os
import sys
from argparse import ArgumentParser
import json

import boto3
import botocore
from botocore.config import Config
S3_CONNECT_TIMEOUT=60
S3_READ_TIMEOUT=1

with open('credentials.json', 'r') as fd:
    credentials = json.loads(fd.read())


def main():

    parser = ArgumentParser(description='Downloads a file from a bucket')
    parser.add_argument('--bucket-name',
                        dest='bucket_name',
                        action='store',
                        required=True,
                        help='the name of the bucket to download from')
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

    s3 = boto3.resource('s3',
                        endpoint_url=credentials['endpoint_url'],
                        aws_access_key_id=credentials['access_key'],
                        aws_secret_access_key=credentials['secret_key'],
                        config=s3_config)

    bucket = s3.Bucket(args.bucket_name)

    bucket.download_file(Filename=args.file_name,
                         Key=args.key_name)


if __name__ == '__main__':
    main()
