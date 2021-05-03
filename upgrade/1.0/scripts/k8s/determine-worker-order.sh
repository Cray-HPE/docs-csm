#!/bin/bash

all_workers=$(kubectl get nodes | grep ncn-w | awk '{print $1}')
kea_node=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-dhcp-kea' -o wide | grep -v NAME | awk '{print $7}')
kea_pod=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-dhcp-kea' -o wide | grep -v NAME | awk '{print $1}')
nexus_node=$(kubectl get po -n nexus -l 'app=nexus' -o wide | grep -v NAME | awk '{print $7}')
nexus_pod=$(kubectl get po -n nexus -l 'app=nexus' -o wide | grep -v NAME | awk '{print $1}')
conman_node=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-conman' -o wide | grep -v NAME | awk '{print $7}')
conman_pod=$(kubectl get po -n services -l 'app.kubernetes.io/name=cray-conman' -o wide | grep -v NAME | awk '{print $1}')

echo ""
echo "Boot related pod locations:"
echo ""
echo "  kea pod is running on:    $kea_node ($kea_pod)"
echo "  nexus pod is running on:  $nexus_node ($nexus_pod)"
echo "  conman pod is running on: $conman_node ($conman_pod)"
echo ""

found_empty_worker=0
for worker in $all_workers; do
  if [ "$worker" == "$kea_node" ] || [ "$worker" == "$nexus_node" ] || [ "$worker" == "$conman_node" ]; then
    continue
  fi
  echo "NOTE: In order to minimize pod moves, it is recommended to first upgrade"
  echo "      $worker first and move pods to that after it is rebuilt."
  found_empty_worker=1
  break
done

if [ "$found_empty_worker" -eq 0 ]; then
  echo "NOTE: There isn't a worker not running one of the critical services, so choose whatever order you wish."
fi

echo ""
echo "      In order to force a pod to move to a given node, you can use the following script:"
echo ""
echo "      /usr/share/doc/metal/upgrade/1.0/scripts/k8s/move-pod.sh <pod_name> <target_node>"
