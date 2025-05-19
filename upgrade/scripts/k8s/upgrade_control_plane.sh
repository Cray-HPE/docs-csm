#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2025 Hewlett Packard Enterprise Development LP
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

if [ "$(yq4 eval '.dns' "${workdir}/ClusterConfiguration.yaml")" = "null" ] || [ "$(yq4 eval '.dns' "${workdir}/ClusterConfiguration.yaml")" == "{}" ]; then
  yq4 eval -i -P '.dns = {"type": "CoreDNS", "imageRepository": "artifactory.algol60.net/csm-docker/stable/k8s.gcr.io/coredns"}' "${workdir}/ClusterConfiguration.yaml"
fi
if [ "$(yq4 eval '.imageRepository' "${workdir}/ClusterConfiguration.yaml")" = 'k8s.gcr.io' ]; then
  yq4 eval -i -P '.imageRepository = "artifactory.algol60.net/csm-docker/stable/k8s.gcr.io"' "${workdir}/ClusterConfiguration.yaml"
fi

# What version of kubeadm are we working with?
version_v1beta4=0
if [ "$(yq4 eval '.apiVersion' "${workdir}/ClusterConfiguration.yaml")" = 'kubeadm.k8s.io/v1beta4' ]; then
  version_v1beta4=1
  yq4 eval -i -P '.apiServer.extraArgs.[] |= select(.name == "api-audiences").value = "api,istio-ca"' "${workdir}/ClusterConfiguration.yaml"
  # The following currently don't exist in kubeadm apiVersion kubeadm.k8s.io/v1beta4, but attempt to modify just in case
  yq4 eval -i -P '.apiServer.extraArgs.[] |= select(.name == "enable-admission-plugins").value = "NodeRestriction"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.controllerManager.extraArgs.[] |= select(.name == "bind-address").value = "0.0.0.0"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.scheduler.extraArgs.[] |= select(.name == "bind-address").value = "0.0.0.0"' "${workdir}/ClusterConfiguration.yaml"
  # Set caCertificateValidityPeriod to 87600h (10 years) and certificateValidityPeriod to 26280h (3 years)
  yq4 eval -i -P '.caCertificateValidityPeriod = "87600h"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.certificateValidityPeriod = "26280h"' "${workdir}/ClusterConfiguration.yaml"
else
  yq4 eval -i -P '.apiServer.extraArgs.api-audiences = "api,istio-ca"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.apiServer.extraArgs.enable-admission-plugins = "NodeRestriction"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.controllerManager.extraArgs.bind-address = "0.0.0.0"' "${workdir}/ClusterConfiguration.yaml"
  yq4 eval -i -P '.scheduler.extraArgs.bind-address = "0.0.0.0"' "${workdir}/ClusterConfiguration.yaml"
fi

# Necessary for K8s 1.26.
echo "Removing udpIdleTimeout from kube-proxy configmap."

kubectl get configmap kube-proxy -n kube-system -o yaml > kube-proxy.yaml
yq4 eval -P '.data."config.conf"' "kube-proxy.yaml" > kube-proxy-config.yaml
yq4 eval -i -P 'del(.udpIdleTimeout)' kube-proxy-config.yaml

# Merge our kube-proxy config.conf back into the kube-proxy manifest.
if IFS= read -rd '' -a kube_proxy; then
  :
fi <<< "$(cat "kube-proxy-config.yaml")"
kube_proxy=$kube_proxy yq4 eval -i '.data."config.conf" = strenv(kube_proxy)' "kube-proxy.yaml"

# Update the kube-proxy configmap.
kubectl -n kube-system apply -f "${workdir}/kube-proxy.yaml"

manifest_auditing_enabled=0
if ! grep -q '/var/log/audit' /etc/kubernetes/manifests/kube-apiserver.yaml; then
  manifest_auditing_enabled=1
fi

cm_auditing_enabled=0
if [ ${version_v1beta4} -eq 1 ]; then
  if [ "$(yq4 eval -P '.extraArgs[] | select(.name=="audit-log-path")' "${workdir}/ClusterConfiguration.yaml")" ]; then
    cm_auditing_enabled=1
  fi
else
  if [ "$(yq4 eval '.extraArgs.audit-log-path' "${workdir}/ClusterConfiguration.yaml")" != "null" ]; then
    cm_auditing_enabled=1
  fi
fi

if [ ${manifest_auditing_enabled} -eq 1 ] && [ ${cm_auditing_enabled} -eq 1 ]; then
  echo "Updating kubeadm-config configmap with audit configuration"
  if [ ${version_v1beta4} -eq 1 ]; then
    yq4 eval -i -P '.apiServer.extraArgs += [{"name": "audit-log-maxbackup", "value": "100"}]' "${workdir}/ClusterConfiguration.yaml"
    yq4 eval -i -P '.apiServer.extraArgs += [{"name": "audit-log-path", "value": "/var/log/audit/kl8s/apiserver/audit.log"}]' "${workdir}/ClusterConfiguration.yaml"
    yq4 eval -i -P '.apiServer.extraArgs += [{"name": "audit-policy-file", "value": "/etc/kubernetes/audit/audit-policy.yaml"}]' "${workdir}/ClusterConfiguration.yaml"
  else
    yq4 eval -i -P '.apiServer.extraArgs.audit-log-maxbackup = "100"' "${workdir}/ClusterConfiguration.yaml"
    yq4 eval -i -P '.apiServer.extraArgs.audit-log-path = "/var/log/audit/kl8s/apiserver/audit.log"' "${workdir}/ClusterConfiguration.yaml"
    yq4 eval -i -P '.apiServer.extraArgs.audit-policy-file = "/etc/kubernetes/audit/audit-policy.yaml"' "${workdir}/ClusterConfiguration.yaml"
  fi

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
cluster_configuration=$cluster_configuration yq4 eval -i '.data.ClusterConfiguration = strenv(cluster_configuration)' "${workdir}/kubeadm-config.yaml"

# Apply the new Kubernetes config.
kubectl -n kube-system apply -f "${workdir}/kubeadm-config.yaml"

export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)

# get version of new k8s
# note: this is running on m002 which should have newer version already
#       so we can query "next" version here
k8s_version_upgrade_to=$(kubeadm version -o json | jq -r '.clientVersion.gitVersion')

for master in $masters; do
  echo "DEBUG Upgrading kube-system pods for $master:"
  echo ""
  pdsh -b -S -w $master "kubeadm upgrade apply ${k8s_version_upgrade_to} -y"
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
  echo "INFO Successfully upgraded apiserver-etcd-client certificate for $master."
  echo ""
done

# Do we have additional charts to deploy after the K8s upgrade?
# Source /etc/cray/upgrade/csm/myenv to get CSM_ARTI_DIR
source /etc/cray/upgrade/csm/myenv
k8s_version=$(kubeadm version -o json | jq -r '.clientVersion.gitVersion' | grep -o "v1.[^.]*")
k8s_minor_version=$(echo ${k8s_version} | cut -d "." -f2)

# Change working directory to CSM_ARTI_DIR
pushd ${CSM_ARTI_DIR}

# Deploy charts in given manifest
function deploy() {
  # Loftsman may not be able to connect to $NEXUS_URL due to certificate
  # trust issues, so use --charts-path instead of --charts-repo.
  loftsman ship --charts-path "${CSM_ARTI_DIR}/helm" --manifest-path "$1"
}

# Undeploy the chart if it exists on the system.
# Use this if a chart has been removed from a manifest and needs
# to be removed from the system as part of an upgrade.
function undeploy() {
  # If the chart is missing (rc==1) just return success.
  helm status "$@" || return 0
  # Remove the chart.
  helm uninstall "$@" --keep-history
}

# Undeploy services if they exist
if [ ${k8s_minor_version} -gt 24 ]; then
  # cray-psp is removed in CSM 1.7 with upgrade to K8s >= 1.25, if it exists
  undeploy -n services cray-psp
fi

# If there are post-upgrade-*-<k8s_version>.yaml files, deploy charts in those files.
manifests_dir="${CSM_ARTI_DIR}/manifests"
# Temporarily set k8s_version to v1.25 to deploy 1.25 manifests, because we're
# trying to jump directly to 1.26, but we still need the 1.25 manifests to be
# deployed.
k8s_version='v1.25' # TODO(fluckdav): Write some logic for this.

find "${manifests_dir}/" -name "post-upgrade-*-${k8s_version}.yaml" | sort | while read -r manifest; do
  echo "INFO Deploying ${manifest} ..."
  deploy "${manifest}"
done

# Return to previous working directory
popd

