#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

usage() {
    echo >&2 "usage: ${0##*/} [-i] [CUSTOMIZATIONS-YAML]"
    exit 1
}

args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            usage
            ;;
        -i)
            inplace="yes"
            ;;
        *)
            args+=("$1")
            ;;
    esac
    shift
done

set -- "${args[@]}"

[[ $# -eq 1 ]] || usage


customizations="$1"

if [[ ! -f "$customizations" ]]; then
    echo >&2 "error: no such file: $customizations"
    usage
fi

if ! command -v yq &> /dev/null
then
    echo >&2 "error: yq could not be found"
    exit 1
fi

c="$(mktemp)"
trap 'rm -f $c' EXIT

cp "$customizations" "$c"

# Get token to access SLS data
# shellcheck disable=SC2046,SC2155
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

# shellcheck disable=SC2166
if [ -z "${TOKEN}" -o "${TOKEN}" == "" -o "${TOKEN}" == "null" ]; then
    echo >&2 "error: failed to obtain token from keycloak"
    exit 1
fi

# Get Networks from SLS
NETWORKSJSON=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks)

# shellcheck disable=SC2166
if [ -z "${NETWORKSJSON}" -o "${NETWORKSJSON}" == "" -o "${NETWORKSJSON}" == "null" ]; then
    echo >&2 "error: failed to get Networks from SLS"
    exit 1
fi

errors=0
peerindex=0

# Gather the metallb peer information and add it to customizations
for n in "NMN" "CMN" "CHN"; do
numpeers=0

    netName=$(echo "${NETWORKSJSON}" | jq --arg n "$n" '.[] | select(.Name == $n) | .Name')

    if [ -z "${netName}" ]; then
        if [ "$n" == "CHN" ]; then
            echo >&2 "info:  No CHN defined in SLS"
        else
            echo >&2 "error:  No ${n} defined in SLS"
            errors=$((errors+1))
        fi
        continue
    fi

    peerASN=$(echo "${NETWORKSJSON}" | jq --arg n "$n" '.[] | select(.Name == $n) | .ExtraProperties.PeerASN')
    myASN=$(echo "${NETWORKSJSON}" | jq --arg n "$n" '.[] | select(.Name == $n) | .ExtraProperties.MyASN')

    # shellcheck disable=SC2166
    if [ -z "${peerASN}" -o "${peerASN}" == "null" -o "${peerASN}" == "" ]; then
        echo >&2 "error:  PeerASN missing in SLS for network ${n}"
        errors=$((errors+1))
    fi

    # shellcheck disable=SC2166
    if [ -z "${myASN}" -o "${myASN}" == "null" -o "${myASN}" == "" ]; then
        echo >&2 "error:  MyASN missing in SLS for network ${n}"
        errors=$((errors+1))
    fi

    subnets=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[].Name')
    for i in ${subnets}; do
        if [[ "${n}" == "CHN" && "${i}" == "bootstrap_dhcp" ]]; then
            reservations=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .IPReservations[].Name')
            for j in ${reservations}; do
                if [[ "${j}" =~ "chn-switch".* ]]; then
                    numpeers=$((numpeers+1))
                    peerIP=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" --arg j "$j" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .IPReservations[] | select(.Name == $j) | .IPAddress')

                    # shellcheck disable=SC2166
                    if [ -z "${peerIP}" -o "${peerIP}" == "null" -o "${peerIP}" == "" ]; then
                        echo >&2 "error:  IPAddress missing in SLS for ${j} in network ${n}"
                        errors=$((errors+1))
                    fi

                    if [ $errors -eq 0 ]; then
                        yq w -i "$c" 'spec.network.metallb.peers['${peerindex}'].peer-address' "${peerIP}"
                        yq w -i "$c" 'spec.network.metallb.peers['${peerindex}'].peer-asn' "${peerASN}"
                        yq w -i "$c" 'spec.network.metallb.peers['${peerindex}'].my-asn' "${myASN}"
                        peerindex=$((peerindex+1))
                    fi
                fi
            done

        elif [[ ("${n}" == "NMN" || "${n}" == "CMN")  && "${i}" == "network_hardware" ]]; then
            reservations=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .IPReservations[].Name')
            for j in ${reservations}; do
                if [[ "${j}" =~ .*"spine".* ]]; then
                    numpeers=$((numpeers+1))
                    peerIP=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" --arg j "$j" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .IPReservations[] | select(.Name == $j) | .IPAddress')

                    # shellcheck disable=SC2166
                    if [ -z "${peerIP}" -o "${peerIP}" == "null" -o "${peerIP}" == "" ]; then
                        echo >&2 "error:  IPAddress missing in SLS for ${j} in network ${n}"
                        errors=$((errors+1))
                    fi

                    if [ $errors -eq 0 ]; then
                        yq w -i "$c" 'spec.network.metallb.peers['${peerindex}'].peer-address' "${peerIP}"
                        yq w -i "$c" 'spec.network.metallb.peers['${peerindex}'].peer-asn' "${peerASN}"
                        yq w -i "$c" 'spec.network.metallb.peers['${peerindex}'].my-asn' "${myASN}"
                        peerindex=$((peerindex+1))
                    fi
                fi
            done
        fi
    done

    if [ $numpeers -eq 0 ]; then
        echo >&2 "error: No peers found for network ${n}"
        errors=$((errors+1))
    fi

done

# Stop here if we had any problems getting the peer information
if [ $errors -gt 0 ]; then
    exit 1
fi

# Gather the metallb pool information and add it to customizations
poolindex=0

# delete all address pools before re-creating them, this is needed for CAN > CHN cleanup 
yq d -i "$c" 'spec.network.metallb.address-pools'

networks=$(echo "${NETWORKSJSON}" | jq -r '.[].Name')
for n in ${networks}; do
    subnets=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[].Name')
    for i in ${subnets}; do
        if [[ "${i}" =~ .*"_metallb_".* ]]; then
            poolName=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .MetalLBPoolName')
            poolCIDR=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .CIDR')

            # shellcheck disable=SC2166
            if [ -z "${poolName}" -o "${poolName}" == "null" -o "${poolName}" == "" ]; then
                echo >&2 "error:  MetalLBPoolName missing in SLS for subnet ${i} in network ${n}"
                errors=$((errors+1))
            fi

            # shellcheck disable=SC2166
            if [ -z "${poolCIDR}" -o "${poolCIDR}" == "null " -o "${poolCIDR}" == "" ]; then
                echo >&2 "error:  CIDR missing in SLS for subnet ${i} in network ${n}"
                errors=$((errors+1))
            fi

            if [ $errors -eq 0 ]; then
                yq w -i "$c" 'spec.network.metallb.address-pools['${poolindex}'].name' ${poolName}
                yq w -i "$c" 'spec.network.metallb.address-pools['${poolindex}'].protocol' 'bgp'
                yq w -i "$c" 'spec.network.metallb.address-pools['${poolindex}'].addresses[0]' ${poolCIDR}
                poolindex=$((poolindex+1))
            fi
        fi
    done
done

# Stop here if we had any problems getting the pool information
if [ $errors -gt 0 ]; then
    exit 1
fi

# argo/cray-nls
yq w -i --style=single "$c" spec.kubernetes.services.cray-nls.externalHostname 'cmn.{{ network.dns.external }}'

if [[ -z "$(yq r "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement(.==argo.cmn.{{ network.dns.external }})')" ]];then
   yq w -i --style=single "$c" spec.proxiedWebAppExternalHostnames.customerManagement[+] 'argo.cmn.{{ network.dns.external }}'
fi

# cray-opa
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-hmn.issuers.shasta-hmn' 'https://api.hmnlb.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-hmn.issuers.keycloak-hmn' 'https://auth.hmnlb.{{ network.dns.external }}/keycloak/realms/shasta'

# cray-istio
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-hmn.serviceAnnotations.[external-dns.alpha.kubernetes.io/hostname]' 'api.hmnlb.{{ network.dns.external }},auth.hmnlb.{{ network.dns.external }},hmcollector.hmnlb.{{ network.dns.external }}'

# cray-ims
# Note to future developers: This is needed to address CASMTRIAGE-4098. It is only needed on upgrades to csm-1.2 and csm-1.3.
yq w -i "$c" 'spec.kubernetes.services.cray-ims.customer_access.access_pool' 'customer-management'

#
# Add new nmn_ncn_storage_mons values that would be generated by CSI on
# a fresh install.  This list is the first three storage nodes which
# are meant to be endpoints for the cephExporter -- which should run
# on ceph nodes with the mgr daemon running.
#
if [[ -z "$(yq r "$c" "spec.network.netstaticips.nmn_ncn_storage_mons")" ]]; then
  yq w -i $c 'spec.network.netstaticips.nmn_ncn_storage_mons'
  mon_nodes=$(yq r $c 'spec.network.netstaticips.nmn_ncn_storage' | head -3 | awk '{print $2}')
  loop_idx=0
  for node in ${mon_nodes}; do
    yq w -i $c "spec.network.netstaticips.nmn_ncn_storage_mons[${loop_idx}]" "${node}"
    loop_idx=$(( loop_idx+1 ))
  done
  yq w -i --style=single "$c" spec.kubernetes.services.cray-sysmgmt-health.cephExporter.endpoints '{{ network.netstaticips.nmn_ncn_storage_mons }}'
fi

if [[ "$inplace" == "yes" ]]; then
    cp "$c" "$customizations"
else
    cat "$c"
fi
