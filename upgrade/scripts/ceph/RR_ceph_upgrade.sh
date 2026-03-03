#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2026 Hewlett Packard Enterprise Development LP
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

# This script is introduced to fix CAST-39537 and is to be used only if Rack Resiliency(RR) is enabled. It performs four main functions:
# 1. Waits for any ongoing Ceph orchestrator operations to complete before syncing the updated monitor configuration to other nodes and kubernetes cluster.
# 2. Updates the monitors list in all Ceph CSI ConfigMaps across relevant namespaces using the current Ceph monitor map.
# 3. Copies the updated `/etc/ceph/ceph.conf` file from the storage node to all Kubernetes master nodes.
# 4. Updates the customizations.yaml file and loftsman-cray-sysmgmt-health ConfigMap with the new monitor information.

# Note -  This script should be executed only after first storage node rollout on the first Ceph node(ncn-s001) where kubernetes access is available.

set -euo pipefail

# ──────────────────────────────
# Function: wait_for_ceph_orch
# Description: Waits for Ceph orchestrator operations to complete.
#              Checks that all daemons are running, MONs are in quorum,
#              and cluster health does not report monitor-related issues.
# ──────────────────────────────
wait_for_ceph_orch() {
  local timeout=600 # 10 minutes max
  local interval=15
  local elapsed=0

  echo "Waiting for ceph orchestrator operations to complete..."

  while true; do
    # Check for any non-running ceph daemons
    if ceph orch ps | grep -E 'starting|stopped|error|unknown' > /dev/null; then
      echo "Daemons still transitioning..."

    # Ensure all MONs are in quorum
    elif ! ceph quorum_status --format json | grep -q '"quorum_names"'; then
      echo "Waiting for MON quorum..."

    # Ensure cluster is not reporting monitor-related health issues
    elif ceph health | grep -qE 'MON_DOWN|MON_LEFT_QUORUM|MON_JOINED_QUORUM'; then
      echo "Waiting for monitor health to stabilize..."

    else
      echo "Ceph orchestrator operations completed successfully."
      break
    fi

    sleep "$interval"
    elapsed=$((elapsed + interval))

    if [[ $elapsed -ge $timeout ]]; then
      echo "Timed out waiting for ceph orchestrator to finish."
      return 1
    fi
  done

  return 0
}

# ──────────────────────────────
# Function: update_ceph_csi_configmaps
# Description: Updates the monitors list in all Ceph CSI ConfigMaps
#              across relevant namespaces using the current Ceph monitor map.
# ──────────────────────────────
update_ceph_csi_configmaps() {
  local NEW_MONITORS
  NEW_MONITORS=$(ceph mon dump -f json | jq -c '[.mons[].public_addr | split("/")[0]]')
  # Namespaces ceph-rbd, ceph-cephfs, default, services contains ceph-csi-config configmap
  for ns in ceph-rbd ceph-cephfs default services; do
    if kubectl -n "$ns" get cm ceph-csi-config > /dev/null 2>&1; then
      echo "Updating ceph-csi-config in namespace $ns"
      kubectl -n "$ns" get cm ceph-csi-config -o json \
        | jq --argjson mons "$NEW_MONITORS" '
                .data["config.json"] |= (
                    fromjson
                    | map(.monitors = $mons)
                    | tojson
                )
            ' \
        | kubectl apply -f -
    else
      echo "Skipping $ns (ceph-csi-config not found)"
    fi
  done

  # Handle ceph-etc configmap in backups namespace separately
  if kubectl -n backups get cm ceph-etc > /dev/null 2>&1; then
    echo "Updating ceph-etc in namespace backups"
    kubectl -n backups get cm ceph-etc -o json \
      | jq --argjson mons "$NEW_MONITORS" '
            .data["config.json"] |= (
                fromjson
                | map(.monitors = $mons)
                | tojson
            )
        ' \
      | kubectl apply -f -
  else
    echo "Skipping backups (ceph-etc not found)"
  fi
}

# ──────────────────────────────
# Function: update_customizations
# Description: Updates the Ceph monitor addresses in the loftsman site-init
#              secret (customizations.yaml) and the loftsman-cray-sysmgmt-health
#              ConfigMap (cephExporter.endpoints).
# ──────────────────────────────
update_customizations() {
  local new_mons
  new_mons=$(ceph mon dump -f json | jq -r '.mons[].public_addr | split("/")[0]')
  local tmpdir
  tmpdir=$(mktemp -d -p ~)

  echo "Extracting customizations.yaml from secret..."

  kubectl get secret -n loftsman site-init \
    -o jsonpath='{.data.customizations\.yaml}' \
    | base64 -d >"${tmpdir}/customizations.yaml"

  echo "Updating monitor list..."

  NEW_MONS="$new_mons" yq -i \
    '.spec.network.netstaticips.nmn_ncn_storage_mons = (strenv(NEW_MONS) | split("\n") | map(select(length > 0)))' \
    "${tmpdir}/customizations.yaml"

  echo "Recreating secret..."

  kubectl delete secret -n loftsman site-init --ignore-not-found

  kubectl create secret -n loftsman generic site-init \
    --from-file="${tmpdir}/customizations.yaml"

  rm -rf "$tmpdir"
  echo "customizations secret updated successfully"

  echo "Updating cephExporter endpoints in loftsman-cray-sysmgmt-health..."

  local manifest_yaml
  manifest_yaml=$(kubectl get cm -n loftsman loftsman-cray-sysmgmt-health \
    -o jsonpath='{.data.manifest\.yaml}')

  local updated_manifest
  updated_manifest=$(echo "$manifest_yaml" \
    | NEW_MONS="$new_mons" yq e \
      '.spec.charts[].values.cephExporter.endpoints = (strenv(NEW_MONS) | split("\n") | map(select(length > 0)))' -)

  kubectl patch cm -n loftsman loftsman-cray-sysmgmt-health \
    --type merge \
    -p "{\"data\":{\"manifest.yaml\":$(echo "$updated_manifest" | jq -Rs .)}}"

  echo "loftsman-cray-sysmgmt-health ConfigMap updated successfully"
}

# Execute functions
wait_for_ceph_orch || {
  echo "Ceph did not stabilize. Exiting."
  exit 1
}
update_ceph_csi_configmaps
update_customizations

# Update the ceph.conf file on all k8s master nodes to ensure they have the latest CEPH configuration which would have changed during upgrade to enable CEPH access from the k8s masters
for master in $(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}'); do
  scp -o StrictHostKeyChecking=no /etc/ceph/ceph.conf "${master}:/etc/ceph/ceph.conf"
done
