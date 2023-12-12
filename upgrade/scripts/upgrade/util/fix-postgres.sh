#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

set -e -o pipefail

# After postgresql-operator upgrade, a few issues may happen:
# - operator may not be updating postgresqls.acid.zalan.do CRD, although instructed to do so. We mitigate this
#   by explicitly restarting operator pod and waiting for CRD to be updated.
# - operator will try to perform rolling restart of all postgresql clusters to add new mount to each pod, by setting
#   zalando-postgres-operator-rolling-update-required: true annotation onto sts, but this may fail due to PSP issue (CASMINST-6728).
#   restarting operator pod clears this error.
# - operator will perform rolling restart of all postgresql clusters to add new mount to each pod, but restart sequence
#   may stuck on pod trying to update it's own label (CASMINST-6728). We mitigate this by explicit rolling restart
#   of all PostgreSQL stateful sets.
#

function postgres_operator_running() {
  if [ "$(kubectl -n services get pod -l app.kubernetes.io/name=postgres-operator --no-headers | awk '{ print $2 ":" $3 }')" == "2/2:Running" ]; then
    return 0
  else
    return 1
  fi
}

function postgres_crd_updated() {
  if kubectl get crd postgresqls.acid.zalan.do -o json \
    | jq -r '.spec.versions[].schema.openAPIV3Schema.properties.spec.properties.postgresql.properties.version.enum[]' \
    | grep -q -w "14"; then
    return 0
  else
    return 1
  fi
}

function postgres_pods_running() {
  if [ "$(kubectl get pod -l application=spilo -A --no-headers | awk '{ print $3 ":" $4 }' | sort -u)" == "3/3:Running" ]; then
    return 0
  else
    return 1
  fi
}

function postgres_clusters_running() {
  if [ "$(kubectl get postgresql -A -o json | jq -r '.items[].status.PostgresClusterStatus' | sort -u)" == "Running" ]; then
    return 0
  else
    return 1
  fi
}

function wait_for() {
  local command="${1}"
  local message="${2}"
  local count=0
  local total=120
  local sleep=5
  while true; do
    if ${command}; then
      echo "${message}" | awk '{print toupper(substr($0, 1, 1)) substr($0, 2)}'
      break
    else
      if [ "${count}" -ge "${total}" ]; then
        echo "ERROR: giving up for ${message} after ${total} attempts"
        exit 1
      fi
      count=$((count + 1))
      echo "Waiting for ${message}, sleeping for ${sleep} seconds and retry, attempt ${count}/${total} ..."
      sleep ${sleep}
    fi
  done
}

echo "Waiting for 60 seconds for cray-postgres-operator pod to settle after upgrade ..."
sleep 60
echo "Restarting cray-postgres-operator pod ..."
kubectl -n services delete pod -l app.kubernetes.io/name=postgres-operator
wait_for postgres_operator_running "postgres-operator pod running"
wait_for postgres_crd_updated "postgresqls.acid.zalan.do CRD updated to support PostgreSQL 14"
# Only restart postgres clusters in argo, services, spire namespaces - but wait for all clusters (such as sma) to be healthy, as
# preflight checks at the end of prerequisites script will need all clusters anyway.
kubectl get sts -A -l application=spilo -o json \
  | jq -r '.items[] | select(.metadata.namespace == "argo" or .metadata.namespace == "services" or .metadata.namespace == "spire") | (.metadata.namespace + ":" + .metadata.name)' \
  | while IFS=: read -r namespace sts; do
    echo "Rolling restart ${sts} in namespace ${namespace} ..."
    kubectl rollout restart -n "${namespace}" statefulset "${sts}"
  done
echo "Waiting for 300 seconds for postgres statefulsets rolling restart to commence ..."
sleep 300
wait_for postgres_pods_running "all postgres pods running"
wait_for postgres_clusters_running "all postgres clusters in state Running"
echo "State of postgres clusters after operator upgrade:"
kubectl get postgresql -A
