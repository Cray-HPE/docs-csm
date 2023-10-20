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

# This script is a replacement for the script of the same name in the lib
# directory of the CSM tarballs and repository.

# This script is run twice during CSM installs. It does different things depending
# on when it is run.

# It is run the first time from the PIT node, after the other NCNs have been deployed. In this
# case, it does the following:
# 1) Finds the latest versions of select RPMs in the expanded CSM tarball
# 2) Copies the RPMs into a prep subdirectory
# 3) Installs the RPMs onto the other NCNs and the PIT node
#
# It is run for the second time from ncn-m001, after PIT redeploy. In this case, it does
# the following:
# 1) Installs the RPMs in the prep subdirectory (populated from the first time the script was
#    executed) onto ncn-m001
# 2) Enables and restarts goss-servers on ncn-m001

# Globally disable warning about globbing and word splitting
# shellcheck disable=SC2086

set -e

function find_latest_rpm {
  # $1 - RPM name prefix (e.g. csm-testing, goss-servers, etc)
  local name vpattern rpm_regex1 rpm_regex2 filepath
  name="$1"
  vpattern="[0-9][0-9]*[.][0-9][0-9]*[.][0-9][0-9]*"                # The first part of the version will be three
                                                                    # .-separated numbers
                                                                    # After the name and version, there are two
                                                                    # ways our RPM may be named:
  rpm_regex1="${name}-${vpattern}-[^/]*[.]rpm"                      # It could have a -, followed by characters we
                                                                    # do not care about, ending in .rpm
  rpm_regex2="${name}-${vpattern}[.]rpm"                            # Or it could just have .rpm after the name
                                                                    # and version
  filepath=$(find "$RPMDIR" -type f -name \*.rpm |                  # List all RPM files in the rpm directory
             grep -E "/(${rpm_regex1}|${rpm_regex2})$" |            # Select only names fitting one of our patterns
             sed -e "s#^${RPMDIR}.*/\(${rpm_regex1}\)\$#\1 \0#" \
                 -e "s#^${RPMDIR}.*/\(${rpm_regex2}\)\$#\1 \0#" |   # Change each line so first it shows just the
                                                                    # RPM filename, followed by a blank space,
                                                                    # followed by the original full path and filename
             sort -k1V |                                            # Sort the first field (the RPM filename without
                                                                    # path) by version
             tail -1 |                                              # Choose the last one listed (the one with the
                                                                    # highest version)
             sed 's/^[^ ]* //')                                     # Change the line, removing the RPM filename and
                                                                    # space, leaving only the full path and filename
  if [[ -z ${filepath} ]]; then
    echo "The ${name} RPM was not found at the expected location. Ensure this RPM exists under the '$RPMDIR' directory" >&2
    return 1
  fi
  echo "${filepath}"
  return 0
}

function paths_to_basenames() {
  local rpm_name_list
  while [[ $# -gt 0 ]]; do
    rpm_name_list="${rpm_name_list} ${1##*/}"
    shift
  done
  echo "${rpm_name_list}"
  return 0
}

function run_on_pit {
  if [[ -z ${CSM_RELEASE} ]]; then
    echo "Please set and export \$CSM_RELEASE and try again" >&2
    exit 1
  fi

  local MTOKEN STOKEN WTOKEN PREPDIR STORAGE_NCNS K8S_NCNS PREP_RPM_DIR ncn
  local STORAGE_RPM_PATHS K8S_RPM_PATHS STORAGE_RPM_BASENAMES K8S_RPM_BASENAMES
  local HPE_GOSS_RPM CMSTOOLS_RPM CANU_RPM CSM_TESTING_RPM GOSS_SERVERS_RPM PLATFORM_UTILS_RPM IUF_CLI_RPM

  MTOKEN='ncn-m\w+'
  STOKEN='ncn-s\w+'
  WTOKEN='ncn-w\w+'

  PITDATA=${PITDATA:-/var/www/ephemeral}
  CSM_DIRNAME=${CSM_DIRNAME:-${PITDATA}}
  CSM_PATH=${CSM_PATH:-${CSM_DIRNAME}/csm-${CSM_RELEASE}}
  RPMDIR=${RPMDIR:-${CSM_PATH}/rpm}
  PREPDIR="${PITDATA}/prep"

  if [[ ! -d ${CSM_PATH} ]]; then
    echo "The csm-${CSM_RELEASE} directory was not found at the expected location. Please set \$CSM_DIRNAME to the absolute path" >&2
    echo "containing the csm-$CSM_RELEASE directory" >&2
    exit 1
  elif [[ ! -d ${RPMDIR} ]]; then
    echo "The 'rpm' directory was not found in the base directory of the expanded CSM tarball: ${CSM_PATH}" >&2
    echo "Please set \$CSM_PATH to the path of the base directory of the expanded CSM tarball, and verify that it contains the 'rpm' directory." >&2
    exit 1
  elif [[ ! -d ${PREPDIR} ]]; then
    echo "The 'prep' directory was not found in its expected location: '${PREPDIR}'" >&2
    exit 1
  fi

  STORAGE_NCNS=$(grep -oE "${STOKEN}" /etc/dnsmasq.d/statics.conf | grep -v m001 | sort -u)
  K8S_NCNS=$(grep -oE "(${MTOKEN}|${WTOKEN})" /etc/dnsmasq.d/statics.conf | grep -v m001 | sort -u)

  CANU_RPM=$(find_latest_rpm canu)
  CSM_TESTING_RPM=$(find_latest_rpm csm-testing)
  GOSS_SERVERS_RPM=$(find_latest_rpm goss-servers)
  IUF_CLI_RPM=$(find_latest_rpm iuf-cli)
  PLATFORM_UTILS_RPM=$(find_latest_rpm platform-utils)
  HPE_GOSS_RPM=$(find_latest_rpm hpe-csm-goss-package)
  CMSTOOLS_RPM=$(find_latest_rpm cray-cmstools-crayctldeploy)

  # cmstools RPM is not installed on storage nodes
  STORAGE_RPM_PATHS="${HPE_GOSS_RPM} ${CANU_RPM} ${CSM_TESTING_RPM} ${GOSS_SERVERS_RPM} ${IUF_CLI_RPM} ${PLATFORM_UTILS_RPM}"
  K8S_RPM_PATHS="${STORAGE_RPM_PATHS} ${CMSTOOLS_RPM}"

  STORAGE_RPM_BASENAMES=$(paths_to_basenames ${STORAGE_RPM_PATHS})
  K8S_RPM_BASENAMES=$(paths_to_basenames ${K8S_RPM_PATHS})

  # Create prep subdirectory
  PREP_RPM_DIR="${PREPDIR}/rpms"
  mkdir -v "${PREP_RPM_DIR}"

  # Copy test RPMs into it
  cp -v ${K8S_RPM_PATHS} "${PREP_RPM_DIR}"

  # Install the RPMs onto the other NCNs
  for ncn in ${STORAGE_NCNS}; do
    echo "Installing RPMs on ${ncn}"
    scp ${STORAGE_RPM_PATHS} ${ncn}:/tmp/
    # shellcheck disable=SC2029
    ssh ${ncn} "cd /tmp && zypper --non-interactive in ${STORAGE_RPM_BASENAMES} && systemctl enable goss-servers && systemctl restart goss-servers && systemctl daemon-reload && echo systemctl daemon-reload has been run && rm -f ${STORAGE_RPM_BASENAMES}"
  done

  for ncn in ${K8S_NCNS}; do
    echo "Installing RPMs on ${ncn}"
    scp ${K8S_RPM_PATHS} ${ncn}:/tmp/
    # shellcheck disable=SC2029
    ssh ${ncn} "cd /tmp && zypper --non-interactive in ${K8S_RPM_BASENAMES} && systemctl enable goss-servers && systemctl restart goss-servers && systemctl daemon-reload && echo systemctl daemon-reload has been run && rm -f ${K8S_RPM_BASENAMES}"
  done

  # The RPMs should have been installed on the PIT at the same time csi was installed. Trust, but verify:
  echo "Installing RPMs on PIT if needed"
  rpm -q canu || zypper install -y canu
  rpm -q hpe-csm-goss-package || zypper install -y ${HPE_GOSS_RPM}
  rpm -q csm-testing || zypper install -y ${CSM_TESTING_RPM}
  rpm -q goss-servers || (zypper install -y ${GOSS_SERVERS_RPM} && systemctl enable goss-servers && systemctl restart goss-servers)
  rpm -q platform-utils || zypper install -y ${PLATFORM_UTILS_RPM}
  rpm -q iuf-cli || zypper install -y ${IUF_CLI_RPM}
  systemctl daemon-reload && echo "systemctl daemon-reload has been run"
}

function run_on_m001 {
  local PREP_RPM_DIR

  PREP_RPM_DIR=/metal/bootstrap/prep/rpms
  if [[ ! -d ${PREP_RPM_DIR} ]]; then
    echo "ERROR: Directory does not exist: '${PREP_RPM_DIR}'"
    exit 1
  fi

  echo "Installing RPMs from '${PREP_RPM_DIR}':"
  rpm -Uvh --force "${PREP_RPM_DIR}/"*.rpm

  echo "Enabling goss-servers"
  systemctl enable goss-servers

  echo "Restarting goss-servers"
  systemctl restart goss-servers

  echo "Reloading daemons"
  systemctl daemon-reload && echo "systemctl daemon-reload has been run"
}

if [[ -f /etc/pit-release ]]; then
  run_on_pit
elif [[ ${HOSTNAME} == ncn-m001 ]]; then
  run_on_m001
else
  echo "ERROR: This script should only be run from the PIT node or ncn-m001"
  exit 1
fi

echo PASSED
