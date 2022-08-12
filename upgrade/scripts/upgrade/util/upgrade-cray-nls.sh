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
    argoUrl=$(kubectl get VirtualService/cray-argo -n argo -o json | jq -r '.spec.hosts[0]')

    TOKEN=$(curl -ks -d grant_type=password \
    --data-urlencode client_id="$(kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.client-id}' -n services | base64 -d)" \
    --data-urlencode username="$(kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.user}' -n services | base64 -d)" \
    --data-urlencode password="$(kubectl get secrets keycloak-master-admin-auth -o jsonpath='{.data.password}' -n services | base64 -d)" \
    https://api-gw-service-nmn.local/keycloak/realms/master/protocol/openid-connect/token | jq -r '.access_token')

    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -k -XGET -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        exit 1
    fi
    
    id=$(jq -r '.[] | select(.clientId=="oauth2-proxy-customer-management") | .id'  < "${res_file}" )
    echo "Get client id: ${id}"

    http_code=$(curl -s -o "client.json" -w "%{http_code}" -k -XGET -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients/${id}")
    if [[ ${http_code} -ne 200 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        exit 1
    else
        echo "Get client json"
    fi
    
    echo "Configure RedirectUris"
    if jq '.[] | select(.clientId=="oauth2-proxy-customer-management") | .redirectUris' < "${res_file}" | grep "https://argo.cmn"; then
        echo "  Argo URL is set in RedirectUris"
    else
        tmpFile=$(mktemp)
        jq ".redirectUris[.redirectUris | length] |= . + \"https://$argoUrl/oauth/callback\"" < client.json  | tee "${tmpFile}" > /dev/null
        mv "${tmpFile}" client.json
    fi
    
    echo "Configure WebOrigins"
    if jq '.[] | select(.clientId=="oauth2-proxy-customer-management") | .webOrigins'  < "${res_file}" | grep "https://argo.cmn"; then
        echo "  Argo URL is set in WebOrigins"
    else
        tmpFile=$(mktemp)
        jq ".webOrigins[.webOrigins | length] |= . + \"https://$argoUrl\"" < client.json  | tee "${tmpFile}"  > /dev/null
        mv "${tmpFile}" client.json
    fi

    res_file=$(mktemp)
    http_code=$(curl -s -o "${res_file}" -w "%{http_code}" -XPUT \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d @client.json \
        "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients/${id}")
    if [[ ${http_code} -ne 204 ]]; then
        echo "Request Failed, Response code: ${http_code}"
        cat "${res_file}"
        exit 1
    fi
    echo "Successfully configured keycloak for argo"
}

deployNLS
patchKeycloak