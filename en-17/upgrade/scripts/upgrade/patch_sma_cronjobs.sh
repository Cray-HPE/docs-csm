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

function patch_sma_cronjobs() {
  local namespace cronjobs name
  namespace="sma"

  echo "[INFO] Checking for batch/v1beta1 CronJobs in namespace: $namespace"

  # Ensure the namespace exists
  if ! kubectl get ns "$namespace" > /dev/null 2>&1; then
    echo "[INFO] Namespace '$namespace' not found. Nothing to patch."
    return 0
  fi

  # Get all batch/v1beta1 CronJobs in the sma namespace
  cronjobs=$(kubectl get cronjob -n "$namespace" -o name 2> /dev/null || true)

  if [[ -z $cronjobs ]]; then
    echo "[INFO] No batch/v1beta1 CronJobs found in namespace '$namespace'."
    return 0
  fi

  # Loop through each CronJob and patch
  for cronjob in $cronjobs; do
    name="${cronjob##*/}"
    echo "[INFO] Patching CronJob: $name"

    # Export, modify, and re-apply (remove status block and update apiVersion)
    kubectl get "$cronjob" -n "$namespace" -o yaml \
      | sed '/^status:/,$d' \
        > "/tmp/${name}-cronjob-patched.yaml"

    echo "[INFO] Deleting old CronJob: $name"
    kubectl delete "$cronjob" -n "$namespace" || true

    echo "[INFO] Applying patched CronJob: $name"
    kubectl apply -f "/tmp/${name}-cronjob-patched.yaml" -n "$namespace"

    # Clean up temporary file
    rm -f "/tmp/${name}-cronjob-patched.yaml"
  done

  echo "[INFO] Finished patching CronJobs in namespace: $namespace"
}
