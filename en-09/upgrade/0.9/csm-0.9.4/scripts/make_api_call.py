# Copyright (C) 2021 Hewlett Packard Enterprise Development LP

import json
import os
import requests
from requests.adapters import HTTPAdapter
from requests.auth import HTTPBasicAuth
import sys
from urllib3.util.retry import Retry
import warnings

# Read in username, password, vendor, method, URL, and payload from environment variables
# Payload may not be set, but that is okay -- we only look at it if the method
# is post or patch, in which case it needs to be set
user=os.environ['USERNAME']
pw=os.environ['IPMI_PASSWORD']
vendor=os.environ['VENDOR']
try:
    payload=os.environ['payload']
except KeyError:
    payload = "null"
url=os.environ['url']
method=os.environ['method']

# Because we are often issuing requests to BMCs which may have just been restarted using
# a cold reset, we want to do more retries than we otherwise would. The settings below
# mean that if our first attempt fails, we will sleep 0.1 seconds, retry, sleep 0.2 seconds,
# retry, etc, finally sleeping for 0.5 seconds before the final attempt. This is a total of
# 0.1 + 0.2 + 0.3 + 0.4 + 0.5 + 0.6 + 0.7 + 0.8 + 0.9 + 1 = 5.5 seconds
#
# These settings also enable retries when "server busy" type status codes are received.
s = requests.Session()
retries = Retry(total=10, backoff_factor=0.1, status_forcelist=[ 500, 502, 503, 504 ])

# This tells our session to apply the above retry options when making requests to our URL
s.mount(url, HTTPAdapter(max_retries=retries))

# Determine the requests function we will be calling.
# Even though the script currently only makes get, patch, and post calls, no reason
# not to include delete and put, in case they are needed in the future
if method.lower() == "delete":
    rfunc = s.delete
elif method.lower() == "get":
    rfunc = s.get
elif method.lower() == "patch":
    rfunc = s.patch
elif method.lower() == "post":
    rfunc = s.post
elif method.lower() == "put":
    rfunc = s.put
else:
    raise AssertionError("Invalid method specified: %s" % method)

# Build up initial argument list for request call
kwargs = {
    "url": url,
    "auth": HTTPBasicAuth(user, pw),
    "verify": False,
    "allow_redirects": True }

if payload != "null":
    # Convert to JSON and add to argument list
    try:
        kwargs["json"] = json.loads(payload)
    except json.decoder.JSONDecodeError:
        print("Invalid JSON found in payload string: %s" % payload, file=sys.stderr)
        raise

# Build up our headers
if method in { "patch", "post" }:
    headers = dict()
    headers["Content-Type"] = "application/json"
    headers["Accept"] = "application/json"

    # We use the same vendor check that is used in the set-bmc-ntp-dns.sh script to determine
    # whether or not this is Gigabyte
    if -1 < vendor.find("GIGA") < vendor.find("BYTE"):
        # Adding this header based on this comment in the shell script:
        # GIGABYTE seems to need If-Match headers. For now, just accept * all because we do not
        # know yet what they are looking for
        headers["If-Match"] = "*"

    # Add the headers to our request argument list
    kwargs["headers"] = headers

# Make the request
with warnings.catch_warnings():
    warnings.simplefilter('ignore', category=requests.packages.urllib3.exceptions.InsecureRequestWarning)
    resp = rfunc(**kwargs)

# Just as with the curl command this script is replacing, we do not validate the status
# code. However, to aid in debugging, we do print a warning if the status code is not in the
# 200s. We print it to stderr because this script is typically piped to jq
if not 200 <= resp.status_code <= 299:
    print("WARNING: %s request to %s returned status code %d" % (method, url, resp.status_code), file=sys.stderr)

# Print the response body and exit
print(resp.text)
