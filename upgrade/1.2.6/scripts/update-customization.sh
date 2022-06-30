#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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

# update podman config
SITE_INIT_DIR=/etc/cray/upgrade/csm/${CSM_RELEASE_VERSION}/site-init
mkdir -p "${SITE_INIT_DIR}"
pushd ${SITE_INIT_DIR}
DATETIME=$(date +%Y-%m-%d_%H-%M-%S)
CUSTOMIZATIONS_YAML=$(mktemp -p "${SITE_INIT_DIR}" "customizations-${DATETIME}-XXX.yaml")
kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > "${CUSTOMIZATIONS_YAML}"
cp "${CUSTOMIZATIONS_YAML}" "${CUSTOMIZATIONS_YAML}.bak"
yq w -i --style=single "${CUSTOMIZATIONS_YAML}" spec.kubernetes.services.cray-nls.externalHostname 'cmn.{{ network.dns.external }}'
yq w -i --style=single "${CUSTOMIZATIONS_YAML}" spec.proxiedWebAppExternalHostnames.customerManagement[+] 'argo.cmn.{{ network.dns.external }}'
kubectl delete secret -n loftsman site-init
kubectl create secret -n loftsman generic site-init --from-file="${CUSTOMIZATIONS_YAML}"