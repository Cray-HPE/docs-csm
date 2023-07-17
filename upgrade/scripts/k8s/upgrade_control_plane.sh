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
echo "Updating imageRepository and extraArgs in kubeadm-config configmap"
echo ""
kubectl get configmap kubeadm-config -n kube-system -o yaml > /tmp/kubeadm-config.yaml
cp /tmp/kubeadm-config.yaml /tmp/kubeadm-config.yaml.back
sed -i 's/imageRepository: k8s.gcr.io/imageRepository: artifactory.algol60.net\/csm-docker\/stable\/k8s.gcr.io/' /tmp/kubeadm-config.yaml
if grep -q 'dns: {}' /tmp/kubeadm-config.yaml; then
  sed -i -E "s/^([[:space:]]+)dns:.*/\1dns:\n\1  type: CoreDNS\n\1  imageRepository: artifactory.algol60.net\/csm-docker\/stable\/k8s.gcr.io\/coredns/" /tmp/kubeadm-config.yaml
fi
if ! grep -q istio-ca /tmp/kubeadm-config.yaml; then
  sed -i '/      runtime-config/a\        api-audiences: "api,istio-ca"' /tmp/kubeadm-config.yaml
fi
if ! grep -A4 '    controllerManager' /tmp/kubeadm-config.yaml | grep -q bind-address; then
  sed -i '/      flex-volume-plugin-dir/a\        bind-address: 0.0.0.0' /tmp/kubeadm-config.yaml
fi
if ! grep -A3 '    scheduler:' /tmp/kubeadm-config.yaml | grep -q bind-address; then
  sed -i 's/    scheduler: {}/    scheduler:\n      extraArgs:\n        bind-address: 0.0.0.0/' /tmp/kubeadm-config.yaml
fi

grep -q '/var/log/audit' /etc/kubernetes/manifests/kube-apiserver.yaml
manifest_auditing_enabled=$?
grep -q '^    audit-log-path:' /tmp/kubeadm-config.yaml
cm_auditing_enabled=$?

if [[ ${manifest_auditing_enabled} -eq 0 && ${cm_auditing_enabled} -ne 0 ]]; then
  echo "Updating kubeadm-config configmap with audit configuration"
  sed -i '/      runtime-config/a\        audit-log-maxbackup: "100"\n        audit-log-path: /var/log/audit/kl8s/apiserver/audit.log\n        audit-policy-file: /etc/kubernetes/audit/audit-policy.yaml' /tmp/kubeadm-config.yaml
  sed -i '/    apiServer:/a\      extraVolumes:\n      - hostPath: /var/log/audit/kl8s/apiserver\n        mountPath: /var/log/audit/kl8s/apiserver\n        name: k8s-audit-log\n        pathType: DirectoryOrCreate\n        readOnly: false\n      - hostPath: /etc/kubernetes/audit\n        mountPath: /etc/kubernetes/audit\n        name: k8s-audit\n        pathType: DirectoryOrCreate\n        readOnly: true' /tmp/kubeadm-config.yaml
fi

kubectl -n kube-system apply -f /tmp/kubeadm-config.yaml

export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)

# get version of new k8s
# note: this is running on m002 which should have newer version already
#       so we can query "next" version here
k8sVersionUpgradeTo=$(kubeadm version -o json | jq -r '.clientVersion.gitVersion')

for master in $masters; do
  echo "Upgrading kube-system pods for $master:"
  echo ""
  pdsh -b -S -w $master "kubeadm upgrade apply ${k8sVersionUpgradeTo} -y"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo ""
    echo "ERROR: The 'kubeadm upgrade apply' failed. The output from this script should be inspected"
    echo "       and addressed before moving on with the upgrade. If unable to determine the issue"
    echo "       and run this script without errors, discontinue the upgrade and contact HPE Service"
    echo "       for support."
    exit 1
  fi
  echo ""
  echo "Successfully upgraded kube-system pods for $master."
  echo ""
  echo "Upgrading apiserver-etcd-client certificate for $master:"
  echo ""
  pdsh -b -S -w $master "kubeadm certs renew apiserver-etcd-client --config /etc/kubernetes/kubeadmcfg.yaml"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo ""
    echo "ERROR: The 'kubeadm certs renew apiserver-etcd-client' failed. The output from this script should be inspected"
    echo "       and addressed before moving on with the upgrade. If unable to determine the issue"
    echo "       and run this script without errors, discontinue the upgrade and contact HPE Service"
    echo "       for support."
    exit 1
  fi
  echo ""
  echo "Successfully upgraded  apiserver-etcd-client certificate for $master."
  echo ""
done
