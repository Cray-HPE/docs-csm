#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2025 Hewlett Packard Enterprise Development LP
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

#
# Values to be applied by this script  are taken from:
#
# /usr/share/doc/csm/upgrade/scripts/upgrade/tds_cpu_requests.yaml
#

base="spec.kubernetes.services"
yaml="/usr/share/doc/csm/upgrade/scripts/upgrade/tds_cpu_requests.yaml"

if [ ! -f $yaml ]; then
  echo "ERROR: Unable to find file: $yaml"
  echo "       Ensure the latest docs-csm rpm is installed on this system."
  exit 1
fi

TMP_CUST_YAML=$(mktemp --tmpdir="/tmp" lower.XXXXXX.yaml)
kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d > "${TMP_CUST_YAML}"
cp "${TMP_CUST_YAML}" "${TMP_CUST_YAML}.bak"

function roll_postgres() {
  ns=$1
  cluster=$2
  setting=$3
  current_req=$(kubectl get postgresql -n $ns $cluster -o json | jq -r '.spec.resources.requests.cpu')
  echo "Patching $cluster cluster with new cpu request of $setting (from $current_req)"
  kubectl patch postgresql -n $ns $cluster --type=json -p="[{'op' : 'replace', 'path':'/spec/resources/requests/cpu', 'value' : \"$setting\" }]"
  until [[ $(kubectl get postgresql -n $ns $cluster -o json | jq -r '.status.PostgresClusterStatus') == "Running" ]]; do
    echo "Waiting for $cluster cluster to reach running state..."
    sleep 30
  done
  echo ""
}

function update_customizations() {
  key=$1
  value=$2
  yq write -i $TMP_CUST_YAML $key $value
}

function fail_if_empty() {
  key=$1
  value=$2
  if [ -z $value ]; then
    echo "ERROR: Unable to retrieve value for:"
    echo "       $key"
    echo "       Ensure the latest docs-csm rpm is installed on this system."
    exit 1
  else
    update_customizations $key $value
  fi
}

yaml_path="$base.cray-spire.cray-postgresql.sqlCluster.resources.requests.cpu"
cray_spire_postgres_new_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_spire_postgres_new_request

yaml_path="$base.cray-dhcp-kea.cray-postgresql.sqlCluster.resources.requests.cpu"
cray_dhcp_kea_postgres_new_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_dhcp_kea_postgres_new_request

yaml_path="$base.cray-hms-capmc.cray-service.containers.cray-capmc.resources.requests.cpu"
cray_capmc_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_capmc_new_cpu_request

yaml_path="$base.sma-elasticsearch.resources.requests.cpu"
elasticsearch_master_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $elasticsearch_master_new_cpu_request

yaml_path="$base.sma-zk-kafka.kafkaReqCPU"
cluster_kafka_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cluster_kafka_new_cpu_request

yaml_path="$base.sma-grafana.cray-service.containers.sma-grafana.resources.requests.cpu"
sma_grafana_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $sma_grafana_new_cpu_request

yaml_path="$base.sma-kibana.cray-service.containers.sma-kibana.resources.requests.cpu"
sma_kibana_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $sma_kibana_new_cpu_request

yaml_path="$base.sma-zk-kafka.zkReqCPU"
cluster_zookeeper_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cluster_zookeeper_new_cpu_request

yaml_path="$base.cray-hms-smd.cray-service.containers.cray-smd.resources.requests.cpu"
cray_smd_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_smd_new_cpu_request

yaml_path="$base.cray-hms-smd.cray-postgresql.sqlCluster.resources.requests.cpu"
cray_smd_postgres_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_smd_postgres_new_cpu_request

yaml_path="$base.sma-postgres-cluster.pgReqCPU"
sma_postgres_cluster_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $sma_postgres_cluster_new_cpu_request

yaml_path="$base.cray-nexus.sonatype-nexus.nexus.resources.requests.cpu"
nexus_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $nexus_new_cpu_request

yaml_path="$base.cray-metallb.metallb.speaker.resources.requests.cpu"
cray_metallb_speaker_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_metallb_speaker_new_cpu_request

yaml_path="$base.cray-metallb.metallb.controller.resources.requests.cpu"
cray_metallb_controller_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_metallb_controller_new_cpu_request

yaml_path="$base.cray-istio-ingress.deployments.istio-ingressgateway.resources.requests.cpu"
cray_istio_ingressgateway_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_istio_ingressgateway_new_cpu_request

yaml_path="$base.cray-istio-ingress.deployments.istio-ingressgateway-customer-admin.resources.requests.cpu"
cray_istio_admin_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_istio_admin_new_cpu_request

yaml_path="$base.cray-istio-ingress.deployments.istio-ingressgateway-customer-user.resources.requests.cpu"
cray_istio_user_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_istio_user_new_cpu_request

yaml_path="$base.cray-istio-ingress.deployments.istio-ingressgateway-hmn.resources.requests.cpu"
cray_istio_hmn_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_istio_hmn_new_cpu_request

yaml_path="$base.cray-keycloak.keycloak.resources.requests.cpu"
cray_keycloak_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_keycloak_new_cpu_request

yaml_path="$base.cray-kyverno.kyverno.admissionController.container.resources.requests.cpu"
cray_kyverno_admission_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_kyverno_admission_new_cpu_request

yaml_path="$base.cray-kyverno.kyverno.reportsController.resources.requests.cpu"
cray_kyverno_reports_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_kyverno_reports_new_cpu_request

yaml_path="$base.cray-kyverno.kyverno.cleanupController.resources.requests.cpu"
cray_kyverno_cleanup_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_kyverno_cleanup_new_cpu_request

yaml_path="$base.cray-kyverno.kyverno.backgroundController.resources.requests.cpu"
cray_kyverno_background_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_kyverno_background_new_cpu_request

yaml_path="$base.cray-opa.opa.resources.requests.cpu"
cray_opa_new_cpu_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $cray_opa_new_cpu_request

if kubectl get postgresqls -n spire cray-spire-postgres > /dev/null 2>&1; then
  if [ ! -z $cray_spire_postgres_new_request ]; then
    roll_postgres "spire" "cray-spire-postgres" $cray_spire_postgres_new_request
  fi
fi

if kubectl get postgresqls -n services cray-dhcp-kea-postgres > /dev/null 2>&1; then
  if [ ! -z $cray_dhcp_kea_postgres_new_request ]; then
    roll_postgres "services" "cray-dhcp-kea-postgres" $cray_dhcp_kea_postgres_new_request
  fi
fi

if kubectl get postgresqls -n services cray-smd-postgres > /dev/null 2>&1; then
  if [ ! -z $cray_smd_postgres_new_cpu_request ]; then
    roll_postgres "services" "cray-smd-postgres" $cray_smd_postgres_new_cpu_request
  fi
fi

if [ ! -z $cray_smd_new_cpu_request ]; then
  current_req=$(kubectl get deployment -n services cray-smd -o json | jq -r '.spec.template.spec.containers[] | select(.name== "cray-smd") | .resources.requests.cpu')
  echo "Patching cray-smd deployment with new cpu request of $cray_smd_new_cpu_request (from $current_req)"
  kubectl patch deployment cray-smd -n services --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_smd_new_cpu_request\" }]"
  kubectl rollout status deployment -n services cray-smd
  echo ""
fi

if [ ! -z $cray_capmc_new_cpu_request ]; then
  current_req=$(kubectl get deployment -n services cray-capmc -o json | jq -r '.spec.template.spec.containers[] | select(.name== "cray-capmc") | .resources.requests.cpu')
  echo "Patching cray-capmc deployment with new cpu request of $cray_capmc_new_cpu_request (from $current_req)"
  kubectl patch deployment cray-capmc -n services --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_capmc_new_cpu_request\" }]"
  kubectl rollout status deployment -n services cray-capmc
  echo ""
fi

esDeployed=$(kubectl get pods -A | grep elasticsearch-master | wc -l)
if [[ $esDeployed -ne 0 ]]; then
  if [ ! -z $elasticsearch_master_new_cpu_request ]; then
    current_req=$(kubectl get statefulset elasticsearch-master -n sma -o json | jq -r '.spec.template.spec.containers[] | select(.name== "sma-elasticsearch") | .resources.requests.cpu')
    echo "Patching elasticsearch-master statefulset with new cpu request of $elasticsearch_master_new_cpu_request (from $current_req)"
    kubectl patch statefulset elasticsearch-master -n sma --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$elasticsearch_master_new_cpu_request\" }]"
    kubectl rollout status statefulset -n sma elasticsearch-master
    echo ""
  fi
fi

smaGrafanaDeployed=$(kubectl get pods -n services | grep sma-grafana | wc -l)
if [[ $smaGrafanaDeployed -ne 0 ]]; then
  if [ ! -z $sma_grafana_new_cpu_request ]; then
    current_req=$(kubectl get deployment sma-grafana -n services -o json | jq -r '.spec.template.spec.containers[] | select(.name== "sma-grafana") | .resources.requests.cpu')
    echo "Patching sma-grafana deployment with new cpu request of $sma_grafana_new_cpu_request (from $current_req)"
    kubectl patch deployment sma-grafana -n services --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$sma_grafana_new_cpu_request\" }]"
    kubectl rollout status deployment -n services sma-grafana
    echo ""
  fi
fi

smaKibanaDeployed=$(kubectl get pods -n services | grep sma-kibana | wc -l)
if [[ $smaKibanaDeployed -ne 0 ]]; then
  if [ ! -z $sma_kibana_new_cpu_request ]; then
    current_req=$(kubectl get deployment sma-kibana -n services -o json | jq -r '.spec.template.spec.containers[] | select(.name== "sma-kibana") | .resources.requests.cpu')
    echo "Patching sma-kibana deployment with new cpu request of $sma_kibana_new_cpu_request (from $current_req)"
    kubectl patch deployment sma-kibana -n services --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$sma_kibana_new_cpu_request\" }]"
    kubectl rollout status deployment -n services sma-kibana
    echo ""
  fi
fi

kafkaDeployed=$(kubectl get pods -n sma | grep kafka | wc -l)
if [[ $kafkaDeployed -ne 0 ]]; then

  # For sma 1.9, the cluster-kafka and cluster-zookeeper resources are based on a statefulset.
  # For sma 1.10, the cluster-kafka and cluster-zookeeper resources are based on the strimzipodset.
  if kubectl get statefulset cluster-kafka -n sma > /dev/null 2>&1; then
    resource='statefulset'
    status='.status.updatedReplicas'
  else
    resource='strimzipodset'
    status='.status.readyPods'
  fi

  if [ ! -z $cluster_kafka_new_cpu_request ]; then
    current_req=$(kubectl get kafkas -n sma cluster -o json | jq -r '.spec.kafka.resources.requests.cpu')
    echo "Patching cluster-kafka with new cpu request of $cluster_kafka_new_cpu_request (from $current_req)"
    kubectl patch kafkas cluster -n sma --type=json -p="[{'op' : 'replace', 'path':'/spec/kafka/resources/requests/cpu', 'value' : \"$cluster_kafka_new_cpu_request\" }]"
    sleep 10
    until [[ $(kubectl -n sma get "${resource}" cluster-kafka -o json | jq --arg status $status -r "$status") -eq 3 ]]; do
      echo "Waiting for cluster-kafka cluster to have three updated replicas..."
      sleep 30
    done
    echo ""
  fi

  if [ ! -z $cluster_zookeeper_new_cpu_request ]; then
    current_req=$(kubectl get kafkas -n sma cluster -o json | jq -r '.spec.zookeeper.resources.requests.cpu')
    echo "Patching cluster-zookeeper with new cpu request of $cluster_zookeeper_new_cpu_request (from $current_req)"
    kubectl patch kafkas cluster -n sma --type=json -p="[{'op' : 'replace', 'path':'/spec/zookeeper/resources/requests/cpu', 'value' : \"$cluster_zookeeper_new_cpu_request\" }]"
    sleep 10
    until [[ $(kubectl -n sma get "${resource}" cluster-zookeeper -o json | jq --arg status $status -r "$status") -eq 3 ]]; do
      echo "Waiting for cluster-zookeeper cluster to have three updated replicas..."
      sleep 30
    done
    echo ""
  fi
fi

smaPgDeployed=$(kubectl get pods -n sma | grep sma-postgres-cluster | wc -l)
if [[ $smaPgDeployed -ne 0 ]]; then
  if [ ! -z $sma_postgres_cluster_new_cpu_request ]; then
    roll_postgres "sma" "sma-postgres-cluster" $sma_postgres_cluster_new_cpu_request
  fi
fi

if [ ! -z $nexus_new_cpu_request ]; then
  current_req=$(kubectl get deployment -n nexus nexus -o json | jq -r '.spec.template.spec.containers[] | select(.name== "nexus") | .resources.requests.cpu')
  echo "Patching nexus deployment with new cpu request of $nexus_new_cpu_request (from $current_req)"
  kubectl patch deployment nexus -n nexus --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$nexus_new_cpu_request\" }]"
  kubectl rollout status deployment -n nexus nexus
  echo ""
fi

crayMetallbSpeakerDeployed=$(kubectl get pods -n metallb-system | grep metallb-speaker | wc -l)
if [[ $crayMetallbSpeakerDeployed -ne 0 ]]; then
  if [ ! -z $cray_metallb_speaker_new_cpu_request ]; then
    current_req=$(kubectl get daemonset metallb-speaker -n metallb-system -o json | jq -r '.spec.template.spec.containers[] | select(.name== "speaker") | .resources.requests.cpu')
    echo "Patching metallb-speaker daemonset with new cpu request of $cray_metallb_speaker_new_cpu_request (from $current_req)"
    kubectl patch daemonset metallb-speaker -n metallb-system --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_metallb_speaker_new_cpu_request\" }]"
    kubectl rollout status daemonset -n metallb-system metallb-speaker
    echo ""
  fi
fi

crayMetallbControllerDeployed=$(kubectl get pods -n metallb-system | grep metallb-controller | wc -l)
if [[ $crayMetallbControllerDeployed -ne 0 ]]; then
  if [ ! -z $cray_metallb_controller_new_cpu_request ]; then
    current_req=$(kubectl get deployment metallb-controller -n metallb-system -o json | jq -r '.spec.template.spec.containers[] | select(.name== "controller") | .resources.requests.cpu')
    echo "Patching metallb-controller deployment with new cpu request of $cray_metallb_controller_new_cpu_request (from $current_req)"
    kubectl patch deployment metallb-controller -n metallb-system --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_metallb_controller_new_cpu_request\" }]"
    kubectl rollout status deployment -n metallb-system metallb-controller
    echo ""
  fi
fi

crayIstioIngressDeployed=$(kubectl get pods -n istio-system | grep istio-ingressgateway | wc -l)
if [[ $crayIstioIngressDeployed -ne 0 ]]; then
  if [ ! -z $cray_istio_ingressgateway_new_cpu_request ]; then
    current_req=$(kubectl get deployment istio-ingressgateway -n istio-system -o json | jq -r '.spec.template.spec.containers[] | select(.name== "istio-proxy") | .resources.requests.cpu')
    echo "Patching istio-ingressgateway deployment with new cpu request of $cray_istio_ingressgateway_new_cpu_request (from $current_req)"
    kubectl patch deployment istio-ingressgateway -n istio-system --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_istio_ingressgateway_new_cpu_request\" }]"
    kubectl rollout status deployment -n istio-system istio-ingressgateway
    echo ""
  fi
fi

crayIstioAdminDeployed=$(kubectl get pods -n istio-system | grep istio-ingressgateway-customer-admin | wc -l)
if [[ $crayIstioAdminDeployed -ne 0 ]]; then
  if [ ! -z $cray_istio_admin_new_cpu_request ]; then
    current_req=$(kubectl get deployment istio-ingressgateway-customer-admin -n istio-system -o json | jq -r '.spec.template.spec.containers[] | select(.name== "istio-proxy") | .resources.requests.cpu')
    echo "Patching istio-ingressgateway deployment with new cpu request of $cray_istio_admin_new_cpu_request (from $current_req)"
    kubectl patch deployment istio-ingressgateway-customer-admin -n istio-system --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_istio_admin_new_cpu_request\" }]"
    kubectl rollout status deployment -n istio-system istio-ingressgateway-customer-admin
    echo ""
  fi
fi

crayIstioUserDeployed=$(kubectl get pods -n istio-system | grep istio-ingressgateway-customer-user | wc -l)
if [[ $crayIstioUserDeployed -ne 0 ]]; then
  if [ ! -z $cray_istio_user_new_cpu_request ]; then
    current_req=$(kubectl get deployment istio-ingressgateway-customer-user -n istio-system -o json | jq -r '.spec.template.spec.containers[] | select(.name== "istio-proxy") | .resources.requests.cpu')
    echo "Patching istio-ingressgateway-customer-user deployment with new cpu request of $cray_istio_user_new_cpu_request (from $current_req)"
    kubectl patch deployment istio-ingressgateway-customer-user -n istio-system --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_istio_user_new_cpu_request\" }]"
    kubectl rollout status deployment -n istio-system istio-ingressgateway-customer-user
    echo ""
  fi
fi

crayIstioHmnDeployed=$(kubectl get pods -n istio-system | grep istio-ingressgateway-hmn | wc -l)
if [[ $crayIstioHmnDeployed -ne 0 ]]; then
  if [ ! -z $cray_istio_hmn_new_cpu_request ]; then
    current_req=$(kubectl get deployment istio-ingressgateway-hmn -n istio-system -o json | jq -r '.spec.template.spec.containers[] | select(.name== "istio-proxy") | .resources.requests.cpu')
    echo "Patching istio-ingressgateway-hmn deployment with new cpu request of $cray_istio_hmn_new_cpu_request (from $current_req)"
    kubectl patch deployment istio-ingressgateway-hmn -n istio-system --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_istio_hmn_new_cpu_request\" }]"
    kubectl rollout status deployment -n istio-system istio-ingressgateway-hmn
    echo ""
  fi
fi

if [ ! -z $cray_keycloak_new_cpu_request ]; then
  current_req=$(kubectl get statefulset -n services cray-keycloak -o json | jq -r '.spec.template.spec.containers[] | select(.name== "keycloak") | .resources.requests.cpu')
  echo "Patching cray-keycloak statefulset with new cpu request of $cray_keycloak_new_cpu_request (from $current_req)"
  kubectl patch statefulset cray-keycloak -n services --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_keycloak_new_cpu_request\" }]"
  kubectl rollout status statefulset -n services cray-keycloak
  echo ""
fi

crayKyvernoAdmissionDeployed=$(kubectl get pods -n kyverno | grep kyverno-admission-controller | wc -l)
if [[ $crayKyvernoAdmissionDeployed -ne 0 ]]; then
  if [ ! -z $cray_kyverno_admission_new_cpu_request ]; then
    current_req=$(kubectl get deployment kyverno-admission-controller -n kyverno -o json | jq -r '.spec.template.spec.containers[] | select(.name== "kyverno") | .resources.requests.cpu')
    echo "Patching kyverno-admission-controller deployment with new cpu request of $cray_kyverno_admission_new_cpu_request (from $current_req)"
    kubectl patch deployment kyverno-admission-controller -n kyverno --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_kyverno_admission_new_cpu_request\" }]"
    kubectl rollout status deployment -n kyverno kyverno-admission-controller
    echo ""
  fi
fi

crayKyvernoReportsDeployed=$(kubectl get pods -n kyverno | grep kyverno-reports-controller | wc -l)
if [[ $crayKyvernoReportsDeployed -ne 0 ]]; then
  if [ ! -z $cray_kyverno_reports_new_cpu_request ]; then
    current_req=$(kubectl get deployment kyverno-reports-controller -n kyverno -o json | jq -r '.spec.template.spec.containers[] | select(.name== "controller") | .resources.requests.cpu')
    echo "Patching kyverno-reports-controller deployment with new cpu request of $cray_kyverno_reports_new_cpu_request (from $current_req)"
    kubectl patch deployment kyverno-reports-controller -n kyverno --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_kyverno_reports_new_cpu_request\" }]"
    kubectl rollout status deployment -n kyverno kyverno-reports-controller
    echo ""
  fi
fi

crayKyvernoCleanupDeployed=$(kubectl get pods -n kyverno | grep kyverno-cleanup-controller | wc -l)
if [[ $crayKyvernoCleanupDeployed -ne 0 ]]; then
  if [ ! -z $cray_kyverno_cleanup_new_cpu_request ]; then
    current_req=$(kubectl get deployment kyverno-cleanup-controller -n kyverno -o json | jq -r '.spec.template.spec.containers[] | select(.name== "controller") | .resources.requests.cpu')
    echo "Patching kyverno-cleanup-controller deployment with new cpu request of $cray_kyverno_cleanup_new_cpu_request (from $current_req)"
    kubectl patch deployment kyverno-cleanup-controller -n kyverno --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_kyverno_cleanup_new_cpu_request\" }]"
    kubectl rollout status deployment -n kyverno kyverno-cleanup-controller
    echo ""
  fi
fi

crayKyvernoBackgroundDeployed=$(kubectl get pods -n kyverno | grep kyverno-background-controller | wc -l)
if [[ $crayKyvernoBackgroundDeployed -ne 0 ]]; then
  if [ ! -z $cray_kyverno_background_new_cpu_request ]; then
    current_req=$(kubectl get deployment kyverno-background-controller -n kyverno -o json | jq -r '.spec.template.spec.containers[] | select(.name== "controller") | .resources.requests.cpu')
    echo "Patching kyverno-background-controller deployment with new cpu request of $cray_kyverno_background_new_cpu_request (from $current_req)"
    kubectl patch deployment kyverno-background-controller -n kyverno --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_kyverno_background_new_cpu_request\" }]"
    kubectl rollout status deployment -n kyverno kyverno-background-controller
    echo ""
  fi
fi

crayOpaIngressDeployed=$(kubectl get pods -n opa | grep opa-ingressgateway | wc -l)
if [[ $crayOpaIngressDeployed -ne 0 ]]; then
  if [ ! -z $cray_opa_new_cpu_request ]; then
    current_req=$(kubectl get daemonset cray-opa-ingressgateway -n opa -o json | jq -r '.spec.template.spec.containers[] | select(.name== "opa-istio") | .resources.requests.cpu')
    echo "Patching cray-opa-ingressgateway daemonset with new cpu request of $cray_opa_new_cpu_request (from $current_req)"
    kubectl patch daemonset cray-opa-ingressgateway -n opa --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_opa_new_cpu_request\" }]"
    kubectl rollout status daemonset -n opa cray-opa-ingressgateway
    echo ""
  fi
fi

crayOpaAdminDeployed=$(kubectl get pods -n opa | grep opa-ingressgateway-customer-admin | wc -l)
if [[ $crayOpaAdminDeployed -ne 0 ]]; then
  if [ ! -z $cray_opa_new_cpu_request ]; then
    current_req=$(kubectl get daemonset cray-opa-ingressgateway-customer-admin -n opa -o json | jq -r '.spec.template.spec.containers[] | select(.name== "opa-istio") | .resources.requests.cpu')
    echo "Patching cray-opa-ingressgateway-customer-admin daemonset with new cpu request of $cray_opa_new_cpu_request (from $current_req)"
    kubectl patch daemonset cray-opa-ingressgateway-customer-admin -n opa --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_opa_new_cpu_request\" }]"
    kubectl rollout status daemonset -n opa cray-opa-ingressgateway-customer-admin
    echo ""
  fi
fi

crayOpaUserDeployed=$(kubectl get pods -n opa | grep opa-ingressgateway-customer-user | wc -l)
if [[ $crayOpaUserDeployed -ne 0 ]]; then
  if [ ! -z $cray_opa_new_cpu_request ]; then
    current_req=$(kubectl get daemonset cray-opa-ingressgateway-customer-user -n opa -o json | jq -r '.spec.template.spec.containers[] | select(.name== "opa-istio") | .resources.requests.cpu')
    echo "Patching cray-opa-ingressgateway-customer-user daemonset with new cpu request of $cray_opa_new_cpu_request (from $current_req)"
    kubectl patch daemonset cray-opa-ingressgateway-customer-user -n opa --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_opa_new_cpu_request\" }]"
    kubectl rollout status daemonset -n opa cray-opa-ingressgateway-customer-user
    echo ""
  fi
fi

crayOpaHmnDeployed=$(kubectl get pods -n opa | grep opa-ingressgateway-hmn | wc -l)
if [[ $crayOpaHmnDeployed -ne 0 ]]; then
  if [ ! -z $cray_opa_new_cpu_request ]; then
    current_req=$(kubectl get daemonset cray-opa-ingressgateway-hmn -n opa -o json | jq -r '.spec.template.spec.containers[] | select(.name== "opa-istio") | .resources.requests.cpu')
    echo "Patching cray-opa-ingressgateway-hmn daemonset with new cpu request of $cray_opa_new_cpu_request (from $current_req)"
    kubectl patch daemonset cray-opa-ingressgateway-hmn -n opa --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_opa_new_cpu_request\" }]"
    kubectl rollout status daemonset -n opa cray-opa-ingressgateway-hmn
    echo ""
  fi
fi

# push updated customizations.yaml to k8s
cp ${TMP_CUST_YAML} /tmp/customizations.yaml
echo "Update site-init secret"
kubectl delete secret -n loftsman site-init
kubectl create secret -n loftsman generic site-init --from-file=/tmp/customizations.yaml
