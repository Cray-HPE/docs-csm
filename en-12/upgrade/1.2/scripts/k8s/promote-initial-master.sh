#!/bin/bash
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

export KUBECONFIG=/etc/kubernetes/admin.conf

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

cp /srv/cray/resources/common/cronjob_kicker.py /usr/bin/cronjob_kicker.py
chmod +x /usr/bin/cronjob_kicker.py
echo "0 */2 * * * root KUBECONFIG=/etc/kubernetes/admin.conf /usr/bin/cronjob_kicker.py >> /var/log/cray/cron.log 2>&1" > /etc/cron.d/cray-k8s-cronjob-kicker