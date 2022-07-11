# Nexus Export and Restore process

The current process for ensuring the saftey of the nexus data is a one time, space intesive, manual process and is only recommeded to be done while nexus is in a known good state. The process is needed to be done if a second copy of the nexus data is needed.
This could be done before an upgrade (with the data taken off cluster) to ensure if the upgrade creates issue nexus can be downgraded again. Taking an export can also be used to ensure nexus resiliency. This process is still a run at your own risk procedure,
and is not recommended for all cases.

## Step One - Check Cluster Storage Size

To check the size of the exported tar file (on the cluster), and the amount of storage the cluster has left run the following command on a master node:

```bash
kubectl exec -n nexus deploy/nexus -c nexus -- df -P /nexus-data | grep '/nexus-data' | awk '{print "Amount of space the nexus export will take up on cluster: "(($3 * 3)/1048576)" GiB";}' && ceph df | grep 'zone1.rgw.buckets.data' | awk '{ print "Currently used: " $7 $8 ", Max Available " $10 $11;}'
```

This will print out the amount of space the nexus export will take on the cluster as well as the amount of space currently used in the pool the tar will be stored. This also gives the max amount of space available in that pool. If the size of the nexus export 
plus the size of the currenty used space is larger than the max available size please submit a help request to figure out a solution. 

## Step Two - Take the export

Taking the export can take multiple hours and nexus will be unavailable for the entire time the export is being taken. For a fresh install of nexus the export takes around 1 hour for every 60 GiB stored in the nexus-data PVC. So for example if the nexus-data
PVC is 120 GiB (meaning the first step showed the export will take 360 GiB on cluster) nexus would be unavaibale for around 2 hours while the export was taking place.

To run the export run the following script on a master node:

```bash
#!/bin/bash
 
set -ex
 
if [[ "Bound" != $(kubectl get pvc -n nexus nexus-bak -o jsonpath={.status.phase}) ]]; then
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
 
kubectl -n nexus scale deployment nexus --replicas=0;
 
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
 
while [[ -z $(kubectl get job nexus-backup -n nexus -o jsonpath={.status.succeeded}) ]]; do
    echo  "Waiting for the backup to finish for another 10 seconds."
    sleep 10
done
 
kubectl -n nexus scale deployment nexus --replicas=1;
```

## Step Three - Restore Nexus

The restore step will delete any changes to made to Nexus after the backup was taken. The restore takes around half the time that the export took (e.g. if the export took 2 hours the restore would take around 1 hour) and during the time to restore 
Nexus is unavailable. 

To restore Nexus to the state of the backup run the following command on any master node:

```bash
#!/bin/bash
 
set -ex
 
if [[ "Bound" != $(kubectl get pvc -n nexus nexus-bak -o jsonpath={.status.phase}) ]]; then
echo "Error no backup PVC was found\nPlease run nexus-backup.sh before trying to restore"
exit 1
fi
 
kubectl -n nexus scale deployment nexus --replicas=0;
 
cat << EOF | kubectl -n nexus apply -f -                                                    
apiVersion: batch/v1
kind: Job
metadata:
  name: nexus-restore
  namespace: nexus
spec:
  template:
    spec:
      containers:
      - name: restore-container
        image: artifactory.algol60.net/csm-docker/stable/docker.io/library/alpine:3.15
        command: [ "/bin/sh", "-c" ]
        args:
        - >-
            cd /nexus-data;
            if [[ -f /nexus-bak/nexus-data.tgz  ]]; then rm -rf *; fi;
            tar xvzf /nexus-bak/nexus-data.tgz;        
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
 
while [[ -z $(kubectl get job nexus-restore -n nexus -o jsonpath={.status.succeeded}) ]]; do
    echo  "Waiting for the restore to finish for another 10 seconds."
    sleep 10
done
 
kubectl -n nexus delete job nexus-restore
kubectl -n nexus scale deployment nexus --replicas=1;
```