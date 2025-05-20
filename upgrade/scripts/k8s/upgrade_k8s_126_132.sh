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

# We should be at K8s 1.26 by this point, so upgrade control planes to 1.29

function prefix() {
  echo -n "$(date --iso-8601=seconds) $(basename "$0")"
}

function fix_sysconfig() {
  # fix_sysconfig ncn-m002
  NODE_IP=$(ssh $1 "dig +short \$(hostname).nmn | grep -v -E '^;;'")

  ssh "$1" "cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS=\"--node-ip ${NODE_IP}\"
EOF"
}

echo "$(prefix) Beginning Kubernetes 1.25 to 1.27 upgrade."

masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)
workers=$(grep -oP 'ncn-w\d+' /etc/hosts | sort -u)

versions=("1.27.16" "1.28.15" "1.29.15")

# TODO(fluckdav): make this idempotent so you can restart it at any version.
for version in "${versions[@]}"; do
  for host in "${masters}"; do
	echo "$(prefix) Installing [kubeadm-${version}] on [${host}]."
	ssh "${host}" zypper --non-interactive install "kubeadm-${version}"

	ssh "${host}" kubeadm version

	if [[ "${host}" == "ncn-m001" ]]; then
	  # Only the first control plane node needs an upgrade plan and upgrade apply.
	  echo "$(prefix) Running kubeadm upgrade plan on [${host}]."
	  ssh "${host}" kubeadm upgrade plan

	  echo "$(prefix) Running kubeadm upgrade apply v${version} on [${host}]."
	  ssh "${host}" kubeadm upgrade apply -y "v${version}" --force
	else
	  # Subsequent control planes can be upgraded this way.
	  echo "$(prefix) Running kubeadm upgrade node on [${host}]."
	  ssh "${host}" kubeadm upgrade node
	fi
  done
done

# Upgrade kubelet on master nodes for K8s 1.29.

# First, update kubelet-config configmap to add containerRuntimeEndpoint. This
# is necessary because --container-runtime-endpoint was deprecated as a kubelet
# command line argument in K8s 1.27.
kubectl get configmap kubelet-config -n kube-system -o yaml > kubelet-config.yaml
yq4 eval -P '.data.kubelet' "kubelet-config.yaml" > kubelet-config-kubelet.yaml
yq4 eval -i -P '.containerRuntimeEndpoint = "unix:///run/containerd/containerd.sock"' kubelet-config-kubelet.yaml

# Merge our kubelet config back into the kubelet-config manifest.
if IFS= read -rd '' -a kubelet_config; then
  :
fi <<< "$(cat "kubelet-config-kubelet.yaml")"
kubelet_config=$kubelet_config yq4 eval -i '.data.kubelet = strenv(kubelet_config)' "kubelet-config.yaml"

# Update the kubelet-config configmap.
kubectl -n kube-system apply -f "${workdir}/kubelet-config.yaml"

echo "$(prefix) Upgrading kubelet on master nodes."

version="1.29.15"
for host in "${masters}"; do
  # Drain the node, ignoring daemonsets and deleting emptydir data.
  echo "$(prefix) Draining node: [${host}]."
  kubectl drain "${host}" --ignore-daemonsets --delete-emptydir-data

  # Update /etc/sysconfig/kubelet to remove deprecated flags. Do this by
  # reconstructing the arguments from scratch.
  fix_sysconfig "${host}"

  # Update kubelet and kubectl. We don't need to update these one at a
  # time; we can skip up to three versions at a time.
  echo "$(prefix) Installing [kubelet-${version}] and [kubectl-${version}] on [${host}]."
  ssh "${host}" zypper --non-interactive install "kubelet-${version}" "kubectl-${version}"

  # Reload daemons and restart kubelet.
  ssh "${host}" systemctl daemon-reload
  ssh "${host}" systemctl restart kubelet

  # Mark the node ready for scheduling.
  echo "$(prefix) Uncordoning node: [${host}]."
  kubectl uncordon "${host}"
done

echo "$(prefix) Upgrading kubelet on worker nodes."

for host in "${workers}"; do
  echo "$(prefix) Installing [kubeadm-${version}] on [${host}]."
  ssh "${host}" zypper --non-interactive install "kubeadm-${version}"  
done
