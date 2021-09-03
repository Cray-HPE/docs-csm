#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR
touch /etc/cray/upgrade/csm/myenv
. /etc/cray/upgrade/csm/myenv

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
      /usr/share/doc/csm/upgrade/1.0/scripts/k8s/remove-k8s-node.sh $upgrade_ncn

      record_state "${state_name}" ${upgrade_ncn}
      echo
   else
      echo "====> ${state_name} has been completed"
   fi
}

function ssh_keygen_keyscan() {
    local upgrade_ncn ncn_ip known_hosts
    known_hosts="/root/.ssh/known_hosts"
    upgrade_ncn="$1"
    ncn_ip=$(host ${upgrade_ncn} | awk '{ print $NF }')
    [ -n "${ncn_ip}" ]
    # Since we may be called without set -e, we should check return codes after running commands
    [ $? -ne 0 ] && return 1
    echo "${upgrade_ncn} IP address is ${ncn_ip}"
    ssh-keygen -R "${upgrade_ncn}" -f "${known_hosts}"
    [ $? -ne 0 ] && return 1
    ssh-keygen -R "${ncn_ip}" -f "${known_hosts}"
    [ $? -ne 0 ] && return 1
    ssh-keyscan -H "${upgrade_ncn},${ncn_ip}" >> "${known_hosts}"
    return $?
}
