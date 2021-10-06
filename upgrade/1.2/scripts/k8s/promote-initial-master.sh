#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

echo "Ensuring cloud-init is healthy"
cloud-init query -a > /dev/null 2>&1
rc=$?
if [[ "$rc" -ne 0 ]]; then
  echo "cloud-init is not healthy -- re-running 'cloud-init init' to repair cached data"
  cloud-init init > /dev/null 2>&1
fi

source /srv/cray/scripts/metal/lib.sh
export KUBERNETES_VERSION="v$(cat /etc/cray/kubernetes/version)"
echo $(kubeadm init phase upload-certs --upload-certs 2>&1 | tail -1) > /etc/cray/kubernetes/certificate-key
export CERTIFICATE_KEY=$(cat /etc/cray/kubernetes/certificate-key)
export MAX_PODS_PER_NODE=$(craysys metadata get kubernetes-max-pods-per-node)
export PODS_CIDR=$(craysys metadata get kubernetes-pods-cidr)
export SERVICES_CIDR=$(craysys metadata get kubernetes-services-cidr)
envsubst < /srv/cray/resources/common/kubeadm.yaml > /etc/cray/kubernetes/kubeadm.yaml

kubeadm token create --print-join-command > /etc/cray/kubernetes/join-command 2>/dev/null
echo "$(cat /etc/cray/kubernetes/join-command) --control-plane --certificate-key $(cat /etc/cray/kubernetes/certificate-key)" > /etc/cray/kubernetes/join-command-control-plane

mkdir -p /srv/cray/scripts/kubernetes
cat > /srv/cray/scripts/kubernetes/token-certs-refresh.sh <<'EOF'
#!/bin/bash

if [[ "$1" != "skip-upload-certs" ]]; then
  kubeadm init phase upload-certs --upload-certs --config /etc/cray/kubernetes/kubeadm.yaml
fi
kubeadm token create --print-join-command > /etc/cray/kubernetes/join-command 2>/dev/null
echo "$(cat /etc/cray/kubernetes/join-command) --control-plane --certificate-key $(cat /etc/cray/kubernetes/certificate-key)" \
  > /etc/cray/kubernetes/join-command-control-plane

EOF
chmod +x /srv/cray/scripts/kubernetes/token-certs-refresh.sh
/srv/cray/scripts/kubernetes/token-certs-refresh.sh
echo "0 */1 * * * root /srv/cray/scripts/kubernetes/token-certs-refresh.sh >> /var/log/cray/cron.log 2>&1" > /etc/cron.d/cray-k8s-token-certs-refresh
