#!/usr/bin/env python3
# MIT License
#
# (C) Copyright [2022-2023] Hewlett Packard Enterprise Development LP
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

import time
import requests
import pathlib
import sys
import os
import json
import argparse
from os import listdir
from os.path import exists, isfile, join
from datetime import datetime

RECIPES_DIR = "recipes"

def getFilepath():
    filepath = os.path.abspath(os.path.dirname(__file__)) + "/" + RECIPES_DIR
    return filepath

def getAvailableFiles(filepath):
    print("Available files in " + filepath + ":")
    onlyfiles = [f for f in listdir(filepath) if isfile(join(filepath, f))]
    for f in listdir(filepath):
      if isfile(join(filepath, f)):
          if pathlib.Path(f).suffix == ".json":
              print(f)

def doAction(token, data, FAS_URL):
    headers = {
        'Content-Type': "application/json",
        'cache-control': "no-cache",
        'Authorization': f'Bearer {token}'
    }
    url = FAS_URL + "/actions"
    payload = json.dumps(data)
    print("JSON payload to FAS action command:\n" + payload)
    ret = requests.request("POST", url, data=payload, headers=headers, verify=True)
    if ret.status_code != 202:
        print("ERROR: Return Code: " + str(ret.status_code))
        print(ret.json())
        return None
    if "actionID" in ret.json():
        actionID = ret.json()["actionID"]
    else:
        actionID = None
    print("Action ID: " + actionID)
    return actionID

def doWatchAction(token, FAS_URL, actionID, watchtime):
    headers = {
        'cache-control': "no-cache",
        'Authorization': f'Bearer {token}'
    }
    state = "none"
    while state != "completed":
        time.sleep(watchtime)
        url = FAS_URL + "/actions/" + actionID + "/status"
        ret = requests.request("GET", url, headers=headers, verify=True)
        retjson = ret.json()
        state = retjson["state"]
        if state == "completed":
            print("--------------------------- COMPLETED ----------------------")
        else:
            print("--------------------------- " + state + " ----------------------")
        print("State: " + state + " Date: " + datetime.now().strftime("%m/%d/%Y %H:%M:%S"))
        for oc in retjson["operationCounts"]:
            count = retjson["operationCounts"][oc]
            if count > 0:
                print("> " + oc + ": " + str(count))
        if "errors" in retjson.keys():
            errors = retjson["errors"]
            if len(errors) > 0:
                print("ERRORS :")
                print(errors)
        if state == "completed":
            print("--------------------------- COMPLETED ----------------------")

# https://stackoverflow.com/questions/15008758/parsing-boolean-values-with-argparse
def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

def main():
    token = os.environ.get('TOKEN')
    if token is None or token == "":
        print("Error environment variable TOKEN was not set")
        print('Run the following to set the TOKEN:')
        print('''export TOKEN=$(curl -s -S -d grant_type=client_credentials \\
    -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth \\
    -o jsonpath='{.data.client-secret}' | base64 -d` \\
    https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \\
    | jq -r '.access_token')
            ''')
        sys.exit(1)

    parser = argparse.ArgumentParser(description="Run a default FAS update")

    parser.add_argument("--file", type=str, required=False, help="Filename of the .json action recipe file to use", default="")
    parser.add_argument("--list", required=False, help="List files available in the recipes directory", action="store_true")
    parser.add_argument("--recipedir", type=str, required=False, help="Specify the directory to find the recipes", default="")
    parser.add_argument("--xnames", type=str, required=False, help="List of xnames to update", default="")
    parser.add_argument("--imageID", type=str, required=False, help="image ID of image to flash to node", default="")
    parser.add_argument("--overrideDryrun", type=str2bool, required=False, help="Perform Dry or Real update", default=False)
    parser.add_argument("--watchtime", type=int, required=False, help="Time between actions status", default=30)
    parser.add_argument("--description", type=str, required=False, help="Overwrite description", default="")
    parser.add_argument("--url-fas", type=str, required=False, help="URL to access FAS API", default="https://api-gw-service-nmn.local/apis/fas/v1")

    args = parser.parse_args()

    FAS_URL = args.url_fas
    watchtime = args.watchtime

# Find filepath
    if args.recipedir != "":
        filepath = args.recipedir
    else:
        filepath = getFilepath()

    if not exists(filepath):
        print("ERROR: Can not find directory " + filepath)
        sys.exit(2)

# Process list option to list files and exit
    if args.list:
        getAvailableFiles(filepath)
        sys.exit(0)

    if args.file == "":
        print("ERROR: No recipe file specified")
        sys.exit(2)

    fullpath = filepath + "/" + args.file
# Not found
    if not exists(fullpath):
        print("ERROR: File does not exist " + fullpath)
# Print available files
        getAvailableFiles(filepath)
        sys.exit(2)

    print("Recipe filename: " + fullpath)

# Read JSON from file and store
    try:
        f = open(fullpath)
        data = json.load(f)
    except Exception as e:
        f.close()
        print("ERROR: Opening and reading Recipe File - Please check file and try again")
        sys.exit(3)
    f.close()

    if "command" not in data:
        data["command"] = {}
    data["command"]["overrideDryrun"] = args.overrideDryrun

# Create xname list
    xnamearg = args.xnames.lower()
    xnames = []
    if len(xnamearg) > 0:
        for xn in xnamearg.split(","):
            xnames.append(xn)
    if len(xnames) > 0:
        if "stateComponentFilter" not in data:
            data["stateComponentFilter"] = {}
        data["stateComponentFilter"]["xnames"] = xnames

# Create image override
    imageIDarg = args.imageID
    if len(imageIDarg) > 0:
        if "imageFilter" not in data:
            data["imageFilter"] = {}
        data["imageFilter"]["imageID"] = imageIDarg
        data["imageFilter"]["overrideImage"] = True

# Update description
    if "command" not in data:
        data["command"] = {}
    if args.description != "":
        data["command"]["description"] = args.description
    else:
        if "description" not in data["command"]:
            data["command"]["description"] = args.file
        desc = data["command"]["description"] + " -- "
        if not args.overrideDryrun:
            desc += "Dryrun "
        desc += datetime.now().strftime("%m/%d/%Y %H:%M:%S")
        data["command"]["description"] = desc

    actionID = doAction(token, data, FAS_URL)
    if actionID == None:
        print("ERROR: Did not receive an actionID from FAS")
        sys.exit(3)

    doWatchAction(token, FAS_URL, actionID, watchtime)

    print("Action ID: " + actionID)
    print("Review action with the following command:")
    print("cray fas actions describe " + actionID)

    return 0

if __name__ == "__main__":
    sys.exit(main())
