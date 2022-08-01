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

set -eu

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
    #shellcheck disable=SC2126
    foundArgoInRedirectUris=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq '.[] | select(.clientId=="oauth2-proxy-customer-management") | .redirectUris' | grep "https://argo.cmn" | wc -l)
    redirectUris=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq -r '.[] | select(.clientId=="oauth2-proxy-customer-management") | .redirectUris')
    #shellcheck disable=SC2126
    foundArgoInWebOrigins=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq '.[] | select(.clientId=="oauth2-proxy-customer-management") | .webOrigins' | grep "https://argo.cmn" | wc -l)
    webOrigins=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq -r '.[] | select(.clientId=="oauth2-proxy-customer-management") | .webOrigins')

    id=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients" | jq -r '.[] | select(.clientId=="oauth2-proxy-customer-management") | .id')

    curl -s -k -H "Authorization: Bearer ${TOKEN}" "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients/${id}" > client.json
    if [[ ${foundArgoInRedirectUris} -ge 1 ]];then
        echo "Argo URL is set in RedirectUris"
        echo "${redirectUris}"
    else
        echo
        cat client.json | jq ".redirectUris[.redirectUris | length] |= . + \"https://$argoUrl/oauth/callback\""  | tee client.json
    fi

    if [[ ${foundArgoInWebOrigins} -ge 1 ]];then
        echo "Argo URL is set in WebOrigins"
        echo "${webOrigins}"
    else
        echo
        #shellcheck disable=SC2002
        cat client.json | jq ".webOrigins[.webOrigins | length] |= . + \"https://$argoUrl\"" | tee client.json
    fi

    curl -k -XPUT \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d @client.json \
        "https://api-gw-service-nmn.local/keycloak/admin/realms/shasta/clients/${id}" > /dev/null
}

deployNLS
patchKeycloak