#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

set -e

function to_bytes ()
# KMGTPEi to bytes
{
    CAP=$1
    echo $CAP | awk \
      'BEGIN{IGNORECASE = 1}
       function printpower(n,b,p) {printf "%d", n*b^p}
       /Ki$/{printpower($1, 2, 10)};
       /Mi$/{printpower($1, 2, 20)};
       /Gi$/{printpower($1, 2, 30)};
       /Ti$/{printpower($1, 2, 40)};
       /Pi$/{printpower($1, 2, 50)};
       /Ei$/{printpower($1, 2, 60)};'
}


function pre_install_resize ()
# Resize postgres pvc to prepare for deploy of new chart which contains postgresql volume size change
{
    POSTGRESQL=$1
    PGDATA=$2
    NAMESPACE=$3
    PGRESIZE=$4

    # Only run if postgres pvcs found to be set to less than the new resized value $PGRESIZE
    capacity=$(kubectl get  pvc "${PGDATA}-0" -n "${NAMESPACE}" -o json | jq -r '.status.capacity.storage')

    capacity_in_bytes=$( to_bytes "$capacity" )
    resize_capacity_in_bytes=$( to_bytes "$PGRESIZE" )

    # If current pvc size is less than the chart resize value, then proceed to resize
    if [ $capacity_in_bytes -lt $resize_capacity_in_bytes ]; then
      echo "Proceed with pre upgrade steps to resize the ${POSTGRESQL} cluster ${PGDATA} PVCs ${PGRESIZE}"

      # Scale POSTGRESQL cluster to 1 to prepare for resize
      kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 1}]'
      while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n "${NAMESPACE}" | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to terminate"; sleep 2; done

      # Delete the pvcs from the non running postgres pods
      kubectl delete pvc "${PGDATA}-1" "${PGDATA}-2" -n "${NAMESPACE}"

      # Resize the remaining postgres pvc
      kubectl patch -p '{"spec": {"resources": {"requests": {"storage": "'${PGRESIZE}'"}}}}' "pvc/${PGDATA}-0" -n "${NAMESPACE}"

      # Wait for the pvc to resize
      while [ -z '$(kubectl describe pvc "{PGDATA}-0" -n "${NAMESPACE}" | grep FileSystemResizeSuccessful' ] ; do echo "  waiting for pvc to resize"; sleep 2; done

      echo "Completed"
    else
      echo "Completed - ${POSTGRESQL} cluster ${PGDATA} PVCs is already at or above ${PGRESIZE}"
    fi
}

# The new PGRESIZE must match that deployed in the helm chart.
# Do not change the below values unless the associated chart values are also changed.

# Resizing cray-smd-postgres PVCs to 100Gi (from 30Gi)
pre_install_resize cray-smd-postgres pgdata-cray-smd-postgres services 100Gi

# Resizing keycloak-postgres pvcs to 10Gi (from 1Gi)
pre_install_resize keycloak-postgres pgdata-keycloak-postgres services 10Gi

# Resizing spire-postgres PVCs to 60Gi (from 20Gi)
pre_install_resize spire-postgres pgdata-spire-postgres spire 60Gi
