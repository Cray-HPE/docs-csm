#!/bin/bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

# Restart CFS deployments to avoid CASMINST-6852

set -e -o pipefail

function err_exit {
  echo "ERROR: $*" >&2
  exit 1
}

function run_cmd {
  "$@" || err_exit "Command failed with rc $?: $*"
}

CFS_DEPLOYMENTS="cray-cfs-api, cray-cfs-batcher, cray-cfs-operator, cfs-trust, cfs-hwsync-agent, cfs-ara"

# First wait until all CFS pods are running (or timeout if this has not happened after 10 minutes)
WAIT_MINUTES=10

# Get tempfile
TEMPFILE=$(mktemp)

echo "$(date) Waiting for all CFS pods to be Running"

let CFS_RUNNING_TIMEOUT=SECONDS+WAIT_MINUTES*60
while true; do
  run_cmd kubectl get pods -l "app.kubernetes.io/instance in (${CFS_DEPLOYMENTS})" -n services --no-headers > "${TEMPFILE}"
  [[ -s ${TEMPFILE} ]] || err_exit "Command gave no output: kubectl get pods -l 'app.kubernetes.io/instance in (${CFS_DEPLOYMENTS})' -n services --no-headers"
  grep -qv Running "${TEMPFILE}" || break
  [[ ${SECONDS} -le ${CFS_RUNNING_TIMEOUT} ]] || err_exit "Not all CFS pods running even after waiting ${WAIT_MINUTES} minutes"
  sleep 10
done

echo "$(date) Initiating rolling restarts of all CFS deployments"

# Now do restarts
run_cmd kubectl rollout restart deployment -n services ${CFS_DEPLOYMENTS//,/}

echo "$(date) Waiting for all CFS deployments to complete rolling restarts"

# And wait for them to complete successfully
for DEP in ${CFS_DEPLOYMENTS//,/}; do
  run_cmd kubectl rollout status deployment -n services ${DEP}
done

echo "$(date) All CFS deployment restarts completed"
