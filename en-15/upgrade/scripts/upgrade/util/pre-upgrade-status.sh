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
OUTPUT_DIR_SUFFIX="/system-status/system-status-pre-upgrade-$(date +%Y%m%d_%H%M%S)"
OUTPUT_MOUNT="/etc/cray/upgrade/csm"
FULL_OUTPUT_DIR=${OUTPUT_MOUNT}${OUTPUT_DIR_SUFFIX}
USER_OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -o | --output)
      USER_OUTPUT_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    *) # unknown option
      echo "[ERROR] - unknown options"
      echo "usage 1: $0"
      echo "usage 2: $0 [-o|--output] OUTPUT_DIRECTORY"
      echo
      echo "If no output directory is supplied, status files will be saved in ${FULL_OUTPUT_DIR}."
      echo "If OUTPUT_DIRECTORY is supplied, status files will be save in the provided directory."
      exit 1
      ;;
  esac
done

# check that mount exists
if [[ -n $USER_OUTPUT_DIR ]]; then
  FULL_OUTPUT_DIR=$USER_OUTPUT_DIR
elif [[ ! -d $OUTPUT_MOUNT ]]; then
  echo -e "Warning: did not find $OUTPUT_MOUNT directory. Saving files on '/root/'. These files will not persist after a node rebuild/upgrade.\n"
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

function execute() {
  file_path=$(get_file_path "$2")
  echo "Executing: '$1'"
  echo -e "Saving output to: '$file_path'\n"
  $1 | tee -a "$file_path"
  if [[ $? != 0 ]]; then
    error_msg="ERROR executing $1. Manually run this command to investigate the problem."
    exit_status=1
    error_summary="${error_summary}\n${error_msg}"
  fi
  echo
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
  else
    error_msg="ERROR no slingshot-fabric-manager pod was found. HSN status is not being recoreded."
    echo "$error_msg"
    exit_status=1
    error_summary="${error_summary}\n${error_msg}"
  fi
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
    warn_message="WARNING cray-sdu-rda is not active. The SDU and RDA configuration can only be bakced up when cray-sdu-rda is active."
    error_summary="${error_summary}\n${warn_message}"
    echo "$warn_message"
    echo "Run 'systemctl start cray-sdu-rda' to start service."
    exit_status=1
  else
    execute "sdu bash cat /etc/opt/cray/sdu/sdu.conf" "sdu.conf"
    execute "sdu bash cat /etc/rda/rda.conf" "rda.conf"
  fi
}

function main() {
  sat_status
  hsn_status
  ceph_status
  sat_rev_status
  sdu_status
}

main

if [[ $exit_status != 0 ]]; then
  echo -e "\nERROR SUMMARY"
  echo -e "$error_summary\n"
  echo "Manually run these commands or look at the output above to investigate the problem(s)."
fi
exit $exit_status
