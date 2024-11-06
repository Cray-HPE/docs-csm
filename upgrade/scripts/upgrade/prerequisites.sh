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

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
. "${locOfScript}/../common/ncn-common.sh" "$(hostname)"
# upgrade-state.sh uses CSM_RELEASE defined by ncn-common.sh
. "${locOfScript}/../common/upgrade-state.sh"
. "${locOfScript}/../common/k8s-common.sh"
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

if [[ -f ${PREREQS_DONE_FILE} ]]; then
  echo "Deleting the existing file: ${PREREQS_DONE_FILE}"
  rm ${PREREQS_DONE_FILE}
fi

function get_token() {
  if [ -z "${TOKEN}" ]; then
    TOKEN=$(curl -s -S -d grant_type=client_credentials \
      -d client_id=admin-client \
      -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
      https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    export TOKEN
  fi
  echo "${TOKEN}"
}

# Takes as input the path to a CSM RPM in the expanded tarball. e.g.:
# /etc/cray/upgrade/csm/csm-1.5.0-beta.64/tarball/csm-1.5.0-beta.64/rpm/cray/csm/noos/x86_64/hpe-csm-virtiofsd-1.7.0-hpe1.x86_64.rpm
# /etc/cray/upgrade/csm/csm-1.5.0-beta.64/tarball/csm-1.5.0-beta.64/rpm/cray/csm/noos/noarch/csm-testing-1.16.59-1.noarch.rpm
# /etc/cray/upgrade/csm/csm-1.5.0-beta.64/tarball/csm-1.5.0-beta.64/rpm/cray/csm/sle-15sp4/x86_64/loftsman-1.2.0-3.x86_64.rpm
#
# And outputs the corresponding Nexus URL of that RPM. e.g.:
# https://packages.local/repository/csm-noos/x86_64/hpe-csm-virtiofsd-1.7.0-hpe1.x86_64.rpm
# https://packages.local/repository/csm-noos/noarch/csm-testing-1.16.59-1.noarch.rpm
# https://packages.local/repository/csm-sle-15sp4/x86_64/loftsman-1.2.0-3.x86_64.rpm
#
# Exits non-0 if the specified path does not start with / and end with /rpm/cray/csm/<os-string>/<arch>/<rpm-name>.rpm
function csm_rpm_tarball_path_to_nexus_url {
  if [[ $# -ne 1 ]]; then
    echo "ERROR: $0: This function requires exactly 1 argument but received $#. Invalid arguments: $*" >&2
    return 1
  elif [[ -z $1 ]]; then
    echo "ERROR: $0: Argument to this function may not be blank" >&2
    return 1
  elif [[ ! $1 =~ ^/.*/rpm/cray/csm/[^/[:space:]]+/[^/[:space:]]+/[^/[:space:]]+[.]rpm$ ]]; then
    echo "ERROR: $0: RPM path not in expected format: '$1'" >&2
    return 1
  fi
  echo "$1" | sed 's#^.*/rpm/cray/csm/\([^/[:space:]]\+\)/\([^/[:space:]]\+\)/\([^/[:space:]]\+[.]rpm\)$#https://packages.local/repository/csm-\1/\2/\3#'
}

# Several CSM charts are upgraded "early" during the execution of prerequisites.sh
function upgrade_csm_chart {
  # Usage: upgrade_csm_chart <chart name> <manifest_file>
  #
  # <manifest_file> is the name of the manifest file within the $CSM_MANIFESTS_DIR
  local manifest_folder TMP_CUST_YAML TMP_MANIFEST TMP_MANIFEST_CUSTOMIZED chart_name manifest_file

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

function do_upgrade_csm_chart {
  # Usage: do_upgrade_csm_chart <chart name> <manifest_file>
  #
  # Wrapper function for upgrade_csm_chart which also manages the upgrade states, to reduce
  # needlessly repeated code in the main body of the script, making it less readable.

  if [[ $# -ne 2 ]]; then
    echo "ERROR: $0 function requires exactly 2 arguments but received $#. Invalid argument(s): $*"
    return 1
  elif [[ -z $1 ]]; then
    echo "ERROR: $0: chart name may not be blank"
    return 1
  elif [[ -z $2 ]]; then
    echo "ERROR: $0: manifest file name may not be blank"
    return 1
  fi
  local chart_name manifest_file manifest_file_prefix state_label
  chart_name="$1"
  manifest_file="$2"

  # Strip off the file extension from the manifest file name
  manifest_file_prefix=$(echo "${manifest_file}" | cut -d. -f1)
  state_label="UPGRADE_${manifest_file_prefix}_CHART_${chart_name}"
  # Convert lowercase to uppercase, and convert non-alphanumeric characters to underscores
  state_name=$(echo "${state_label}" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9]/_/g')

  # So if this function is called with chart kyverno-policy and manifest platform.yaml, the
  # state name will be UPGRADE_PLATFORM_CHART_KYVERNO_POLICY

  state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
  if [[ $state_recorded == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
    echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
    {

      if ! upgrade_csm_chart "${chart_name}" "${manifest_file}"; then
        echo "ERROR: failed to upgrade ${chart_name} chart."
        return 1
      fi

    } >> "${LOG_FILE}" 2>&1
    record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  else
    echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
  fi
}

function is_vshasta_node {
  # This is the best check for an image specifically booted to vshasta
  [[ -f /etc/google_system ]] && return 0

  # metal images can still be booted on GCP, so check if there are any disks vendored by Google
  # if not, we conclude that this is not GCP
  lsblk --noheadings -o vendor | grep -q Google
  return $?
}

function set_backupBucket_var {
  backupBucket="config-data"
  cray artifacts list "${backupBucket}" || backupBucket="vbis"
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

    /usr/share/doc/csm/upgrade/scripts/upgrade/util/pre-upgrade-status.sh -o "${SNAPSHOT_DIR}" --hsn-not-required --sdu-not-required

    SNAPSHOT_DIR_BASENAME=$(basename "${SNAPSHOT_DIR}")
    TARFILE_BASENAME="${SNAPSHOT_DIR_BASENAME}.tgz"
    TARFILE_FULLPATH="/tmp/${TARFILE_BASENAME}"
    echo "Creating compressed tarfile of backup data: ${TARFILE_FULLPATH}"
    tar -C /root -czf "${TARFILE_FULLPATH}" "${SNAPSHOT_DIR_BASENAME}"

    # This function sets the $backupBucket variable. It is defined earlier in this file.
    set_backupBucket_var

    echo "Uploading tarfile to S3 (bucket $backupBucket)"
    cray artifacts create "${backupBucket}" "${TARFILE_BASENAME}" "${TARFILE_FULLPATH}"

    echo "Deleting tar file from local filesystem"
    rm -v "${TARFILE_FULLPATH}"
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
    curl -k -H "Authorization: Bearer $(get_token)" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | jq .[] > cloud-init-global.json

    CURRENT_MTU=$(jq '."cloud-init"."meta-data"."kubernetes-weave-mtu"' cloud-init-global.json)
    echo "Current kubernetes-weave-mtu is ${CURRENT_MTU}"

    # make sure kubernetes-weave-mtu is set to 1376
    jq '."cloud-init"."meta-data"."kubernetes-weave-mtu" = "1376"' cloud-init-global.json > cloud-init-global-update.json

    echo "Setting kubernetes-weave-mtu to 1376"
    # post the update json to bss
    curl -s -k -H "Authorization: Bearer $(get_token)" --header "Content-Type: application/json" \
      --request PUT \
      --data @cloud-init-global-update.json \
      https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters

  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  echo
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# Set new ssh config, this should be done everytime the script is run
# This is reversed at the end of the script and also reversed in err_report function
test -f /root/.ssh/config && mv /root/.ssh/config /root/.ssh/config.bak
cat << EOF > /root/.ssh/config
Host *
    StrictHostKeyChecking no
EOF

state_name="UPDATE_SSH_KEYS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
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

      # shellcheck disable=SC2029 # it is intentional that ${TOKEN} expands on the client side
      # run the script
      if ! ssh "${target_ncn}" "TOKEN=$(get_token) /srv/cray/scripts/common/chrony/csm_ntp.py"; then
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
    . "${locOfScript}/util/update-customizations.sh" -i "${CUSTOMIZATIONS_YAML}" "${CSM_ARTI_DIR}/shasta-cfg/customizations.yaml"

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

# Need to upgrade Nexus prior to uploading new images into it.
# Nexus 3.38.0 does not support multi-platform images with sigstore attachments.
# To upgrade Nexus, we need to upload new Nexus images into existing Nexus,
# then pre-cache these images, and finally run cray-nexus chart upgrade.
#
state_name="PRECACHE_NEXUS_IMAGES"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    NEXUS_USERNAME=${NEXUS_USERNAME:-$(kubectl get secret -n nexus nexus-admin-credential --template '{{.data.username}}' | base64 -d)}
    NEXUS_PASSWORD=${NEXUS_PASSWORD:-$(kubectl get secret -n nexus nexus-admin-credential --template '{{.data.password}}' | base64 -d)}
    set +e
    nexus-cred-check() {
      pod=$(kubectl get pods -n nexus --selector app=nexus -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep -v nexus-init | head -1)
      kubectl -n nexus exec -it "${pod}" -c nexus -- curl -i -sfk -u "${NEXUS_USERNAME}:${NEXUS_PASSWORD}" \
        -H "accept: application/json" -X GET http://nexus/service/rest/v1/security/user-sources > /dev/null 2>&1
    }
    if ! nexus-cred-check; then
      echo "Nexus password is incorrect. Please set NEXUS_USERNAME and NEXUS_PASSWORD and try again."
      exit 1
    fi
    set -e

    # Skopeo image is stored as "skopeo:csm-${CSM_RELEASE}", which may resolve to docker.io/lirary/skopeo or quay.io/skopeo, depending on configured shortcuts
    SKOPEO_IMAGE=$(podman load -q -i "${CSM_ARTI_DIR}/vendor/skopeo.tar" 2> /dev/null | sed -e 's/^.*: //')
    nexus_images=$(yq r -j "${CSM_MANIFESTS_DIR}/platform.yaml" 'spec.charts.(name==cray-precache-images).values.cacheImages' | jq -r '.[] | select( . | contains("nexus"))')
    worker_nodes=$(grep -oP "(ncn-w\d+)" /etc/hosts | sort -u)
    while read -r nexus_image; do
      echo "Uploading $nexus_image into Nexus ..."
      podman run --rm -v "${CSM_ARTI_DIR}/docker":/images \
        "${SKOPEO_IMAGE}" \
        --override-os=linux --override-arch=amd64 \
        copy \
        --remove-signatures \
        --dest-tls-verify=false \
        --dest-creds "${NEXUS_USERNAME:-admin}:${NEXUS_PASSWORD}" \
        "dir:/images/${nexus_image}" \
        "docker://registry.local/${nexus_image}"
      while read -r worker_node; do
        echo "Pre-caching image ${nexus_image} on node ${worker_node}"
        ssh -n "${worker_node}" "crictl pull ${nexus_image}"
      done <<< "${worker_nodes}"
    done <<< "${nexus_images}"
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

do_upgrade_csm_chart cray-nexus nexus.yaml

state_name="SETUP_NEXUS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    "${CSM_ARTI_DIR}/lib/setup-nexus.sh"
    # Workaround: To make SAT commands work, use the command below as a WAR to update cray-sat container image
    zypper --non-interactive update cray-sat-podman
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

do_upgrade_csm_chart csm-config sysmgmt.yaml

# Wait for the csm-config-import Kubernetes job to complete before proceeding
state_name="WAIT_FOR_CSM_CONFIG_IMPORT"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    job_name="csm-config-import-${CSM_RELEASE}"
    ns=services
    # First, wait for the job to be created
    wait_for_k8s_job_to_exist "${ns}" "${job_name}"

    # Now wait for the job to succeed
    wait_for_k8s_job_to_succeed "${ns}" "${job_name}"
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# Upgrade Kyverno charts before istio to avoid webhook timeouts
do_upgrade_csm_chart cray-kyverno platform.yaml
do_upgrade_csm_chart kyverno-policy platform.yaml
do_upgrade_csm_chart cray-kyverno-policies-upstream platform.yaml

# Pre-cache images needed for istio upgrade. As soon as cray-istio-deploy is upgraded, network
# connection to nexus will be broken, due to istio proxy and istiod versions mismatch. Upgrade of
# cray-istio will fix that, but images must be pre-cached for it to succeed.
state_name="PRECACHE_ISTIO_IMAGES"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    istio_images=$(yq r -j "${CSM_MANIFESTS_DIR}/platform.yaml" 'spec.charts.(name==cray-precache-images).values.cacheImages' | jq -r '.[] | select( . | (contains("istio") or contains("docker-kubectl")))')
    worker_nodes=$(grep -oP "(ncn-w\d+)" /etc/hosts | sort -u)
    while read -r istio_image; do
      while read -r worker_node; do
        echo "Pre-caching image ${istio_image} on node ${worker_node}"
        ssh -n "${worker_node}" "crictl pull ${istio_image}"
      done <<< "${worker_nodes}"
    done <<< "${istio_images}"
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# Update fs.inotify.max_user_* sysctl settings on running CSM 1.5 nodes. This setting will be persisted
# on new CSM 1.6 nodes, but istio is upgraded before nodes are rebuilt, so we need to modify settings on running worker nodes.
state_name="UPDATE_SYSCTL"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    worker_nodes=$(grep -oP "(ncn-w\d+)" /etc/hosts | sort -u)
    while read -r worker_node; do
      echo "Updating sysctl settings on node ${worker_node}"
      ssh -n "${worker_node}" "sysctl -w fs.inotify.max_user_watches=1048576"
      ssh -n "${worker_node}" "sysctl -w fs.inotify.max_user_instances=1024"
    done <<< "${worker_nodes}"
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# upgrade all charts dependent on cray-certmanager chart
# it is neccessary to upgrade these before upgrade
do_upgrade_csm_chart cray-istio-operator platform.yaml
do_upgrade_csm_chart cray-istio-deploy platform.yaml
do_upgrade_csm_chart cray-istio platform.yaml
do_upgrade_csm_chart cray-kiali platform.yaml

# Cleanup for Kiali configmaps
state_name="KIALI_CLEANUP"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    echo "Cleaning up old Configmap of Kiali"
    cmap=$(kubectl get cm -n istio-system -l app=kiali,app.kubernetes.io/instance=kiali,app.kubernetes.io/name=kiali,app.kubernetes.io/part-of=kiali -o name)
    if [ -n "$cmap" ]; then
      kubectl delete -n istio-system "$cmap"
    fi
    echo "Configmap deleted"

    opr=$(kubectl get po -n istio-system -l app=kiali,app.kubernetes.io/instance=kiali,app.kubernetes.io/name=kiali,app.kubernetes.io/part-of=kiali -o name)
    if [ -n "$opr" ]; then
      kubectl delete -n istio-system "$opr" --grace-period=0 --force
    fi
    echo "Kiali Operator restarted"
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

do_upgrade_csm_chart cray-keycloak platform.yaml
do_upgrade_csm_chart cray-oauth2-proxies platform.yaml
do_upgrade_csm_chart spire sysmgmt.yaml
do_upgrade_csm_chart cray-spire sysmgmt.yaml
do_upgrade_csm_chart cray-tapms-crd sysmgmt.yaml
do_upgrade_csm_chart cray-tapms-operator sysmgmt.yaml

# Restart vault pods because pods were having the older proxyv2 image version.
# Running the rollout restart script to restart the required resources in istio-injection=enabled namespaces.
state_name="RESTART_SERVICES_REFRESH_ISTIO"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    "${locOfScript}/rollout-restart.sh"
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

# Note for csm 1.5/k8s 1.22 only if ANY chart depends on /v1 cert-manager api
# usage it *MUST* come after this or prerequisites will fail on an upgrade.
# Helper functions for cert-manager upgrade
has_craycm() {
  ns="${1?no namespace provided}"
  helm list -n "${ns}" --filter 'cray-certmanager$' | grep cray-certmanager > /dev/null 2>&1
}

state_name="UPGRADE_CERTMANAGER_155_CHART"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    # The actions below only need to happen iff we are on 1.5.5. If we're
    # already at 1.12.9+ the crd ownership changes makes this logic impossible to
    # work due to helm hooks. Making this work on both isn't really worth the
    # time so just constrain this block of logic to 1.5.5 where we know its
    # needed.
    gate="1.5.5"
    found=$(helm list -n cert-manager --filter 'cray-certmanager$' | awk '/deployed/ {print $10}')

    needs_upgrade=0

    if [ "${found}" = "${gate}" ]; then
      printf "note: found old cert-manager that needs upgrades %s\n" "${found}" >&2
      ((needs_upgrade += 1))
    else
      printf "note: cert-manager helm chart version %s\n" "${found}" >&2

      # We might be rerunning from a pre 1.6.x install and there is no
      # cert-manager installed due to a prior removal
      if [ "${found}" = "" ]; then
        printf "note: no helm install appears to exist for cert-manager, likely this state is being run again\n" >&2
        ((needs_upgrade += 1))
      else
        printf "note: no cert-manager upgrade steps needed, cert-manager 1.5.5 is not installed\n" >&2
      fi
    fi

    # cert-manager will need to be upgraded if cray-drydock version is less than 2.18.4.
    # This will only be the case in some CSM 1.6 to CSM 1.6 upgrades.
    # It only needs to be checked if cert-manager is not already being upgraded.
    if [ "${needs_upgrade}" -eq 0 ]; then
      drydock_vers=$(helm get values -n loftsman cray-drydock | grep version: | sed 's/ *version: //')
      major=2
      minor=18
      patch=4
      drydock_major="${drydock_vers%%.*}"
      drydock_minor_patch="${drydock_vers#*.}" # temp
      drydock_patch="${drydock_minor_patch#*.}"
      drydock_minor="${drydock_minor_patch%.*}"
      if [ $drydock_major -lt $major ]; then
        needs_upgrade=1
      elif [ $drydock_major -eq $major ] && [ $drydock_minor -lt $minor ]; then
        needs_upgrade=1
      elif [ $drydock_major -eq $major ] && [ $drydock_minor -eq $minor ] && [ $drydock_patch -lt $patch ]; then
        needs_upgrade=1
      elif [[ $drydock_vers == "" ]]; then
        needs_upgrade=1
      fi
      if [ $needs_upgrade -ne 0 ]; then
        echo "cray-drydock version [$drydock_vers] less than $major.$minor.$patch and needs to be upgraded."
        echo "Cray-drydock will be upgraded and the cert-manager namespace will be redeployed."
      fi
    fi

    # Only run if we need to and detected not 1.12.9 or ""
    if [ "${needs_upgrade}" -gt 0 ]; then
      cmns="cert-manager"

      backup_secret="cm-restore-data"

      # We need to backup before any helm uninstalls.
      needs_backup=0

      if has_craycm ${cmns}; then
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

      # Only remove cray-certmanager if installed
      if has_craycm ${cmns}; then
        helm uninstall -n "${cmns}" cray-certmanager
      fi

      # Note: These should *never* fail as we depend on helm uninstall doing
      # its job, but if it didn't exit early here as something is amiss.
      cm=1

      if ! helm list -n "${cmns}" --filter 'cray-certmanager$' | grep cray-certmanager > /dev/null 2>&1; then
        cm=0
      fi

      if [ "${cm}" = "1" ]; then
        printf "fatal: helm uninstall did not remove expected chart cert-manager %s\n" "${cm}" >&2
        exit 1
      fi

      # Ensure the cert-manager namespace is deleted in a case of both helm charts
      # removed but there might be detritus left over in the namespace.
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

do_upgrade_csm_chart cray-psp platform.yaml
do_upgrade_csm_chart cray-postgres-operator platform.yaml
do_upgrade_csm_chart cray-iuf platform.yaml
do_upgrade_csm_chart cray-nls platform.yaml

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

do_upgrade_csm_chart cray-drydock platform.yaml
do_upgrade_csm_chart cray-sysmgmt-health platform.yaml
do_upgrade_csm_chart cray-tftp sysmgmt.yaml
do_upgrade_csm_chart cray-tftp-pvc sysmgmt.yaml
# cms-ipxe needs to be upgraded here so it is compatible with the newer istio version in CSM 1.6
do_upgrade_csm_chart cms-ipxe sysmgmt.yaml
# cray-product-catalog needs to be upgraded here in CSM 1.6 so it is compatible with SAT when building images/cfs configs
do_upgrade_csm_chart cray-product-catalog sysmgmt.yaml

state_name="UPLOAD_NEW_NCN_IMAGE"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    artdir=${CSM_ARTI_DIR}/images
    SQUASHFS_ROOT_PW_HASH=$(awk -F':' /^root:/'{print $2}' < /etc/shadow)
    export SQUASHFS_ROOT_PW_HASH
    set -o pipefail
    NCN_IMAGE_MOD_SCRIPT=$(rpm -ql docs-csm | grep ncn-image-modification.sh)
    set +o pipefail

    KUBERNETES_VERSION=$(find "${artdir}/kubernetes" -name 'kubernetes*.squashfs' -exec basename {} .squashfs \; | sed -e 's/^kubernetes-//' -e 's/-[^-]*$//')
    CEPH_VERSION=$(find "${artdir}/storage-ceph" -name 'storage-ceph*.squashfs' -exec basename {} .squashfs \; | sed -e 's/^storage-ceph-//' -e 's/-[^-]*$//')

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
      # ${artdir} is mounted on top of CephFS. Running mksquashfs against it is very slow. We will copy squashfs files to temporary dir
      # instead, and run NCN modification script there.
      tmpdir_kubernetes=$(mktemp -d)
      tmpdir_storage=$(mktemp -d)
      cp "${artdir}/kubernetes/kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs" "${tmpdir_kubernetes}/"
      cp "${artdir}/storage-ceph/storage-ceph-${CEPH_VERSION}-${arch}.squashfs" "${tmpdir_storage}/"
      DEBUG=1 "${NCN_IMAGE_MOD_SCRIPT}" \
        -d /root/.ssh \
        -k "${tmpdir_kubernetes}/kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs" \
        -s "${tmpdir_storage}/storage-ceph-${CEPH_VERSION}-${arch}.squashfs" \
        -p
      mv "${tmpdir_kubernetes}/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs" "${artdir}/kubernetes/"
      mv "${tmpdir_storage}/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs" "${artdir}/storage-ceph/"
      rm -Rf "${tmpdir_kubernetes}" "${tmpdir_storage}"
    fi

    set -o pipefail
    IMS_UPLOAD_SCRIPT=$(rpm -ql docs-csm | grep ncn-ims-image-upload.sh)

    UUID_REGEX='^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$'

    echo "Uploading Kubernetes images..."
    export IMS_ROOTFS_FILENAME="${artdir}/kubernetes/secure-kubernetes-${KUBERNETES_VERSION}-${arch}.squashfs"
    export IMS_INITRD_FILENAME="${artdir}/kubernetes/initrd.img-${KUBERNETES_VERSION}-${arch}.xz"
    # do not quote this glob.  bash will add single ticks (') around it, preventing expansion later
    resolve_kernel_glob=$(echo ${artdir}/kubernetes/*-${arch}.kernel)
    export IMS_KERNEL_FILENAME=$resolve_kernel_glob
    K8S_IMS_IMAGE_ID=$($IMS_UPLOAD_SCRIPT)
    [[ -n ${K8S_IMS_IMAGE_ID} ]] && [[ ${K8S_IMS_IMAGE_ID} =~ $UUID_REGEX ]]

    echo "Uploading Ceph images..."
    export IMS_ROOTFS_FILENAME="${artdir}/storage-ceph/secure-storage-ceph-${CEPH_VERSION}-${arch}.squashfs"
    export IMS_INITRD_FILENAME="${artdir}/storage-ceph/initrd.img-${CEPH_VERSION}-${arch}.xz"
    # do not quote this glob.  bash will add single ticks (') around it, preventing expansion later
    resolve_kernel_glob=$(echo ${artdir}/storage-ceph/*-${arch}.kernel)
    export IMS_KERNEL_FILENAME=$resolve_kernel_glob
    STORAGE_IMS_IMAGE_ID=$($IMS_UPLOAD_SCRIPT)
    [[ -n ${STORAGE_IMS_IMAGE_ID} ]] && [[ ${STORAGE_IMS_IMAGE_ID} =~ $UUID_REGEX ]]
    set +o pipefail

    # clean up any previous set values just in case.
    echo "Updating image ids..."
    touch /etc/cray/upgrade/csm/myenv
    sed -i 's/^export STORAGE_IMS_IMAGE_ID.*//' /etc/cray/upgrade/csm/myenv
    sed -i 's/^export KUBERNETES_IMS_IMAGE_ID.*//' /etc/cray/upgrade/csm/myenv
    echo "export STORAGE_IMS_IMAGE_ID=${STORAGE_IMS_IMAGE_ID}" >> /etc/cray/upgrade/csm/myenv
    echo "export K8S_IMS_IMAGE_ID=${K8S_IMS_IMAGE_ID}" >> /etc/cray/upgrade/csm/myenv

    # NOTE: NCN node images are no longer set in BSS here
    # IUF workflows handle setting the correct node image before a node is upgraded
    # If doing a CSM only upgrade, NCN images are set in the CSM-Only procedure
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
    curl -k -H "Authorization: Bearer $(get_token)" https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters?name=Global | jq .[] > cloud-init-global.json

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
    curl -s -k -H "Authorization: Bearer $(get_token)" --header "Content-Type: application/json" \
      --request PUT \
      --data @cloud-init-global_update.json \
      https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters
  } >> "${LOG_FILE}" 2>&1
  record_state "${state_name}" "$(hostname)" | tee -a "${LOG_FILE}"
  echo
else
  echo "====> ${state_name} has been completed" | tee -a "${LOG_FILE}"
fi

state_name="UPDATE_NCN_CLOUD_INIT_PACKAGE_LISTS_AND_REPO_DEFINITIONS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    do_patch=0
    error=0
    sourcefile="${CSM_ARTI_DIR}/rpm/cloud-init"

    # If this is a re-run and our source JSON was already created we don't need to recreate it.
    if [ ! -f "${sourcefile}.json" ]; then

      # If the source JSON does not exist, check that our source YAML exists for creating the source JSON.
      if [ ! -f "${sourcefile}.yaml" ]; then

        # If the source YAML does not exist, then it can be assumed that this vintage of CSM does not support package installs from cloud-init.
        # In this case, there is nothing to do because the CSM version we are upgrading to is too old.
        echo "No $(basename "$sourcefile").yaml file found at: ${sourcefile}.yaml. Skipping package & repo meta-data injection."

        # Do not error out, if the file is missing then the feature is considered to be disabled/unused by the tarball's contents.
        error=0
      else

        # csi handoff bss-update-cloud-init --user-data` only takes JSON, convert the human-friendlier YAML to JSON and nest it under the expected key.
        yq4 eval '{"user-data": .}' "${sourcefile}.yaml" -j > "${sourcefile}.json"

        # Set `do_patch` to 1 so that the operations in this stage run.
        do_patch=1
      fi
    else
      do_patch=1
    fi

    # Patch cloud-init user-data for each NCN only if we have our ${sourcefile}.json.
    if [ "$do_patch" -eq 1 ]; then

      # Get a list of NCNs.
      if IFS=$'\n' read -rd '' -a NCN_XNAMES; then
        :
      fi <<< "$(cray hsm state components list --role Management --type Node --format json | jq -r '.Components | map(.ID) | join("\n")')"

      # If no NCNs are found we should exit, otherwise if forces its way forward then NCNs will be missing critical packages.
      if [ "${#NCN_XNAMES[@]}" -eq '0' ]; then
        echo >&2 'No NCN xnames were found in HSM! Aborting.'
        exit 1
      fi

      # Loop through one at a time. If `--limit` isn't provided, we will error out on the 'Global' key.
      for ncn_xname in "${NCN_XNAMES[@]}"; do

        # Purge the old user-data.zypper list for each NCN to make way for new definitions.
        if ! csi handoff bss-update-cloud-init --limit "$ncn_xname" --delete 'user-data.zypper' > /dev/null 2>&1; then
          echo "${ncn_xname}: No defined zypper meta to delete."
        fi

        # Purge any weird user-data.repos keys that may exist from previous upgrades. These keys are harmless but will look confusing.
        if ! csi handoff bss-update-cloud-init --limit "$ncn_xname" --delete 'user-data.repos' > /dev/null 2>&1; then
          :
        fi

        # Verify that user-data.zypper is now null.
        if [ ! "$(cray bss bootparameters list --format json --hosts "$ncn_xname" | jq '.[]."cloud-init"."user-data".zypper')" = 'null' ]; then
          echo >&2 "${ncn_xname}: user-data.zypper key is still defined!"
          error=1
        fi

        # Purge the old user-data.packages list for each NCN to make way for the new list.
        if ! csi handoff bss-update-cloud-init --limit "$ncn_xname" --delete 'user-data.packages' > /dev/null 2>&1; then
          echo "${ncn_xname}: No defined packages to delete."
        fi

        # Verify that user-data.packages is now null.
        if [ ! "$(cray bss bootparameters list --format json --hosts "$ncn_xname" | jq '.[]."cloud-init"."user-data".packages')" = 'null' ]; then
          echo >&2 "${ncn_xname}: user-data.packages key is still defined!"
          error=1
        fi

        # Set the new values for user-data.zypper and user-data.packages.
        if ! csi handoff bss-update-cloud-init --limit "$ncn_xname" --user-data "${sourcefile}.json" > /dev/null 2>&1; then
          echo >&2 "${ncn_xname}: Failed to apply new cloud-init data!"
          error=1
        fi

      done
    fi

    # If error was ever set we need to exit so the admin can investigate. We don't exit early so that all the errors can be seen at once.
    if [ "$error" -ne 0 ]; then
      echo >&2 "Errors were encountered during cloud-init patching for zypper repos and package manifests."
      exit 1
    fi

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

    # Get a list of NCNs.
    if IFS=$'\n' read -rd '' -a NCN_XNAMES; then
      :
    fi <<< "$(cray hsm state components list --role Management --subrole Worker --type Node --format json | jq -r '.Components | map(.ID) | join("\n")')"
    # If no NCNs are found we should exit, otherwise if forces its way forward then NCNs will be missing critical packages.
    if [ "${#NCN_XNAMES[@]}" -eq '0' ]; then
      echo >&2 'No NCN xnames were found in HSM! Aborting.'
      exit 1
    fi

    params=""
    error=0

    # Loop through one at a time. If `--hosts` isn't provided, we will error out on the 'Global' key.
    for ncn_xname in "${NCN_XNAMES[@]}"; do
      printf "% -15s: " "${ncn_xname}"

      params=$(cray bss bootparameters list --hosts "${ncn_xname}" --format json | jq '.[] |."params"' \
        | sed -E \
          -e 's/ip=hsn[0-9]+:auto6\s?//g' \
          -e 's/ifname=hsn[0-9]+:[0-9a-fA-F:]{17}\s?//g' \
          -e 's/\"//g')

      if ! cray bss bootparameters update --hosts "${ncn_xname}" \
        --params "${params}" > /dev/null 2>&1; then
        echo "ERROR - Failed to update boot parameters for $xname! Skipping ..."
        error=1
        continue
      fi
      echo 'OK'
    done
    if [ "$error" -ne 0 ]; then
      echo >&2 "Errors were detected, please inspect the scripts output."
      exit 1
    else
      echo "Successfully updated boot parameters for [${#NCN_XNAMES[@]}] xname(s):"
      printf "\t%s\n" "${NCN_XNAMES[@]}"
    fi

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

do_upgrade_csm_chart trustedcerts-operator platform.yaml

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

state_name="UPDATE_BSS_DATA_NCNS"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" && $(hostname) == "${PRIMARY_NODE}" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {

    # Template cloud-init disk configurations
    csi config template cloud-init disks
    master_user_data=$(< "ncn-master/cloud-init/user-data.json")
    worker_user_data=$(< "ncn-worker/cloud-init/user-data.json")
    storage_user_data=$(< "ncn-storage/cloud-init/user-data.json")

    # Get xnames for all Management nodes
    if IFS=$'\n' read -rd '' -a NCN_XNAMES; then
      :
    fi <<< "$(cray hsm state components list --role Management --type Node --format json | jq -r '.Components | map(.ID) | join("\n")')"

    # Update BSS data for ncn-master nodes
    for xname in "${NCN_XNAMES[@]}"; do
      xname_bss="$(cray bss bootparameters list --format json --hosts "${xname}" | jq '.[0]')"

      # Add disk configuration for each NCN
      jq --argjson bss "$xname_bss" \
        --argjson master_user_data "$master_user_data" \
        --argjson worker_user_data "$worker_user_data" \
        --argjson storage_user_data "$storage_user_data" \
        'if .["cloud-init"]["meta-data"]["shasta-role"] == "ncn-master" then
          .["cloud-init"]["user-data"]["bootcmd"] = $master_user_data["user-data"]["bootcmd"] |
          .["cloud-init"]["user-data"]["fs_setup"] = $master_user_data["user-data"]["fs_setup"] |
          .["cloud-init"]["user-data"]["mounts"] = $master_user_data["user-data"]["mounts"]
        elif .["cloud-init"]["meta-data"]["shasta-role"] == "ncn-worker" then
          .["cloud-init"]["user-data"]["bootcmd"] = $worker_user_data["user-data"]["bootcmd"] |
          .["cloud-init"]["user-data"]["fs_setup"] = $worker_user_data["user-data"]["fs_setup"] |
          .["cloud-init"]["user-data"]["mounts"] = $worker_user_data["user-data"]["mounts"]
        elif .["cloud-init"]["meta-data"]["shasta-role"] == "ncn-storage" then
          .["cloud-init"]["user-data"]["bootcmd"] = $storage_user_data["user-data"]["bootcmd"] |
          .["cloud-init"]["user-data"]["fs_setup"] = $storage_user_data["user-data"]["fs_setup"] |
          .["cloud-init"]["user-data"]["mounts"] = $storage_user_data["user-data"]["mounts"]
        else .
        end' <<< "$xname_bss" > "bss-patched-${xname}.json"

      # Update BSS
      curl -s -i -k -H "Authorization: Bearer $(get_token)" -X PUT \
        https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters \
        --data @./"bss-patched-${xname}.json" \
        && rm "bss-patched-${xname}.json"
    done
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
      cray cfs v3 components update "${xname}" --enabled false --format json

      # Make sure it is actually disabled
      echo "Verifying that CFS is now disabled on ${xname}"
      set -o pipefail
      cray cfs v3 components describe "${xname}" --format json | jq '.enabled' | grep "^false$"
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
    # Restore labels and annotations on Argo CRDs
    for c in $(kubectl get crd | grep argo | cut -d' ' -f1); do
      kubectl label --overwrite crd "$c" app.kubernetes.io/managed-by="Helm"
      kubectl annotate --overwrite crd "$c" meta.helm.sh/release-name="cray-nls"
      kubectl annotate --overwrite crd "$c" meta.helm.sh/release-namespace="argo"
    done

    # CASMINST-6040 - need to wait for hooks.cray-nls.hpe.com crd to be created
    # before uploading rebuild workflow templates which use hooks
    echo "Wait for hooks.cray-nls.hpe.com crd to be created"

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

state_name="PREPARE_KUBEADM"
state_recorded=$(is_state_recorded "${state_name}" "$(hostname)")
if [[ ${state_recorded} == "0" ]]; then
  echo "====> ${state_name} ..." | tee -a "${LOG_FILE}"
  {
    tmpdir=$(mktemp -d)

    echo "Patching ConfigMap kubeadm-config ..."
    kubectl -n kube-system get configmap kubeadm-config -o go-template --template '{{ .data.ClusterConfiguration }}' \
      | yq4 e '.kubernetesVersion="1.24.17"' \
      | yq4 e '.dns.imageRepository="artifactory.algol60.net/csm-docker/stable/registry.k8s.io/coredns"' \
      | yq4 e '.imageRepository="artifactory.algol60.net/csm-docker/stable/registry.k8s.io"' \
      | yq4 e '.apiServer.extraArgs.profiling="false"' \
      | yq4 e '.controllerManager.extraArgs.terminated-pod-gc-threshold="250"' \
      | yq4 e '.controllerManager.extraArgs.profiling="false"' \
        > "${tmpdir}/kubeadm-config.yaml"
    patch=$(jq -c -n --rawfile text "${tmpdir}/kubeadm-config.yaml" '.data["ClusterConfiguration"]=$text')
    kubectl -n kube-system patch configmap kubeadm-config --type merge --patch "${patch}"

    if kubectl -n kube-system get configmap -o custom-columns=name:.metadata.name --no-headers | grep -x -q -F kubelet-config-1.22; then
      echo "Creating ConfigMap kubelet-config-1.24 ..."
      kubectl -n kube-system get configmap kubelet-config-1.22 -o yaml \
        | yq4 e '.metadata.name="kubelet-config-1.24"' \
        | yq4 e 'del .metadata.creationTimestamp' \
        | yq4 e 'del .metadata.resourceVersion' \
        | yq4 e 'del .metadata.uid' \
        | kubectl apply -f -
    else
      echo "ConfigMap kubelet-config-1.22 not found, assuming kubelet-config or kubelet-config-1.24 is already in place."
    fi

    if kubectl -n kube-system get role -o custom-columns=name:.metadata.name --no-headers | grep -x -q -F kubeadm:kubelet-config-1.22; then
      echo "Creating Role kubeadm:kubelet-config-1.24 ..."
      kubectl -n kube-system get role kubeadm:kubelet-config-1.22 -o yaml \
        | yq4 e '.metadata.name="kubeadm:kubelet-config-1.24"' \
        | yq4 e '.rules[0].resourceNames[0]="kubelet-config-1.24"' \
        | yq4 e 'del .metadata.creationTimestamp' \
        | yq4 e 'del .metadata.resourceVersion' \
        | yq4 e 'del .metadata.uid' \
        | kubectl apply -f -
    else
      echo "Role kubeadm:kubelet-config-1.22 not found, assuming kubeadm:kubelet-config or kubeadm:kubelet-config-1.24 is already in place."
    fi

    if kubectl -n kube-system get rolebinding -o custom-columns=name:.metadata.name --no-headers | grep -x -q -F kubeadm:kubelet-config-1.22; then
      echo "Creating RoleBinding kubeadm:kubelet-config-1.24 ..."
      kubectl -n kube-system get rolebinding kubeadm:kubelet-config-1.22 -o yaml \
        | yq4 e '.metadata.name="kubeadm:kubelet-config-1.24"' \
        | yq4 e '.roleRef.name="kubeadm:kubelet-config-1.24"' \
        | yq4 e 'del .metadata.creationTimestamp' \
        | yq4 e 'del .metadata.resourceVersion' \
        | yq4 e 'del .metadata.uid' \
        | kubectl apply -f -
    else
      echo "RoleBinding kubeadm:kubelet-config-1.22 not found, assuming kubeadm:kubelet-config or kubeadm:kubelet-config-1.24 is already in place."
    fi

    rm -rf "${tmpdir}"
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
    rpm_list=(csm-testing hpe-csm-goss-package platform-utils goss-servers cray-cmstools-crayctldeploy)
    url_list=()
    for rpm_name in "${rpm_list[@]}"; do
      rpm_path=$(find "${CSM_ARTI_DIR}"/rpm/cray/csm/ -name \*${rpm_name}\*.rpm | sort -V | tail -1)
      rpm --force -Uvh "${rpm_path}"
      # CASMPET-6635 & CASMINST-6517
      rpm_url=$(csm_rpm_tarball_path_to_nexus_url "${rpm_path}")
      url_list+=("${rpm_url}")
    done
    systemctl enable goss-servers
    systemctl restart goss-servers

    # Install above RPMs and restart goss-servers on all other NCNs
    ncns=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | grep -Ev "^$(hostname -s)$" | tr -t '\n' ',')
    pdsh -S -b -w ${ncns} "rpm --force -Uvh ${url_list[*]}; systemctl enable goss-servers; systemctl restart goss-servers;"

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
touch ${PREREQS_DONE_FILE}
