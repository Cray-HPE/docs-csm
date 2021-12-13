#!/bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

masterNodes=$(kubectl get nodes| grep "ncn-m" | awk '{print $1}')
for node in $masterNodes; do
  ssh $node -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "/usr/share/doc/csm/upgrade/1.0.1/scripts/k8s/fix-kube-prometheus-alerts.sh"
done
