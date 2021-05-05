#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

if [ "$1" == "" ]
then
  echo "Usage: $0 <ncn-?00?>"
  exit 1
fi

rebuild_node=$1

if [[ "$rebuild_node" =~ ^ncn-w ]]; then

  echo "Tainting worker node $rebuild_node so nothing gets scheduled on it"
  kubectl taint nodes $rebuild_node key=value:NoSchedule
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "ERROR: kubectl taint command failed -- halting..."
    exit 1
  fi

  for ns in $(kubectl get namespace | grep -v NAME | awk '{print $1}')
  do
    for pdr in $(kubectl get poddisruptionbudgets -n $ns 2>/dev/null | grep -v NAME | awk '{print $1}')
    do
      match_labels=$(kubectl get poddisruptionbudgets -n $ns $pdr -o json | jq -r '.spec.selector.matchLabels' | sed 's/[{}]//g')
      for match_label in "$match_labels"
      do
        label=$(echo $match_label | sed 's/ //g' | sed 's/"//g' | sed 's/:/=/g')
        output=$(kubectl get po -o wide -n $ns -l $label 2>/dev/null)
        rc=$?
        if [ "$rc" -ne 0 ]; then
          continue
        fi
        pods=$(echo "$output" | grep $rebuild_node | awk '{print $1}')
        if [ -z "$pods" ]; then
          continue
        fi
        for pod in $pods
        do
          echo "Deleting pod: $pod in namespace: $ns from pod distribution budget: $pdr"
          kubectl delete po -n $ns $pod
          rc=$?
          if [ "$rc" -ne 0 ]; then
            echo "ERROR: kubectl delete command failed -- halting..."
            exit 1
          fi
        done
      done
    done
  done
fi

echo "Draining $rebuild_node"
kubectl drain --ignore-daemonsets --delete-local-data $rebuild_node
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "ERROR: kubectl drain command failed -- halting..."
  exit 1
fi

echo "Removing $rebuild_node from cluster"
kubectl delete node $rebuild_node
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "ERROR: kubectl delete node command failed..."
  exit 1
fi

exit 0
