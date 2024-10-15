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

set -e
basedir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
. ${basedir}/upgrade-state.sh
trap 'err_report' ERR
target_ncn=$1

. ${basedir}/ncn-common.sh ${target_ncn}

state_name="FORCE_TIME_SYNC"
state_recorded=$(is_state_recorded "${state_name}" ${target_ncn})
TOKEN=$(curl -s -S -d grant_type=client_credentials \
  -d client_id=admin-client \
  -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export TOKEN
if [[ $state_recorded == "0" ]]; then
  echo "====> ${state_name} ..."
  {
    ssh_keygen_keyscan "${target_ncn}"
    # TODO: This is used in ncn-rebuild-common.sh
    # ssh_keys_done=1
    ssh "$target_ncn" "TOKEN=$TOKEN /srv/cray/scripts/common/chrony/csm_ntp.py"
    loop_idx=0
    in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
    if [[ $in_sync == "no" ]]; then
      ssh "$target_ncn" chronyc makestep
      sleep 5
      in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
      # wait up to 90s for the node to be in sync
      while [[ $loop_idx -lt 18 && $in_sync == "no" ]]; do
        sleep 5
        in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
        loop_idx=$((loop_idx + 1))
      done
      if [[ $in_sync == "yes" ]]; then
        record_state "${state_name}" "${target_ncn}"
      fi
      # else wait for goss tests to catch time sync problems during CSM health checks
    else
      record_state "${state_name}" "${target_ncn}"
    fi
  } >> ${LOG_FILE} 2>&1
else
  echo "====> ${state_name} has been completed"
fi
