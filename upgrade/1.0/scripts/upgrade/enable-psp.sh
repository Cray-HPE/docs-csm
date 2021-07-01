#!/usr/bin/env bash
set -e
set -o pipefail


for master in $(kubectl get nodes | grep 'master' | awk '{print $1}'); do
echo "* Enabling PodSecurityPolicy on kube-apiserver node ${master}"
  ssh "$master" "sed -i 's/--enable-admission-plugins=NodeRestriction$/--enable-admission-plugins=NodeRestriction,PodSecurityPolicy/' /etc/kubernetes/manifests/kube-apiserver.yaml"

for i in 1 2 3 4 5; do
  if kubectl describe pod -n kube-system "kube-apiserver-${master}" | grep -q 'enable-admission-plugins=NodeRestriction,PodSecurityPolicy'; then
    sleep 5
    break
  fi
  sleep 10
done

  if ! kubectl describe pod -n kube-system "kube-apiserver-${master}" | grep -q 'enable-admission-plugins=NodeRestriction,PodSecurityPolicy'; then
    echo "kube-apiserver-${master} pod did not restart on it's own. Forcing recreation."
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
