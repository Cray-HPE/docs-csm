#!/bin/bash

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

cat > /tmp/csm-high-priority-service.yaml <<'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: csm-high-priority-service
value: 1000000
globalDefault: false
description: "This priority class should be used for CSM critical service pods only."
EOF

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
  fi
done
