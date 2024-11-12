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
. ${basedir}/../common/upgrade-state.sh
. ${basedir}/../common/k8s-common.sh
trap 'err_report' ERR

. /etc/cray/upgrade/csm/myenv

if [[ -z ${CSM_REL_NAME} ]]; then
  echo "ERROR: CSM_REL_NAME environment variable is not set and must be present in /etc/cray/upgrade/csm/myenv."
  exit 1
fi

if [[ ! -f ${PREREQS_DONE_FILE} ]]; then
  echo "ERROR: prerequisites.sh script was not completed successfully."
  echo "To fix the error, please re-run the prerequisites.sh script successfully before upgrading."
  exit 1
fi

if [[ -z ${LOG_FILE} ]]; then
  #shellcheck disable=SC2155
  export LOG_FILE="/root/output.log"
  echo
  echo
  echo " ************"
  echo " *** NOTE ***"
  echo " ************"
  echo "LOG_FILE is not specified; use default location: ${LOG_FILE}"
  echo
fi

state_name="VERIFY_K8S_NODES_UPGRADED"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
  echo "====> ${state_name} ..."
  {
    /usr/share/doc/csm/upgrade/scripts/upgrade/util/verify-k8s-nodes-upgraded.sh
  } >> ${LOG_FILE} 2>&1
  #shellcheck disable=SC2046
  record_state ${state_name} $(hostname)
else
  echo "====> ${state_name} has been completed"
fi

state_name="PRE_CEPH_CSI_TARGET_REQUIREMENTS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
  echo "====> ${state_name} ..."
  {
    scp ncn-s001:/srv/cray/scripts/common/csi-configuration.sh /tmp/csi-configuration.sh
    pool=$(ceph fs ls --format json-pretty | jq -r '.[] | select(. "name" == "cephfs") | .data_pools[]')
    sed -i "s/.*ceph fs ls.*/         pool: $pool/" /tmp/csi-configuration.sh
    mkdir -p /srv/cray/tmp
    . /tmp/csi-configuration.sh
    create_ceph_rbd_1.2_csi_configmap
    create_ceph_cephfs_1.2_csi_configmap
    create_k8s_1.2_ceph_secrets
    create_sma_1.2_ceph_secrets
    create_cephfs_1.2_ceph_secrets
    create_k8s_1.2_storage_class
    create_sma_1.2_storage_class
    create_cephfs_1.2_storage_class
  } >> ${LOG_FILE} 2>&1
  #shellcheck disable=SC2046
  record_state ${state_name} $(hostname)
else
  echo "====> ${state_name} has been completed"
fi

state_name="PRE_CSM_SERVICES_UPGRADE_BUCKETS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
  target_ncn="ncn-s001"
  echo "====> ${state_name} ..."
  {
    scp /usr/share/doc/csm/upgrade/scripts/ceph/create_rgw_buckets.sh $target_ncn:/tmp
    scp /usr/share/doc/csm/upgrade/scripts/ceph/csm-1.5-new-buckets.yml $target_ncn:/tmp
    ssh ${target_ncn} '/tmp/create_rgw_buckets.sh'
  } >> ${LOG_FILE} 2>&1
  record_state ${state_name} "$(hostname)"
else
  echo "====> ${state_name} has been completed"
fi

state_name="CSM_SERVICE_UPGRADE"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
  echo "====> ${state_name} ..."
  {
    pushd ${CSM_ARTI_DIR}
    ./upgrade.sh
    popd +0
  } >> ${LOG_FILE} 2>&1
  #shellcheck disable=SC2046
  record_state ${state_name} $(hostname)
else
  echo "====> ${state_name} has been completed"
fi

state_name="POST_CSM_ENABLE_PSP"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
  echo "====> ${state_name} ..."
  {
    /usr/share/doc/csm/upgrade/scripts/k8s/enable-psp.sh
  } >> ${LOG_FILE} 2>&1
  #shellcheck disable=SC2046
  record_state ${state_name} $(hostname)
else
  echo "====> ${state_name} has been completed"
fi

state_name="FIX_SPIRE_ON_STORAGE"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
  echo "====> ${state_name} ..."
  {
    /opt/cray/platform-utils/spire/fix-spire-on-storage.sh
  } >> ${LOG_FILE} 2>&1
  #shellcheck disable=SC2046
  record_state ${state_name} $(hostname)
else
  echo "====> ${state_name} has been completed"
fi

# Restart CFS deployments to avoid CASMINST-6852
"${basedir}/../common/restart-cfs.sh"

state_name="UPDATE_TEST_CLI_RPMS"
#shellcheck disable=SC2046
state_recorded=$(is_state_recorded "${state_name}" $(hostname))
if [[ $state_recorded == "0" ]]; then
  echo "====> ${state_name} ..."
  {
    # Update test/CLI RPMs on NCNs
    "${basedir}/util/upgrade-test-rpms.sh"
  } >> ${LOG_FILE} 2>&1
  #shellcheck disable=SC2046
  record_state ${state_name} $(hostname)
else
  echo "====> ${state_name} has been completed"
fi

# Back up BOS data post-sysmgmt upgrade, and record contents of the migration pod
# This only needs to be done if the cray-bos-migration job exists
job_name=cray-bos-migration
ns=services
state_name="POST_UPGRADE_BOS_SNAPSHOT"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ $state_recorded == "0" ]] && k8s_job_exists "${ns}" "${job_name}"; then
  echo "====> ${state_name} ..."
  {
    # Make sure the BOS migration job is complete (succeeded or failed)
    job_error=""
    wait_for_k8s_job_to_succeed "${ns}" "${job_name}" || job_error="migration_job_not_successful."

    DATESTRING=$(date +%Y-%m-%d_%H-%M-%S)
    SNAPSHOT_DIR=$(mktemp -d --tmpdir=/root "csm_upgrade.post_bos_upgrade_snapshot.${job_error}${DATESTRING}.XXXXXX")
    echo "Post-BOS-upgrade snapshot directory: ${SNAPSHOT_DIR}"

    # Record BOS data, because the upgrade to CSM 1.6 deleted all BOS v1 data, and sanitized
    # the BOS v2 data
    echo "Backing up BOS data"
    /usr/share/doc/csm/scripts/operations/configuration/export_bos_data.sh "${SNAPSHOT_DIR}"

    # Record state of BOS Kubernetes pods.
    K8S_PODS_SNAPSHOT=${SNAPSHOT_DIR}/k8s_bos_pods.txt
    echo "Taking snapshot of current BOS Kubernetes pod states to ${K8S_PODS_SNAPSHOT}"
    kubectl get pods -n services -l 'app.kubernetes.io/instance in (cray-bos, cray-bos-db)' \
      -o wide --show-labels > "${K8S_PODS_SNAPSHOT}"

    # Record pod logs
    K8S_POD_LOGS=${SNAPSHOT_DIR}/k8s_bos_pod_logs.txt
    kubectl logs -n services --ignore-errors --all-containers --timestamps --prefix --max-log-requests 500 \
      --insecure-skip-tls-verify-backend --tail=-1 \
      -l 'app.kubernetes.io/instance in (cray-bos, cray-bos-db)' > "${K8S_POD_LOGS}"

    SNAPSHOT_DIR_BASENAME=$(basename "${SNAPSHOT_DIR}")
    TARFILE_BASENAME="${SNAPSHOT_DIR_BASENAME}.tgz"
    TARFILE_FULLPATH="/tmp/${TARFILE_BASENAME}"
    echo "Creating compressed tarfile of snapshot data: ${TARFILE_FULLPATH}"
    tar -C /root -czf "${TARFILE_FULLPATH}" "${SNAPSHOT_DIR_BASENAME}"

    backupBucket="config-data"
    cray artifacts list "${backupBucket}" || backupBucket="vbis"

    echo "Uploading tarfile to S3 (bucket $backupBucket)"
    cray artifacts create "${backupBucket}" "${TARFILE_BASENAME}" "${TARFILE_FULLPATH}"

    echo "Deleting tar file from local filesystem"
    rm -v "${TARFILE_FULLPATH}"

    if [[ -n ${job_error} ]]; then
      echo "ERROR: Kubernetes job ${job_name} (namespace: ${ns}) did not succeed" >&2
      exit 1
    fi
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)"
  echo
else
  echo "====> ${state_name} has been completed"
fi

state_name="POST CSM Upgrade Validation"
echo "====> ${state_name} ..."
GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-post-csm-service-upgrade-tests.yaml --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate
echo "====> ${state_name} has been completed"

ok_report
