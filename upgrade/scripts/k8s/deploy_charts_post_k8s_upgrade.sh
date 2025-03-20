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

# Do we have additional charts to deploy after the K8s upgrade?
# Source /etc/cray/upgrade/csm/myenv to get CSM_ARTI_DIR
source /etc/cray/upgrade/csm/myenv

if [[ -z ${CSM_ARTI_DIR} ]]; then
  echo "ERROR The CSM_ARTI_DIR environment variable is not set and must be present in /etc/cray/upgrade/csm/myenv."
  exit 1
fi

k8s_version=$(kubeadm version -o json | jq -r '.clientVersion.gitVersion' | grep -o "v1.[^.]*")
k8s_minor_version=$(echo ${k8s_version} | cut -d "." -f2)

# Change working directory to CSM_ARTI_DIR
pushd ${CSM_ARTI_DIR}

# Deploy charts in given manifest
function deploy() {
  # Loftsman may not be able to connect to $NEXUS_URL due to certificate
  # trust issues, so use --charts-path instead of --charts-repo.
  loftsman ship --charts-path "${CSM_ARTI_DIR}/helm" --manifest-path "$1"
}

# If there are post-upgrade-*-<k8s_version>.yaml files, deploy charts in those files.
manifests_dir="${CSM_ARTI_DIR}/build/manifests"
find "${manifests_dir}/" -name "post-upgrade-*-${k8s_version}.yaml" | sort | while read -r manifest; do
  echo "INFO Deploying ${manifest} ..."
  deploy "${manifest}"
done

# Return to previous working directory
popd

