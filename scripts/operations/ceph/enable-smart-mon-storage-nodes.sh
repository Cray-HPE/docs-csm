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

set -euo pipefail

smartmon_url=''
ssh_options="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

function get_smartmon_url() {
  local repos

  if ! curl -sSfk https://packages.local/service/rest/v1/repositories >&/dev/null; then
    echo "***"
    echo "WARNING: Unable to contact Nexus! This must be addressed before proceeding."
    echo "***"
    return 1
  fi

  # get a list of repos that start with "csm-noos"
  if IFS=$'\n' read -rd '' -a repos; then
    :
  fi <<< "$(curl -sSfk https://packages.local/service/rest/v1/repositories | jq -r '.[] | .["name"]' | grep ^csm-noos | tr '\n' ' ')"

  echo "Will look for smart-mon rpm in the following repos: ${repos[*]}"

  # search through the csm-noos repos looking for our package
  for repo in "${repos[@]}"; do
    # Retrieve the packages from nexus
    if [[ -z $smartmon_url ]]; then
      if ! repo_items="$(paginate "https://packages.local/service/rest/v1/components?repository=$repo")"; then
        echo "ERROR on line $LINENO: unable to get items from $repo, exiting"
        return 1
      else
        smartmon_url="$(echo $repo_items | jq -r '.items[] | .assets[] | .downloadUrl' | grep smart-mon | sort -V | tail -1)"
      fi
    fi
  done

  if [[ -z $smartmon_url ]]; then
    echo WARNING: unable to install smart-mon rpm
    return 1
  fi
}

function paginate() {
  local url="$1"
  local token

  if [[ -z $url ]]; then
    echo "ERROR: paginate() called without an argument"
    return 1
  fi

  # check if last char of url is a space
  if [[ ${url: -1} == " " ]]; then
    # remove last character if it is a space
    url=${url::-1}
  fi

  { token="$(curl -sSk "$url" | tee /dev/fd/3 | jq -r '.continuationToken // null')"; } 3>&1

  if [[ -z $token ]]; then
    echo "ERROR on line $LINENO: unable to retreive continuation token, exiting"
    return 1
  fi

  until [[ $token == "null" ]]; do
    {
      token="$(curl -sSk "$url&continuationToken=${token}" | tee /dev/fd/3 | jq -r '.continuationToken // null')"
    } 3>&1

    if [[ -z $token ]]; then
      echo "ERROR on line $LINENO: unable to retreive continuation token, exiting"
      return 1
    fi
  done
}

if ! get_smartmon_url; then
  exit 1
fi

echo "Using ${smartmon_url} to install rpm on storage nodes..."
if IFS=$'\n' read -rd '' -a ORCH_HOSTS; then
  :
fi <<< "$(ceph orch host ls -f json | jq -r '.[].hostname')"
for storage_node in "${ORCH_HOSTS[@]}"; do
  echo "Installing smart-mon rpm on ${storage_node}..."
  ssh ${storage_node} ${ssh_options} "zypper in -y --auto-agree-with-licenses ${smartmon_url} && systemctl enable smart && systemctl restart smart"
done

echo "Reconfiguring node-exporter to publish smartmon data"
ssh ncn-s001 ${ssh_options} "ceph orch apply -i /etc/cray/ceph/node-exporter.yml"
