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

# Must run from m001
if [[ $(hostname) != ncn-m001 ]]; then
    echo "Must be run on m001"
    exit 1
fi

# Yapl must be installed
rpm -qi yapl > /dev/null 2>&1 || (echo "Yapl must be installed"; exit 1)

#export CSM_RELEASE=1.4.2
# Check that needed environment variables are set
env_vars=("CSM_RELEASE" "SYSTEM_NAME")
for each in "${env_vars[@]}"; do
    if [ -z "${!each}" ]; then
        echo "$each must be defined"
        exit 1
    fi
done

export PITDATA=/var/www/ephemeral
export CSM_PATH="${PITDATA}/csm-${CSM_RELEASE}"
export SLS_INPUT_FILE=${PITDATA}/prep/${SYSTEM_NAME}/sls_input_file.json

# Reset all the NCN keys
truncate --size=0 /root/.ssh/known_hosts 2>&1
grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh-keyscan -H \{\} >> /root/.ssh/known_hosts

# Copy the k8s admin conf from m002
scp ncn-m002:/etc/kubernetes/admin.conf /etc/kubernetes/admin.conf
cp /etc/kubernetes/admin.conf  $HOME/.kube/config

# Clear the whole IPVS routing table on m001 (this may have been setup if kube-proxy was ever running on m001).
# This will allow for m001 use unbound once it is running in the k8s cluster.
ipvsadm --clear

# Start the CSM install
pushd /usr/share/doc/csm/install/scripts/csm_services
yapl -f install1thru4.yaml execute --no-cache
if [[ $? -ne 0 ]]
then
   echo "Address any above errors and re-run the rapid_reinstall.sh"
   exit 1
fi

# Edit the host file to move from the pit nexus to k8s nexus for packages.local and registry.local.
# This is needed before step5 where k8s nexus is setup.
UNBOUNDIP=10.92.100.71
ncnregistry="${UNBOUNDIP}    registry.local packages.local"
sed -i "s/.*registry.*/${ncnregistry}/" /etc/hosts

# Complete the CSM install
yapl -f install5thru7.yaml execute --no-cache
popd

# Post install WARs
# If the keycloak users-localize job failed, re-run it.
kubectl get job -l app.kubernetes.io/instance=cray-keycloak-users-localize -n services --no-headers | grep -q "1/1"
if [[ $? -eq 0 ]]
then
   echo "Keycloak users-localize job completed"
else
   echo "Keycloak users-localize job failed -- re running ..."
   LOCALIZE_JOB=$(kubectl -n services get jobs -l app.kubernetes.io/name=cray-keycloak-users-localize -o name)
   kubectl -n services get "${LOCALIZE_JOB}" -o json | jq 'del(.spec.selector)' \
       | jq 'del(.spec.template.metadata.labels."controller-uid")' \
       | kubectl replace --force -f -
   kubectl -n services wait "${LOCALIZE_JOB}" --for=condition=complete --timeout=15m
fi

# Create base BSS Global boot parameters
# https://github.com/Cray-HPE/docs-csm/blob/release/1.4/install/install_csm_services.md#2-create-base-bss-global-boot-parameters
export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                  -d client_id=admin-client \
                  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
curl -i -k -H "Authorization: Bearer ${TOKEN}" -X PUT \
    https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters \
    --data '{"hosts":["Global"]}'

SPIRE_JOB=$(kubectl -n spire get jobs -l app.kubernetes.io/name=spire-update-bss -o name)
kubectl -n spire get "${SPIRE_JOB}" -o json | jq 'del(.spec.selector)' \
    | jq 'del(.spec.template.metadata.labels."controller-uid")' \
    | kubectl replace --force -f -
kubectl -n spire wait "${SPIRE_JOB}" --for=condition=complete --timeout=5m
