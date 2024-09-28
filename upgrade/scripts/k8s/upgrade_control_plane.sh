#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2024 Hewlett Packard Enterprise Development LP
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

workdir="$(mktemp -d)"
[ -z "${DEBUG:-}" ] && trap 'rm -fr '"${workdir}"'' ERR INT EXIT RETURN || echo "DEBUG was set in environment, $workdir will not be cleaned up."

echo "Updating imageRepository and extraArgs in kubeadm-config configmap"
kubectl get configmap kubeadm-config -n kube-system -o yaml > "${workdir}/kubeadm-config.yaml"
cp "${workdir}/kubeadm-config.yaml" "${workdir}/kubeadm-config.yaml.back"
yq4 eval -P '.data.ClusterConfiguration' "${workdir}/kubeadm-config.yaml" > "${workdir}/ClusterConfiguration.yaml"

yq4 eval -i -P '.imageRepository = "artifactory.algol60.net/csm-docker/stable/k8s.gcr.io"' "${workdir}/ClusterConfiguration.yaml"
yq4 eval -i -P '.dns = {"type": "CoreDNS", "imageRepository": "artifactory.algol60.net/csm-docker/stable/k8s.gcr.io/coredns"' "${workdir}/ClusterConfiguration.yaml"
yq4 eval -i -P '.apiServer.extraArgs.api-audiences = "api,istio-ca"' "${workdir}/ClusterConfiguration.yaml"
yq4 eval -i -P '.controllerManager.extraArgs.bind-address = "0.0.0.0"' "${workdir}/ClusterConfiguration.yaml"
yq4 eval -i -P '.scheduler.extraArgs.bind-address = "0.0.0.0"' "${workdir}/ClusterConfiguration.yaml"
yq4 eval -i -P '.scheduler.extraArgs.enable-admission-plugins = "NodeRestriction,PodSecurityPolicy"' "${workdir}/ClusterConfiguration.yaml"

manifest_auditing_enabled=0
if ! grep -q '/var/log/audit' /etc/kubernetes/manifests/kube-apiserver.yaml; then
  manifest_auditing_enabled=1
fi

cm_auditing_enabled=0
if [ "$(yq4 eval '.audit-log-path' "${workdir}/ClusterConfiguration.yaml")" != "null" ]; then
  cm_auditing_enabled=1
fi

if [[ ${manifest_auditing_enabled} -eq 1 && ${cm_auditing_enabled} -ne 1 ]]; then
  echo "Updating kubeadm-config configmap with audit configuration"
  yq4 eval -i -P '.apiServer.extraArgs.audit-log-maxbackup = "100"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.apiServer.extraArgs.audit-log-path = "/var/log/audit/kl8s/apiserver/audit.log"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.apiServer.extraArgs.audit-policy-file = "/etc/kubernetes/audit/audit-policy.yaml"' "${workdir}/ClusterConfiguration.yaml"

  if [ -z "$(yq4 eval -P '.apiServer.extraVolumes[] | select(.name=="k8s-audit")' "${workdir}/ClusterConfiguration.yaml")" ]; then
    yq4 eval -i -P '.apiServer.extraVolumes += [{"hostPath": "/etc/kubernetes/audit", "mountPath": "/etc/kubernetes/audit", "name": "k8s-audit", "pathType": "DirectoryOrCreate", "readOnly": true}]' "${workdir}/ClusterConfiguration.yaml"
  fi

  if [ -z "$(yq4 eval -P '.apiServer.extraVolumes[] | select(.name=="k8s-audit-log")' "${workdir}/ClusterConfiguration.yaml")" ]; then
    yq4 eval -i -P '.apiServer.extraVolumes += [{"hostPath": "/var/log/audit/kl8s/apiserver", "mountPath": "/var/log/audit/kl8s/apiserver", "name": "k8s-audit-log", "pathType": "DirectoryOrCreate", "readOnly": false}]' "${workdir}/ClusterConfiguration.yaml"
  fi
fi

# Merge our two YAML files together.
if IFS= read -rd '' -a cluster_configuration; then
  :
fi <<< "$(cat "${workdir}/ClusterConfiguration.yaml")"
cluster_configuration=$cluster_configuration yq4 eval '.data.ClusterConfiguration = strenv(cluster_configuration)' "${workdir}/kubeadm-config.yaml"

# Apply the new Kubernetes config.
kubectl -n kube-system apply -f "${workdir}/kubeadm-config.yaml"

export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)

# get version of new k8s
# note: this is running on m002 which should have newer version already
#       so we can query "next" version here
k8sVersionUpgradeTo=$(kubeadm version -o json | jq -r '.clientVersion.gitVersion')

for master in $masters; do
  echo "DEBUG Upgrading kube-system pods for $master:"
  echo ""
  pdsh -b -S -w $master "kubeadm upgrade apply ${k8sVersionUpgradeTo} -y"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo ""
    echo "ERROR The 'kubeadm upgrade apply' failed. The output from this script should be inspected"
    echo "ERROR and addressed before moving on with the upgrade. If unable to determine the issue"
    echo "ERROR and run this script without errors, discontinue the upgrade and contact HPE Service"
    echo "ERROR for support."
    exit 1
  fi
  echo ""
  echo "INFO Successfully upgraded kube-system pods for $master."
  echo ""
  echo "DEBUG Upgrading apiserver-etcd-client certificate for $master:"
  echo ""
  pdsh -b -S -w $master "kubeadm certs renew apiserver-etcd-client --config /etc/kubernetes/kubeadmcfg.yaml"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo ""
    echo "ERROR The 'kubeadm certs renew apiserver-etcd-client' failed. The output from this script should be inspected"
    echo "ERROR and addressed before moving on with the upgrade. If unable to determine the issue"
    echo "ERROR and run this script without errors, discontinue the upgrade and contact HPE Service"
    echo "ERROR for support."
    exit 1
  fi
  echo ""
  echo "INFO Successfully upgraded  apiserver-etcd-client certificate for $master."
  echo ""
done
