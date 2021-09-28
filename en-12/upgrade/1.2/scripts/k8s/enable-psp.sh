#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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
set -o pipefail


for master in $(kubectl get nodes | grep 'master' | awk '{print $1}'); do
echo "* Enabling PodSecurityPolicy on kube-apiserver node ${master}"
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$master" "sed -i 's/--enable-admission-plugins=NodeRestriction$/--enable-admission-plugins=NodeRestriction,PodSecurityPolicy/' /etc/kubernetes/manifests/kube-apiserver.yaml"

for i in 1 2 3 4 5; do
  if kubectl describe pod -n kube-system "kube-apiserver-${master}" | grep -q 'enable-admission-plugins=NodeRestriction,PodSecurityPolicy'; then
    sleep 5
    break
  fi
  sleep 10
done

  if ! kubectl describe pod -n kube-system "kube-apiserver-${master}" | grep -q 'enable-admission-plugins=NodeRestriction,PodSecurityPolicy'; then
    echo "kube-apiserver-${master} pod did not restart on its own. Forcing recreation."
    echo kubectl rm pod -n kube-system "kube-apiserver-${master}"
    sleep 10
  fi
done

echo "* Validating kube-apiserver pods all have PodSecurityPolicy enabled"

fail=0
for master in $(kubectl get nodes | grep 'master' | awk '{print $1}'); do
  if ! kubectl describe pod -n kube-system "kube-apiserver-${master}" | grep -q 'enable-admission-plugins=NodeRestriction,PodSecurityPolicy'; then
    echo "PodSecurityPolicy failed to enable on kube-apiserver-${master}"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PodSecurityPolicy has been successfully enabled."
else
  echo "One or more kube-apiservers failed to enable PodSecurityPolicy. Please manually fix the failed servers before continuing the patch."
fi
