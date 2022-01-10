#!/bin/bash

export PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
masters=$(grep -oP 'ncn-m\d+' /etc/hosts | sort -u)
for master in $masters
do
  echo "Upgrading kube-system pods for $master:"
  echo ""
  pdsh -b -S -w $master 'kubeadm upgrade apply v1.20.13 -y'
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo ""
    echo "ERROR: The 'kubeadm upgrade apply' failed. The output from this script should be inspected"
    echo "       and addressed before moving on with the upgrade. If unable to determine the issue"
    echo "       and run this script without errors, discontinue the upgrade and contact HPE Service"
    echo "       for support."
    exit 1
  fi
  echo ""
  echo "Successfully upgraded kube-system pods for $master."
  echo ""
done
