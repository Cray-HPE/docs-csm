#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

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
      break
    fi
    echo "Sleeping for ten seconds waiting for $desired_size pods in $etcd_cluster etcd cluster"
    sleep 10
  done
}

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
    echo ""
  fi
done

for daemonset in $DAEMONSETS; do
  ns=$(kubectl get daemonset -A | grep " $daemonset " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    echo "Patching $daemonset daemonset in $ns namespace"
    kubectl -n $ns patch daemonset $daemonset --type merge -p '{"spec": {"template": {"spec": {"priorityClassName": "csm-high-priority-service"}}}}'
    echo ""
  fi
done

for statefulset in $STATEFULSETS; do
  ns=$(kubectl get statefulset -A | grep " $statefulset " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    echo "Patching $statefulset statefulset in $ns namespace"
    kubectl -n $ns patch statefulset $statefulset --type merge -p '{"spec": {"template": {"spec": {"priorityClassName": "csm-high-priority-service"}}}}'
    echo ""
  fi
done

for etcdcluster in $ETCDCLUSTERS; do
  ns=$(kubectl get etcdcluster -A | grep " $etcdcluster " | awk '{print $1}')
  if [ ! -z "$ns" ]; then
    echo "Patching $etcdcluster etcdcluster in $ns namespace"
    kubectl -n $ns patch etcdcluster $etcdcluster --type merge -p '{"spec": {"template": {"spec": {"priorityClassName": "csm-high-priority-service"}}}}'
    echo ""
    restart_etcd_pods $ns $etcdcluster
    echo ""
  fi
done
