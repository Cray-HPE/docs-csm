#!/bin/bash
# MIT License
#
# (C) Copyright 2021-2024 Hewlett Packard Enterprise Development LP
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
DEFAULT_REGISTRY_NAME="registry.local"
DEFAULT_REGISTRY_REGEX="registry[.]local"
THIS_REGISTRY_NAME="${DEFAULT_REGISTRY_NAME}"
THIS_REGISTRY_PROTOCOL="https"
THIS_PODMAN_TLS=""
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd $SCRIPT_DIR

# Ensure the script is running from within the workflows directory so it finds argo yaml files."
if [[ "$(basename ${SCRIPT_DIR})" != "workflows" ]]; then
  echo "ERROR: This script must be located in the workflows directory to run."
  exit 1
fi

# Change registry URL target for PIT
function update_registry_url_to_pit() {
  echo "INFO: Running on PIT. Updating registry URL."
  export THIS_REGISTRY_NAME="pit.nmn:5000"
  export THIS_REGISTRY_PROTOCOL="http"
  export THIS_PODMAN_TLS="--tls-verify=false"
}

[[ ! $(curl -s ${THIS_REGISTRY_PROTOCOL}://${THIS_REGISTRY_NAME}) ]] && update_registry_url_to_pit

if [[ ! $(curl -s ${THIS_REGISTRY_PROTOCOL}://${THIS_REGISTRY_NAME}) ]]; then
  echo "WARNING: Unable to update workflow image tag references. The registry is not accessible."
  echo "This is expected if installed outside of CSM or before the registry is populated."
  echo "If you believe this should have succeeded, try rerunning this script once the registry is up."
  echo "e.g. \$ ${SCRIPT_DIR}/update_tags.sh."
  exit 0
fi

function get_list_of_images_to_update() {
  grep -rhPo "(?<=image: )[a-z].*(?=:)" . | sort | uniq
}

function get_latest_tag_for_image() {
  THIS_IMAGE=$1
  # Handle the case where the image already begins with registry.local
  if [[ ${DEFAULT_REGISTRY_NAME} == "${THIS_REGISTRY_NAME}" ]]; then
    # If the image is already prefixed with registry.local, we do not need to add it as a prefix
    THIS_PREFIX=$([[ $(echo $THIS_IMAGE | grep -e "^${THIS_REGISTRY_NAME}/") ]] && echo "" || echo "${THIS_REGISTRY_NAME}/")
  else
    # CASMINST-6778
    # The above code does not work on the PIT node, since the value of THIS_REGISTRY_NAME has changed.
    # On the PIT node, we always want to use the PIT node prefix, but we still need to strip the registry.local
    # prefix, if present.
    THIS_PREFIX="${THIS_REGISTRY_NAME}/"
    THIS_IMAGE=$(echo "${THIS_IMAGE}" | sed "s#^${DEFAULT_REGISTRY_REGEX}/##")
  fi
  podman search $THIS_PODMAN_TLS $THIS_PREFIX$THIS_IMAGE --list-tags --format=json | jq -r '
    def opt(f):
      . as $in | try f catch $in;
    def semver_cmp:
          sub("\\+.*$"; "")
            | capture("^(?<v>[^-]+)(?:-(?<p>.*))?$") | [.v, .p // empty]
            | map(split(".") | map(opt(tonumber)))
            | .[1] |= (. // {});
    .[0].Tags | sort_by(.|semver_cmp) | map(select(. != "csm-latest" and (. | endswith(".sig") | not))) | last'
}

function get_filenames_referring_to_image() {
  local fallback_image="artifactory.algol60.net/csm-docker/stable/cray-sat"
  # Search for filenames referring to the image in the passed THIS_IMAGE value
  filenames=$(grep -RHl -e "${THIS_IMAGE}:" .)
  # If no files are found, search for the image in the fallback location
  if [[ -z $filenames && ${THIS_IMAGE} =~ cray-sat ]]; then
    filenames=$(grep -RHl -e "${fallback_image}:" .)
  fi
  echo "$filenames"
}

function update_tags_in_file() {
  THIS_IMAGE=$1
  LATEST_TAG=$2
  THIS_FILE=$3
  echo "Updating tag of ${THIS_IMAGE} in ${SCRIPT_DIR}/${THIS_FILE} to ${LATEST_TAG}."
  if [[ ${THIS_IMAGE} =~ cray-sat$ ]]; then
    # Use a more flexible sed replacement for cray-sat images
    sed -i -e "s|[^ ]*cray-sat[^ ]*|${THIS_IMAGE}:${LATEST_TAG}|g" "$THIS_FILE"
  else
    sed -i -e "s|${THIS_IMAGE}:.*|${THIS_IMAGE}:${LATEST_TAG}|g" "$THIS_FILE"
  fi
}

function update_cray_sat_image() {
  THIS_IMAGE=$1
  # Capture the output of the podman search for img & update the img if it doesnt exist
  SEARCH_OUTPUT=$(podman search ${DEFAULT_REGISTRY_NAME}/${THIS_IMAGE} 2>&1)
  if [[ -z ${SEARCH_OUTPUT} ]]; then
    THIS_IMAGE="artifactory.algol60.net/sat-docker/stable/cray-sat"
  fi
  echo "$THIS_IMAGE"
}

# Look up the latest tag for each image found and update the references in every file.
for THIS_IMAGE in $(get_list_of_images_to_update); do
  if [[ ${THIS_IMAGE} =~ cray-sat ]]; then
    # CASMTRIAGE-7175 handle cray-sat image
    THIS_IMAGE=$(update_cray_sat_image $THIS_IMAGE)
  fi
  LATEST_TAG=$(get_latest_tag_for_image $THIS_IMAGE)
  # CASMTRIAGE-6188 retry for up to 60 seconds if LATEST_TAG is empty
  i=1
  while [[ -z ${LATEST_TAG} ]]; do
    if [[ ${i} -le 6 ]]; then
      echo "Retry getting the latest tag for image: $THIS_IMAGE"
      sleep 10
      LATEST_TAG=$(get_latest_tag_for_image $THIS_IMAGE)
      i=$((i + 1))
      echo "Inside loop: $LATEST_TAG"
    else
      echo "ERROR: unable to get the latest tag for image: $THIS_IMAGE"
      exit 1
    fi
  done
  echo "Outside loop: $LATEST_TAG"
  for FILE in $(get_filenames_referring_to_image); do
    update_tags_in_file $THIS_IMAGE $LATEST_TAG $FILE
  done
done

cd $OLDPWD
