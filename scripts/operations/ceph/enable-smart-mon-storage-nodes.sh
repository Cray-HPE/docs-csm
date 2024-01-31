#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

smartmon_url=''
ssh_options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

function get_smartmon_url() {
  local repos

  if ! curl -sSfk https://packages.local/service/rest/v1/repositories >&/dev/null; then
    echo "***"
    echo "WARNING: Unable to contact Nexus! This must be addressed before proceeding."
    echo "***"
    return
  fi

  # get a list of repos that start with "csm-noos"
  repos=$(curl -sSfk https://packages.local/service/rest/v1/repositories | jq -r '.[] | .["name"]' | grep ^csm-noos | tr '\n' ' ')

  echo "Will look for smart-mon rpm in the following repos: $repos"

  # search through the csm-noos repos looking for our package
  for repo in $repos; do
    # Retrieve the packages from nexus
    test -n "$smartmon_url" || smartmon_url=$(paginate "https://packages.local/service/rest/v1/components?repository=$repo" \
      | jq -r '.items[] | .assets[] | .downloadUrl' | grep smart-mon | sort -V | tail -1)
  done

  test -z "$smartmon_url" && echo WARNING: unable to install smart-mon rpm
}

function paginate() {
  local url="$1"
  local token

  if test -z $url; then
    echo "ERROR: paginate() called without an argument"
    exit 1
  fi

  { token="$(curl -sSk "$url" | tee /dev/fd/3 | jq -r '.continuationToken // null')"; } 3>&1

  if test -z $token; then
    echo "ERROR on line $LINENO: unable to retreive continuation token, exiting"
    exit 1
  fi

  until [[ $token == "null" ]]; do
    {
      token="$(curl -sSk "$url&continuationToken=${token}" | tee /dev/fd/3 | jq -r '.continuationToken // null')"
    } 3>&1

    if test -z $token; then
      echo "ERROR on line $LINENO: unable to retreive continuation token, exiting"
      exit 1
    fi
  done
}

get_smartmon_url

echo "Using ${smartmon_url} to install rpm on storage nodes..."

for storage_node in $(ceph orch host ls -f json | jq -r '.[].hostname'); do
  echo "Installing smart-mon rpm on ${storage_node}..."
  ssh ${storage_node} ${ssh_options} "zypper in -y --auto-agree-with-licenses ${smartmon_url} && systemctl enable smart && systemctl restart smart"
done

echo "Reconfiguring node-exporter to publish smartmon data"
ssh ncn-s001 ${ssh_options} "cephadm shell --mount /etc/cray/ceph/ -- ceph orch apply -i /mnt/node-exporter.yml"
