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
basedir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${basedir}/upgrade-state.sh
trap 'err_report' ERR
touch /etc/cray/upgrade/csm/myenv
. /etc/cray/upgrade/csm/myenv

if [[ -z ${LOG_FILE} ]]; then
    export LOG_FILE="/root/output.log"
    echo
    echo
    echo " ************"
    echo " *** NOTE ***"
    echo " ************"
    echo "LOG_FILE is not specified; use default location: ${LOG_FILE}"
    echo
fi

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

export TARGET_NCN=$1
export STABLE_NCN=$(hostname)

export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
   -d client_id=admin-client \
   -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

export TARGET_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | \
     jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$TARGET_NCN\")) | .Xname")


export TARGET_MGMT_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | \
     jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$TARGET_NCN\")) | .Parent")

export TARGET_IP_NMN=$(dig +short $TARGET_NCN.nmn)

function drain_node() {
   target_ncn=$1
   state_name="DRAIN_NODE"
   state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
   if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."
      {
      csi automate ncn kubernetes --action delete-ncn --ncn ${target_ncn} --kubeconfig /etc/kubernetes/admin.conf
      } >> ${LOG_FILE} 2>&1

      record_state "${state_name}" ${target_ncn}
      echo
   else
      echo "====> ${state_name} has been completed"
   fi
}

function ssh_keygen_keyscan() {
    set +e
    local target_ncn ncn_ip known_hosts
    known_hosts="/root/.ssh/known_hosts"
    sed -i 's@pdsh.*@@' $known_hosts
    target_ncn="$1"
    ncn_ip=$(host ${target_ncn} | awk '{ print $NF }')
    [ -n "${ncn_ip}" ]
    # Because we run with set +e in this function, check return codes after running commands
    [ $? -ne 0 ] && return 1
    echo "Updating SSH keys for node ${target_ncn} with IP address of ${ncn_ip}"
    ssh-keygen -R "${target_ncn}" -f "${known_hosts}" > /dev/null 2>&1
    [ $? -ne 0 ] && return 1
    ssh-keygen -R "${ncn_ip}" -f "${known_hosts}" > /dev/null 2>&1
    [ $? -ne 0 ] && return 1
    ssh-keyscan -H "${target_ncn},${ncn_ip}" >> "${known_hosts}"  > /dev/null 2>&1
    res=$?

    # remove the old authorized_hosts entry for the target NCN cluster-wide
    {
        NCNS=$(grep -oP 'ncn-w\w\d+|ncn-s\w\d+' /etc/hosts | sort -u)
        HOSTS=$(echo $NCNS | tr -t ' ' ',')
        pdsh -w $HOSTS ssk-keygen -R ${target-ncn}
        pdsh -w $HOSTS ssk-keygen -R ${ncn_ip}
    } >& /dev/null

    set -e
    return $res
}

function wait_for_kubernetes() {
  local target_ncn=$1
  state_name="WAIT_FOR_K8S"
  state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
  if [[ $state_recorded == "0" ]]; then
      echo "====> ${state_name} ..."
      {
      set +e
      echo "waiting for k8s: $target_ncn ..."
      until csi automate ncn kubernetes --action is-member --ncn $target_ncn --kubeconfig /etc/kubernetes/admin.conf
      do
          sleep 5
      done
      # Restore set -e
      set -e
      echo "$target_ncn joined k8s"
      } >> ${LOG_FILE} 2>&1

      record_state "${state_name}" ${target_ncn}
  else
      echo "====> ${state_name} has been completed"
  fi
}
