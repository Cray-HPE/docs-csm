#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2024-2025 Hewlett Packard Enterprise Development LP
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
basedirLoc=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
. ${basedirLoc}/../../common/upgrade-state.sh
trap 'err_report' ERR
set -o pipefail

usage() {
  echo >&2 "Update customizations during upgrade, using current customizations (from live system) and"
  echo >&2 "    new customizations (from upgrade tarball). With -i, update CUSTOMIZATIONS-YAML in place."
  echo >&2 "usage: ${0##*/} [-i] CUSTOMIZATIONS-YAML CUSTOMIZATIONS-YAML-FROM-UPGRADE-TARBALL"
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

[[ $# -eq 2 ]] || usage

customizations="$1"
upgrade_customizations="$2"

if [[ ! -f $customizations ]]; then
  echo >&2 "error: no such file: $customizations"
  usage
fi

if ! command -v yq &> /dev/null; then
  echo >&2 "error: yq could not be found"
  exit 1
fi

c="$(mktemp)"
trap 'rm -f $c' EXIT

cp "$customizations" "$c"

# argo/cray-nls
yq w -i --style=single "$c" spec.kubernetes.services.cray-nls.externalHostname 'cmn.{{ network.dns.external }}'

if [[ -z "$(yq r "$c" 'spec.proxiedWebAppExternalHostnames.customerManagement(.==argo.cmn.{{ network.dns.external }})')" ]]; then
  yq w -i --style=single "$c" spec.proxiedWebAppExternalHostnames.customerManagement[+] 'argo.cmn.{{ network.dns.external }}'
fi

# cray-vault
# required in upgrade to CSM 1.7
yq4 eval '.spec.kubernetes.services.cray-vault.ingress.host = "vault.cmn.{{ network.dns.external }}"' -i "$c"

# victoria-metrics-k8s-stack
if [ "$(yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.kube-prometheus-stack' $c)" != null ]; then
  yq4 eval 'del(.spec.kubernetes.services.cray-sysmgmt-health.kube-prometheus-stack)' -i $c
  yq4 eval 'del(.spec.proxiedWebAppExternalHostnames.customerManagement.[] | select(. == "*kube-prometheus-stack*"))' -i $c
  yq4 eval 'del(.spec.proxiedWebAppExternalHostnames.customerManagement.[] | select(. == "*victoria-metrics-k8s-stack*"))' -i $c

  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].vmselect.vmselectSpec.externalAuthority }}\"" -i $c
  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].vmagent.vmagentSpec.externalAuthority }}\"" -i $c
  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].alertmanager.externalAuthority }}\"" -i $c
  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].grafana.externalAuthority }}\"" -i $c
  yq4 eval ".spec.kubernetes.services.cray-kiali.kiali-operator.cr.spec.external_services.grafana.url = \"https://{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].grafana.externalAuthority }}/\"" -i $c
  yq4 -i eval ".spec.kubernetes.services.cray-sysmgmt-health[\"victoria-metrics-k8s-stack\"] += (load(\"${upgrade_customizations}\") | .spec.kubernetes.services.cray-sysmgmt-health[\"victoria-metrics-k8s-stack\"])" "$c"
fi
#sma-vm-cluster
if [ "$(yq4 eval '.spec.kubernetes.services.sma-vm-cluster' $c)" == null ]; then
  yq4 -i eval ".spec.kubernetes.services[\"sma-vm-cluster\"] += (load(\"${upgrade_customizations}\") | .spec.kubernetes.services[\"sma-vm-cluster\"])" "$c"
fi
#sma-pcim
if [ "$(yq4 eval '.spec.kubernetes.services.sma-pcim' $c)" == null ]; then
  yq4 eval '.spec.proxiedWebAppExternalHostnames.customerManagement += [ "sma-pcim.cmn.{{network.dns.external}}" ]' -i $c
  yq4 eval '.spec.kubernetes.services.sma-pcim.externalAuthority = "sma-pcim.cmn.{{ network.dns.external }}"' -i $c
  yq4 eval '.spec.kubernetes.services.sma-pcim.cray-service.containers.sma-pcim.resources.requests.cpu = "1"' -i $c
  yq4 eval '.spec.kubernetes.services.sma-pcim.cray-service.containers.sma-pcim.resources.requests.memory = "2Gi"' -i $c
fi

# When upgrading to CSM 1.5 or later, ensure that we remove obsolete cray-service.sqlCluster entries (CASMPET-6584).
yq4 -i eval 'del(.spec.kubernetes.services.*.cray-service.sqlCluster)' "$c"

# kyverno-policy did not have configurable customization prior to 1.6. Import kyverno-policy.checkImageSettings from upgrade customizations file during upgrade.
yq4 -i eval ".spec.kubernetes.services[\"kyverno-policy\"].checkImagePolicy += (load(\"${upgrade_customizations}\") | .spec.kubernetes.services[\"kyverno-policy\"].checkImagePolicy)" "$c"

# when CSM is getting upgraded from 1.6 to 1.7, the image-verification-policy need to take the values from the new customizations file
if [ "$(yq4 eval '.spec.kubernetes.services."image-verification-policy"' "${upgrade_customizations}")" != "null" ]; then
  yq4 eval -i '
    .spec.kubernetes.services["image-verification-policy"] =
      (load("'"${upgrade_customizations}"'") | .spec.kubernetes.services["image-verification-policy"]) |
    del(.spec.kubernetes.services["kyverno-policy"])
  ' "$c"
fi

# Add entries for Cilium Hubble observability GUI (CASMNET-2194)
yq4 -i eval '.spec.kubernetes.services.["cray-hubble"].externalHostname = "hubble.cmn.{{ network.dns.external }}"' "$c"
yq4 -i eval ".spec.proxiedWebAppExternalHostnames.customerManagement |= (. + [\"{{ kubernetes.services['cray-hubble'].externalHostname }}\"] | unique)" "$c"

# From CSM 1.7, cray-istio is no longer used for ingress, so we need to update the customizations.yaml
# to reflect this change. We will rename cray-istio to cray-istio-ingress and update the
# proxiedWebAppExternalHostnames to use cray-istio-ingress instead of cray-istio.
if [ "$(yq4 eval '.spec.kubernetes.services."cray-istio"' "$c")" != "null" ]; then
  # If the cray-istio-ingress configuration does not exist, copy the cray-istio configuration to cray-istio-ingress
  if [ "$(yq4 eval '.spec.kubernetes.services."cray-istio-ingress"' "$c")" == "null" ]; then
    yq4 eval -i '.spec.kubernetes.services."cray-istio-ingress" = .spec.kubernetes.services."cray-istio"' "$c"
  fi
  # Delete the old cray-istio key
  yq4 eval -i 'del(.spec.kubernetes.services."cray-istio")' "$c"
fi

# Update proxiedWebAppExternalHostnames references from cray-istio to cray-istio-ingress
yq4 eval -i 'del(.spec.proxiedWebAppExternalHostnames.customerManagement.[] | select(. == "*cray-istio*"))' "$c"
yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-istio-ingress'].istio.tracing.externalAuthority }}\"" -i "$c"

metallb_path='.spec.kubernetes.services."cray-metallb".metallb'
config_inline_key='configInline'
config_inline_new_key='configInlineHistorical'

# Remove MetalLB configInline due to this feature being depracated in MetalLB upstream,
# moving value to configInlineHistorical in case is needed to restore old configuration
# information.
if [ "$(yq4 eval "${metallb_path}.${config_inline_key}" "$c")" != "null" ]; then
  # Copy the value from the old key to the new key
  yq4 eval -i "${metallb_path}.${config_inline_new_key} = ${metallb_path}.${config_inline_key}" "$c"
  # Delete the old key
  yq4 eval -i "del(${metallb_path}.${config_inline_key})" "$c"
fi

if yq4 eval '.spec.network.metallb.peers' "$c" &> /dev/null; then

  # 1. Get SLS Authentication Token
  # shellcheck disable=SC2046,SC2155
  export SLS_TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

  # shellcheck disable=SC2166
  if [ -z "${SLS_TOKEN}" -o "${SLS_TOKEN}" == "" -o "${SLS_TOKEN}" == "null" ]; then
    echo >&2 "error: failed to obtain token from keycloak"
    exit 1
  fi

  # 2. Fetch Network Data from SLS
  SLS_NETWORKS_JSON=$(curl -s -k -H "Authorization: Bearer ${SLS_TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/networks)

  # 3. Get the number of peers currently in customizations.yaml
  num_peers=$(yq4 eval '.spec.network.metallb.peers | length' "$c")

  for i in $(seq 0 $((num_peers - 1))); do
    # 4. Get the peer-address for the current peer from the temp file
    current_peer_ip=$(yq4 eval ".spec.network.metallb.peers[$i].\"peer-address\"" "$c")
    [[ -z $current_peer_ip || $current_peer_ip == "null" ]] && continue

    # 5. Search SLS data for the reservation matching the current_peer_ip
    match_info=$(echo "$SLS_NETWORKS_JSON" | jq -c --arg ip "$current_peer_ip" '
            first(
                .[] | select(.ExtraProperties.Subnets) | . as $network |
                .ExtraProperties.Subnets[] | select(.IPReservations and (.Name == "network_hardware" or .Name == "bootstrap_dhcp")) |
                .IPReservations[] | select(.Name? and .IPAddress?) | select(.IPAddress == $ip) |
                {deviceName: .Name, deviceNetwork: ($network.Name | ascii_downcase)}
            )
        ')

    # 6. Extract device name and network
    if [[ -n $match_info ]]; then
      device_name=$(echo "$match_info" | jq -r '.deviceName')
      device_network=$(echo "$match_info" | jq -r '.deviceNetwork')

      # 7. Add the fields for the current peer index in the temp file
      yq4 eval -i ".spec.network.metallb.peers[$i].\"device-name\" = \"${device_name}\"" "$c"
      yq4 eval -i ".spec.network.metallb.peers[$i].\"device-network\" = \"${device_network}\"" "$c"
    fi
  done
fi

# lower cpu request for tds systems (4 workers)
num_workers=$(kubectl get nodes | grep ncn-w | wc -l)
if [ $num_workers -le 4 ]; then
  yq m -i --overwrite "$c" /usr/share/doc/csm/upgrade/scripts/upgrade/tds_cpu_requests.yaml
fi

if [[ $inplace == "yes" ]]; then
  cp "$c" "$customizations"
else
  cat "$c"
fi
