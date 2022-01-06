#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
set -e

function post_install_resize ()
# Complete steps needed for postgres pvc resize
{
    POSTGRESQL=$1
    PGDATA=$2
    NAMESPACE=$3
    PGRESIZE=$4

    echo "Proceed with post upgrade steps to resize the ${POSTGRESQL} cluster ${PGDATA} PVCs to ${PGRESIZE}"

    # Scale POSTGRESQL cluster back to 3
    kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n "${NAMESPACE}" | grep -v NAME | grep -c "Running") != 3 ] ; do echo "  waiting for pods to restart"; sleep 2; done

    # Verify the status of the POSTGRESQL resources after the resize has completed
    status=$(kubectl get postgresqls.acid.zalan.do "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus')
    if [ "$status" == "Running" ]; then
      echo "Successful"
    else
      echo "Failed $status"
    fi
}

# restart postgres operator
kubectl delete pod  -l app.kubernetes.io/name=postgres-operator -n services
while [ $(kubectl get pods -l app.kubernetes.io/name=postgres-operator -n services | grep -v NAME | grep -c "Running") != 1 ] ; do echo "  waiting for pods to restart"; sleep 2; done


# The new PGRESIZE must match that deployed in the helm chart.
# Do not change the below values unless the associated chart values are also changed.

# Complete resizing cray-smd-postgres PVCs to 100Gi (from 30Gi)
post_install_resize cray-smd-postgres pgdata-cray-smd-postgres services 100Gi

# Complete resizing keycloak-postgres pvcs to 10Gi (from 1Gi)
post_install_resize keycloak-postgres pgdata-keycloak-postgres services 10Gi

# Complete resizing spire-postgres PVCs to 60Gi (from 20Gi)
post_install_resize spire-postgres pgdata-spire-postgres spire 60Gi
