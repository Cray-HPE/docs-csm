# Console Logs Fill All Available Storage Space

The log rotation functionality of the console logging services has a bug where
the files are not rotated correctly. This will lead to the logs continuing to
expand until eventually all space is consumed on the storage. This can lead to
issues where the log files cease to capture log output, and can sometimes lead
to the `cray-console-node` pods failing to connect to nodes.

## Procedure

1. Verify if the issue exists by checking the used space on the `/var/log/` mount in the `cray-console-node` pods:
   ```text
   ncn# kubectl -n services exec -it cray-console-node-0 -- sh
   sh-4.4$ df -h | grep var
   Filesystem                     Size  Used Avail Use% Mounted on
   /volumes/csi/csi-vol-ab81e37b  100G   99G  100G  99% /var/log
   ```

2. If the issue is identified, manually delete log files to clear up space:
   ```text
   ncn# kubectl -n services exec -it cray-console-node-0 -- sh
   sh-4.4$ rm -f /var/log/conman.old/*
   sh-4.4$ rm -f /var/log/conman/*
   sh-4.4$ exit
   ncn#
   ```

3. Scale the services down to zero replicas:
   ```text
   ncn# kubectl -n services scale --replicas=0 deployment/cray-console-operator
   deployment.apps/cray-console-operator scaled
   ncn# kubectl -n services scale --replicas=0 statefulset/cray-console-node
   statefulset.apps/cray-console-node scaled
   ```

4. Wait for the `cray-console-operator` and `cray-console-node` pods to terminate:
   ```text
   ncn# kubectl -n services get pods | grep console
   console-node-post-upgrade-gtzj4       0/2     Completed   0    12d
   cray-console-data-58764f845-frksj     2/2     Running     0    12d
   cray-console-data-postgres-0          3/3     Running     0    12d
   cray-console-data-postgres-1          3/3     Running     0    12d
   cray-console-data-postgres-2          3/3     Running     0    12d
   ncn#
   ```

5. Scale the `cray-console-operator` deployment back to 1 replica:
   ```text
   ncn# kubectl -n services scale --replicas=1 deployment/cray-console-operator
   deployment.apps/cray-console-operator scaled
   ```

6. When the `cray-console-operator` pod is running again it will scale the `cray-console-node`
stateful set to the correct number of replicas. Watch for the pods to come back up again:
   ```text
   ncn# kubectl -n services get pods | grep console
   console-node-post-upgrade-gtzj4         0/2     Completed   0    12d
   cray-console-data-58764f845-frksj       2/2     Running     0    12d
   cray-console-data-postgres-0            3/3     Running     0    12d
   cray-console-data-postgres-1            3/3     Running     0    12d
   cray-console-data-postgres-2            3/3     Running     0    12d
   cray-console-node-0                     3/3     Running     0    10m
   cray-console-node-1                     3/3     Running     1    12m
   cray-console-operator-69f6588596-6txtp  2/2     Running     0    10m
   ncn#
   ```

It make take a few minutes for the system to start monitoring all consoles again.