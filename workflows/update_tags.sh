#!/bin/bash
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

# This script updates all image tag references in the workflows directory.
# This is necessary since a new docs-csm version could land before or after a CSM update.

set -e
REGISTRY="registry.local"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

if [[ "$(basename $(pwd))" != "workflows" ]]; then
  echo "This script must be located in the workflows directory to run."
  exit 1
fi

if [[ ! $(nslookup $REGISTRY) ]]; then
  echo "${REGISTRY} does not resolve. Exiting script as success under assumption that docs were installed outside of CSM environment."
  exit 0
fi

if [[ ! $(curl -s https://${REGISTRY}) ]]; then
  echo "${REGISTRY} is not accessible over https. Check that it is accessible before continuing."
  exit 1
fi

function get_list_of_images_to_update() {
  grep -rhPo "(?<=image: )[a-z].*(?=:)" . | sort | uniq
}

function get_latest_tag_for_image() {
  THIS_IMAGE=$1
  THIS_PREFIX=$([[ $(echo $THIS_IMAGE | grep -e "^${REGISTRY}/") ]] && echo "" || echo "${REGISTRY}/")
  podman search $THIS_PREFIX$THIS_IMAGE --list-tags --format=json | jq -r '.[0].Tags | sort_by(.) | last'
}

function get_filenames_referring_to_image() {
  grep -RHl -e "${THIS_IMAGE}:" .
}

function update_tags_in_file() {
  THIS_IMAGE=$1
  LATEST_TAG=$2
  THIS_FILE=$3
  echo "Updating tag of ${THIS_IMAGE} in ${THIS_FILE} to ${LATEST_TAG}."
  sed -i -e "s|${THIS_IMAGE}:.*|${THIS_IMAGE}:${LATEST_TAG}|g" $THIS_FILE
}

# For each image found, lookup the latest tag and update the references in every file.
for THIS_IMAGE in $(get_list_of_images_to_update); do
  LATEST_TAG=$(get_latest_tag_for_image $THIS_IMAGE)
  for FILE in $(get_filenames_referring_to_image); do
    update_tags_in_file $THIS_IMAGE $LATEST_TAG $FILE
  done
done

cd $OLDPWD
