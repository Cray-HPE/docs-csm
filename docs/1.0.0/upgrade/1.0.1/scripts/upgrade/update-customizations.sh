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