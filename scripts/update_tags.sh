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

# Accepts two arguments
# First argument is the image name needing tag references updated.
# Second argument is the path of files to recursively update.
# e.g. `update_tags.sh cray-ims-load-artifacts /etc/cray/upgrade/csm/docs-csm`

set -e
THIS_IMAGE=$1
DIRECTORY_TO_PROCESS=$2

cd $DIRECTORY_TO_PROCESS

if [[ -z $THIS_IMAGE ]]; then
  echo "Must specify an image name."
  exit 1
fi

if [[ -z $DIRECTORY_TO_PROCESS ]]; then
  echo "Must specify a directory of files to process."
  exit 1
fi

function get_repository_name_for_image() {
  podman search registry.local/$THIS_IMAGE --format=json | jq -r '.[0].Name'
}

function get_latest_tag_for_image() {
  THIS_REPO=$(get_repository_name_for_image $THIS_IMAGE)
  podman search $THIS_REPO --list-tags --format=json | jq -r '.[0].Tags | last'
}

LATEST_TAG=$(get_latest_tag_for_image $THIS_IMAGE)

function get_filenames_referring_to_image() {
  grep -RHl -e "${THIS_IMAGE}:[0-9]\.[0-9]\.[0-9]" .
}

function update_tags_in_file() {
  THIS_FILE=$1
  echo "Updating tag of ${THIS_IMAGE} in ${THIS_FILE} to ${LATEST_TAG}."
  sed -i -e "s/${THIS_IMAGE}:[0-9]\.[0-9]\.[0-9].*/${THIS_IMAGE}:${LATEST_TAG}/g" $THIS_FILE
}

for FILE in $(get_filenames_referring_to_image); do
  update_tags_in_file $FILE
done

cd $OLD_PWD
