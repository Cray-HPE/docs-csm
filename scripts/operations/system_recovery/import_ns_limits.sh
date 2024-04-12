#!/bin/bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
# Import the namespace resourcequotas and limitranges
#
# For any exported resourcequota or limitrange which differs from the current values, import the data by replacing the current
# kubernetes resource with that from the exported data.
#
### Check that the s3 endpoint hosting the exports is running
#
systemctl is-active --quiet minio.service || (
  echo "Pit disk minio service is not running"
  exit
)

function err_echo {
  echo "$*" >&2
}

### Import Resource

function import_resource {

  # $1 resource - either resourcequotas or limitranges
  # Copy the exported resource file to the local filesystem
  # Save the data from the current k8s resource to a file on the local filesystem
  # Compare the exported data to the current data
  # If they differ, ask if the exported data should be applied to the current k8s resource.

  if [[ $# -ne 1 ]]; then
    err_echo "ERROR: $0 function requires exactly 1 argument but received $#. Invalid arguments: $*"
    return 1
  elif [[ -z $1 ]]; then
    err_echo "ERROR: Argument to $0 function may not be blank"
    return 1
  fi

  if [[ $1 != "resourcequotas" ]] && [[ $1 != "limitranges" ]]; then
    err_echo "ERROR: $0 function supports either resourcequotas or limitranges. Invalid arguments: $*"
    return 1
  fi

  resource=$1

  #
  # Copy the exported files to the local filesystem
  #
  while read exported; do
    mkdir -p ./"$(dirname $exported)"
    aws s3api get-object --bucket customizations --endpoint-url http://ncn-m001.nmn:8000 --key $exported ./$exported > /dev/null 2>&1
  done < <(aws s3api list-objects --bucket customizations --endpoint-url http://ncn-m001.nmn:8000 \
    | jq -r --arg resource "$resource" '.Contents[] |select(.Key | contains($resource)).Key')

  #
  # Save the data for the current resources
  #
  mkdir -p ./current
  while read ns current; do
    mkdir -p ./current/$resource/$ns
    kubectl get $resource $current -n $ns -o yaml > ./current/$resource/$ns/$current.yaml
  done < <(kubectl get $resource -A --no-headers --ignore-not-found | awk '{print $1 " " $2}')

  #
  # Compare the exported data to the current data and replace with the exported data if different
  #
  local resources
  if IFS=$'\n' read -rd '' -a resources; then
    :
  fi <<< "$(find $resource -maxdepth 2 -type f -print)"
  for res in "${resources[@]}"; do
    diff -I 'creationTimestamp:' -I 'resourceVersion:' -I 'uid:' $res ./current/$res
    if [[ $? -ne 0 ]]; then
      read -r -p "Exported $res does not match the current values - do you want to import the $resource? (y/n) " -n 1 import
      echo -e
      if [[ $import == "y" ]]; then
        yq r $res --tojson | jq 'del(.metadata.uid)' | jq 'del(.metadata.creationTimestamp)' | jq 'del(.metadata.resourceVersion)' \
          | kubectl replace --force -f -
      else
        echo "Exported $res does not match then current values - import was not done."
      fi
    else
      echo "Exported $res matches the current values - no import needed."
    fi
  done

  #
  # Clean up the local files
  #
  rm -rf ./current
  rm -rf ./${resource}
}

import_resource resourcequotas
import_resource limitranges
