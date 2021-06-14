#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
trap 'err_report' ERR
. ./myenv

export UPGRADE_NCN=$1
export STABLE_NCN=$(hostname)

export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
   -d client_id=admin-client \
   -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

export UPGRADE_XNAME=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/apis/sls/v1/search/hardware?extra_properties.Role=Management" | \
     jq -r ".[] | select(.ExtraProperties.Aliases[] | contains(\"$UPGRADE_NCN\")) | .Xname")

export UPGRADE_IP_NMN=$(dig +short $UPGRADE_NCN.nmn)

if [[ -z ${IPMI_USERNAME} ]]; then
   export IPMI_USERNAME=root
   echo "IPMI_USERNAME environment variable is not set. Use default value"
fi

if [[ -z ${IPMI_PASSWORD} ]]; then
   export IPMI_PASSWORD=initial0
   echo "IPMI_PASSWORD environment variable is not set. Use default value"
fi

if [[ -z ${SW_USERNAME} ]]; then
   export SW_USERNAME=root
   echo "SW_USERNAME environment variable is not set. Use default value"
fi

if [[ -z ${SW_PASSWORD} ]]; then
   export SW_PASSWORD="!nitial0"
   echo "SW_PASSWORD environment variable is not set. Use default value"
fi

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
      echo "====> ${state_name} has beed completed"
   fi
}