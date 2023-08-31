#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

target_ncn="${1:-$(hostname)}"

while true; do
  missing_rpms=""
  for rpm in csm-testing goss-servers; do
    if ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $target_ncn -t "rpm -qa | grep -q $rpm" 2> /dev/null; then
      missing_rpms="$missing_rpms $rpm"
    fi
  done
  if ! test -z "$missing_rpms"; then
    echo "Waiting for the following rpm(s) to installed via cloud-init on $target_ncn: ${missing_rpms}..."
    sleep 5
  else
    echo "csm-testing and goss-servers rpms verified on $target_ncn"
    break
  fi
done
