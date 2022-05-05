#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

set -e
basedirLoc=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. ${basedirLoc}/../../common/upgrade-state.sh
trap 'err_report' ERR
set -o pipefail

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

if ! command -v jq &> /dev/null
then
    echo >&2 "error: jq could not be found"
    exit 1
fi

c="$(mktemp)"
trap "rm -f '$c'" EXIT

cp "$customizations" "$c"

# Get token to access SLS data
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

if [ -z "${TOKEN}" -o "${TOKEN}" == "" -o "${TOKEN}" == "null" ]; then
    echo >&2 "error: failed to obtain token from keycloak"
    exit 1
fi

# Get Networks from SLS
NETWORKSJSON=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks)

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

    if [ -z "${peerASN}" -o "${peerASN}" == "null" -o "${peerASN}" == "" ]; then
        echo >&2 "error:  PeerASN missing in SLS for network ${n}"
        errors=$((errors+1))
    fi

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

networks=$(echo "${NETWORKSJSON}" | jq -r '.[].Name')
for n in ${networks}; do
    subnets=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[].Name')
    for i in ${subnets}; do
        if [[ "${i}" =~ .*"_metallb_".* ]]; then
            poolName=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .MetalLBPoolName')
            poolCIDR=$(echo "${NETWORKSJSON}" | jq -r --arg n "$n" --arg i "$i" '.[] | select(.Name == $n) | .ExtraProperties.Subnets[] | select(.Name == $i) | .CIDR')

            if [ -z "${poolName}" -o "${poolName}" == "null" -o "${poolName}" == "" ]; then
                echo >&2 "error:  MetalLBPoolName missing in SLS for subnet ${i} in network ${n}"
                errors=$((errors+1))
            fi

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

NMN_GW=$(echo "${NETWORKSJSON}" | jq -r '.[] | select(.Name == "NMN") | .ExtraProperties.Subnets[0].Gateway')
if [ -z $NMN_GW ]; then
    echo >&2 "error:  Could not find NMN Gateway"
    exit 1
fi

UAI_NMN_BH=$(echo "${NETWORKSJSON}" | jq -r '.[] | select(.Name == "NMN") | .ExtraProperties.Subnets[] | select(.Name == "uai_macvlan") | .IPReservations[] | select(.Name == "uai_nmn_blackhole") | .IPAddress')
if [ -z $UAI_NMN_BH ]; then
    echo >&2 "error:  Could not find uai_nmn_blackhole reservation"
    exit 1
fi

CMN_CIDR=$(echo "${NETWORKSJSON}" | jq -r '.[] | select(.Name == "CMN") | .ExtraProperties.CIDR')
if [ -z $CMN_CIDR ]; then
    echo >&2 "error:  Could not find CMN CIDR"
    exit 1
fi

NMNLB_CIDR=$(echo "${NETWORKSJSON}" | jq -r '.[] | select(.Name == "NMNLB") | .ExtraProperties.CIDR')
if [ -z $NMNLB_CIDR ]; then
    echo >&2 "error:  Could not find NMNLB CIDR"
    exit 1
fi

# Replace the NMNLB route in macvlan routes with the UAI NMN blackhole for gateway
yq d -i "$c" "spec.wlm.macvlansetup.routes.(dst==${NMNLB_CIDR})"
yq w -i "$c" "spec.wlm.macvlansetup.routes[+].dst" "${NMNLB_CIDR}"
yq w -i "$c" "spec.wlm.macvlansetup.routes.(dst==${NMNLB_CIDR}).gw" "${UAI_NMN_BH}"

# Add the CMN route to macvlan routes if it is not already there
if [[ -z "$(yq r "$c" "spec.wlm.macvlansetup.routes.(dst==${CMN_CIDR})")" ]]; then
    yq w -i "$c" "spec.wlm.macvlansetup.routes[+].dst" "${CMN_CIDR}"
    yq w -i "$c" "spec.wlm.macvlansetup.routes.(dst==${CMN_CIDR}).gw" "${NMN_GW}"
fi

# Ensure Gitea's PVC configuration has been removed (stop gap for potential upgrades from CSM 0.9.4)
yq d -i "$c" 'spec.kubernetes.services.gitea.cray-service.persistentVolumeClaims'

yq w -i "$c" 'spec.kubernetes.services.cray-hms-badger-loader.nexus.repo' 'csm-diags'

yq d -i "$c" 'spec.kubernetes.services.cray-keycloak-gatekeeper.hosts(.==mma.{{ network.dns.external }})'
if [[ -z "$(yq r "$c" 'spec.kubernetes.services.cray-keycloak-gatekeeper.hosts(.==csms.{{ network.dns.external }})')" ]]; then
    yq w -i "$c" 'spec.kubernetes.services.cray-keycloak-gatekeeper.hosts[+]' 'csms.{{ network.dns.external }}'
fi

yq w -i "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.uai_macvlan_range_start' '{{ wlm.macvlansetup.nmn_reservation_start }}'
yq w -i "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.uai_macvlan_range_end' '{{ wlm.macvlansetup.nmn_reservation_end }}'
yq d -i "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.images'

yq w -i "$c" -- 'spec.kubernetes.services.sma-elasticsearch.esJavaOpts' '-Xmx30g -Xms30g'

yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.cray-service.service.loadBalancerIP' '10.92.100.72'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.cray-service.volumeClaimTemplate.storageClassName' 'sma-block-replicated'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.cray-service.volumeClaimTemplate.resources.requests.storage' '16Gi'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.rsyslogAggregatorHmn.service.loadBalancerIP' '10.94.100.72'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.rsyslogAggregatorCan'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.rsyslogAggregatorCmn.externalHostname' 'rsyslog.cmn.{{ network.dns.external }}'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.volumeClaimTemplate'

yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.service.loadBalancerIP' '10.92.100.72'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.volumeClaimTemplate.storageClassName' 'sma-block-replicated'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.volumeClaimTemplate.resources.requests.storage' '16Gi'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.rsyslogAggregatorUdpHmn.service.loadBalancerIP' '10.94.100.72'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.rsyslogAggregatorCan'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.rsyslogAggregatorCmn.externalHostname' 'rsyslog.cmn.{{ network.dns.external }}'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.volumeClaimTemplate'

# Add new PowerDNS values that would be generated by CSI on a fresh install
yq w -i "$c" 'spec.network.dns.primary_server_name' primary
yq w -i --style=double "$c" 'spec.network.dns.secondary_servers' ""
yq w -i --style=double "$c" 'spec.network.dns.notify_zones' ""

# Add new generator for the PowerDNS API key Sealed Secret
if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.powerdns')" ]]; then
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.name' cray-powerdns-credentials
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].type' randstr
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].args.name' pdns_api_key
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].args.length' 32
fi

# Add new generator for the dnssec key
if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.dnssec')" ]]; then
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.name' dnssec-keys
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.data[0].type' static_b64
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.data[0].args.name' dummy
  yq w -i "$c" 'spec.kubernetes.sealed_secrets.dnssec.generate.data[0].args.value' ZHVtbXkK
fi

# Remove unused cray-externaldns configuration and add domain filters required for bifurcated CAN.
if [[ -z "$(yq r "$c" 'spec.kubernetes.services.cray-externaldns.external-dns.domainFilters')" ]]; then
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-externaldns.external-dns'
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-externaldns.external-dns.domainFilters[+]' '.{{ network.dns.external }}'
fi
if [[ ! -z "$(yq r "$c" 'spec.kubernetes.services.cray-externaldns.coredns')" ]]; then
    yq d -i "$c" 'spec.kubernetes.services.cray-externaldns.coredns'
    yq d -i "$c" 'spec.kubernetes.services.cray-externaldns.sharedIPServices'
fi

# Add required PowerDNS and Unbound configuration
yq w -i "$c" 'spec.kubernetes.services.cray-dns-unbound.domain_name' '{{ network.dns.external }}'
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.primary_server' '{{ network.dns.primary_server_name }}/{{ network.netstaticips.site_to_system_lookups }}'
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.secondary_servers' "{{ network.dns.secondary_servers }}"
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.base_domain' "{{ network.dns.external }}"
yq w -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.notify_zones' "{{ network.dns.notify_zones }}"
yq w -i "$c" 'spec.kubernetes.services.cray-powerdns-manager.cray-service.sealedSecrets[0]' '{{ kubernetes.sealed_secrets.dnssec | toYaml }}'
yq w -i "$c" 'spec.kubernetes.services.cray-dns-powerdns.service.cmn.loadBalancerIP' '{{ network.netstaticips.site_to_system_lookups }}'
yq w -i "$c" 'spec.kubernetes.services.cray-dns-powerdns.cray-service.sealedSecrets[0]' '{{ kubernetes.sealed_secrets.powerdns | toYaml }}'

# Add proxiedWebAppExternalHostnames
if [[ -z "$(yq r "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement')" ]]; then
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' "{{ kubernetes.services['gatekeeper-policy-manager']['gatekeeper-policy-manager'].externalAuthority }}"
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' "{{ kubernetes.services['cray-istio'].istio.tracing.externalAuthority }}"
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' "{{ kubernetes.services['cray-kiali'].externalAuthority }}"
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' "{{ kubernetes.services['cray-sysmgmt-health']['prometheus-operator'].prometheus.prometheusSpec.externalAuthority }}"
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' "{{ kubernetes.services['cray-sysmgmt-health']['prometheus-operator'].alertmanager.alertmanagerSpec.externalAuthority }}"
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' "{{ kubernetes.services['cray-sysmgmt-health']['prometheus-operator'].grafana.externalAuthority }}"
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' '{{ kubernetes.services.gitea.externalHostname }}'
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' 'sma-grafana.cmn.{{ network.dns.external }}'
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' 'sma-kibana.cmn.{{network.dns.external}}'
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement[+]' 'csms.cmn.{{ network.dns.external }}'
fi
if [[ -z "$(yq r "$c" 'spec.proxiedWebAppExternalHostnames.customerAccess')" ]]; then
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerAccess[+]' 'capsules.can.{{ network.dns.external }}'
fi
if [[ -z "$(yq r "$c" 'spec.proxiedWebAppExternalHostnames.customerHighSpeed')" ]]; then
    yq w -i --style=single "$c" 'spec.proxiedWebAppExternalHostnames.customerHighSpeed[+]' 'capsules.chn.{{ network.dns.external }}'
fi

# Add network to externalAuthority names
yq w -i "$c" 'spec.kubernetes.services.cray-nexus.istio.ingress.hosts.ui.authority' 'nexus.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.istio.tracing.externalAuthority' 'jaeger-istio.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.prometheus.prometheusSpec.externalAuthority' 'prometheus.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.alertmanager.alertmanagerSpec.externalAuthority' 'alertmanager.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.cray-sysmgmt-health.prometheus-operator.grafana.externalAuthority' 'grafana.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.cray-s3.service.annotations.[external-dns.alpha.kubernetes.io/hostname]' 's3.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.gitea.externalHostname' 'vcs.cmn.{{ network.dns.external }}'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.rsyslogAggregatorCan'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.rsyslogAggregatorCmn.externalHostname' 'rsyslog.cmn.{{ network.dns.external }}'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.rsyslogAggregatorCan'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.rsyslogAggregatorCmn.externalHostname' 'rsyslog.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.sma-kibana.externalAuthority' 'sma-kibana.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.sma-grafana.externalAuthority' 'sma-grafana.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.gatekeeper-policy-manager.gatekeeper-policy-manager.externalAuthority' 'opa-gpm.cmn.{{ network.dns.external }}'

# cray-opa changes
yq d -i "$c" 'spec.kubernetes.services.cray-opa.jwtValidation'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway.issuers.shasta-cmn' 'https://api.cmn.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway.issuers.keycloak-cmn' 'https://auth.cmn.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway.issuers.shasta-nmn' 'https://api.nmnlb.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway.issuers.keycloak-nmn' 'https://auth.nmnlb.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-customer-admin.issuers.shasta-cmn' 'https://api.cmn.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-customer-admin.issuers.keycloak-cmn' 'https://auth.cmn.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-customer-user.issuers.shasta-chn' 'https://api.chn.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-customer-user.issuers.keycloak-chn' 'https://auth.chn.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-customer-user.issuers.shasta-can' 'https://api.can.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-customer-user.issuers.keycloak-can' 'https://auth.can.{{ network.dns.external }}/keycloak/realms/shasta'

# cray-istio changes
yq d -i "$c" 'spec.kubernetes.services.cray-istio-deploy'
yq d -i "$c" 'spec.kubernetes.services.cray-istio.istio.prometheus'
yq d -i "$c" 'spec.kubernetes.services.cray-istio.istio.kiali'
yq d -i "$c" 'spec.kubernetes.services.cray-istio.istio.grafana'
yq d -i "$c" 'spec.kubernetes.services.cray-istio.istio.gateways'
if [[ -z "$(yq r "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames(.==*.cmn.{{ network.dns.external }})')" ]]; then
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' '*.cmn.{{ network.dns.external }}'
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' '*.can.{{ network.dns.external }}'
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' '*.chn.{{ network.dns.external }}'
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' '*.nmn.{{ network.dns.external }}'
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' '*.hmn.{{ network.dns.external }}'
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' '*.nmnlb.{{ network.dns.external }}'
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' '*.hmnlb.{{ network.dns.external }}'
fi
yq d -i "$c" 'spec.kubernetes.services.cray-istio.extraIngressServices'
yq d -i "$c" 'spec.kubernetes.services.cray-istio.ingressgatewayhmn'

yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway.loadBalancerIP' '{{ network.netstaticips.nmn_api_gw }}'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway.serviceAnnotations.[metallb.universe.tf/address-pool]' 'node-management'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway.serviceAnnotations.[external-dns.alpha.kubernetes.io/hostname]' 'api.nmnlb.{{ network.dns.external}},auth.nmnlb.{{ network.dns.external }}'

yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-hmn.loadBalancerIP' '{{ network.netstaticips.hmn_api_gw }}'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-hmn.serviceAnnotations[metallb.universe.tf/address-pool]' 'hardware-management'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-hmn.serviceAnnotations.[external-dns.alpha.kubernetes.io/hostname]' 'hmcollector.hmnlb.{{ network.dns.external }}'

yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-can.serviceAnnotations.[metallb.universe.tf/address-pool]' 'customer-access'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-can.serviceAnnotations.[external-dns.alpha.kubernetes.io/hostname]' 'api.can.{{ network.dns.external}},auth.can.{{ network.dns.external }}'

yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-cmn.serviceAnnotations.[metallb.universe.tf/address-pool]' 'customer-management'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-cmn.serviceAnnotations.[external-dns.alpha.kubernetes.io/hostname]' 'api.cmn.{{ network.dns.external}},auth.cmn.{{ network.dns.external }},nexus.cmn.{{ network.dns.external }}'

yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-chn.serviceAnnotations.[metallb.universe.tf/address-pool]' 'customer-high-speed'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-chn.serviceAnnotations.[external-dns.alpha.kubernetes.io/hostname]' 'api.chn.{{ network.dns.external}},auth.chn.{{ network.dns.external }}'

yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-local.loadBalancerIP' '{{ network.netstaticips.nmn_api_gw_local }}'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-local.serviceAnnotations.[metallb.universe.tf/address-pool]' 'node-management'

# cray-keycloak changes
yq w -i "$c" 'spec.kubernetes.services.cray-keycloak.setup.keycloak.customerAccessUrl' 'https://auth.cmn.{{ network.dns.external }}/keycloak'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-keycloak.setup.keycloak.gatekeeper.proxiedHosts' '{{ proxiedWebAppExternalHostnames.customerManagement }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-keycloak.setup.keycloak.clients.oauth2-proxy-customer-management.proxiedHosts' '{{ proxiedWebAppExternalHostnames.customerManagement }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-keycloak.setup.keycloak.clients.oauth2-proxy-customer-access.proxiedHosts' '{{ proxiedWebAppExternalHostnames.customerAccess }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-keycloak.setup.keycloak.clients.oauth2-proxy-customer-high-speed.proxiedHosts' '{{ proxiedWebAppExternalHostnames.customerHighSpeed }}'

# nexus -- add admin credential
if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential')" ]]; then
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.name' nexus-admin-credential
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[0].type' static
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[0].args.name' username
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[0].args.value' "${NEXUS_USERNAME:-admin}"
    if [[ -v NEXUS_PASSWORD && -n "$NEXUS_PASSWORD" ]]; then
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].type' static_b64
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].args.name' password
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].args.value' "$(base64 <<< "$NEXUS_PASSWORD")"
    else
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].type' randstr
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].args.name' password
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].args.length' 32
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].args.encoding' base64
        yq w -i "$c" 'spec.kubernetes.sealed_secrets.nexus-admin-credential.generate.data[1].args.url_safe' yes
    fi
fi
if [[ -z "$(yq r "$c" 'spec.kubernetes.services.cray-nexus.sealedSecrets')" ]]; then
    yq w -i --style=single "$c" 'spec.kubernetes.services.cray-nexus.sealedSecrets[+]' "{{ kubernetes.sealed_secrets['nexus-admin-credential'] | toYaml }}"
fi
# remove cray-keycloak-gatekeeper
yq d -i "$c" 'spec.kubernetes.services.cray-keycloak-gatekeeper'

# Add oauth2-proxies
if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-management')" ]]; then
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-management.generate.name' 'cray-oauth2-proxy-customer-management'
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-management.generate.data[0].type' randstr
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-management.generate.data[0].args.name' cookie-secret
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-management.generate.data[0].args.length' 32
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-management.generate.data[0].args.encoding' base64
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-management.generate.data[0].args.url_safe' yes
fi

if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-access')" ]]; then
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-access.generate.name' 'cray-oauth2-proxy-customer-access'
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-access.generate.data[0].type' randstr
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-access.generate.data[0].args.name' cookie-secret
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-access.generate.data[0].args.length' 32
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-access.generate.data[0].args.encoding' base64
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-access.generate.data[0].args.url_safe' yes
fi

if [[ -z "$(yq r "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-high-speed')" ]]; then
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-high-speed.generate.name' 'cray-oauth2-proxy-customer-high-speed'
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-high-speed.generate.data[0].type' randstr
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-high-speed.generate.data[0].args.name' cookie-secret
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-high-speed.generate.data[0].args.length' 32
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-high-speed.generate.data[0].args.encoding' base64
    yq w -i "$c" 'spec.kubernetes.sealed_secrets.cray-oauth2-proxy-customer-high-speed.generate.data[0].args.url_safe' yes
fi

yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-management.sealedSecrets[0]'  "{{ kubernetes.sealed_secrets['cray-oauth2-proxy-customer-management'] | toYaml }}"
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-management.hostAliases[0].ip' '{{ network.netstaticips.nmn_api_gw }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-management.hostAliases[0].hostnames[0]' 'auth.cmn.{{ network.dns.external }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-management.hosts' '{{ proxiedWebAppExternalHostnames.customerManagement }}'

yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-access.sealedSecrets[0]' "{{ kubernetes.sealed_secrets['cray-oauth2-proxy-customer-access'] | toYaml }}"
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-access.hostAliases[0].ip' '{{ network.netstaticips.nmn_api_gw }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-access.hostAliases[0].hostnames[0]' 'auth.cmn.{{ network.dns.external }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-access.hosts' '{{ proxiedWebAppExternalHostnames.customerAccess }}'

yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-high-speed.sealedSecrets[0]' "{{ kubernetes.sealed_secrets['cray-oauth2-proxy-customer-high-speed'] | toYaml }}"
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-high-speed.hostAliases[0].ip' '{{ network.netstaticips.nmn_api_gw }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-high-speed.hostAliases[0].hostnames[0]' 'auth.cmn.{{ network.dns.external }}'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-oauth2-proxies.customer-high-speed.hosts' '{{ proxiedWebAppExternalHostnames.customerHighSpeed }}'

# cray-kiali
yq w -i "$c" 'spec.kubernetes.services.cray-kiali.externalAuthority' 'kiali-istio.cmn.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.cray-kiali.kiali-operator.cr.spec.external_services.grafana.url' "https://{{ kubernetes.services['cray-sysmgmt-health']['prometheus-operator'].grafana.externalAuthority}}"
yq w -i "$c" 'spec.kubernetes.services.cray-kiali.kiali-operator.cr.spec.external_services.tracing.url' "https://{{ kubernetes.services['cray-istio'].istio.tracing.externalAuthority}}"

# cray-uas-mgr changes
yq w -i "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.require_bican' 'false'
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-uas-mgr.uasConfig.dns_domain' '{{ network.dns.external }}'

# cray-metallb
yq w -i --style=single "$c" 'spec.kubernetes.services.cray-metallb.metallb.configInline' '{{ network.metallb | toYaml }}'

# wlm.macvlan
yq w -i "$c" 'spec.wlm.macvlansetup.nmn_vlan' 'bond0.nmn0'
yq w -i "$c" 'spec.kubernetes.services.cray-slurmctld.macvlan.master' '{{ wlm.macvlansetup.nmn_vlan }}'
yq w -i "$c" 'spec.kubernetes.services.cray-slurmdbd.macvlan.master' '{{ wlm.macvlansetup.nmn_vlan }}'
yq w -i "$c" 'spec.kubernetes.services.cray-pbs.macvlan.master' '{{ wlm.macvlansetup.nmn_vlan }}'

# lower cpu request for tds systems (3 workers)
num_workers=$(kubectl get nodes | grep ncn-w | wc -l)
if [ $num_workers -le 3 ]; then
  yq m -i --overwrite "$c" ${basedirLoc}/../tds_cpu_requests.yaml
fi

if [[ "$inplace" == "yes" ]]; then
    cp "$c" "$customizations"
else
    cat "$c"
fi

