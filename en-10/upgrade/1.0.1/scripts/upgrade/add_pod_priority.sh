#!/bin/bash
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


DEPLOYMENTS="\
cray-bss \
cray-keycloak-gatekeeper-ingress \
cray-postgres-operator \
cray-postgres-operator-postgres-operator-ui \
istio-operator \
istio-ingressgateway \
istio-ingressgateway-hmn \
istiod \
spire-jwks \
cray-ipxe \
cray-tftp \
cray-dhcp-kea \
cray-dns-unbound \
nexus \
cray-opa \
cray-smd \
cray-ceph-csi-cephfs-provisioner \
cray-ceph-csi-rbd-provisioner \
"

STATEFULSETS="\
cray-keycloak \
keycloak-postgres \
spire-postgres \
spire-server \
cray-smd-postgres \
"

ETCDCLUSTERS="\
cray-bss-etcd \
"

DAEMONSETS="\
cray-metallb-speaker \
"

cat > /tmp/csm-high-priority-service.yaml <<'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: csm-high-priority-service
value: 1000000
globalDefault: false
description: "This priority class should be used for CSM critical service pods only."
EOF

function wait_for_running_pods() {
  while true; do
    ns=$1
    etcd_cluster=$2
    desired_size=$3
    current_running_num=$(kubectl get po -n $ns | grep $etcd_cluster | grep Running | wc -l)
    if [[ "$desired_size" -eq "$current_running_num" ]]; then
      echo "Found $desired_size running pods in $etcd_cluster etcd cluster"
      while true; do
        operator_num_ready=$(kubectl get etcd $etcd_cluster -n $ns -o jsonpath='{.status.members.ready}' | jq .[] | wc -l)
        if [[ "$desired_size" -eq "$operator_num_ready" ]]; then
          echo "Found $desired_size ready members in $etcd_cluster etcd cluster"
          op_state=$(kubectl get etcd $etcd_cluster -n $ns -o jsonpath='{.status.phase}')
          if [ $op_state == "Running" ]; then
            echo "Found status of $op_state for $etcd_cluster etcd cluster"
            echo "Sleeping for thirty seconds to let the etcd operator reconcile"
            sleep 30
            break
          fi
        fi
        echo "Sleeping for ten seconds waiting for $desired_size ready members and 'Running' state for $etcd_cluster etcd cluster"
        sleep 10
      done
      break
    fi
    echo "Sleeping for ten seconds waiting for $desired_size pods in $etcd_cluster etcd cluster"
    sleep 10
  done
}

# Ensure etcd clusters have three running members before proceeding
for etcdcluster in $ETCDCLUSTERS; do
  ns=$(kubectl get etcdcluster -A | grep " $etcdcluster " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    wait_for_running_pods $ns $etcdcluster 3
  fi
done

function restart_etcd_pods() {
  ns=$1
  etcd_cluster=$2
  num_pods=$(kubectl get etcd $etcd_cluster -n $ns -o jsonpath='{.status.size}')
  member_list=$(kubectl get etcd $etcd_cluster -n $ns -o jsonpath='{.status.members.ready}')
  pods=$(echo "$member_list" | sed 's/,//g; s/"/ /g; s/\]//g; s/\[//g')
  stringarray=($pods)
  for pod in "${stringarray[@]}"; do
    kubectl delete pod -n $ns $pod
    wait_for_running_pods $ns $etcd_cluster $num_pods
  done
}

echo "Creating csm-high-priority-service pod priority class"
kubectl apply -f /tmp/csm-high-priority-service.yaml
echo ""

for deployment in $DEPLOYMENTS; do
  ns=$(kubectl get deployment -A | grep " $deployment " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    echo "Patching $deployment deployment in $ns namespace"
    kubectl -n $ns patch deployment $deployment --type merge -p '{"spec": {"template": {"spec": {"priorityClassName": "csm-high-priority-service"}}}}'
    kubectl rollout status deployment -n $ns $deployment
    echo ""
  fi
done

for daemonset in $DAEMONSETS; do
  ns=$(kubectl get daemonset -A | grep " $daemonset " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    echo "Patching $daemonset daemonset in $ns namespace"
    kubectl -n $ns patch daemonset $daemonset --type merge -p '{"spec": {"template": {"spec": {"priorityClassName": "csm-high-priority-service"}}}}'
    kubectl rollout status daemonset -n $ns $daemonset
    echo ""
  fi
done

for statefulset in $STATEFULSETS; do
  ns=$(kubectl get statefulset -A | grep " $statefulset " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    echo "Patching $statefulset statefulset in $ns namespace"
    kubectl -n $ns patch statefulset $statefulset --type merge -p '{"spec": {"template": {"spec": {"priorityClassName": "csm-high-priority-service"}}}}'
    kubectl rollout status statefulset -n $ns $statefulset
    echo ""
  fi
done

echo "Creating a backup of cray-bss etcdcluster prior to restarting the cluster"
kubectl exec -it -n operators $(kubectl get pod -n operators -l app.kubernetes.io/name=cray-etcd-backup -o jsonpath='{.items[0].metadata.name}') -c util -- create_backup cray-bss pod-priority-backup-$(date "+%D-%T") | grep -v 'unknown operand'

for etcdcluster in $ETCDCLUSTERS; do
  ns=$(kubectl get etcdcluster -A | grep " $etcdcluster " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    echo "Patching $etcdcluster etcdcluster in $ns namespace"
    kubectl -n $ns patch etcdcluster $etcdcluster --type merge -p '{"spec": {"pod": {"priorityClassName": "csm-high-priority-service"}}}'
    echo ""
    restart_etcd_pods $ns $etcdcluster
    echo ""
  fi
done
