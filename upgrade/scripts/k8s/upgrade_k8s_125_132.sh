#!/bin/bash
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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

# We should be at K8s 1.25 by this point, so upgrade control planes to 1.27.

function prefix(){
  echo -n "$(date --iso-8601=seconds) $(basename "$0")"
}

echo "$(prefix) Beginning Kubernetes 1.25 to 1.27 upgrade."

masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)
workers=$(grep -oP 'ncn-w\d+' /etc/hosts | sort -u)

versions=("1.26.15" "1.27.16")

# TODO(fluckdav): make this idempotent so you can restart it at any version.
for host in "${masters}"; do
  for version in "${versions[@]}"; do
	echo "$(prefix) Installing [kubeadm-${version}] on [${host}]."
	ssh "${host}" zypper --non-interactive install "kubeadm-${version}"

	ssh "${host}" kubeadm version

	if [[ "${host}" == "ncn-m001" ]]; then
	  # Only the first control plane node needs an upgrade plan and upgrade apply.
	  echo "$(prefix) Running kubeadm upgrade plan on [${host}]."
	  ssh "${host}" kubeadm upgrade plan

	  echo "$(prefix) Running kubeadm upgrade apply v${version} on [${host}]."
	  ssh "${host}" kubeadm upgrade apply "v${version}"
	else
	  # Subsequent control planes can be upgraded this way.
	  echo "$(prefix) Running kubeadm upgrade node on [${host}]."
	  ssh "${host}" kubeadm upgrade node
	fi
  done

  # Drain the node, ignoring daemonsets and deleting emptydir data.
  kubectl drain "${host}" --ignore-daemonsets --delete-emptydir-data

  # Update kubelet and kubectl. We don't need to update these one at a
  # time; we can skip up to three versions at a time.
  version="${versions[-1]}"
  ssh "${host}" zypper --non-interactive install "kubelet-${version}" "kubectl-${version}"

  # Reload daemons and restart kubelet.
  ssh "${host}" systemctl daemon-reload
  ssh "${host}" systemctl restart kubelet

  # Mark the node ready for scheduling.
  kubectl uncordon "${host}"
done
