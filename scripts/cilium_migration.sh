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

echo "INFO Checking current k8s-primary-cni value in BSS"
CNI_VALUE=$(cray bss bootparameters list --hosts Global --format json | jq -r '.[]."cloud-init"."meta-data"."k8s-primary-cni"')

if [[ $CNI_VALUE == "cilium" ]]; then
  echo "INFO k8s-primary-cni is already set to 'cilium'. Skipping migration workflow."
else
  echo "INFO k8s-primary-cni is '$CNI_VALUE'. Proceeding with migration workflow."

  echo "INFO Generating Cilium workflow manifest"

  if [[ ! -f /usr/share/doc/csm/workflows/cilium/generateCiliumLiveMigration.py ]]; then
    echo "ERROR Missing file: generateCiliumLiveMigration.py"
    exit 1
  fi

  if ! /usr/share/doc/csm/workflows/cilium/generateCiliumLiveMigration.py; then
    echo "ERROR Failed to generate Cilium workflow manifest"
    exit 1
  fi

  if [[ ! -f /usr/share/doc/csm/workflows/cilium/cilium-live-migration.yaml ]]; then
    echo "ERROR Missing file: cilium-live-migration.yaml"
    exit 1
  fi

  echo "INFO Applying Cilium workflow manifest"
  if ! kubectl apply -f /usr/share/doc/csm/workflows/cilium/cilium-live-migration.yaml -n argo; then
    echo "ERROR Failed to apply Cilium workflow manifest"
    exit 1
  fi

  WORKFLOW_NAME=$(grep '^  name:' /usr/share/doc/csm/workflows/cilium/cilium-live-migration.yaml | awk '{print $2}')

  echo "INFO Monitoring Cilium workflow status"
  while true; do
    STATUS=$(kubectl get workflow -n argo "${WORKFLOW_NAME}" -o jsonpath='{.status.phase}' 2> /dev/null)

    if [[ $STATUS == "Succeeded" ]]; then
      echo "INFO Workflow ${WORKFLOW_NAME} succeeded"
      break
    elif [[ $STATUS == "Failed" ]]; then
      echo "ERROR Workflow ${WORKFLOW_NAME} failed"
      exit 1
    elif [[ -z $STATUS ]]; then
      echo "INFO Waiting for workflow ${WORKFLOW_NAME} to be created..."
    else
      echo "INFO Workflow ${WORKFLOW_NAME} status: $STATUS"
    fi
    sleep 120
  done
  echo "INFO Cilium workflow completed"
fi
