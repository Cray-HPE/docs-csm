#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

master=$1

export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
echo "Updating service account signing key and issuer kube-api on $master:"
pdsh -b -S -w $master "sed -i '/service-account-key-file/a\    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key\n    - --service-account-issuer=https://kubernetes.default.svc.cluster.local' /etc/kubernetes/manifests/kube-apiserver.yaml"
rc=$?
if [ "$rc" -ne 0 ]; then
  echo ""
  echo "ERROR: Updating kube-apiserver manifest failed. The output from this script should be inspected"
  echo "       and addressed before moving on with the upgrade. If unable to determine the issue"
  echo "       and run this script without errors, discontinue the upgrade and contact HPE Service"
  echo "       for support."
  exit 1
fi
echo "Sleeping for one minute to let kube-apiserver restart on $master"
sleep 60
