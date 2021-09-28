#!/bin/bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

set -euo pipefail

# This means that something like /tmp/*.log will evaluate to an empty string if no files fit the pattern
shopt -s nullglob

# This script is a replacement for the steps that were previously done manually
# during the "Deploy Final NCN" step of CSM installs.

function err_exit {
  echo "ERROR: $*" >&2
  exit 1
}

function dir_exists {
  [[ -e $1 ]] || err_exit "Directory '$1' does not exist"
  [[ -d $1 ]] || err_exit "'$1' exists but is not a directory"
}

function run_cmd {
  echo "# $*"
  "$@" || err_exit "Command failed with exit code $?: $*"
}

# Ensure that PITDATA and CSM_PATH variables are set
[[ -v PITDATA && -n ${PITDATA} ]] || err_exit "PITDATA variable must be set"
[[ -v CSM_PATH && -n ${CSM_PATH} ]] || err_exit "CSM_PATH variable must be set"

# Make sure that expected directories exist and are actually directories
for DIR in "${PITDATA}" "${PITDATA}/prep" "${PITDATA}/configs" "${CSM_PATH}"; do

  dir_exists "${DIR}"

done

PIT_ISO_DIR="${CSM_PATH}"

# Make sure that expected PIT iso file can be found
compgen -G "${PIT_ISO_DIR}/pre-install-toolkit*.iso" > /dev/null 2>&1 || err_exit "PIT ISO file (${PIT_ISO_DIR}/pre-install-toolkit*.iso) not found"

# Make sure we can figure out the first master node
DATA_JSON="${PITDATA}/configs/data.json"
[[ -e ${DATA_JSON} ]] || err_exit "File does not exist: '${DATA_JSON}'"
[[ -f ${DATA_JSON} ]] || err_exit "Exists but is not a regular file: '${DATA_JSON}'"
[[ -s ${DATA_JSON} ]] || err_exit "File exists but is empty: '${DATA_JSON}'"

FM=$(jq -r '."Global"."meta-data"."first-master-hostname"' < "${DATA_JSON}") || err_exit "Error getting first-master-hostname from '${DATA_JSON}'"
[[ -n ${FM} ]] || err_exit "No first-master-hostname found in '${DATA_JSON}'"
echo "first-master-hostname: $FM"

# Set up passwordless SSH **to** the PIT node from the first-master node
echo "If prompted, enter the $(whoami) password for ${FM}"
ssh "${FM}" cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys || err_exit "Unable to read ${FM}:/root/.ssh/id_rsa.pub and/or write to /root/.ssh/authorized_keys"
run_cmd chmod 600 /root/.ssh/authorized_keys

# Okay, everything seems good
run_cmd mkdir -pv "${PITDATA}"/prep/logs

# Because some of these files are log files that are changing during this procedure, any call to directly
# tar them may result in the tar command failing. Thus, we first copy all of these files into a temporary
# directory, and from there we create the tar archive

TEMPDIR=$(mktemp -d) || err_exit "Command failed: mktemp -d"

echo "Copying selected files to temporary directory"

for BACKUP_TARGET in \
  /etc/conman.conf \
  /etc/dnsmasq.d \
  /etc/os-release \
  /etc/sysconfig/network \
  /opt/cray/tests/cmsdev.log \
  /opt/cray/tests/install/logs \
  /opt/cray/tests/logs \
  /root/.bash_history \
  /root/.canu \
  /root/.config/cray/logs \
  /root/csm*.{log,txt} \
  /tmp/*.log \
  /usr/share/doc/csm/install/scripts/csm_services/yapl.log \
  /var/log; do

  [[ -e ${BACKUP_TARGET} ]] || continue
  DIRNAME=$(dirname "${BACKUP_TARGET}")
  TARG_DIR="${TEMPDIR}${DIRNAME}"
  run_cmd mkdir -pv "${TARG_DIR}"
  run_cmd cp -pr "${BACKUP_TARGET}" "${TARG_DIR}"

done

echo "Creating PIT backup tarfile"

pushd "${TEMPDIR}"
run_cmd tar --sparse -czvf "${PITDATA}/prep/logs/pit-backup-$(date +%Y-%m-%d_%H-%M-%S).tgz" --remove-files *
popd
run_cmd rmdir -v "${TEMPDIR}"

echo "Copying files to ${FM}"
ssh "${FM}" \
  "mkdir -pv /metal/bootstrap &&
   rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:'${PITDATA}'/prep /metal/bootstrap/ &&
   rsync -e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -rltD -P --delete pit.nmn:'${PIT_ISO_DIR}'/pre-install-toolkit*.iso /metal/bootstrap/"

PITBackupDateTime=$(date +%Y-%m-%d_%H-%M-%S)
run_cmd tar -czvf "${PITDATA}/PitPrepIsoConfigsBackup-${PITBackupDateTime}.tgz" "${PITDATA}/prep" "${PITDATA}/configs" "${PIT_ISO_DIR}/pre-install-toolkit"*.iso
run_cmd cray artifacts create config-data \
  "PitPrepIsoConfigsBackup-${PITBackupDateTime}.tgz" \
  "${PITDATA}/PitPrepIsoConfigsBackup-${PITBackupDateTime}.tgz"
run_cmd rm -v "${PITDATA}/PitPrepIsoConfigsBackup-${PITBackupDateTime}.tgz"

# Since the installer needs to take note of this value, we will display it again here at the end of the script
echo "first-master-hostname: $FM"

echo COMPLETED
