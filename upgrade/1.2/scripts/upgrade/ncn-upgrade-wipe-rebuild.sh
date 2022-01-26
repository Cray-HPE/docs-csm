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
upgrade_ncn=$1

. ${BASEDIR}/ncn-upgrade-common.sh ${upgrade_ncn}

echo " ****** DATA LOSS ON ${upgrade_ncn} - FRESH OS INSTALL UPON REBOOT ******"
echo " ****** BACKUP DATA ON ${upgrade_ncn} TO USB OR OTHER SAFE LOCATION ******"
echo " ****** DATA MANAGED BY K8S/CEPH WILL BE BACKED UP/RESTORED AUTOMATICALLY ******"
read -p "Read and act on above steps. Press Enter key to continue ..."

state_name="REBUILD_NODE"
state_recorded=$(is_state_recorded "${state_name}" ${upgrade_ncn})
if [[ $state_recorded == "0" ]]; then
    echo "====> ${state_name} ..."
    echo
    echo " ***** Rebuild Node: ${upgrade_ncn} *****"
    echo
    # run cfs job
    session_name="ncn-rebuild-${upgrade_ncn}-$(date +%s)"
    cray cfs sessions create --name ${session_name} \
        --configuration-name rebuild-ncn \
        --ansible-verbosity 1 \
        --ansible-limit $(ssh ${upgrade_ncn} 'cat /etc/cray/xname')

    cfs_job_id=$(cray cfs sessions describe ${session_name} --format json  | jq -r '.status.session.job')

    cat <<EOF
TIPS:
    watch cfs job progress:
        kubectl logs -f -n services --selector=job-name=${cfs_job_id} -c ansible-0
EOF

    echo "Wait for CFS job"
    while true ; do
        cfs_job_status=$(cray cfs sessions describe ${session_name} --format json  | jq -r '.status.session.status')
        if [[ ${cfs_job_status} == "complete" ]] ; then
            cfs_job_succeeded=$(cray cfs sessions describe ${session_name} --format json  | jq -r '.status.session.succeeded')
            if [[ ${cfs_job_succeeded} == "false" ]]; then
                echo "cfs job: ${cfs_job_id} failed"
                kubectl logs -n services --selector=job-name=${cfs_job_id} -c ansible-0
                exit 1
            fi
            break
        fi
        printf "%c" "."
        sleep 10
    done
    record_state "${state_name}" ${upgrade_ncn}
else
    echo "====> ${state_name} has been completed"
fi




