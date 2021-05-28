#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e

POSTGRESQL=cray-smd-postgres
PGDATA=pgdata-cray-smd-postgres

echo "Proceed with post upgrade steps to resize the ${POSTGRESQL} cluster ${PGDATA} PVCs to 100Gi"

# Scale POSTGRESQL cluster back to 3
kubectl get postgresql "${POSTGRESQL}" -n services -o yaml | sed 's/numberOfInstances:.*$/numberOfInstances: 3/g' | kubectl replace -f -
while [ $(kubectl get pods -l "cluster-name=${POSTGRESQL}" -n services | grep -v NAME | grep -c "Running") != 3 ] ; do echo "  waiting for pods to restart"; sleep 2; done
  
# Verify the status of the POSTGRESQL resources after the resize has completed
status=$(kubectl get postgresqls.acid.zalan.do "${POSTGRESQL}" -n services -o json | jq -r '.status.PostgresClusterStatus')
if [ "$status" == "Running" ]; then
  echo "Successful"
else
  echo "Failed $status"
fi
