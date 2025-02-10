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
