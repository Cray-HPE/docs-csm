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
. ${basedir}/../common/upgrade-state.sh
#shellcheck disable=SC2046
. ${basedir}/../common/ncn-common.sh $(hostname)
trap 'err_report' ERR
# array for paths to unmount after chrooting images
#shellcheck disable=SC2034
declare -a UNMOUNTS=()


state_name="CHECK_DOC_RPM"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    if [[ ! -f /root/docs-csm-latest.noarch.rpm ]]; then
        echo "ERROR: docs-csm-latest.noarch.rpm is missing under: /root -- halting..."
        exit 1
    fi
    rpm -Uvh --force /root/docs-csm-latest.noarch.rpm
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="SNAPSHOOT_CPS_DEPLOYMENT"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    ${basedir}/../cps/snapshot-cps-deployment.sh
    
    #shellcheck disable=SC2046
    record_state ${state_name} $(hostname)
else
    echo "====> ${state_name} has been completed"
fi

state_name="ELIMINATE_NTP_CLOCK_SKEW_M001"
state_recorded=$(is_state_recorded "${state_name}" "${target_ncn}")
if [[ $state_recorded == "0" && $2 != "--rebuild" ]]; then
    echo "====> ${state_name} ..."
    {
    if [[ "${target_ncn}" == "ncn-m001" ]]; then
      # ensure the directory exists
      mkdir -p /srv/cray/scripts/common/
      # copy the NTP script and template to ncn-m001
      cp -r --preserve=mode "${CSM_ARTI_DIR}"/chrony/ /srv/cray/scripts/common/
      # run the script
      if ! TOKEN=$TOKEN /srv/cray/scripts/common/chrony/csm_ntp.py; then
          echo "${target_ncn} csm_ntp failed"
          exit 1
      else
          record_state "${state_name}" "${target_ncn}"
      fi

      # if the node is not in sync after three minutes, fail
      # ncn-m001 can take a little longer to syncrhonize, so it waits longer than the normal test
      if ! ssh "${target_ncn}" 'chronyc waitsync 6 0.5 0.5 30'; then
          echo "${target_ncn} the clock is not in sync.  Wait a bit more or try again."
          exit 1
      else
          record_state "${state_name}" "${target_ncn}"
      fi
    fi
    } >> ${LOG_FILE} 2>&1
else
    echo "====> ${state_name} has been completed"
fi

ok_report
