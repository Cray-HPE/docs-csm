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

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Inform ShellCheck about the file we are sourcing
# shellcheck source=../configuration/bash_lib/common.sh
. "${locOfScript}/../configuration/bash_lib/common.sh"

set -o pipefail

function usage {
  echo "Usage: restart_ipxe.sh" >&2
  echo >&2
  echo "Restarts the Kubernetes cms-ipxe deployment and waits until the restart completes." >&2
  echo >&2
}

NS=services
K8S_INSTANCE=cms-ipxe

[[ $# -eq 0 ]] || usage_err_exit "This script takes no arguments"

echo "Restarting iPXE deployments"

deployment_names=$(kubectl get deployments -n "${NS}" --no-headers -o custom-columns=':.metadata.name' -l "app.kubernetes.io/instance=${K8S_INSTANCE}") \
  || err_exit "Command failed: kubectl get deployments -n '${NS}' --no-headers -o custom-columns=':.metadata.name' -l 'app.kubernetes.io/instance=${K8S_INSTANCE}'"

[[ -n ${deployment_names} ]] || err_exit "No '${K8S_INSTANCE}' Kubernetes deployments found in '${NS}' namespace"

run_cmd kubectl rollout restart deployment -n services ${deployment_names}

for name in ${deployment_names}; do
  run_cmd kubectl rollout status deployment -n services ${name}
done

echo "SUCCESS: iPXE deployments restarted"
exit 0
