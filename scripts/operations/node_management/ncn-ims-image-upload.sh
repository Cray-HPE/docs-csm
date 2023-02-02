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
# shellcheck disable=SC2086

test -n "$DEBUG" && set -x
set -eou pipefail

unset CRAY_FORMAT

while [[ $# -gt 0 ]]; do
    case $1 in
        -k)
            IMS_KERNEL_FILENAME=$2
            shift
            shift
            ;;
        -i)
            IMS_INITRD_FILENAME=$2
            shift
            shift
            ;;
        -s)
            IMS_ROOTFS_FILENAME=$2
            shift
            shift
            ;;
    esac
done

if [ -z "$IMS_KERNEL_FILENAME" ]; then
    echo "Error: required option (-k) is missing" >&2
    exit 1
fi

if [ -z "$IMS_INITRD_FILENAME" ]; then
    echo "Error: required option (-i) is missing" >&2
    exit 1
fi

if [ -z "$IMS_ROOTFS_FILENAME" ]; then
    echo "Error: required option (-s) is missing" >&2
    exit 1
fi

if [[ -z ${CSM_RELEASE} ]]; then
    echo "\$CSM_RELEASE is not specified" >&2
    exit 1
fi

if [[ -z ${CSM_ARTI_DIR} ]] && [[ -z ${CSM_PATH} ]]; then
    echo "One of \$CSM_ARTI_DIR or \$CSM_PATH must be set to the path of unpacked CSM tarball" >&2
    exit 1
fi

CSM_TARBALL=${CSM_ARTI_DIR:-$CSM_PATH}

CPC_VERSION=$(find "$CSM_TARBALL"/docker/artifactory.algol60.net/csm-docker/stable/ -maxdepth 1 | awk -F':' /cray-product-catalog-update/'{print $NF}' | sort -V | tail -1)

IMS_ROOTFS_MD5SUM=$(md5sum "$IMS_ROOTFS_FILENAME" | awk '{ print $1 }')
IMS_INITRD_MD5SUM=$(md5sum "$IMS_INITRD_FILENAME" | awk '{ print $1 }')
IMS_KERNEL_MD5SUM=$(md5sum "$IMS_KERNEL_FILENAME" | awk '{ print $1 }')

IMS_IMAGE_NAME=$(basename "${IMS_ROOTFS_FILENAME}")
IMS_IMAGE_ID=$(cray ims images create --name "${IMS_IMAGE_NAME}" --format json | jq -r .id)
cray artifacts create boot-images "$IMS_IMAGE_ID/rootfs" "$IMS_ROOTFS_FILENAME" > /dev/null
cray artifacts create boot-images "$IMS_IMAGE_ID/kernel" "$IMS_KERNEL_FILENAME" > /dev/null
cray artifacts create boot-images "$IMS_IMAGE_ID/initrd" "$IMS_INITRD_FILENAME" > /dev/null

ROOTFS_ETAG=$( cray artifacts describe boot-images ${IMS_IMAGE_ID}/rootfs --format json | jq -r .artifact.ETag  | tr -d '"' )
KERNEL_ETAG=$( cray artifacts describe boot-images ${IMS_IMAGE_ID}/kernel --format json | jq -r .artifact.ETag  | tr -d '"' )
INITRD_ETAG=$( cray artifacts describe boot-images ${IMS_IMAGE_ID}/initrd --format json | jq -r .artifact.ETag  | tr -d '"' )

cat <<EOF> ims_manifest.json
{
  "created": "$(date '+%Y-%m-%d %H:%M:%S')",
  "version": "1.0",
  "artifacts": [
    {
      "link": {
        "etag": "${ROOTFS_ETAG}",
        "path": "s3://boot-images/$IMS_IMAGE_ID/rootfs",
        "type": "s3"
      },
      "md5": "$IMS_ROOTFS_MD5SUM",
      "type": "application/vnd.cray.image.rootfs.squashfs"
    },
    {
      "link": {
        "etag": "${KERNEL_ETAG}",
        "path": "s3://boot-images/$IMS_IMAGE_ID/kernel",
        "type": "s3"
      },
      "md5": "$IMS_KERNEL_MD5SUM",
      "type": "application/vnd.cray.image.kernel"
    },
    {
      "link": {
        "etag": "${INITRD_ETAG}",
        "path": "s3://boot-images/$IMS_IMAGE_ID/initrd",
        "type": "s3"
      },
      "md5": "$IMS_INITRD_MD5SUM",
      "type": "application/vnd.cray.image.initrd"
    }
  ]
}
EOF

cray artifacts create boot-images "$IMS_IMAGE_ID/manifest.json" ims_manifest.json > /dev/null
MANIFEST_ETAG=$( cray artifacts describe boot-images ${IMS_IMAGE_ID}/manifest.json --format json | jq -r .artifact.ETag  | tr -d '"' )

cray ims images update "$IMS_IMAGE_ID" \
        --link-type s3 \
        --link-etag "${MANIFEST_ETAG}" \
        --link-path "s3://boot-images/$IMS_IMAGE_ID/manifest.json" > /dev/null

podman run --rm --name ncn-cpc \
    --user root \
    -e PRODUCT=csm \
    -e PRODUCT_VERSION=$CSM_RELEASE \
    -e YAML_CONTENT_STRING="{images: {\"$IMS_IMAGE_NAME\": {id: \"$IMS_IMAGE_ID\"}}}" \
    -e KUBECONFIG=/.kube/admin.conf \
    -e VALIDATE_SCHEMA="true" \
    -v /etc/kubernetes:/.kube:ro \
    artifactory.algol60.net/csm-docker/stable/cray-product-catalog-update:$CPC_VERSION > /dev/null

echo "$IMS_IMAGE_ID"
