#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023-2024 Hewlett Packard Enterprise Development LP
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

set -u

CSM_ARTI_DIR=${CSM_DISTDIR:-''}
CSM_RELEASE=${CSM_RELEASE_VERSION:-''}

# CSM_ARTI_DIR and CSM_RELEASE are required for ncn-ims-image-upload.sh script used below
if [[ -z ${CSM_ARTI_DIR} ]]; then
  echo "CSM_DISTDIR environment variable needs to be set and exported. It should be set to the path \
of the extracted CSM product release."
  exit 1
fi

if [[ -z ${CSM_RELEASE} ]]; then
  echo "CSM_RELEASE_VERSION environment variable needs to be set and exported. It should be set to the \
version of CSM being patched. For example 'export CSM_RELEASE_VERSION=\"1.4.1\"'"
  exit 1
fi

export CSM_ARTI_DIR
export CSM_RELEASE

artdir=${CSM_ARTI_DIR}/images
SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
export SQUASHFS_ROOT_PW_HASH
set -o pipefail
NCN_IMAGE_MOD_SCRIPT=$(rpm -ql docs-csm | grep ncn-image-modification.sh)
set +o pipefail

KUBERNETES_VERSION=$(find "${artdir}/kubernetes" -name 'kubernetes*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')
CEPH_VERSION=$(find "${artdir}/storage-ceph" -name 'storage-ceph*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')

k8s_done=0
ceph_done=0
arch="$(uname -i)"
if [[ -f ${artdir}/kubernetes/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs ]]; then
  k8s_done=1
fi
if [[ -f ${artdir}/storage-ceph/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs ]]; then
  ceph_done=1
fi

if [[ ${k8s_done} == 1 && ${ceph_done} == 1 ]]; then
  echo "Already ran ${NCN_IMAGE_MOD_SCRIPT}, skipping re-run."
else
  rm -f "${artdir}/storage-ceph/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs" "${artdir}/kubernetes/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs"
  DEBUG=1 "${NCN_IMAGE_MOD_SCRIPT}" \
    -d /root/.ssh \
    -k "${artdir}/kubernetes/kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs" \
    -s "${artdir}/storage-ceph/storage-ceph-${CEPH_VERSION}-${arch}.squashfs" \
    -p
fi

set -o pipefail
IMS_UPLOAD_SCRIPT=$(rpm -ql docs-csm | grep ncn-ims-image-upload.sh)

UUID_REGEX='^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$'

echo "Uploading Kubernetes images..."
export IMS_ROOTFS_FILENAME="${artdir}/kubernetes/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs"
# do not quote this glob.  bash will add single ticks (') around it, preventing expansion later
IMS_INITRD_FILENAME=$(echo ${artdir}/kubernetes/initrd*.xz)
IMS_KERNEL_FILENAME=$(echo ${artdir}/kubernetes/*.kernel)
export IMS_INITRD_FILENAME
export IMS_KERNEL_FILENAME
K8S_IMS_IMAGE_ID=$($IMS_UPLOAD_SCRIPT)
[[ -n ${K8S_IMS_IMAGE_ID} ]] && [[ ${K8S_IMS_IMAGE_ID} =~ $UUID_REGEX ]]

echo "Uploading Ceph images..."
export IMS_ROOTFS_FILENAME="${artdir}/storage-ceph/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs"
# do not quote this glob.  bash will add single ticks (') around it, preventing expansion later
IMS_INITRD_FILENAME=$(echo ${artdir}/storage-ceph/initrd*.xz)
IMS_KERNEL_FILENAME=$(echo ${artdir}/storage-ceph/*.kernel)
export IMS_INITRD_FILENAME
export IMS_KERNEL_FILENAME
STORAGE_IMS_IMAGE_ID=$($IMS_UPLOAD_SCRIPT)
[[ -n ${STORAGE_IMS_IMAGE_ID} ]] && [[ ${STORAGE_IMS_IMAGE_ID} =~ $UUID_REGEX ]]
set +o pipefail

# clean up any previous set values just in case.
echo "Updating image ids..."
touch /etc/cray/upgrade/csm/myenv
sed -i 's/^export STORAGE_IMS_IMAGE_ID.*//' /etc/cray/upgrade/csm/myenv
sed -i 's/^export KUBERNETES_IMS_IMAGE_ID.*//' /etc/cray/upgrade/csm/myenv
echo "export STORAGE_IMS_IMAGE_ID=${STORAGE_IMS_IMAGE_ID}" >> /etc/cray/upgrade/csm/myenv
echo "export K8S_IMS_IMAGE_ID=${K8S_IMS_IMAGE_ID}" >> /etc/cray/upgrade/csm/myenv
