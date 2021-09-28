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

set -e -o pipefail

function k8s_job_exists {
  # usage: k8s_job_exists <namespace> <job name>
  # Returns 0 if the job exists
  # Returns 1 if the job does not exist
  # Exits if Kubernetes errors prevent us from determining that
  if [[ $# -ne 2 ]]; then
    echo "ERROR: $0: Function requires exactly 2 arguments but received $#: $*" >&2
    exit 1
  elif [[ -z $1 ]]; then
    echo "ERROR: $0: Namespace may not be blank" >&2
    exit 1
  elif [[ -z $2 ]]; then
    echo "ERROR: $0: Job name may not be blank" >&2
    exit 1
  fi

  local i wait_time job_name ns tempfile
  i=1
  max_checks=3
  wait_time=15
  ns="$1"
  job_name="$2"
  tempfile=$(mktemp)

  # To prevent failure caused by some transient Kubernetes error, retry this check
  while [[ ${i} -le ${max_checks} ]]; do
    echo "Checking if Kubernetes job ${job_name} (namespace: ${ns}) exists (${i}/${max_checks})"
    [[ ${i} -eq 1 ]] || sleep ${wait_time}
    if kubectl get job -n "${ns}" "${job_name}" > /dev/null 2> "${tempfile}"; then
      echo "${job_name} job exists"
      return 0
    elif grep -Eiq 'NotFound|not found' "${tempfile}"; then
      echo "${job_name} job does not exist"
      return 1
    fi
    echo "Error checking existence of ${job_name} Kubernetes job."
    if [[ ${i} -lt ${max_checks} ]]; then
      echo "Retrying after ${wait_time} seconds."
      sleep ${wait_time}
    fi
  done
  echo "ERROR: Unable to determine whether or not Kubernetes job ${job_name} (namespace ${ns}) exists" >&2
  exit 1
}

function wait_for_k8s_job_to_exist {
  # usage: wait_for_k8s_job_to_exist <namespace> <job name>
  # Returns 0 if the job exists
  # Returns 1 if the job does not exist by the time the retries are exhausted
  # Exits 1 for other fatal errors
  if [[ $# -ne 2 ]]; then
    echo "ERROR: $0: Function requires exactly 2 arguments but received $#: $*" >&2
    exit 1
  elif [[ -z $1 ]]; then
    echo "ERROR: $0: Namespace may not be blank" >&2
    exit 1
  elif [[ -z $2 ]]; then
    echo "ERROR: $0: Job name may not be blank" >&2
    exit 1
  fi

  local i max_checks wait_time job_name ns start_time
  i=1
  max_checks=40
  wait_time=15
  ns="$1"
  job_name="$2"
  start_time=${SECONDS}

  while [[ ${i} -le ${max_checks} ]]; do
    echo "Waiting for Kubernetes job ${job_name} (namespace: ${ns}) to exist (${i}/${max_checks})"
    [[ ${i} -eq 1 ]] || sleep ${wait_time}
    i=$((i + 1))
    if k8s_job_exists "${ns}" "${job_name}"; then
      echo "Kubernetes job ${job_name} exists"
      return 0
    fi
    echo "Kubernetes job ${job_name} does not yet exist"
    if [[ ${i} -lt ${max_checks} ]]; then
      echo "Checking again after ${wait_time} seconds."
      sleep ${wait_time}
    fi
  done
  echo "ERROR: Kubernetes job ${job_name} (namespace: ${ns}) does not exist after $((SECONDS - start_time)) seconds" >&2
  return 1
}

function wait_for_k8s_job_to_succeed {
  # usage: wait_for_k8s_job_to_complete <namespace> <job name>
  # Returns 0 if the job completes successfully
  # Returns 1 if the job does not succeed by the time the retries are exhausted
  # Exits 1 for other fatal errors
  if [[ $# -ne 2 ]]; then
    echo "ERROR: $0: Function requires exactly 2 arguments but received $#: $*" >&2
    exit 1
  elif [[ -z $1 ]]; then
    echo "ERROR: $0: Namespace may not be blank" >&2
    exit 1
  elif [[ -z $2 ]]; then
    echo "ERROR: $0: Job name may not be blank" >&2
    exit 1
  fi

  local i max_checks wait_time job_name ns start_time
  i=1
  max_checks=40
  wait_time=15
  ns="$1"
  job_name="$2"
  start_time=${SECONDS}

  while [[ ${i} -le ${max_checks} ]]; do
    echo "Waiting for Kubernetes job ${job_name} (namespace: ${ns}) to succeed (${i}/${max_checks})"
    [[ ${i} -eq 1 ]] || sleep ${wait_time}
    i=$((i + 1))
    if [[ $(kubectl get job -n services "${job_name}" -o jsonpath='{.status.succeeded}') == 1 ]]; then
      echo "Kubernetes job ${job_name} succeeded"
      return 0
    fi
    echo "Kubernetes job ${job_name} not yet succeeded"
    if [[ ${i} -lt ${max_checks} ]]; then
      echo "Checking again after ${wait_time} seconds."
      sleep ${wait_time}
    fi
  done
  echo "ERROR: Kubernetes job ${job_name} (namespace: ${ns}) did not succeed after $((SECONDS - start_time)) seconds" >&2
  return 1
}
