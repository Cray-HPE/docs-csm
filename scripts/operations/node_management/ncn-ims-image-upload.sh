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

test -n "${DEBUG}" && set -x
set -eo pipefail

unset CRAY_FORMAT
UPDATE_CPC=true

function err_exit() {
    echo "ERROR: $*" >&2
    exit 1
}

function nonblank_arg_required() {
    # $1 $2 ... current command line arguments
    [[ $# -ge 2 ]] || err_exit "'$1' parameter requires an argument"
    [[ -n $2 ]] || err_exit "Argument to '$1' parameter may not be empty"
}

function file_exists_nonempty() {
    # $1 $2 ... current command line arguments
    nonblank_arg_required "$@"
    [[ -e $2 ]] || err_exit "File argument to '$1' does not exist: '$2'"
    [[ -f $2 ]] || err_exit "File argument to '$1' exists but is not a regular file: '$2'"
    [[ -s $2 ]] || err_exit "File argument to '$1' exists but is zero size: '$2'"
}

function update_cpc() {
    [[ ${UPDATE_CPC} == true ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)         file_exists_nonempty  "$@" ; IMS_INITRD_FILENAME=$2 ; shift ;;
        -k)         file_exists_nonempty  "$@" ; IMS_KERNEL_FILENAME=$2 ; shift ;;
        -n)         nonblank_arg_required "$@" ; IMS_IMAGE_NAME=$2      ; shift ;;
        -s)         file_exists_nonempty  "$@" ; IMS_ROOTFS_FILENAME=$2 ; shift ;;
        --no-cpc)   UPDATE_CPC=false ;;
        *)          err_exit "Unknown argument: '$1'" ;;
    esac
    shift
done

[[ -n ${IMS_KERNEL_FILENAME} ]] || err_exit "Required option (-k) is missing"
[[ -n ${IMS_INITRD_FILENAME} ]] || err_exit "Required option (-i) is missing"
[[ -n ${IMS_ROOTFS_FILENAME} ]] || err_exit "Required option (-s) is missing"

# Some parameters are only required if we're updating the product catalog
if update_cpc; then

    [[ -n ${CSM_RELEASE} ]] || err_exit "\$CSM_RELEASE is not specified"
    if [[ -z ${PITDATA} ]] && [[ -f /etc/pit-release ]]; then
        err_exit "\$PITDATA is not specified"
    fi
    [[ -n ${CSM_ARTI_DIR} || -n ${CSM_PATH} ]] || err_exit "One of \$CSM_ARTI_DIR or \$CSM_PATH must be set to the path of unpacked CSM tarball"

    CSM_TARBALL=${CSM_ARTI_DIR:-$CSM_PATH}
    CPC_VERSION=$(find "${CSM_TARBALL}"/docker/artifactory.algol60.net/csm-docker/stable/ -maxdepth 1 | awk -F':' /cray-product-catalog-update/'{print $NF}' | sort -V | tail -1)
fi

IMS_ROOTFS_MD5SUM=$(md5sum "${IMS_ROOTFS_FILENAME}" | awk '{ print $1 }')
IMS_INITRD_MD5SUM=$(md5sum "${IMS_INITRD_FILENAME}" | awk '{ print $1 }')
IMS_KERNEL_MD5SUM=$(md5sum "${IMS_KERNEL_FILENAME}" | awk '{ print $1 }')

# Use default value for IMS image name if one was not passed in
[[ -n ${IMS_IMAGE_NAME} ]] || IMS_IMAGE_NAME=$(basename "${IMS_ROOTFS_FILENAME}")

IMS_IMAGE_ID=$(cray ims images create --name "${IMS_IMAGE_NAME}" --format json | jq -r .id)
cray artifacts create boot-images "${IMS_IMAGE_ID}/rootfs" "${IMS_ROOTFS_FILENAME}" > /dev/null
cray artifacts create boot-images "${IMS_IMAGE_ID}/kernel" "${IMS_KERNEL_FILENAME}" > /dev/null
cray artifacts create boot-images "${IMS_IMAGE_ID}/initrd" "${IMS_INITRD_FILENAME}" > /dev/null

ROOTFS_ETAG=$( cray artifacts describe boot-images "${IMS_IMAGE_ID}/rootfs" --format json | jq -r .artifact.ETag  | tr -d '"' )
KERNEL_ETAG=$( cray artifacts describe boot-images "${IMS_IMAGE_ID}/kernel" --format json | jq -r .artifact.ETag  | tr -d '"' )
INITRD_ETAG=$( cray artifacts describe boot-images "${IMS_IMAGE_ID}/initrd" --format json | jq -r .artifact.ETag  | tr -d '"' )

IMS_MANIFEST_JSON=$(mktemp -p . ims_manifest_XXX.json)

cat <<EOF> "${IMS_MANIFEST_JSON}"
{
  "created": "$(date '+%Y-%m-%d %H:%M:%S')",
  "version": "1.0",
  "artifacts": [
    {
      "link": {
        "etag": "${ROOTFS_ETAG}",
        "path": "s3://boot-images/${IMS_IMAGE_ID}/rootfs",
        "type": "s3"
      },
      "md5": "${IMS_ROOTFS_MD5SUM}",
      "type": "application/vnd.cray.image.rootfs.squashfs"
    },
    {
      "link": {
        "etag": "${KERNEL_ETAG}",
        "path": "s3://boot-images/${IMS_IMAGE_ID}/kernel",
        "type": "s3"
      },
      "md5": "${IMS_KERNEL_MD5SUM}",
      "type": "application/vnd.cray.image.kernel"
    },
    {
      "link": {
        "etag": "${INITRD_ETAG}",
        "path": "s3://boot-images/${IMS_IMAGE_ID}/initrd",
        "type": "s3"
      },
      "md5": "${IMS_INITRD_MD5SUM}",
      "type": "application/vnd.cray.image.initrd"
    }
  ]
}
EOF

cray artifacts create boot-images "${IMS_IMAGE_ID}/manifest.json" "${IMS_MANIFEST_JSON}" > /dev/null
MANIFEST_ETAG=$( cray artifacts describe boot-images "${IMS_IMAGE_ID}/manifest.json" --format json | jq -r .artifact.ETag  | tr -d '"' )

cray ims images update "${IMS_IMAGE_ID}" \
        --link-type s3 \
        --link-etag "${MANIFEST_ETAG}" \
        --link-path "s3://boot-images/${IMS_IMAGE_ID}/manifest.json" > /dev/null

if update_cpc; then

    # shellcheck disable=SC2089
    PODMAN_RUN="podman run --rm --name ncn-cpc \
        --user root \
        -e PRODUCT=csm \
        -e PRODUCT_VERSION=${CSM_RELEASE} \
        -e YAML_CONTENT_STRING=\"{images: {\"${IMS_IMAGE_NAME}\": {id: \"${IMS_IMAGE_ID}\"}}}\" \
        -e KUBECONFIG=/.kube/admin.conf \
        -e VALIDATE_SCHEMA=\"true\" \
        -v /etc/kubernetes:/.kube:ro \
        registry.local/artifactory.algol60.net/csm-docker/stable/cray-product-catalog-update:${CPC_VERSION}"

    if [[ -f /etc/pit-release ]]; then
        FM=$(jq -r '."Global"."meta-data"."first-master-hostname"' < "${PITDATA}"/configs/data.json)

        # shellcheck disable=SC2090,SC2086
        ssh "${FM}" ${PODMAN_RUN} >& /dev/null
    else
        podman run --rm --name ncn-cpc \
            --user root \
            -e PRODUCT=csm \
            -e PRODUCT_VERSION="${CSM_RELEASE}" \
            -e YAML_CONTENT_STRING="{images: {\"$IMS_IMAGE_NAME\": {id: \"$IMS_IMAGE_ID\"}}}" \
            -e KUBECONFIG=/.kube/admin.conf \
            -e VALIDATE_SCHEMA="true" \
            -v /etc/kubernetes:/.kube:ro \
            registry.local/artifactory.algol60.net/csm-docker/stable/cray-product-catalog-update:"${CPC_VERSION}" >& /dev/null
    fi

fi

echo "${IMS_IMAGE_ID}"
