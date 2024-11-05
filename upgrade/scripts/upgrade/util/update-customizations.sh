#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

# cray-opa
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-hmn.issuers.shasta-hmn' 'https://api.hmnlb.{{ network.dns.external }}/keycloak/realms/shasta'
yq w -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway-hmn.issuers.keycloak-hmn' 'https://auth.hmnlb.{{ network.dns.external }}/keycloak/realms/shasta'
yq d -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway.issuers.shasta-cmn'
yq d -i "$c" 'spec.kubernetes.services.cray-opa.ingresses.ingressgateway.issuers.keycloak-cmn'

# cray-spire
if [[ "$(yq r "$c" "spec.kubernetes.services.spire.server.tokenService.enableXNameWorkloads")" == "true" ]]; then
  yq w -i "$c" 'spec.kubernetes.services.cray-spire.server.tokenService.enableXNameWorkloads' 'true'
fi

# cray-vault
yq4 eval '.spec.kubernetes.services.cray-vault.ingress.host = "vault.cmn.{{ network.dns.external }}"' -i "$c"

# cray-istio
yq w -i "$c" 'spec.kubernetes.services.cray-istio.services.istio-ingressgateway-hmn.serviceAnnotations.[external-dns.alpha.kubernetes.io/hostname]' 'api.hmnlb.{{ network.dns.external }},auth.hmnlb.{{ network.dns.external }},hmcollector.hmnlb.{{ network.dns.external }}'
yq w -i "$c" 'spec.kubernetes.services.cray-istio.certificate.dnsNames[+]' 'istio-ingressgateway-cmn.istio-system.svc.cluster.local'
yq4 eval '.spec.kubernetes.services.cray-istio.services.istio-ingressgateway-cmn.serviceAnnotations."external-dns.alpha.kubernetes.io/hostname" += ",vault.cmn.{{ network.dns.external }}"' -i "$c"

# cray-keycloak
if [[ -n "$(yq r "$c" "spec.kubernetes.services.cray-keycloak.keycloak.keycloak")" ]]; then
  yq r "$c" 'spec.kubernetes.services.cray-keycloak.keycloak.keycloak' | yq p - 'spec.kubernetes.services.cray-keycloak.keycloak' | yq m -i "$c" -
  yq d -i "$c" 'spec.kubernetes.services.cray-keycloak.keycloak.keycloak'
  if [[ -n "$(yq r "$c" "spec.kubernetes.services.cray-keycloak.keycloak.basepath")" ]]; then
    yq w -i "$c" 'spec.kubernetes.services.cray-keycloak.keycloak.contextPath' "$(yq r "$c" 'spec.kubernetes.services.cray-keycloak.keycloak.basepath')"
    yq d -i "$c" 'spec.kubernetes.services.cray-keycloak.keycloak.basepath'
  fi
fi
if [[ -n "$(yq r "$c" "spec.kubernetes.services.cray-keycloak.keycloak")" ]]; then
  yq r "$c" 'spec.kubernetes.services.cray-keycloak.keycloak' | yq p - 'spec.kubernetes.services.cray-keycloak.keycloakx' | yq m -i "$c" -
  yq d -i "$c" 'spec.kubernetes.services.cray-keycloak.keycloak'
  if [[ -n "$(yq r "$c" "spec.kubernetes.services.cray-keycloak.keycloakx.contextPath")" ]]; then
    yq w -i "$c" 'spec.kubernetes.services.cray-keycloak.keycloakx.http.relativePath' "$(yq r "$c" 'spec.kubernetes.services.cray-keycloak.keycloak.contextPath')"
    yq d -i "$c" 'spec.kubernetes.services.cray-keycloak.keycloakx.contextPath'
  fi
fi

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
    loop_idx=$((loop_idx + 1))
  done
  yq w -i --style=single "$c" spec.kubernetes.services.cray-sysmgmt-health.cephExporter.endpoints '{{ network.netstaticips.nmn_ncn_storage_mons }}'
fi

# Disable prometheus-snmp-exporter servicemonitor
yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.prometheus-snmp-exporter.serviceMonitor.enabled = false' -i $c

# victoria-metrics-k8s-stack
if [ "$(yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.kube-prometheus-stack' $c)" != null ]; then
  if [ "$(yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack' $c)" != null ]; then
    yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack = (.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack * .spec.kubernetes.services.cray-sysmgmt-health.kube-prometheus-stack)' -i $c
  fi
  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].vmselect.vmselectSpec.externalAuthority }}\"" -i $c
  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].vmagent.vmagentSpec.externalAuthority }}\"" -i $c
  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].alertmanager.externalAuthority }}\"" -i $c
  yq4 eval ".spec.proxiedWebAppExternalHostnames.customerManagement += \"{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].grafana.externalAuthority }}\"" -i $c
  yq4 eval 'del(.spec.proxiedWebAppExternalHostnames.customerManagement.[] | select(. == "*kube-prometheus-stack*"))' -i $c
  yq4 eval ".spec.kubernetes.services.cray-kiali.kiali-operator.cr.spec.external_services.grafana.url = \"https://{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].grafana.externalAuthority }}/\"" -i $c
  yq4 eval ".spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack = .spec.kubernetes.services.cray-sysmgmt-health.kube-prometheus-stack | del(.spec.kubernetes.services.cray-sysmgmt-health.kube-prometheus-stack)" -i $c
  yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.vmagent.vmagentSpec.externalAuthority = "vmagent.cmn.{{ network.dns.external }}"' -i $c
  yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.vmselect.vmselectSpec.externalAuthority = "vmselect.cmn.{{ network.dns.external }}"' -i $c
  yq4 eval '.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.alertmanager.externalAuthority = "alertmanager.cmn.{{ network.dns.external }}"' -i $c
  yq4 eval ".spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.vmagent.vmagentSpec.externalUrl = \"https://{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].vmagent.vmagentSpec.externalAuthority }}/\"" -i $c
  yq4 eval ".spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.vmselect.vmselectSpec.externalUrl = \"https://{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].vmselect.vmselectSpec.externalAuthority }}/\"" -i $c
  yq4 eval ".spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.alertmanager.externalUrl = \"https://{{ kubernetes.services['cray-sysmgmt-health']['victoria-metrics-k8s-stack'].alertmanager.externalAuthority }}/\"" -i $c
  yq4 'del(.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.alertmanager.alertmanagerSpec)' -i $c
  yq4 'del(.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.prometheus)' -i $c
  yq4 'del(.spec.kubernetes.services.cray-sysmgmt-health.victoria-metrics-k8s-stack.thanos)' -i $c
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

# Handle REDS removal when upgrading to CSM 1.6
# Remove REDS from customizations.yaml
yq4 -i eval 'del(.spec.kubernetes.services.cray-hms-reds)' "$c"
# Add customizations for cray-hms-discovery for it to get the River credential sealed secret:
yq4 -i eval '.spec.kubernetes.services.cray-hms-discovery.sealedSecrets = ["{{ kubernetes.sealed_secrets.cray_reds_credentials | toYaml }}"]' "$c"

# kyverno-policy did not have configurable customization prior to 1.6. Import kyverno-policy.checkImageSettings from upgrade customizations file during upgrade.
yq4 -i eval ".spec.kubernetes.services[\"kyverno-policy\"].checkImagePolicy += (load(\"${upgrade_customizations}\") | .spec.kubernetes.services[\"kyverno-policy\"].checkImagePolicy)" "$c"

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
