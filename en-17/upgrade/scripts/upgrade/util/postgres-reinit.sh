#!/usr/bin/env bash
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

set -eo pipefail

# After postgresql-operator upgrade, some postgres replicas may failed to start or have lagging issues:
# - operator will perform rolling restart of all postgresql clusters to add new mount to each pod, but restart sequence
#   may get stuck on pod trying to update its own label during CSM 1.6 upgrade (CASMINST-6728). Is this still the case?
# - Use "patronictl reinit" command seem to be able to work around the issue
#

function postgres_operator_running() {
  if [ "$(kubectl -n services get pod -l app.kubernetes.io/name=postgres-operator --no-headers | awk '{ print $2 ":" $3 }')" == "2/2:Running" ]; then
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

wait_for postgres_operator_running "postgres-operator pod running"
# Only recover postgres clusters in argo, services, spire namespaces - but wait for all clusters (such as sma) to be healthy, as
# preflight checks at the end of prerequisites script will need all clusters anyway.
for pg_line in $(kubectl get sts -A -l application=spilo -o json | jq -r '.items[] | select(.metadata.namespace == "argo" or .metadata.namespace == "services" or .metadata.namespace == "spire") | (.metadata.namespace + ":" + .metadata.name)'); do
  pg_cluster=${pg_line#*:}
  pg_ns=${pg_line%:*}
  echo "Working on ${pg_cluster} in namespace ${pg_ns} ..."
  count=1
  total=3
  wait=60
  pg_pod=""
  leader=""
  while [ ${count} -le ${total} ]; do
    # find one pod from the cluster to run patroni command
    if kubectl get pods -n ${pg_ns} -l application=spilo --no-headers | grep ${pg_cluster} | grep "3/3" | grep -m 1 Running; then
      pg_pod=$(kubectl get pods -n ${pg_ns} -l application=spilo --no-headers | grep ${pg_cluster} | grep "3/3" | grep -m 1 Running | awk '{print $1}')
      echo "INFO: found a running pod ${pg_pod}"
      break
    else
      echo "WARNING: No fully running pod is found for ${pg_cluster} in ${pg_ns}. Rollout restart it and sleep for ${wait} seconds, attempt ${count}/${total})..."
      kubectl rollout restart sts ${pg_cluster} -n ${pg_ns}
      sleep ${wait}
      count=$((count + 1))
      continue
    fi
  done

  if [ -z "${pg_pod}" ]; then
    echo "ERROR: Unable to recover ${pg_cluster} in ${pg_ns} automatically. You may have to re-install the chart."
    exit 1
  fi

  count=1
  while [ ${count} -le ${total} ]; do
    # Make sure leader exists for the recovery
    if kubectl exec -i ${pg_pod} -n ${pg_ns} -- patronictl list | grep "${pg_cluster}-" | grep Leader | grep running; then
      leader=$(kubectl exec -i ${pg_pod} -n ${pg_ns} -- patronictl list | grep "${pg_cluster}-" | grep Leader | awk '{print $2}')
      echo "INFO: found the leader pod ${leader}"
      # reinit instances not in "running" state
      reinit_count=1
      reinit_max=5
      while kubectl exec -i ${leader} -n ${pg_ns} -- patronictl list | grep "${pg_cluster}-" | grep -v -m 1 "running"; do
        # get the first instance not in running state
        failed_instance=$(kubectl exec -i ${leader} -n ${pg_ns} -- patronictl list | grep "${pg_cluster}-" | grep -v -m 1 "running" | awk '{print $2}')
        echo "Reinit ${failed_instance} not in running state: attempt ${reinit_count}/${reinit_max}..."
        echo "y" | kubectl exec -i ${leader} -n ${pg_ns} -- patronictl reinit ${pg_cluster} ${failed_instance} 2> /dev/null || true
        # sleep for some time as reinit takes a while to settle
        sleep ${wait}
        reinit_count=$((reinit_count + 1))
        if [ ${reinit_count} -gt ${reinit_max} ]; then
          echo "Reinit count reached ${reinit_max}. Breaking loop."
          break
        fi
      done

      # Reinit instances with replication lag
      reinit_count=1
      reinit_max=3
      while [ "$(kubectl exec -i ${leader} -n ${pg_ns} -- patronictl list | grep Replica | awk '{print $12}' | sort -u)" != "0" ]; do
        while read -r line; do
          if [ "$(echo $line | awk '{print $12}')" != "0" ]; then
            lagged_instance=$(echo $line | awk '{print $2}')
            echo "Reinit ${lagged_instance} with replication lag: attempt ${reinit_count}/${reinit_max}..."
            echo "y" | kubectl exec -i ${leader} -n ${pg_ns} -- patronictl reinit ${pg_cluster} ${lagged_instance} 2> /dev/null || true
            # sleep for some time as reinit takes a while to settle
            sleep ${wait}
          fi
        done < <(kubectl exec -i ${leader} -n ${pg_ns} -- patronictl list | grep Replica)
        reinit_count=$((reinit_count + 1))
        if [ ${reinit_count} -gt ${reinit_max} ]; then
          echo "Reinit count reached ${reinit_max}. Breaking loop."
          break
        fi
      done
    else
      echo "WARNING: No running leader is found for ${pg_cluster} in ${pg_ns}. Rollout restart it and sleep for ${wait} seconds, attempt ${count}/${total})..."
      kubectl rollout restart sts ${pg_cluster} -n ${pg_ns}
      sleep ${wait}
      count=$((count + 1))
      continue
    fi
    break
  done
  if [ -z "${leader}" ]; then
    echo "ERROR: Unable to recover ${pg_cluster} in ${pg_ns} automatically. You may have to re-install the chart."
    exit 1
  fi

done < <(kubectl get sts -A -l application=spilo -o json | jq -r '.items[] | select(.metadata.namespace == "argo" or .metadata.namespace == "services" or .metadata.namespace == "spire") | (.metadata.namespace + ":" + .metadata.name)')

wait_for postgres_pods_running "all postgres pods running"
wait_for postgres_clusters_running "all postgres clusters in state Running"
echo "State of postgres clusters after the fixup:"
kubectl get postgresql -A
