#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
. "${locOfScript}/../common/upgrade-state.sh"
. "${locOfScript}/../common/ncn-common.sh" "$(hostname)"
trap 'err_report' ERR INT TERM HUP EXIT
# array for paths to unmount after chrooting images
# shellcheck disable=SC2034
declare -a UNMOUNTS=()

PRIMARY_NODE="ncn-m001"

while [[ $# -gt 0 ]]; do
  key=$1

  case ${key} in
    --csm-version)
      CSM_RELEASE=$2
      CSM_REL_NAME="csm-${CSM_RELEASE}"
      shift # past argument
      shift # past value
      ;;
    --primary-node)
      PRIMARY_NODE=$2
      shift # past argument
      shift # past value
      ;;
    *) # unknown option
      echo "[ERROR] - unknown options"
      exit 1
      ;;
  esac
done

# CASMPET-6390 - detect unexpected hostname before continuing
if [[ $(hostname) != "${PRIMARY_NODE}" ]]; then
  echo "ERROR: unexpected hostname $(hostname)"
  echo "You should only run prerequisites.sh from ${PRIMARY_NODE}"
  exit 1
fi

if [[ -z ${CSM_RELEASE} ]]; then
  echo "CSM RELEASE is not specified"
  exit 1
fi

if [[ -z ${SW_ADMIN_PASSWORD} ]]; then
  echo "SW_ADMIN_PASSWORD environment variable has not been set"
  exit 1
fi

if [[ -z ${CSM_ARTI_DIR} ]]; then
  echo "CSM_ARTI_DIR environment variable has not been set"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
elif [[ ! -e ${CSM_ARTI_DIR} ]]; then
  echo "CSM_ARTI_DIR does not exist: ${CSM_ARTI_DIR}"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
elif [[ ! -d ${CSM_ARTI_DIR} ]]; then
  echo "CSM_ARTI_DIR exists but is not a directory"
  ls -ald "${CSM_ARTI_DIR}"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
fi

CSM_MANIFESTS_DIR=${CSM_ARTI_DIR}/manifests
if [[ ! -e ${CSM_MANIFESTS_DIR} ]]; then
  echo "CSM manifests directory does not exist: ${CSM_MANIFESTS_DIR}"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
elif [[ ! -d ${CSM_MANIFESTS_DIR} ]]; then
  echo "Location of CSM manifests directory exists but is not a directory"
  ls -ald "${CSM_MANIFESTS_DIR}"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
fi

EXTRACT_CHART_MANIFEST="${locOfScript}/util/extract_chart_manifest.py"
if [[ ! -e ${EXTRACT_CHART_MANIFEST} ]]; then
  echo "Tool does not exist: ${EXTRACT_CHART_MANIFEST}"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
elif [[ ! -f ${EXTRACT_CHART_MANIFEST} ]]; then
  echo "Tool exists but is not a regular file: ${EXTRACT_CHART_MANIFEST}"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
elif [[ ! -x ${EXTRACT_CHART_MANIFEST} ]]; then
  echo "Tool exists but is not executable: ${EXTRACT_CHART_MANIFEST}"
  echo "make sure you have run: prepare-assets.sh"
  exit 1
fi

TOKEN=$(curl -s -S -d grant_type=client_credentials \
  -d client_id=admin-client \
  -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
export TOKEN

# Several CSM charts are upgraded "early" during the execution of prerequisites.sh
function upgrade_csm_chart {
  # Usage: upgrade_csm_chart <chart name> <manifest_file>
  #
  # <manifest_file> is the name of the manifest file within the $CSM_MANIFESTS_DIR
  local manifest_folder TMP_CUST_YAML TMP_MANIFEST TMP_MANIFEST_CUSTOMIZED chart_name manifest_file

  if [[ $# -ne 2 ]]; then
    echo "ERROR: upgrade_csm_chart function requires exactly 2 arguments but received $#. Invalid argument(s): $*"
    return 1
  elif [[ -z $1 ]]; then
    echo "ERROR: upgrade_csm_chart: chart name may not be blank"
    return 1
  elif [[ -z $2 ]]; then
    echo "ERROR: upgrade_csm_chart: manifest file name may not be blank"
    return 1
  fi

  chart_name="$1"
  manifest_file="${CSM_MANIFESTS_DIR}/$2"
  if [[ ! -f ${manifest_file} ]]; then
    echo "ERROR: upgrade_csm_chart: manifest file does not exist or is not a regular file: ${manifest_file}"
    return 1
  fi
  manifest_folder='/tmp'

  # Get customizations.yaml
  TMP_CUST_YAML=$(mktemp --tmpdir="${manifest_folder}" customizations.XXXXXX.yaml)
  set -o pipefail
  kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > "${TMP_CUST_YAML}"
  set +o pipefail

  # Create the base of the new manifest
  TMP_MANIFEST=$(mktemp --tmpdir="${manifest_folder}" "${chart_name}.XXXXXX.yaml")
  echo "${TMP_MANIFEST}"
  "${EXTRACT_CHART_MANIFEST}" "${chart_name}" "${manifest_file}" > "${TMP_MANIFEST}"
  cat "${TMP_MANIFEST}"

  # Customize it
  TMP_MANIFEST_CUSTOMIZED=$(mktemp --tmpdir="${manifest_folder}" "${chart_name}.customized.XXXXXX.yaml")
  echo "${TMP_MANIFEST_CUSTOMIZED}"
  manifestgen -i "${TMP_MANIFEST}" -c "${TMP_CUST_YAML}" -o "${TMP_MANIFEST_CUSTOMIZED}"
  cat "${TMP_MANIFEST_CUSTOMIZED}"

  loftsman ship --manifest-path "${TMP_MANIFEST_CUSTOMIZED}"
}

function is_vshasta_node {
  # This is the best check for an image specifically booted to vshasta
  [[ -f /etc/google_system ]] && return 0

  # metal images can still be booted on GCP, so check if there are any disks vendored by Google
  # if not, we conclude that this is not GCP
  lsblk --noheadings -o vendor | grep -q Google
  return $?
}

if is_vshasta_node; then
  vshasta="true"
else
  vshasta="false"
fi

# Make a backup copy of select pre-upgrade information, just in case it is needed for later reference.
# This is only run on the primary upgrade node
state_name="BACKUP_SNAPSHOT"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    DATESTRING=$(date +%Y-%m-%d_%H-%M-%S)
    SNAPSHOT_DIR=$(mktemp -d --tmpdir=/root "csm_upgrade.pre_upgrade_snapshot.${DATESTRING}.XXXXXX")
    echo "Pre-upgrade snapshot directory: ${SNAPSHOT_DIR}"

    # Record CFS components and configurations, since these are modified during the upgrade process
    CFS_CONFIG_SNAPSHOT=${SNAPSHOT_DIR}/cfs_configurations.json
    echo "Backing up CFS configurations to ${CFS_CONFIG_SNAPSHOT}"
    curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/cfs/v2/configurations > "${CFS_CONFIG_SNAPSHOT}"

    CFS_COMP_SNAPSHOT=${SNAPSHOT_DIR}/cfs_components.json
    echo "Backing up CFS components to ${CFS_COMP_SNAPSHOT}"
    curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/cfs/v2/components > "${CFS_COMP_SNAPSHOT}"

    # Record state of Kubernetes pods. If a pod is later seen in an unexpected state, this can provide a reference to
    # determine whether or not the issue existed prior to the upgrade.
    K8S_PODS_SNAPSHOT=${SNAPSHOT_DIR}/k8s_pods.txt
    echo "Taking snapshot of current Kubernetes pod states to ${K8S_PODS_SNAPSHOT}"
    kubectl get pods -A -o wide --show-labels > "${K8S_PODS_SNAPSHOT}"

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  echo
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="CHECK_WEAVE"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    SLEEVE_MODE="yes"
    weave --local status connections | grep -q sleeve || SLEEVE_MODE="no"
    if [ "${SLEEVE_MODE}" == "yes" ]; then
      echo "Detected that weave is in sleeve mode with at least one peer.   Please consult FN6636 before proceeding with the upgrade."
      exit 1
    fi

    # get BSS global cloud-init data
    curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | jq .[] > cloud-init-global.json

    CURRENT_MTU=$(jq '."cloud-init"."meta-data"."kubernetes-weave-mtu"' cloud-init-global.json)
    echo "Current kubernetes-weave-mtu is ${CURRENT_MTU}"

    # make sure kubernetes-weave-mtu is set to 1376
    jq '."cloud-init"."meta-data"."kubernetes-weave-mtu" = "1376"' cloud-init-global.json > cloud-init-global-update.json

    echo "Setting kubernetes-weave-mtu to 1376"
    # post the update json to bss
    curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" \
      --request PUT \
      --data @cloud-init-global-update.json \
      https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  echo
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPDATE_SSH_KEYS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    test -f /root/.ssh/config && mv /root/.ssh/config /root/.ssh/config.bak
    cat << EOF > /root/.ssh/config
Host *
    StrictHostKeyChecking no
EOF

    grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'truncate --size=0 ~/.ssh/known_hosts'

    grep -oP "(ncn-\w+)" /etc/hosts | sort -u | xargs -t -i ssh {} 'grep -oP "(ncn-s\w+|ncn-m\w+|ncn-w\w+)" /etc/hosts | sort -u | xargs -t -i ssh-keyscan -H \{\} >> /root/.ssh/known_hosts'

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="REPAIR_AND_VERIFY_CHRONY_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")

if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    for target_ncn in $(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u); do

      if is_vshasta_node; then
        if [ "${target_ncn}" == "ncn-m001" ]; then
          echo "Skipping ncn-m001 because we are running on vshasta"
          continue
        fi
      fi

      # ensure host is accessible, skip it if not
      if ! ssh "${target_ncn}" hostname > /dev/null; then
        continue
      fi

      # ensure the directory exists
      ssh "${target_ncn}" mkdir -p /srv/cray/scripts/common/

      # copy the NTP script and template to the target ncn
      rsync -aq "${CSM_ARTI_DIR}"/chrony "${target_ncn}":/srv/cray/scripts/common/

      # shellcheck disable=SC2029 # it is intentional that ${TOKEN} expands on the client side
      # run the script
      if ! ssh "${target_ncn}" "TOKEN=${TOKEN} /srv/cray/scripts/common/chrony/csm_ntp.py"; then
        echo "${target_ncn} csm_ntp failed"
        exit 1
      fi

      ssh "${target_ncn}" chronyc makestep
      loop_idx=0
      in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
      # wait up to 90s for the node to be in sync
      while [[ ${loop_idx} -lt 18 && ${in_sync} == "no" ]]; do
        sleep 5
        in_sync=$(ssh "${target_ncn}" timedatectl | awk /synchronized:/'{print $NF}')
        loop_idx=$((loop_idx + 1))
      done

      if [[ ${in_sync} == "no" ]]; then
        echo "The clock for ${target_ncn} is not in sync.  Wait a bit more or try again."
        exit 1
      fi
    done
    record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  } >> "${LOG_FILE}" 2>&1
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="CHECK_CLOUD_INIT_PREREQ"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    echo "Ensuring cloud-init is healthy"
    set +e
    # K8s nodes
    for host in $(kubectl get nodes -o json | jq -r '.items[].metadata.name'); do
      echo "Node: ${host}"
      counter=0
      ssh_keygen_keyscan "${host}"
      until ssh "${host}" test -f /run/cloud-init/instance-data.json; do
        # The intent appears to be to redirect stdout to /dev/null, and redirect stderr to stdout
        # shellcheck disable=SC2069
        ssh "${host}" cloud-init init 2>&1 > /dev/null
        counter=$((counter + 1))
        sleep 10
        if [[ ${counter} -gt 5 ]]; then
          echo "Cloud-init data is missing and cannot be recreated. Existing upgrade.."
        fi
      done
    done

    ## Ceph nodes
    for host in $(ceph node ls | jq -r '.osd|keys[]'); do
      echo "Node: ${host}"
      counter=0
      ssh_keygen_keyscan "${host}"
      until ssh "${host}" test -f /run/cloud-init/instance-data.json; do
        # The intent appears to be to redirect stdout to /dev/null, and redirect stderr to stdout
        # shellcheck disable=SC2069
        ssh "${host}" cloud-init init 2>&1 > /dev/null
        counter=$((counter + 1))
        sleep 10
        if [[ ${counter} -gt 5 ]]; then
          echo "Cloud-init data is missing and cannot be recreated. Existing upgrade.."
        fi
      done
    done

    set -e
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPDATE_DOC_RPM"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    error=0
    packages=(docs-csm libcsm)
    for package in "${packages[@]}"; do
      if [[ ! -f /root/${package}-latest.noarch.rpm ]]; then
        echo >&2 "ERROR: ${package}-latest.noarch.rpm is missing under: /root"
        error=1
      else
        cp /root/${package}-latest.noarch.rpm "${CSM_ARTI_DIR}/rpm/cray/csm/sle-15sp4/"
      fi
    done
    if [ "${error}" -ne 0 ]; then
      echo >&2 "ERROR: one or more expected packages were missing under: /root -- halting..."
      exit 1
    fi

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPDATE_CUSTOMIZATIONS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    # get existing customization.yaml file
    SITE_INIT_DIR=/etc/cray/upgrade/csm/${CSM_REL_NAME}/site-init
    mkdir -p "${SITE_INIT_DIR}"
    pushd "${SITE_INIT_DIR}"
    DATETIME=$(date +%Y-%m-%d_%H-%M-%S)
    CUSTOMIZATIONS_YAML=$(mktemp -p "${SITE_INIT_DIR}" "customizations-${DATETIME}-XXX.yaml")
    set -o pipefail
    kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > "${CUSTOMIZATIONS_YAML}"
    set +o pipefail

    # NOTE:  There are currently no sealed secrets being added so we are skipping the sealed secrets steps

    cp "${CUSTOMIZATIONS_YAML}" "${CUSTOMIZATIONS_YAML}.bak"
    . "${locOfScript}/util/update-customizations.sh" -i "${CUSTOMIZATIONS_YAML}"

    # rename customizations file so k8s secret name stays the same
    cp "${CUSTOMIZATIONS_YAML}" customizations.yaml

    # push updated customizations.yaml to k8s
    kubectl delete secret -n loftsman site-init
    kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
    popd

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="SETUP_NEXUS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    set +e
    nexus-cred-check() {
      pod=$(kubectl get pods -n nexus --selector app=nexus -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep -v nexus-init)
      kubectl -n nexus exec -it "${pod}" -c nexus -- curl -i -sfk -u \
        "admin:${NEXUS_PASSWORD:=$(kubectl get secret -n nexus nexus-admin-credential --template '{{.data.password}}' | base64 -d)}" \
        -H "accept: application/json" -X GET http://nexus/service/rest/beta/security/user-sources > /dev/null 2>&1
    }
    if ! nexus-cred-check; then
      echo "Nexus password is incorrect. Please set NEXUS_PASSWORD and try again."
      exit 1
    fi
    set -e
    "${CSM_ARTI_DIR}/lib/setup-nexus.sh"

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_NLS_POSTGRES"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    # CASMPET-6602 ignore the cray-nls deployment error as cray-nls-postgres is not ready
    "${locOfScript}/util/upgrade-cray-nls.sh" || true
    sleep 5
    echo "Rolling cray-nls-postgres statefulset"
    kubectl rollout restart -n argo statefulset cray-nls-postgres
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="RESTART_SPIRE_POSTGRES"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    echo "Rolling spire-postgres statefulset"
    kubectl rollout restart -n spire statefulset spire-postgres
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_SYSMGMT_HEALTH"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    "${locOfScript}/util/sysmgmt-health-upgrade.sh"

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_CSM_CONFIG"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    upgrade_csm_chart csm-config sysmgmt.yaml

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_DRYDOCK"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    upgrade_csm_chart cray-drydock platform.yaml

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_KYVERNO"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    upgrade_csm_chart cray-kyverno platform.yaml

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_KYVERNO_POLICY"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    upgrade_csm_chart kyverno-policy platform.yaml

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_CRAY_KYVERNO_POLICIES_UPSTREAM"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    upgrade_csm_chart cray-kyverno-policies-upstream platform.yaml
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_TFTP"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ $state_recorded == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    upgrade_csm_chart cray-tftp sysmgmt.yaml

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi
state_name="UPGRADE_TFTP_PVC"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ $state_recorded == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    upgrade_csm_chart cray-tftp-pvc sysmgmt.yaml

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPLOAD_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" && ${vshasta} == "false" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    artdir=${CSM_ARTI_DIR}/images
    SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
    export SQUASHFS_ROOT_PW_HASH
    set -o pipefail
    NCN_IMAGE_MOD_SCRIPT=$(rpm -ql docs-csm | grep ncn-image-modification.sh)
    set +o pipefail

    KUBERNETES_VERSION=$(find "${artdir}/kubernetes" -name 'kubernetes*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')
    CEPH_VERSION=$(find "${artdir}/storage-ceph" -name 'storage-ceph*.squashfs' -exec basename {} .squashfs \; | awk -F '-' '{print $(NF-1)}')

    k8s_done=0
    ceph_done=0
    arch="$(uname -i)"
    if [[ -f ${artdir}/kubernetes/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs ]]; then
      k8s_done=1
    fi
    if [[ -f ${artdir}/storage-ceph/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs ]]; then
      ceph_done=1
    fi

    if [[ ${k8s_done} == 1 && ${ceph_done} == 1 ]]; then
      echo "Already ran ${NCN_IMAGE_MOD_SCRIPT}, skipping re-run."
    else
      rm -f "${artdir}/storage-ceph/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs" "${artdir}/kubernetes/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs"
      DEBUG=1 "${NCN_IMAGE_MOD_SCRIPT}" \
        -d /root/.ssh \
        -k "${artdir}/kubernetes/kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs" \
        -s "${artdir}/storage-ceph/storage-ceph-${CEPH_VERSION}-${arch}.squashfs" \
        -p
    fi

    set -o pipefail
    IMS_UPLOAD_SCRIPT=$(rpm -ql docs-csm | grep ncn-ims-image-upload.sh)

    UUID_REGEX='^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$'

    export IMS_ROOTFS_FILENAME="${artdir}/kubernetes/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs"
    export IMS_INITRD_FILENAME="${artdir}/kubernetes/initrd.img-${KUBERNETES_VERSION}-${arch}.xz"
    # do not quote this glob.  bash will add single ticks (') around it, preventing expansion later
    resolve_kernel_glob=$(echo ${artdir}/kubernetes/*-${arch}.kernel)
    export IMS_KERNEL_FILENAME=$resolve_kernel_glob
    K8S_IMS_IMAGE_ID=$($IMS_UPLOAD_SCRIPT)
    [[ -n ${K8S_IMS_IMAGE_ID} ]] && [[ ${K8S_IMS_IMAGE_ID} =~ $UUID_REGEX ]]

    export IMS_ROOTFS_FILENAME="${artdir}/storage-ceph/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs"
    export IMS_INITRD_FILENAME="${artdir}/storage-ceph/initrd.img-${CEPH_VERSION}-${arch}.xz"
    # do not quote this glob.  bash will add single ticks (') around it, preventing expansion later
    resolve_kernel_glob=$(echo ${artdir}/storage-ceph/*-${arch}.kernel)
    export IMS_KERNEL_FILENAME=$resolve_kernel_glob
    STORAGE_IMS_IMAGE_ID=$($IMS_UPLOAD_SCRIPT)
    [[ -n ${STORAGE_IMS_IMAGE_ID} ]] && [[ ${STORAGE_IMS_IMAGE_ID} =~ $UUID_REGEX ]]
    set +o pipefail

    # clean up any previous set values just in case.
    sed -i 's/^export STORAGE_IMS_IMAGE_ID.*//' /etc/cray/upgrade/csm/myenv
    sed -i 's/^export KUBERNETES_IMS_IMAGE_ID.*//' /etc/cray/upgrade/csm/myenv
    echo "export STORAGE_IMS_IMAGE_ID=${STORAGE_IMS_IMAGE_ID}" >> /etc/cray/upgrade/csm/myenv
    echo "export K8S_IMS_IMAGE_ID=${K8S_IMS_IMAGE_ID}" >> /etc/cray/upgrade/csm/myenv

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

    for xname in ${K8S_XNAME_LIST}; do
      METAL_SERVER=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
        | awk -F 'metal.server=' '{print $2}' \
        | awk -F ' ' '{print $1}')
      NEW_METAL_SERVER="s3://boot-images/${K8S_IMS_IMAGE_ID}/rootfs"
      PARAMS=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
        | sed "/metal.server/ s|${METAL_SERVER}|${NEW_METAL_SERVER}|" \
        | tr -d \")

      cray bss bootparameters update --hosts "${xname}" \
        --kernel "s3://boot-images/${K8S_IMS_IMAGE_ID}/kernel" \
        --initrd "s3://boot-images/${K8S_IMS_IMAGE_ID}/initrd" \
        --params "${PARAMS}"
    done
    for xname in ${STORAGE_XNAME_LIST}; do
      METAL_SERVER=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
        | awk -F 'metal.server=' '{print $2}' \
        | awk -F ' ' '{print $1}')
      NEW_METAL_SERVER="s3://boot-images/${STORAGE_IMS_IMAGE_ID}/rootfs"
      PARAMS=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
        | sed "/metal.server/ s|${METAL_SERVER}|${NEW_METAL_SERVER}|" \
        | tr -d \")

      cray bss bootparameters update --hosts "${xname}" \
        --kernel "s3://boot-images/${STORAGE_IMS_IMAGE_ID}/kernel" \
        --initrd "s3://boot-images/${STORAGE_IMS_IMAGE_ID}/initrd" \
        --params "${PARAMS}"
    done
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPDATE_CLOUD_INIT_RECORDS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    # get BSS cloud-init data with host_records
    curl -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | jq .[] > cloud-init-global.json

    # get IP of api-gw in NMN
    ip=$(dig api-gw-service-nmn.local +short)

    # get entry number to add record to
    entry_number=$(jq '."cloud-init"."meta-data".host_records|length' cloud-init-global.json)

    # check if record already exists and create the script to be idempotent
    for ((i = 0; i < entry_number; i++)); do
      record=$(jq '."cloud-init"."meta-data".host_records['${i}']' cloud-init-global.json)
      if [[ ${record} == "packages.local" || ${record} == "registry.local" ]]; then
        echo "packages.local and registry.local already in BSS cloud-init host_records"
      fi
    done

    # create the updated json
    jq '."cloud-init"."meta-data".host_records['${entry_number}']|= . + {"aliases": ["packages.local", "registry.local"],"ip": "'${ip}'"}' cloud-init-global.json > cloud-init-global_update.json

    # post the update json to bss
    curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" \
      --request PUT \
      --data @cloud-init-global_update.json \
      https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  echo
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPDATE_NCN_KERNEL_PARAMETERS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    # As boot parameters are added or removed, update these arrays.
    # NOTE: bootparameters_to_delete should contain keys only, nothing should have "=<value>" appended to it.
    bootparameters_to_set=("split_lock_detect=off" "psi=1" "rd.live.squashimg=rootfs" "rd.live.overlay.thin=0" "rd.live.dir=${CSM_RELEASE}")
    bootparameters_to_delete=("rd.live.squashimg" "rd.live.overlay.thin" "rd.live.dir")

    for bootparameter in "${bootparameters_to_delete[@]}"; do
      csi handoff bss-update-param --delete "${bootparameter}"
    done

    for bootparameter in "${bootparameters_to_set[@]}"; do
      csi handoff bss-update-param --set "${bootparameter}"
    done

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  echo
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_PRECACHE_CHART"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    tmp_current_configmap=/tmp/precache-current-configmap.yaml
    kubectl get configmap -n nexus cray-precache-images -o yaml > "${tmp_current_configmap}"
    helm uninstall -n nexus cray-precache-images
    tmp_manifest=/tmp/precache-manifest.yaml

    cat > "${tmp_manifest}" << EOF
apiVersion: manifests/v1beta1
metadata:
  name: cray-precache-images-manifest
spec:
  charts:
  -
EOF

    yq r "${CSM_MANIFESTS_DIR}/platform.yaml" 'spec.charts.(name==cray-precache-images)' | sed 's/^/    /' >> "${tmp_manifest}"
    loftsman ship --charts-path "${CSM_ARTI_DIR}/helm" --manifest-path "${tmp_manifest}"

    #
    # Now edit the configmap with the images necessary to move the former nexus
    # pod around on an upgraded NCN (before we deploy the new nexus chart)
    #
    current_nexus_mobility_images=$(yq r "${tmp_current_configmap}" 'data.images_to_cache' | grep -e 'sonatype\|busy\|proxyv2\|envoy' | sort | uniq)
    current_nexus_mobility_images=$(echo "${current_nexus_mobility_images}" | sed 's/ /\n/g; s/^/\n/')

    echo "Adding the following pre-upgrade images to new pre-cache configmap:"
    echo "${current_nexus_mobility_images}"
    echo ""

    kubectl get configmap -n nexus cray-precache-images -o json \
      | jq --arg value "${current_nexus_mobility_images}" '.data.images_to_cache |= . + $value' \
      | kubectl replace --force -f -

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# Helper functions for below
has_cm_init() {
  ns="${1?no namespace provided}"
  helm list -n "${ns}" --filter cray-certmanager-init | grep cray-certmanager-init > /dev/null 2>&1
}

has_craycm() {
  ns="${1?no namespace provided}"
  helm list -n "${ns}" --filter 'cray-certmanager$' | grep cray-certmanager > /dev/null 2>&1
}

state_name="UPGRADE_CERTMANAGER_0141_CHART"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    # The actions below only need to happen iff we are on 0.14.1 if we're
    # already at 1.5.5+ the crd ownership changes makes this logic impossible to
    # work due to helm hooks. Making this work on both isn't really worth the
    # time so just constrain this block of logic to 0.14.1 where we know its
    # needed.
    gate="0.14.1"
    found=$(helm list -n cert-manager --filter 'cray-certmanager$' | awk '/deployed/ {print $10}')

    needs_upgrade=0

    if [ "${found}" = "${gate}" ]; then
      printf "note: found old cert-manager that needs upgrades %s\n" "${found}" >&2
      ((needs_upgrade += 1))
    else
      printf "note: cert-manager helm chart version %s\n" "${found}" >&2

      # We might be rerunning from a pre 1.5.x install and there is no
      # cert-manager installed due to a prior removal
      if [ "${found}" = "" ]; then
        printf "note: no helm install appears to exist for cert-manager, likely this state is being run again\n" >&2
        ((needs_upgrade += 1))
      else
        printf "note: no cert-manager upgrade steps needed, cert-manager 0.14.1 is not installed\n" >&2
      fi
    fi

    # Only run if we need to and detected not 0.14.1 or ""
    if [ "${needs_upgrade}" -gt 0 ]; then
      cmns="cert-manager"
      cminitns="cert-manager-init"

      backup_secret="cm-restore-data"

      # We need to backup before any helm uninstalls.
      needs_backup=0

      if has_craycm ${cmns}; then
        ((needs_backup += 1))
      fi

      if has_cm_init ${cminitns}; then
        ((needs_backup += 1))
      fi

      # Ok so the gist of this "backup" is we back up all the cert-manager data as
      # guided by them. The secret we use for this is only kept around until this
      # prereq state completes.
      if [ "${needs_backup}" -gt 0 ]; then
        # Note, check that the secret is present in case only one helm chart is
        # removed and we error later, we don't want to backup stuff again at that
        # point.
        if ! kubectl get secret "${backup_secret?}" > /dev/null 2>&1; then
          data=$(kubectl get --all-namespaces -o yaml clusterissuer,cert,issuer)
          kubectl create secret generic "${backup_secret?}" --from-literal=data="${data?}"
        fi
      fi

      # Only remove these charts if installed
      if has_craycm ${cmns}; then
        helm uninstall -n "${cmns}" cray-certmanager
      fi

      if has_cm_init ${cminitns}; then
        helm uninstall -n "${cminitns}" cray-certmanager-init
      fi

      # Note: These should *never* fail as we depend on helm uninstall doing
      # its job, but if it didn't exit early here as something is amiss.
      cm=1
      cminit=1

      if ! helm list -n "${cmns}" --filter 'cray-certmanager$' | grep cray-certmanager > /dev/null 2>&1; then
        cm=0
      fi

      if ! helm list -n "${cminitns}" --filter cray-certmanager-init | grep cray-certmanager-init > /dev/null; then
        cminit=0
      fi

      if [ "${cm}" = "1" ] || [ "${cminit}" = "1" ]; then
        printf "fatal: helm uninstall did not remove expected charts, cert-manager %s cert-manager-init %s\n" "${cm}" "${cminit}" >&2
        exit 1
      fi

      # Ensure the cert-manager namespace is deleted in a case of both helm charts
      # removed but there might be detritous leftover in the namespace.
      kubectl delete namespace "${cmns}" || :

      tmp_manifest=/tmp/certmanager-tmp-manifest.yaml

      cat > "${tmp_manifest}" << EOF
apiVersion: manifests/v1beta1
metadata:
  name: cray-certmanager-images-tmp-manifest
spec:
  charts:
EOF

      # While kubectl get namespace cert-manager succeeds, backoff until it
      # doesn't or after 5 minutes fail entirely as its likely not removing
      # for whatever reason, humans get to figure out why or they can
      # re-run...
      start=$(date +%s)
      lim=1
      until ! kubectl get namespace "${cmns}" > /dev/null 2>&1; do
        now=$(date +%s)
        if [ "$((now - start))" -ge 300 ]; then
          printf "fatal: namespace %s likely requires manual intervention after waiting for removal for at least 5 minutes, details:\n" "${cmns}" >&2
          kubectl get namespace "${cmns}" -o yaml
          exit 1
        fi
        lim="$((lim * 2))"
        sleep ${lim}
      done

      platform="${CSM_MANIFESTS_DIR}/platform.yaml"
      for chart in cray-drydock cray-certmanager cray-certmanager-issuers; do
        printf "    -\n" >> "${tmp_manifest}"
        yq r "${platform}" 'spec.charts.(name=='${chart}')' | sed 's/^/      /' >> "${tmp_manifest}"
      done

      # Note the ownership for the cert-manager namespace changes ownership
      # from cray-certmanager-init to cray-drydock, so we need to ensure we
      # update drydock to create our namespace appropriately before
      # reinstalling cray-certmanager. Note, technically reinstalling
      # cray-drydock is unnecessary at this stage but is here "just in case".
      # cray-certmanager-issuers is also in this category in that it should be
      # unnecessary as the upgrade will reinstall it anyway but this is just
      # to be complete.
      #
      # This only needs to happen for this 0.14.1->1.55 upgrade. We should remove
      # this on the next release doing this work each time is unnecessary.
      loftsman ship --charts-path "${CSM_ARTI_DIR}/helm" --manifest-path "${tmp_manifest}"

      # If the restore secret exists, apply that data here and when done then
      # remove the secret as its purpose is no longer necessary.
      if kubectl get secret "${backup_secret?}" > /dev/null 2>&1; then
        # Only delete the secret if there are no errors. Note that existing
        # resources may already exist and the full apply failed yet worked.
        if kubectl get secret "${backup_secret?}" -o jsonpath='{.data.data}' | base64 -d | kubectl apply -f -; then
          kubectl delete secret "${backup_secret}"
        else
          printf "warn: kubectl apply of %s encountered errors, restore of cert-manager data may be incomplete or simply tried to restore existing data\n" "${backup_secret}" >&2
        fi
      fi
    fi
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPGRADE_TRUSTEDCERTS_OPERATOR"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ $state_recorded == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    upgrade_csm_chart trustedcerts-operator platform.yaml

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="CREATE_CEPH_RO_KEY"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    ceph-authtool -C /etc/ceph/ceph.client.ro.keyring -n client.ro --cap mon 'allow r' --cap mds 'allow r' --cap osd 'allow r' --cap mgr 'allow r' --gen-key
    ceph auth import -i /etc/ceph/ceph.client.ro.keyring
    for node in $(ceph orch host ls --format=json | jq -r '.[].hostname'); do
      scp /etc/ceph/ceph.client.ro.keyring "${node}":/etc/ceph/ceph.client.ro.keyring
    done

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="BACKUP_BSS_DATA"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    cray bss bootparameters list --format json > "bss-backup-$(date +%Y-%m-%d).json"

    backupBucket="config-data"
    cray artifacts list "${backupBucket}" || backupBucket="vbis"

    cray artifacts create "${backupBucket}" "bss-backup-$(date +%Y-%m-%d).json" "bss-backup-$(date +%Y-%m-%d).json"

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="TDS_LOWER_CPU_REQUEST"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" && ${vshasta} == "false" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    numOfActiveWokers=$(kubectl get nodes | grep -E "^ncn-w[0-9]{3}[[:space:]]+Ready[[:space:]]" | wc -l)
    minimal_count=4
    if [[ ${numOfActiveWokers} -le ${minimal_count} ]]; then
      /usr/share/doc/csm/upgrade/scripts/k8s/tds_lower_cpu_requests.sh
    else
      echo "==> TDS: false"
    fi

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# This is not run on vshasta because it doesn't have HSM
state_name="CHECK_BMC_NCN_LOCKS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" && ${vshasta} == "false" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    # install the hpe-csm-scripts rpm early to get lock_management_nodes.py
    rpm --force -Uvh "$(find "${CSM_ARTI_DIR}/rpm/cray/csm/" -name \*hpe-csm-scripts\*.rpm | sort -V | tail -1)"

    # mark the NCN BMCs with the Management role in HSM
    cray hsm state components bulkRole update --role Management --component-ids \
      "$(cray hsm state components list --role management --type Node --format json \
        | jq -r .Components[].ID | sed 's/n[0-9]*//' | tr '\n' ',' | sed 's/.$//')"

    # ensure that they are all locked
    python3 /opt/cray/csm/scripts/admin_access/lock_management_nodes.py

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# Disable CFS on the NCNs, to prevent new sessions from being launched during the upgrade.
# Note that it is possible CFS sessions are currently underway on the NCNs. Disabling them
# will not prevent currently scheduled CFS sessions from executing -- it will just prevent
# new sessions from being scheduled. It will also not prevent current sessions from updating
# the status of the component when they complete. However, that update will not re-enable
# the component.
# This is not run on vshasta because it doesn't have HSM
state_name="DISABLE_CFS_ON_NCNS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ $state_recorded == "0" && $(hostname) == "${PRIMARY_NODE}" && ${vshasta} == "false" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    echo "Retrieving a list of all management node component names (xnames)"
    set -o pipefail
    XNAMES=$(cray hsm state components list --role Management --type Node --format json | jq -r '.Components | map(.ID) | join(",")')
    set +o pipefail
    [[ -n ${XNAMES} ]]
    XNAME_LIST=${XNAMES//,/ }

    echo "Disabling CFS configuration for all NCNs"
    for xname in ${XNAME_LIST}; do
      echo "Disabling CFS on ${xname}"
      cray cfs components update "${xname}" --enabled false --format json

      # Make sure it is actually disabled
      echo "Verifying that CFS is now disabled on ${xname}"
      set -o pipefail
      cray cfs components describe "${xname}" --format json | jq '.enabled' | grep "^false$"
      set +o pipefail
    done

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# CRUS is being removed as part of this upgrade
state_name="UNINSTALL_CRUS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ $state_recorded == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    # If CRUS is installed, uninstall it
    if helm status -n services cray-crus; then
      helm uninstall -n services cray-crus
    fi
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="FINISH_NLS_UPGRADE"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    # make sure cray-nls-postgres is healthy
    i=1
    max_checks=40
    wait_time=15
    healthy="false"
    while [[ ${i} -le ${max_checks} ]]; do
      if [[ "$(kubectl get postgresql cray-nls-postgres -n argo -ojsonpath='{.status.PostgresClusterStatus}')" == "Running" ]]; then
        echo "cray-nls-postgres is healthy"
        healthy="true"
        break
      fi
      echo "Waiting for postgres operator to consider cray-nls-postgres healthy (${i}/${max_checks})"
      sleep ${wait_time}
      i=$((i + 1))
    done

    if [[ ${healthy} == "false" ]]; then
      echo "ERROR: cray-nls-postgres is not healthy after $((max_checks * wait_time)) seconds"
      exit 1
    fi

    # retry cray-nls upgrade which is expected to succeed
    "${locOfScript}/util/upgrade-cray-nls.sh"
    # CASMINST-6040 - need to wait for hooks.cray-nls.hpe.com crd to be created
    # before uploading rebuild workflow templates which use hooks
    echo "Wait for hooks.cray-nls.hpe.com crd to be created"
    set +e
    counter=0
    until kubectl get crd hooks.cray-nls.hpe.com; do
      counter=$((counter + 1))
      sleep 5
      # wait up to 90 seconds
      if [[ ${counter} -gt 18 ]]; then
        echo "ERROR: failed to find hooks.cray-nls.hpe.com crd"
        exit 1
      fi
    done
    set -e
    "${locOfScript}/../../../workflows/scripts/upload-rebuild-templates.sh"
    rpm --force -Uvh "$(find "${CSM_ARTI_DIR}"/rpm/cray/csm/ -name \*iuf-cli\*.rpm | sort -V | tail -1)"

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="VALIDATE_SPIRE_POSTGRES_HEALTH"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    # make sure spire-postgres is healthy
    i=1
    max_checks=40
    wait_time=15
    healthy="false"
    while [[ ${i} -le ${max_checks} ]]; do
      if [[ "$(kubectl get postgresql spire-postgres -n spire -ojsonpath='{.status.PostgresClusterStatus}')" == "Running" ]]; then
        echo "spire-postgres is healthy"
        healthy="true"
        break
      fi
      echo "Waiting for postgres operator to consider spire-postgres healthy (${i}/${max_checks})"
      sleep ${wait_time}
      i=$((i + 1))
    done

    if [[ ${healthy} == "false" ]]; then
      echo "ERROR: spire-postgres is not healthy after $((max_checks * wait_time)) seconds"
      exit 1
    fi
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="PREFLIGHT_CHECK"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    rpm --force -Uvh "$(find "${CSM_ARTI_DIR}"/rpm/cray/csm/ -name \*csm-testing\*.rpm | sort -V | tail -1)"
    rpm --force -Uvh "$(find "${CSM_ARTI_DIR}"/rpm/cray/csm/ -name \*platform-utils\*.rpm | sort -V | tail -1)"
    rpm --force -Uvh "$(find "${CSM_ARTI_DIR}"/rpm/cray/csm/ -name \*goss-servers\*.rpm | sort -V | tail -1)"
    rpm --force -Uvh "$(find "${CSM_ARTI_DIR}"/rpm/cray/csm/ -name \*cmstools-crayctldeploy\*.rpm | sort -V | tail -1)"
    systemctl enable goss-servers
    systemctl restart goss-servers

    # CASMPET-6635 & CASMINST-6517
    # Get the RPM versions from the primary node
    ct_version=$(rpm -q csm-testing)
    ct_rpm_nexus_url="https://packages.local/repository/csm-sle-15sp4/noarch/${ct_version}.rpm"
    pu_version=$(rpm -q platform-utils)
    pu_rpm_nexus_url="https://packages.local/repository/csm-sle-15sp4/noarch/${pu_version}.rpm"
    gs_version=$(rpm -q goss-servers)
    gs_rpm_nexus_url="https://packages.local/repository/csm-sle-15sp4/noarch/${gs_version}.rpm"
    cc_version=$(rpm -q cray-cmstools-crayctldeploy)
    cc_rpm_nexus_url="https://packages.local/repository/csm-sle-15sp4/noarch/${cc_version}.rpm"
    # Install above RPMs and restart goss-servers on ncn-w001
    ssh ncn-w001 "rpm --force -Uvh $ct_rpm_nexus_url $pu_rpm_nexus_url $gs_rpm_nexus_url $cc_rpm_nexus_url; systemctl enable goss-servers; systemctl restart goss-servers;"

    # get all installed CSM version into a file
    kubectl get cm -n services cray-product-catalog -o json | jq -r '.data.csm' | yq r - -d '*' -j | jq -r 'keys[]' > /tmp/csm_versions
    # sort -V: version sort
    highest_version=$(sort -V /tmp/csm_versions | tail -1)
    minimum_version=1.2.0
    # compare sorted versions with unsorted so we know if our highest is greater than minimum
    if [[ $(printf "${minimum_version}\n${highest_version}") != $(printf "${minimum_version}\n${highest_version}" | sort -V) ]]; then
      echo "Required CSM patch ${minimum_version} or above has not been applied to this system"
      exit 1
    fi

    if is_vshasta_node; then
      sed -i 's/vshasta: false/vshasta: true/g' /opt/cray/tests/install/ncn/vars/variables-ncn.yaml
    fi

    GOSS_BASE=/opt/cray/tests/install/ncn goss -g /opt/cray/tests/install/ncn/suites/ncn-upgrade-preflight-tests.yaml \
      --vars=/opt/cray/tests/install/ncn/vars/variables-ncn.yaml validate

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# restore previous ssh config if there was one, remove ours
rm -f /root/.ssh/config
test -f /root/.ssh/config.bak && mv /root/.ssh/config.bak /root/.ssh/config

ok_report
