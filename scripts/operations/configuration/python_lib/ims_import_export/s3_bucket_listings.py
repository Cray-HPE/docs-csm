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

from typing import Union

from python_lib import s3

from python_lib.types import JsonDict

from .s3_bucket_info import S3BucketInfo

class S3BucketListings(dict):
    """
    Mapping from bucket names (str) to S3BucketInfo for that bucket
    """
    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_system(cls) -> "S3BucketListings":
        return S3BucketListings({ bucket_name: S3BucketInfo.load_from_system(bucket_name)
                                  for bucket_name in s3.list_buckets() })


    # Use a string for the type hint in the case where the type is not yet defined.
    # https://peps.python.org/pep-0484/#forward-references
    @classmethod
    def load_from_json(cls, json_dict: JsonDict) -> "S3BucketListings":
        """
        Returns a S3BucketListings object populated with the data from json_dict
        """
        return S3BucketListings({ bucket_name: S3BucketInfo(bucket_info)
                                  for bucket_name, bucket_info in json_dict.items() })


    def artifact_exists(self, s3_url: Union[s3.S3Url, None], load_if_needed: bool) -> bool:
        """
        If s3_url is None, return False.

        If a listing for the bucket for the specified s3_url does not exist in our dict, then:
        * If load_if_needed is False, raise a KeyError. Otherwise query S3 to get the listing for
          the bucket and proceed.

        Call has_artifact for the specified s3_url on the bucket listing
        """
        # Check to see if there is an associated S3 artifact
        if s3_url is None:
            return False
        # Check to see if this S3 artifact actually exists
        try:
            s3_bucket_listing = self[s3_url.bucket]
        except KeyError:
            if not load_if_needed:
                raise
            # Need to get this listing
            s3_bucket_listing = S3BucketInfo.load_from_system(s3_url.bucket)
            self[s3_url.bucket] = s3_bucket_listing
        return s3_bucket_listing.has_artifact(s3_url)
