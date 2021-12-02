#!/bin/sh
# Copyright 2021 Hewlett Packard Enterprise Development LP

EXPECTED_VERSION="v1.20.13"
display_output=$(kubectl get nodes)
versions=$(kubectl get nodes -o json | jq -r '.items[].status.nodeInfo.kubeletVersion')
stringarray=($versions)
for version in "${stringarray[@]}"; do
  if [ "$version" != "$EXPECTED_VERSION" ]; then
    echo "FAILURE: Not all NCNs have been updated to ${EXPECTED_VERSION}!"
    echo "         Return to the previous step to ensure all NCNs have been upgraded"
    echo "         before proceeding."
    echo ""
    echo "Node versions:"
    echo ""
    echo "$display_output"
    exit 1
  fi
done

echo "SUCCESS: All NCNs have been updated to ${EXPECTED_VERSION}:"
echo ""
echo "$display_output"
exit 0
