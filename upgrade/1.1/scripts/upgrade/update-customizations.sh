#!/usr/bin/env bash

set -o errexit
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

# Add new generator for the PowerDNS API key Seaaled Secret
yq write -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.name' cray-powerdns-credentials
yq write -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].type' randstr
yq write -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].args.name' pdns_api_key
yq write -i "$c" 'spec.kubernetes.sealed_secrets.powerdns.generate.data[0].args.length' 32

# Delete unused externaldns configuraation
yq delete -i "$c" 'spec.kubernetes.services.cray-externaldns'

yq write -i "$c" 'spec.kubernetes.services.cray-dns-unbound.domain_name' '{{ network.dns.external }}'
yq write -i --style=double "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.master_server' 'master/{{ network.netstaticips.site_to_system_lookups }}'
yq write -i "$c" 'spec.kubernetes.services.cray-powerdns-manager.manager.base_domain' "{{ network.dns.external }}"
yq write -i "$c" 'spec.kubernetes.services.cray-dns-powerdns.service.can.loadBalancerIP' '{{ network.netstaticips.site_to_system_lookups }}'
yq write -i "$c" 'spec.kubernetes.services.cray-dns-powerdns.cray-service.sealedSecrets[0]' '{{ kubernetes.sealed_secrets.powerdns | toYaml }}'

if [[ "$inplace" == "yes" ]]; then
    cp "$c" "$customizations"
else
    cat "$c"
fi