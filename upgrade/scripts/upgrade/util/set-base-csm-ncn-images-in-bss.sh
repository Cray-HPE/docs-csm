#!/bin/bash
#
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
#
echo "This script should be used during a CSM ONLY upgrade."
echo -e "This will set the CSM BASE NCN images in BSS for all NCN nodes.\n"

if [[ $(hostname) != 'ncn-m001' ]]; then
  echo "ERROR this script should be run from ncn-m001. It is not expected to run on $(hostname)."
  exit 1
fi

if [[ -f /etc/cray/upgrade/csm/myenv ]]; then
  source /etc/cray/upgrade/csm/myenv
else
  echo "ERROR did not find '/etc/cray/upgrade/csm/myenv' file."
  echo "It is expected that prerequisites.sh has run and has set values in '/etc/cray/upgrade/csm/myenv'."
  echo "Please verify 'prerequisistes.sh' has run successfully."
  exit 1
fi

if [[ -z $K8S_IMS_IMAGE_ID ]] || [[ -z $STORAGE_IMS_IMAGE_ID ]]; then
   echo "ERROR did not find 'STORAGE_IMS_IMAGE_ID' or 'K8S_IMS_IMAGE_ID' in '/etc/cray/upgrade/csm/myenv'."
   echo "Verify that 'prerequisistes.sh' has run successfully."
   exit 1
fi

echo "Retrieving a list of all management node component names (xnames)"
set -o pipefail

WORKER_XNAMES=$(cray hsm state components list --role Management --subrole Worker --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
[[ -n ${WORKER_XNAMES} ]]
MASTER_XNAMES=$(cray hsm state components list --role Management --subrole Master --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
[[ -n ${MASTER_XNAMES} ]]
K8S_XNAMES="$WORKER_XNAMES $MASTER_XNAMES"
K8S_XNAME_LIST=${K8S_XNAMES//,/ }
STORAGE_XNAMES=$(cray hsm state components list --role Management --subrole Storage --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
[[ -n ${STORAGE_XNAMES} ]]
STORAGE_XNAME_LIST=${STORAGE_XNAMES//,/ }
set +o pipefail

echo "Setting image: ${K8S_IMS_IMAGE_ID} on K8s nodes."
for xname in ${K8S_XNAME_LIST}; do
  METAL_SERVER=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
    | awk -F 'metal.server=' '{print $2}' \
    | awk -F ' ' '{print $1}')
  NEW_METAL_SERVER="s3://boot-images/${K8S_IMS_IMAGE_ID}/rootfs"
  PARAMS=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
    | sed "/metal.server/ s|${METAL_SERVER}|${NEW_METAL_SERVER}|" \
    | tr -d \")

  echo "Setting image on $xname"
  cray bss bootparameters update --hosts "${xname}" \
    --kernel "s3://boot-images/${K8S_IMS_IMAGE_ID}/kernel" \
    --initrd "s3://boot-images/${K8S_IMS_IMAGE_ID}/initrd" \
    --params "${PARAMS}"
done
echo "Setting image: ${STORAGE_IMS_IMAGE_ID} on storage nodes."
for xname in ${STORAGE_XNAME_LIST}; do
  METAL_SERVER=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
    | awk -F 'metal.server=' '{print $2}' \
    | awk -F ' ' '{print $1}')
  NEW_METAL_SERVER="s3://boot-images/${STORAGE_IMS_IMAGE_ID}/rootfs"
  PARAMS=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
    | sed "/metal.server/ s|${METAL_SERVER}|${NEW_METAL_SERVER}|" \
    | tr -d \")

  echo "Setting image on $xname"
  cray bss bootparameters update --hosts "${xname}" \
    --kernel "s3://boot-images/${STORAGE_IMS_IMAGE_ID}/kernel" \
    --initrd "s3://boot-images/${STORAGE_IMS_IMAGE_ID}/initrd" \
    --params "${PARAMS}"
done

echo "Done. The CSM base image has been set in BSS for all NCNs."
