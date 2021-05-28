#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e

# The new PVC capacity will be set to 100Gi - do not change this as it needs to match what is set in the chart for volume size.

POSTGRESQL=cray-smd-postgres
PGDATA=pgdata-cray-smd-postgres

# Only run if postgres pvcs found to be set to less than 100Gi - supports [EPTGMK]i
capacity=$(kubectl get  pvc "${PGDATA}-0" -n services -o json | jq -r '.status.capacity.storage')

capacity_in_bytes=$(echo $capacity | awk \
      'BEGIN{IGNORECASE = 1}
       function printpower(n,b,p) {printf "%d", n*b^p}
       /Ki$/{printpower($1, 2, 10)};
       /Mi$/{printpower($1, 2, 20)};
       /Gi$/{printpower($1, 2, 30)};
       /Ti$/{printpower($1, 2, 40)};
       /Pi$/{printpower($1, 2, 50)};
       /Ei$/{printpower($1, 2, 60)};')

echo "capacity_in_bytes : $capacity_in_bytes"

# If less than 100Gi (107374182400), then proceed to resize
if [ $capacity_in_bytes -lt 107374182400 ]; then
  echo "Proceed with pre upgrade steps to resize the ${POSTGRESQL} cluster ${PGDATA} PVCs to 100Gi"

  # Scale POSTGRESQL cluster to 1 to prepare for resize
  kubectl get postgresql "${POSTGRESQL}" -n services -o yaml | sed 's/numberOfInstances:.*$/numberOfInstances: 1/g' | kubectl replace -f -
  while [ $(kubectl get pods -l "cluster-name=${POSTGRESQL}" -n services | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to terminate"; sleep 2; done

  # Delete the pvcs from the non running postgres pods
  kubectl delete pvc "${PGDATA}-1" "${PGDATA}-2" -n services

  # Resize the remaining postgres pvc
  kubectl patch -p '{"spec": {"resources": {"requests": {"storage": "'100Gi'"}}}}' "pvc/${PGDATA}-0" -n services

  # Wait for the pvc to resize
  while [ -z '$(kubectl describe pvc "{PGDATA}-0" -n services | grep FileSystemResizeSuccessful' ] ; do echo "  waiting for pvc to resize"; sleep 2; done

  echo "Completed"
else
  echo "Completed - ${POSTGRESQL} cluster ${PGDATA} PVCs is already at or above 100Gi"
fi
