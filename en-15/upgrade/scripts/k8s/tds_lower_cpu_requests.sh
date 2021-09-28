#!/bin/bash
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

function fail_if_empty() {
  key=$1
  value=$2
  if [ -z $value ]; then
    echo "ERROR: Unable to retrieve value for:"
    echo "       $key"
    echo "       Ensure the latest docs-csm rpm is installed on this system."
    exit 1
  fi
}

yaml_path="$base.spire.cray-postgresql.sqlCluster.resources.requests.cpu"
spire_postgres_new_request=$(yq r $yaml -pv $yaml_path)
fail_if_empty $yaml_path $spire_postgres_new_request

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

if kubectl get postgresqls -n spire spire-postgres > /dev/null 2>&1; then
  if [ ! -z $spire_postgres_new_request ]; then
    roll_postgres "spire" "spire-postgres" $spire_postgres_new_request
  fi
fi

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
  if [ ! -z $cluster_kafka_new_cpu_request ]; then
    current_req=$(kubectl get kafkas -n sma cluster -o json | jq -r '.spec.kafka.resources.requests.cpu')
    echo "Patching cluster-kafka with new cpu request of $cluster_kafka_new_cpu_request (from $current_req)"
    kubectl patch kafkas cluster -n sma --type=json -p="[{'op' : 'replace', 'path':'/spec/kafka/resources/requests/cpu', 'value' : \"$cluster_kafka_new_cpu_request\" }]"
    sleep 10
    until [[ $(kubectl -n sma get statefulset cluster-kafka -o json | jq -r '.status.updatedReplicas') -eq 3 ]]; do
      echo "Waiting for cluster-kafka cluster to have three updated replicas..."
      sleep 30
    done
    echo ""
  fi

  if [ ! -z $cluster_zookeeper_new_cpu_request ]; then
    current_req=$(kubectl get kafkas -n sma cluster -o json | jq -r '.spec.zookeeper.resources.requests.cpu')
    echo "Patching cluster-zookeeper statefulset with new cpu request of $cluster_zookeeper_new_cpu_request (from $current_req)"
    kubectl patch kafkas cluster -n sma --type=json -p="[{'op' : 'replace', 'path':'/spec/zookeeper/resources/requests/cpu', 'value' : \"$cluster_zookeeper_new_cpu_request\" }]"
    sleep 10
    until [[ $(kubectl -n sma get statefulset cluster-zookeeper -o json | jq -r '.status.updatedReplicas') -eq 3 ]]; do
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

crayMetallbDeployed=$(kubectl get pods -n metallb-system | grep metallb-speaker | wc -l)
if [[ $crayMetallbDeployed -ne 0 ]]; then
  if [ ! -z $cray_metallb_speaker_new_cpu_request ]; then
    current_req=$(kubectl get daemonset metallb-speaker -n metallb-system -o json | jq -r '.spec.template.spec.containers[] | select(.name== "speaker") | .resources.requests.cpu')
    echo "Patching metallb deployment with new cpu request of $cray_metallb_speaker_new_cpu_request (from $current_req)"
    kubectl patch daemonset metallb-speaker -n metallb-system --type=json -p="[{'op' : 'replace', 'path':'/spec/template/spec/containers/0/resources/requests/cpu', 'value' : \"$cray_metallb_speaker_new_cpu_request\" }]"
    kubectl rollout status daemonset -n metallb-system metallb-speaker
    echo ""
  fi
fi
