#!/usr/bin/env python3
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

import os
import sys
from argparse import ArgumentParser
import json

import boto3


with open('credentials.json', 'r') as fd:
    credentials = json.loads(fd.read())


def main():

    parser = ArgumentParser(description='Lists objects in a bucket')
    parser.add_argument('--bucket-name',
                        dest='bucket_name',
                        action='store',
                        required=True,
                        help='the name of the bucket to list')
    args = parser.parse_args()

    s3 = boto3.client('s3',
                      endpoint_url=credentials['endpoint_url'],
                      aws_access_key_id=credentials['access_key'],
                      aws_secret_access_key=credentials['secret_key'])

    response = s3.list_objects_v2(Bucket=args.bucket_name)
    for item in response['Contents']:
        print(item['Key'])


if __name__ == '__main__':
    main()
