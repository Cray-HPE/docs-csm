#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023-2024 Hewlett Packard Enterprise Development LP
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

set -o pipefail

exit_status=0
error_summary=""
OUTPUT_SUBDIR="system-status"
OUTPUT_DIR_BASENAME="system-status-pre-upgrade-$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR_SUFFIX="/${OUTPUT_SUBDIR}/${OUTPUT_DIR_BASENAME}"
OUTPUT_MOUNT="/etc/cray/upgrade/csm"
FULL_OUTPUT_DIR=${OUTPUT_MOUNT}${OUTPUT_DIR_SUFFIX}
USER_OUTPUT_DIR=""
HSN_REQUIRED=Y
SDU_REQUIRED=Y

TARFILE_BASENAME="${OUTPUT_DIR_BASENAME}.tgz"
TARFILE_KEY="${OUTPUT_SUBDIR}/${OUTPUT_DIR_BASENAME}"

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --hsn-not-required)
      HSN_REQUIRED=N
      shift # past argument
      ;;
    -o | --output)
      USER_OUTPUT_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    --sdu-not-required)
      SDU_REQUIRED=N
      shift # past argument
      ;;
    *) # unknown option
      echo "[ERROR] - unknown options"
      echo "usage 1: $0"
      echo "usage 2: $0 [--hsn-not-required] [-o|--output] [--sdu-not-required] OUTPUT_DIRECTORY"
      echo
      echo "If no output directory is supplied, status files will be saved in ${FULL_OUTPUT_DIR}."
      echo "If OUTPUT_DIRECTORY is supplied, status files will be save in the provided directory."
      echo "--hsn-not-required and --sdu-not-required means the script will not consider it a failure if"
      echo "those are not available. However, if they are available, errors collecting their data will"
      echo "still result in a failure."
      exit 1
      ;;
  esac
done

# Check that the Cray CLI is authenticated
if ! /usr/bin/cray artifacts buckets list > /dev/null; then
  echo "ERROR: Command failed: /usr/bin/cray artifacts buckets list"
  echo
  echo "Verify that the Cray CLI is authenticated on this node"
  exit 1
fi

# check that mount exists
if [[ -n $USER_OUTPUT_DIR ]]; then
  FULL_OUTPUT_DIR=$USER_OUTPUT_DIR
elif [[ ! -d $OUTPUT_MOUNT ]]; then
  echo "Warning: did not find $OUTPUT_MOUNT directory. Saving files on '/root/'."
  FULL_OUTPUT_DIR="/root${OUTPUT_DIR_SUFFIX}"
fi
if [[ ! -d $FULL_OUTPUT_DIR ]]; then
  mkdir -p "$FULL_OUTPUT_DIR"
  echo "Created $FULL_OUTPUT_DIR directory"
fi

# check if last character in path is '/''
if [[ ${FULL_OUTPUT_DIR: -1} != '/' ]]; then
  FULL_OUTPUT_DIR="${FULL_OUTPUT_DIR}/"
fi

function get_file_path() {
  echo "${FULL_OUTPUT_DIR}${1}.$(date +%Y%m%d_%H%M%S).txt"
}

function log_error() {
  echo "$*"
  exit_status=1
  error_summary="${error_summary}\n$*"
}

function execute() {
  local rc
  file_path=$(get_file_path "$2")
  echo "Executing: '$1'"
  echo -e "Saving output to: '$file_path'\n"
  $1 | tee -a "$file_path"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    log_error "ERROR executing $1. Manually run this command to investigate the problem."
  fi
  echo
  return $rc
}

function execute_no_output_file() {
  # usage: execute_no_output_file <command> [arg1] [arg2] ...
  # Same as previous function, except the output is not redirected -- this is used when
  # running commands that save off their own output files
  local rc
  echo "Executing: $*"
  "$@"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    log_error "ERROR executing $*. Manually run this command to investigate the problem."
  fi
  echo
  return $rc
}

function sat_status() {
  echo "---- Recording SAT Status of Nodes ----"
  execute "sat status --filter Enabled=false" "sat.status.enabled.false"
  execute "sat status --filter Enabled=true --filter State=off" "sat.status.state.off"
  execute "sat status --filter Enabled=true --filter State=on" "sat.status.state.on"
}

function hsn_status() {
  echo "---- Recording HSN Status ----"
  if [[ -n $(kubectl get pods -A | grep slingshot-fabric-manager | awk '{print $2}') ]]; then
    execute "kubectl exec -it -n services $(kubectl get pods -A | grep slingshot-fabric-manager | awk '{print $2}') -c slingshot-fabric-manager -- fmn_status" "fmn.show.status"
    execute "kubectl exec -it -n services $(kubectl get pods -A | grep slingshot-fabric-manager | awk '{print $2}') -c slingshot-fabric-manager -- fmn_status --details" "fmn.show.status.detail"
    execute "kubectl exec -it -n services $(kubectl get pods -A | grep slingshot-fabric-manager | awk '{print $2}') -c slingshot-fabric-manager -- linkdbg -L fabric" "linkdbg.L.fabric"
    execute "kubectl exec -it -n services $(kubectl get pods -A | grep slingshot-fabric-manager | awk '{print $2}') -c slingshot-fabric-manager -- linkdbg -L edge" "linkdbg.L.edge"
    execute "kubectl exec -it -n services $(kubectl get pods -A | grep slingshot-fabric-manager | awk '{print $2}') -c slingshot-fabric-manager -- show-flaps" "show.flaps"
    return
  fi
  msg="no slingshot-fabric-manager pod was found. HSN status is not being recoreded."
  if [[ ${HSN_REQUIRED} == N ]]; then
    echo "WARNING ${msg}"
    return
  fi
  log_error "ERROR ${msg}."
}

function ceph_status() {
  echo "---- Recording Ceph Status ----"
  execute "ceph -s" "ceph.s"
  execute "ceph osd perf" "ceph.osd.perf"
}

function sat_rev_status() {
  echo "---- Recording SAT System Status ----"
  execute "sat showrev --system" "sat.showrev.system"
  # get sat site_info file if it exists
  if [ -f '/root/.config/sat/sat.toml' ]; then
    site_info_conf=$(cat /root/.config/sat/sat.toml | grep 'site_info')
    if [ -n "$site_info_conf" ]; then
      # get filepath after '='
      site_info_file=${site_info_conf##*= }
      site_info_file=${site_info_file//\"/}
      if [ -f $site_info_file ]; then
        execute "cat $site_info_file" "sat.site_info"
      fi
    fi
  fi
}

function sdu_status() {
  echo "---- Recording SDU and RDS Configurations ----"
  if [[ $(systemctl is-active cray-sdu-rda) != "active" ]]; then
    warn_message="WARNING cray-sdu-rda is not active. The SDU and RDA configuration can only be backed up when cray-sdu-rda is active."
    echo "$warn_message"
    echo "Run 'systemctl start cray-sdu-rda' to start service."
    [[ ${SDU_REQUIRED} == N ]] && return
    error_summary="${error_summary}\n${warn_message}"
    exit_status=1
    return
  fi
  execute "sdu bash cat /etc/opt/cray/sdu/sdu.conf" "sdu.conf"
  execute "sdu bash cat /etc/rda/rda.conf" "rda.conf"
}

function cfs_backup() {
  echo "---- Backing up CFS data ----"
  execute_no_output_file /usr/share/doc/csm/scripts/operations/configuration/export_cfs_data.sh "${FULL_OUTPUT_DIR}"
}

function bos_backup() {
  echo "---- Backing up BOS data ----"
  execute_no_output_file /usr/share/doc/csm/scripts/operations/configuration/export_bos_data.sh --include-v1 "${FULL_OUTPUT_DIR}"
}

function k8s_status() {
  # Record state of Kubernetes pods. If a pod is later seen in an unexpected state, this can provide a reference to
  # determine whether or not the issue existed prior to the upgrade.
  echo "Taking snapshot of current Kubernetes pod states"
  execute "kubectl get pods -A -o wide --show-labels" k8s_pods.txt
}

function collect_data() {
  sat_status
  hsn_status
  ceph_status
  sat_rev_status
  sdu_status
  cfs_backup
  bos_backup
  k8s_status
}

function upload_data_to_s3() {
  local tempdir tarfile bucket

  # Create compressed tar archive of data
  if ! tempdir=$(mktemp -d); then
    log_error "ERROR Failed to create temporary directory -- cannot create tar archive"
    return
  fi
  tarfile="${tempdir}/${TARFILE_BASENAME}"

  execute_no_output_file ln -s "${FULL_OUTPUT_DIR}" "${tempdir}/${OUTPUT_DIR_BASENAME}" || return
  execute_no_output_file tar -C "${tempdir}" -czvf "${tarfile}" "${OUTPUT_DIR_BASENAME}" || return

  bucket="config-data"
  cray artifacts list "${bucket}" > /dev/null 2>&1 || bucket="vbis"

  execute_no_output_file cray artifacts create "${bucket}" "${TARFILE_KEY}" "${tarfile}" || return

  # Clean up temporary directory
  if ! rm "${tempdir}/${OUTPUT_DIR_BASENAME}" "${tarfile}"; then
    echo "WARNING: Failed to remove temporary files: ${tempdir}/${OUTPUT_DIR_BASENAME} ${tarfile}"
    return
  fi
  rmdir "${tempdir}" || echo "WARNING: Failed to remove temporary directory: ${tempdir}"
}

function main() {
  collect_data
  upload_data_to_s3
}

main

if [[ $exit_status != 0 ]]; then
  echo -e "\nERROR SUMMARY"
  echo -e "$error_summary\n"
  echo "Manually run these commands or look at the output above to investigate the problem(s)."
fi
exit $exit_status
