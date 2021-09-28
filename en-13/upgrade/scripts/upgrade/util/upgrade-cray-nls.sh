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

set -euo pipefail

function deployNLS() {
    BUILDDIR="/tmp/build"
    mkdir -p "$BUILDDIR"
    kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > "${BUILDDIR}/customizations.yaml"
    manifestgen -i "${CSM_ARTI_DIR}/manifests/platform.yaml" -c "${BUILDDIR}/customizations.yaml" -o "${BUILDDIR}/platform.yaml"
    charts="$(yq r /tmp/build/platform.yaml 'spec.charts[*].name')"
    for chart in $charts; do
        if [[ $chart != "cray-nls" ]] && [[ $chart != "cray-opa" ]] && [[ $chart != "cray-drydock" ]] && [[ $chart != "cray-oauth2-proxies" ]]; then 
            yq d -i /tmp/build/platform.yaml "spec.charts.(name==$chart)"
        fi
    done

    yq d -i /tmp/build/platform.yaml "spec.sources"

    loftsman ship --charts-path "${CSM_ARTI_DIR}/helm/" --manifest-path /tmp/build/platform.yaml
}

function patchKeycloak() {

    # Get the SYSTEM_DOMAIN from cloud-init 
    SYSTEM_NAME=$(craysys metadata get system-name)
    SITE_DOMAIN=$(craysys metadata get site-domain)
    SYSTEM_DOMAIN=${SYSTEM_NAME}.${SITE_DOMAIN}

    # Use the CMN LB/Ingress
    KC_URL="auth.cmn.${SYSTEM_DOMAIN}"
    ARGO_URL=$(kubectl get VirtualService/cray-argo -n argo -o json | jq -r '.spec.hosts[0]')
    KC_CLIENT_ID=$(kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.client-id}' -n services | base64 -d)
    KC_USERNAME=$(kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.user}' -n services | base64 -d)
    KC_PASSWORD=$(kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.password}' -n services | base64 -d)

    export KC_URL="${KC_URL}"
    export ARGO_URL="${ARGO_URL}"
    export KC_CLIENT_ID="${KC_CLIENT_ID}"
    export KC_USERNAME="${KC_USERNAME}"
    export KC_PASSWORD="${KC_PASSWORD}"
    
    python /usr/share/doc/csm/upgrade/scripts/upgrade/util/nls-keycloak-configure.py
}

deployNLS
patchKeycloak