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
      #shellcheck disable=SC2066
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
