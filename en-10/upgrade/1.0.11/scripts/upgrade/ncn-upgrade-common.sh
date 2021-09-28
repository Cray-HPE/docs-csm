#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR
touch /etc/cray/upgrade/csm/myenv
. /etc/cray/upgrade/csm/myenv

# make an array of all the csm versions that are installed
IFS=$'\n' \
  read -r -d '' \
  -a csm_versions \
  < <(kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}' \
    | yq r -j - \
    | jq -r 'keys[]' \
    | sed '/-/!{s/$/_/}' \
    | sort -V \
    | sed 's/_$//' \
      && printf '\0')

for i in "${csm_versions[@]}"
do
  if [[ "$i" == 1.* ]]; then
    # if 1.x is already installed set the var to true and break the loop
    export CSM1_EXISTS="true"
    break
  else
    export CSM1_EXISTS="false"
  fi
done

export UPGRADE_NCN=$1
export STABLE_NCN=$(hostname)

export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
   -d client_id=admin-client \
   -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

export UPGRADE_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | \
     jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$UPGRADE_NCN\")) | .Xname")


export UPGRADE_MGMT_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | \
     jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$UPGRADE_NCN\")) | .Parent")

export UPGRADE_IP_NMN=$(dig +short $UPGRADE_NCN.nmn)

function drain_node() {
   upgrade_ncn=$1
   state_name="DRAIN_NODE"
   state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."
      /usr/share/doc/csm/upgrade/1.0.11/scripts/k8s/remove-k8s-node.sh $upgrade_ncn

      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo "====> ${state_name} has been completed"
   fi
}

function ssh_keygen_keyscan() {
    local upgrade_ncn ncn_ip known_hosts
    known_hosts="/root/.ssh/known_hosts"
    sed -i 's@pdsh.*@@' $known_hosts
    upgrade_ncn="$1"
    ncn_ip=$(host ${upgrade_ncn} | awk '{ print $NF }')
    [ -n "${ncn_ip}" ]
    # Because we may be called without set -e, we should check return codes after running commands
    [ $? -ne 0 ] && return 1
    echo "Updating SSH keys for node ${upgrade_ncn} with IP address of ${ncn_ip}"
    ssh-keygen -R "${upgrade_ncn}" -f "${known_hosts}" > /dev/null 2>&1
    [ $? -ne 0 ] && return 1
    ssh-keygen -R "${ncn_ip}" -f "${known_hosts}" > /dev/null 2>&1
    [ $? -ne 0 ] && return 1
    ssh-keyscan -H "${upgrade_ncn},${ncn_ip}" >> "${known_hosts}"
    return $?
}
