#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

pod_name=$1
target_node=$2

if [ "$pod_name" == "" ] ||  [ "$target_node" == "" ]; then
  echo "Usage: $0 <pod_name> <target_node>"
fi

ns=$(kubectl get po -A | grep $pod_name | awk '{print $1}')
all_workers=$(kubectl get nodes | grep ncn-w | awk '{print $1}')

echo
for worker in $all_workers; do
  if [ "$worker" == "$target_node" ]; then
    continue
  fi
  echo "tainting $worker..."
  kubectl taint nodes $worker key=value:NoSchedule
done

kubectl delete pod -n $ns $pod_name

for worker in $all_workers; do
  if [ "$worker" == "$target_node" ]; then
    continue
  fi
  echo "un-tainting $worker..."
  kubectl taint nodes $worker key=value:NoSchedule-
done
