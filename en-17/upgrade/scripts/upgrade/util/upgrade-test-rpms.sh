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

# Usage: upgrade-test-rpms.sh [--local]
# If --local is not specified, upgrade the test RPMs on all NCNs
# If --local is specified, upgrade the test RPMs just on the system where the script is being executed

RPM_LIST="hpe-csm-goss-package csm-testing goss-servers craycli cray-cmstools-crayctldeploy"

set -euo pipefail
if [[ $# -eq 0 ]]; then

  ncns=$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | tr -t '\n' ',')

  echo "Installing updated versions of RPMs on all NCNs: ${RPM_LIST}"
  pdsh -S -b -w ${ncns} "zypper install -y --allow-vendor-change ${RPM_LIST}"

  echo "Enabling and restarting goss-servers"
  pdsh -S -b -w ${ncns} 'systemctl enable goss-servers && systemctl restart goss-servers'

  echo "Waiting for goss-servers service to start"
  pdsh -S -b -w ${ncns} 'for X in 1 2 3 4 5; do [[ $X -gt 1 ]] && sleep 3; systemctl is-active goss-servers && exit 0; done; exit 1'

elif [[ $# -eq 1 && $1 == --local ]]; then

  echo "Installing updated versions of RPMs: ${RPM_LIST}"
  zypper install -y --allow-vendor-change ${RPM_LIST}

  echo "Enabling and restarting goss-servers"
  systemctl enable goss-servers && systemctl restart goss-servers

  echo "Waiting for goss-servers service to start"
  started=n
  for X in 1 2 3 4 5; do
    [[ $X -gt 1 ]] && sleep 3
    systemctl is-active goss-servers && started=y && break
  done
  [[ ${started} == y ]] || exit 1

else

  echo "usage: upgrade-test-rpms.sh [--local]" >&2
  echo >&2
  echo "ERROR: Invalid arguments" >&2
  exit 1

fi

echo "SUCCESS"
