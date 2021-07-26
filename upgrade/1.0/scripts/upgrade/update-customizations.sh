#!/usr/bin/env bash

set -e
BASEDIR=$(dirname $0)
. ${BASEDIR}/upgrade-state.sh
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

set -o xtrace

customizations="$1"

if [[ ! -f "$customizations" ]]; then
    echo >&2 "error: no such file: $customizations"
    usage
fi

c="$(mktemp)"
trap "rm -f '$c'" EXIT

cp "$customizations" "$c"

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
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.rsyslogAggregatorHmn.service.loadBalancerIP' '10.94.100.2'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator.volumeClaimTemplate'

yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.service.loadBalancerIP' '10.92.100.75'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.volumeClaimTemplate.storageClassName' 'sma-block-replicated'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.cray-service.volumeClaimTemplate.resources.requests.storage' '16Gi'
yq w -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.rsyslogAggregatorUdpHmn.service.loadBalancerIP' '10.94.100.3'
yq d -i "$c" 'spec.kubernetes.services.sma-rsyslog-aggregator-udp.volumeClaimTemplate'

if [[ "$inplace" == "yes" ]]; then
    cp "$c" "$customizations"
else
    cat "$c"
fi

ok_report