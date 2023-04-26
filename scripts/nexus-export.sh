#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

set -eo pipefail

availRGW=$(ceph df -f json | jq '.stats.total_avail_bytes' | awk '{printf "%.0f", ($1/1024/1024/1024)}')
echo  "Gibibytes available in cluster: $availRGW"

usedNexus=$(kubectl exec -n nexus deploy/nexus -c nexus -- df -P /nexus-data | grep '/nexus-data' | awk '{printf "%.0f", ($3/1024/1024)}')
echo  "Gibibytes used in nexus-data: $usedNexus"

availNexus=$(kubectl exec -n nexus deploy/nexus -c nexus -- df -P /nexus-data | grep '/nexus-data' | awk '{printf "%.0f", ($4/1024/1024)}')
echo  "Gibibytes available in nexus-data: $availNexus"

echo $usedNexus | awk '{print "Space to be used from backup: ", ($1 * 3)}'

if (( $usedNexus*3 > $availRGW )); then
  echo "Not Enough Space on the Cluster for the Export."
  exit 1
fi

echo "Creating PVC for Nexus backup, if needed"
if [[ "Bound" != $(kubectl get pvc -n nexus nexus-bak -o jsonpath='{.status.phase}') ]]; then
cat << EOF | kubectl -n nexus create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nexus-bak
spec:
  storageClassName: k8s-block-replicated
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1000Gi
EOF
fi

echo "Scaling Nexus deployment to 0"
kubectl -n nexus scale deployment nexus --replicas=0

echo "Starting backup"
cat << EOF | kubectl -n nexus apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: nexus-backup
  namespace: nexus
spec:
  template:
    spec:
      containers:
      - name: backup-container
        image: artifactory.algol60.net/csm-docker/stable/docker.io/library/alpine:3.15
        command: [ "/bin/sh", "-c" ]
        args:
        - >-
            cd /nexus-data && tar cvzf /nexus-bak/nexus-data.tgz *;
        volumeMounts:
        - mountPath: /nexus-data
          name: nexus-data
        - mountPath: /nexus-bak
          name: nexus-bak
      restartPolicy: Never
      volumes:
      - name: nexus-data
        persistentVolumeClaim:
          claimName: nexus-data
      - name: nexus-bak
        persistentVolumeClaim:
          claimName: nexus-bak
EOF

while [[ -z $(kubectl get job nexus-backup -n nexus -o jsonpath='{.status.succeeded}') ]]; do
    echo  "Waiting for the backup to finish for another 10 seconds."
    sleep 10
done

echo "Scaling Nexus back up to 1"
kubectl -n nexus scale deployment nexus --replicas=1

echo "Done"
