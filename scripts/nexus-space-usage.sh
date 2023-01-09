#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

set -eo pipefail

PYSCRIPT_BLOBS='
import os, requests
resp=requests.get("https://packages.local/service/rest/v1/blobstores", 
                  auth=(os.environ["NEXUS_USERNAME"], os.environ["NEXUS_PASSWORD"]))
print(resp.text)
'

PYSCRIPT_REPOS='
import os, requests
resp=requests.get("https://packages.local/service/rest/beta/repositories", 
                  auth=(os.environ["NEXUS_USERNAME"], os.environ["NEXUS_PASSWORD"]))
print(resp.text)
'

nexus-get-blob-usage(){
    NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template '{{.data.username}}' | base64 -d)"
    NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template '{{.data.password}}' | base64 -d)"
    export NEXUS_USERNAME NEXUS_PASSWORD

    echo "Nexus blob usage by size in descending order."
    echo "Blob Size (GiB), Blob Name"
    echo ""
    python3 -c "${PYSCRIPT_BLOBS}" | jq -r '.[] | {"bsize":(.totalSizeInBytes/1024/1024/1024), "bname":.name} | join(", ")' | sort -g -r

    echo ""
    echo "Remaining free storage (GiB):"
    python3 -c "${PYSCRIPT_BLOBS}" | jq -r '.[0].availableSpaceInBytes/1024/1024/1024'
}

nexus-get-repo(){

  echo "Repositories by Blobstore."
  python3 -c "${PYSCRIPT_REPOS}" | jq -r 'group_by(.storage | .blobStoreName) | map({ blobStore: (.[0].storage.blobStoreName), repositoryName: [.[] | .name] })'
  # To select one Blobstores list of repositories append "| jq -r '.[] | select(.blobStore=="csm") | .repositoryName | .[]'"

}

nexus-get-blob-usage
nexus-get-repo
