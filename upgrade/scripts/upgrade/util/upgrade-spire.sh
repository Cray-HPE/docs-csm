#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

prefix=/var/lib/spire
conf="${prefix}/conf"
datadir="${prefix}/data"
svidkey="${datadir}/svid.key"
bundleder="${datadir}/bundle.der"
agentsvidder="${datadir}/agent_svid.der"
jointoken="${conf}/join_token"

function sshnh() {
  /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@"
}

for node in $(kubectl get nodes -o name | cut -d"/" -f2) $(ceph node ls | jq -r '.[] | keys[]' | sort -u); do
  echo "$node: Stopping spire-agent"
  sshnh "$node" systemctl stop spire-agent
  sshnh "$node" rm "${svidkey}" "${bundleder}" "${agentsvidder}" "${jointoken}" || true

  sshnh "$node" zypper install -y spire-agent

  echo "$node: Starting spire-agent"
  sshnh "$node" systemctl start spire-agent
done

echo "Uninstalling spire helm chart"
helm uninstall -n spire spire
echo "Uninstalling spire PVCs"
kubectl delete -n spire pvc spire-data-spire-server-0 spire-data-spire-server-1 spire-data-spire-server-2

RETRY=0
MAX_RETRIES=30
RETRY_SECONDS=5

until [ "$(kubectl get pods -n spire --no-headers | wc -l)" -ne 0 ]; do
  if [[ "$RETRY" -lt "$MAX_RETRIES" ]]; then
    RETRY="$((RETRY + 1))"
    echo "spire-server is not ready. Will retry after $RETRY_SECONDS seconds. ($RETRY/$MAX_RETRIES)"
  else
    echo "spire-server did not start after $(echo "$RETRY_SECONDS" \* "$MAX_RETRIES" | bc) seconds."
    exit 1
  fi
  sleep "$RETRY_SECONDS"
done

echo "Installing new spire helm chart"
BUILDDIR="/tmp/build"
mkdir -p "$BUILDDIR"
kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d >"${BUILDDIR}/customizations.yaml"
manifestgen -i "${CSM_ARTI_DIR}/manifests/sysmgmt.yaml" -c "${BUILDDIR}/customizations.yaml" -o "${BUILDDIR}/spireupgrade.yaml"
charts="$(yq r $BUILDDIR/spireupgrade.yaml 'spec.charts[*].name')"
for chart in $charts; do
  if [[ $chart != "spire" ]]; then
    yq d -i $BUILDDIR/spireupgrade.yaml "spec.charts.(name==$chart)"
  fi
done

yq w -i $BUILDDIR/spireupgrade.yaml "metadata.name" "spireupgrade"
yq d -i $BUILDDIR/spireupgrade.yaml "spec.sources"

loftsman ship --charts-path "${CSM_ARTI_DIR}/helm/" --manifest-path $BUILDDIR/spireupgrade.yaml

RETRY=0
MAX_RETRIES=30
RETRY_SECONDS=10

until kubectl exec -itn spire spire-server-0 --container spire-server -- ./bin/spire-server healthcheck | grep -q 'Server is healthy'; do
  if [[ "$RETRY" -lt "$MAX_RETRIES" ]]; then
    RETRY="$((RETRY + 1))"
    echo "spire-server is not ready. Will retry after $RETRY_SECONDS seconds. ($RETRY/$MAX_RETRIES)"
  else
    echo "spire-server did not start after $(echo "$RETRY_SECONDS" \* "$MAX_RETRIES" | bc) seconds."
    exit 1
  fi
  sleep "$RETRY_SECONDS"
done

echo "Joining storage nodes to spire"
/opt/cray/platform-utils/spire/fix-spire-on-storage.sh
