# Recover from Postgres WAL Event

A WAL event can occur because of lag, network communication, or bandwidth issues. This can cause the PVC hosted by Ceph and mounted inside the container on /home/postgres/pgdata to fill and the database to stop running. If no database dump exists, the disk space issue needs to be fixed so that a dump can be taken. Then the dump can be restored to a newly created postgresql cluster. If a dump already exists, skip to [Rebuild the cluster and Restore the data](#rebuild-restore).

If no database dump exists and neither option results in a successful dump, then services specific [Disaster Recovery for Postgres](Disaster_Recovery_Postgres.md) will be required.

The Recovery Workflow:

- [Option 1 : Clear logs and/or WAL files ](#option1)
- [Option 2 : Resize the Postgres PVCs](#option2)
- [Dump the data](#dump)
- [Rebuild the cluster and Restore the data](#rebuild-restore)


### Attempt to Recover to a Running Database

A running database is needed to be able to dump the current data.

The following example is based on `cray-smd-postgres`.

1. Confirm that the database is down (no endpoint exists) and that the disk is full on one or more postgresql cluster member.

```
ncn-w001# POSTGRESQL=cray-smd-postgres
$ NAMESPACE=services

ncn-w001# kubectl get endpoints ${POSTGRESQL} -n ${NAMESPACE}
NAME                ENDPOINTS         AGE
cray-smd-postgres                     3d22h
```

```
ncn-w001# for i in {0..2}; do echo "${POSTGRESQL}-${i}:"; kubectl exec ${POSTGRESQL}-${i} -n ${NAMESPACE} -c postgres -- df -h pgdata; done
cray-smd-postgres-0:
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd8        30G   28G  1.6G  95% /home/postgres/pgdata
cray-smd-postgres-1:
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd15       30G   30G     0 100% /home/postgres/pgdata
cray-smd-postgres-2:
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd6        30G  383M   30G   2% /home/postgres/pgdata
```

If the database is down and the disk is full because of replication issues, there are two ways to attempt to get back to a running database: either delete files or resize the Postgres PVCs until the database is able to start running again.

<a name="option1"></a>
#### Option 1 : Clear logs and/or WAL files

The following example is based on `cray-smd-postgres`.

1. Clear files from /home/postgres/pgdata/pgroot/pg_log/ until the database is running again and you can successfully connect. For example, if the disk space is at 100%, exec into that pod, copy the logs off (optional) and then clear the logs to recover some disk space.
```
ncn-w001# kubectl cp "${POSTGRESQL}-1":/home/postgres/pgdata/pgroot/pg_log /tmp -c postgres -n ${NAMESPACE}
ncn-w001# kubectl exec "${POSTGRESQL}-1" -n ${NAMESPACE} -c postgres -it -- bash
root@cray-smd-postgres-1:/home/postgres# for i in {0..7}; do > /home/postgres/pgdata/pgroot/pg_log/postgresql-$i.csv; done
```
2. Restart the Postgres cluster and postgres-operator.
```
ncn-w001# kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2"
ncn-w001# kubectl delete pod -n services -l app.kubernetes.io/name=postgres-operator

```
3. Check if the database is running. If it is running, continue with [Dumping the data](#dump).
```
ncn-w001# kubectl exec "${POSTGRESQL}-1" -n ${NAMESPACE} -c postgres -it -- psql -U postgres
psql (12.2 (Ubuntu 12.2-1.pgdg18.04+1), server 11.7 (Ubuntu 11.7-1.pgdg18.04+1))
Type "help" for help.

postgres=#   <----- success!!  Type \q
```
4. If the database is still not running, delete files from /home/postgres/pgdata/pgroot/data/pg\_wal/.
CAUTION: This method could result in unintended consequences for the Postgres database and long service downtime; do not use unless there is a known [Disaster Recovery for Postgres](Disaster_Recovery_Postgres.md) procedure for repopulating the Postgres cluster.
```
ncn-w001# kubectl exec "${POSTGRESQL}-1" -n ${NAMESPACE} -c postgres -it -- bash
root@cray-smd-postgres-1:/home/postgres# rm pgdata/pgroot/data/pg_wal/0*

```
5. Restart the Postgres cluster and postgres-operator.
```
ncn-w001# kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2"
ncn-w001# kubectl delete pod -n services -l app.kubernetes.io/name=postgres-operator
```
6. Check if the database is running.
```
ncn-w001# kubectl exec "${POSTGRESQL}-1" -n ${NAMESPACE} -c postgres -it -- psql -U postgres
psql (12.2 (Ubuntu 12.2-1.pgdg18.04+1), server 11.7 (Ubuntu 11.7-1.pgdg18.04+1))
Type "help" for help.

postgres=#   <----- success!!  Type \q
```

7. If the database is still not running, try recovering using the other option listed in this document.

<a name="option2"></a>
#### Option 2 : Resize the Postgres PVCs

The following example is based on `cray-smd-postgres`, where the postgresql `cray-smd-postgres` resource and the `pgdata-cray-smd-postgres` PVCs will be resized from `100Gi` to `120Gi`.

1. Determine the current size of the Postgres PVCs and set PGRESIZE to the desired new size (it must be larger than the current size).
```
ncn-w001# kubectl get postgresql -A | grep "smd\|NAME"
NAMESPACE   NAME                         TEAM                VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
services    cray-smd-postgres            cray-smd            11        3      100Gi    4             8Gi              18h   Running

ncn-w001# kubectl get pvc -A | grep "cray-smd-postgres\|NAME"
NAMESPACE      NAME                         STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
services       pgdata-cray-smd-postgres-0   Bound     pvc-c86859f4-a57f-4694-a66a-8120e96a1ab4   100Gi      RWO            k8s-block-replicated   18h
services       pgdata-cray-smd-postgres-1   Bound     pvc-300f52e4-f88d-47ef-9a1e-e598fd919047   100Gi      RWO            k8s-block-replicated   18h
services       pgdata-cray-smd-postgres-2   Bound     pvc-f33879f3-0e99-4299-b796-210fbb693a2f   100Gi      RWO            k8s-block-replicated   18h

ncn-w001# PGRESIZE=120Gi
ncn-w001# POSTGRESQL=cray-smd-postgres
ncn-w001# PGDATA=pgdata-cray-smd-postgres
ncn-w001# NAMESPACE=services
```

2. Edit numberOfInstances in the postgresql resource from 3 to 1.

```
ncn-w001# kubectl patch postgresql ${POSTGRESQL} -n ${NAMESPACE} --type=json -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 1}]'
postgresql.acid.zalan.do/cray-smd-postgres patched
```

3. Wait for 2 of the 3 postgresql pods to terminate.
```
ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
```

4. Delete the PVCs from the non-running Postgres pods.
```
ncn-w001# kubectl delete pvc "${PGDATA}-1" "${PGDATA}-2" -n ${NAMESPACE}
persistentvolumeclaim "pgdata-cray-smd-postgres-1" deleted
persistentvolumeclaim "pgdata-cray-smd-postgres-2" deleted
```

5. Resize the remaining Postgres PVC resources.requests.storage to $PGRESIZE.
```
ncn-w001# kubectl patch -p '{"spec": {"resources": {"requests": {"storage": "'${PGRESIZE}'"}}}}' "pvc/${PGDATA}-0" -n ${NAMESPACE}
persistentvolumeclaim/pgdata-cray-smd-postgres-0 patched
```

6. Wait for the PVC to resize.
```
ncn-w001# while [ -z '$(kubectl describe pvc "${PGDATA}-0" -n ${NAMESPACE} | grep FileSystemResizeSuccessful' ] ; do echo "  waiting for PVC to resize"; sleep 2; done
```

7. Update the postgresql resource spec.volume.size to $PGRESIZE.
```
ncn-w001# kubectl get "postgresql/${POSTGRESQL}" -n ${NAMESPACE} -o json | jq '.spec.volume = {"size": "'${PGRESIZE}'"}' | kubectl apply -f -
postgresql.acid.zalan.do/cray-smd-postgres configured
```

8. Restart the existing postgresql pod.
```
ncn-w001# kubectl delete pod "${POSTGRESQL}-0" -n services
pod "cray-smd-postgres-0" deleted
```

9. Check that the single instance pod is Running with 3/3 Ready, patronictl reports the member is running and postgresql resource is Running with new volume size ($PGRESIZE).
```
ncn-w001# kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE}
NAME                  READY   STATUS    RESTARTS   AGE
cray-smd-postgres-0   3/3     Running   0          14s

$ kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
+-------------------+---------------------+------------+--------+---------+----+-----------+
|      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+------------+--------+---------+----+-----------+
| cray-smd-postgres | cray-smd-postgres-0 | 10.44.0.38 | Leader | running |  2 |           |
+-------------------+---------------------+------------+--------+---------+----+-----------+

ncn-w001# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE}
NAME                TEAM       VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
cray-smd-postgres   cray-smd   11        1      120Gi    500m          100Mi            11m   Running

```

10. Check that the database is running.
```
ncn-w001# kubectl exec "${POSTGRESQL}-0" -n services -c postgres -it -- psql -U postgres
psql (12.2 (Ubuntu 12.2-1.pgdg18.04+1), server 11.7 (Ubuntu 11.7-1.pgdg18.04+1))
Type "help" for help.

postgres=#   <----- success!!  Type \q
```

11. Scale numberOfInstances in postgresql resource from 1 back to 3.
```
ncn-w001# kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'
postgresql.acid.zalan.do/cray-smd-postgres patched
```

12. Logs may indicate WAL error such as the following, but a dump can be taken at this point.
```
ncn-w001# kubectl logs "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres | grep -i error
ncn-w001# kubectl logs "${POSTGRESQL}-1" -n ${NAMESPACE} -c postgres | grep -i error
ncn-w001# kubectl logs "${POSTGRESQL}-2" -n ${NAMESPACE} -c postgres | grep -i error
error: could not get write-ahead log end position from server: ERROR:  invalid segment number
```

13. In order to persist any Postgres PVC storage volume size changes, it is necessary that this change also be made to the customer-managed customizations.yaml file. See the Postgres PVC Resize information in the [Post Install Customizations](../CSM_product_management/Post_Install_Customizations.md#postgres_pvc_resize).

<a name="dump"></a>
### Dump the data

If the recovery was successful such that the database is now running, then continue with the following steps to dump the data.

<a name="scale"></a>
1. Scale the client service to 0.

The following example is based on `cray-smd`. The `cray-smd` client service is deployed as a deployment. Other services may differ; e.g. statefulset.

```
ncn-w001# CLIENT=cray-smd
ncn-w001# POSTGRESQL=cray-smd-postgres
ncn-w001# NAMESPACE=services

ncn-w001# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=0
deployment.apps/cray-smd scaled

ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
```

2. Dump all the data.

Determine which Postgres member is the leader and exec into the leader pod to dump the data to a local file:
```
ncn-w001# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
+-------------------+---------------------+------------+--------+---------+----+-----------+
|      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+------------+--------+---------+----+-----------+
| cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 | Leader | running |  1 |           |
| cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |        | running |    |         0 |
| cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |        | running |    |         0 |
+-------------------+---------------------+------------+--------+---------+----+-----------+

ncn-w001# POSTGRES_LEADER=cray-smd-postgres-0

ncn-w001# kubectl exec -it ${POSTGRES_LEADER} -n ${NAMESPACE} -c postgres -- pg_dumpall -c -U postgres > "${POSTGRESQL}-dumpall.sql"

ncn-w001# ls "${POSTGRESQL}-dumpall.sql"
cray-smd-postgres-dumpall.sql
```

<a name="rebuild-restore"></a>

### Rebuild the cluster and Restore the data

If recovery was successful such that a dump could be taken or a dump already exists, then continue with the following steps to rebuild the postgresql cluster and restore the data.

The following example restores the dump to the `cray-smd-postgres` cluster.

1. If your client service is not yet scaled to 0, follow the step above to [Scale the client service to 0](#scale).

2. Delete and re-create the postgresql resource (which includes the PVCs).
```
ncn-w001# CLIENT=cray-smd
ncn-w001# POSTGRESQL=cray-smd-postgres
ncn-w001# NAMESPACE=services

ncn-w001# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.yaml

ncn-w001# kubectl delete -f postgres-cr.yaml
postgresql.acid.zalan.do "cray-smd-postgres" deleted

ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done

ncn-w001# kubectl create -f postgres-cr.yaml
postgresql.acid.zalan.do/cray-smd-postgres created

ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start running"; sleep 2; done
```

3. Determine which Postgres member is the leader.
```
ncn-w001# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
+-------------------+---------------------+------------+--------+---------+----+-----------+
|      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+------------+--------+---------+----+-----------+
| cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 | Leader | running |  1 |           |
| cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |        | running |    |         0 |
| cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |        | running |    |         0 |
+-------------------+---------------------+------------+--------+---------+----+-----------+

ncn-w001# POSTGRES_LEADER=cray-smd-postgres-0
```

4. Copy the dump taken above to the Postgres leader pod and restore the data.

If the dump exists in a different location, adjust this example as needed.
```
ncn-w001# kubectl cp ./cray-smd-postgres-dumpall.sql ${POSTGRES_LEADER}:/home/postgres/cray-smd-postgres-dumpall.sql -c postgres -n ${NAMESPACE}

ncn-w001# kubectl exec ${POSTGRES_LEADER} -c postgres -n ${NAMESPACE} -it -- psql -U postgres < cray-smd-postgres-dumpall.sql
```

5. Restore the secrets.

Once the dump has been restored onto the newly built postgresql cluster, the current Kubernetes secrets need to be updated in the postgresql cluster, otherwise the service will experience readiness and liveness probe failures because it will be unable to authenticate to the database.

Determine which Postgres member is the leader.
```
ncn-w001# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
+-------------------+---------------------+------------+--------+---------+----+-----------+
|      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+------------+--------+---------+----+-----------+
| cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 | Leader | running |  1 |           |
| cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |        | running |    |         0 |
| cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |        | running |    |         0 |
+-------------------+---------------------+------------+--------+---------+----+-----------+

ncn-w001# POSTGRES_LEADER=cray-smd-postgres-0
```
Determine what secrets are associated with the postgresql credentials.
```
ncn-w001# kubectl get secrets -n ${NAMESPACE} | grep "${POSTGRESQL}.credentials"
services            hmsdsuser.cray-smd-postgres.credentials                       Opaque                                2      31m
services            postgres.cray-smd-postgres.credentials                        Opaque                                2      31m
services            service-account.cray-smd-postgres.credentials                 Opaque                                2      31m
services            standby.cray-smd-postgres.credentials                         Opaque                                2      31m
```
For each secret above, get the username and password from Kubernetes and update the Postgres database with this information.
For example (hmsdsuser.cray-smd-postgres.credentials) :
```
ncn-w001# kubectl get secret hmsdsuser.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d
hmsdsuser

ncn-w001# kubectl get secret hmsdsuser.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d
ABCXYZ
```
Exec into the leader pod to reset the user's password :
```
ncn-w001# kubectl exec ${POSTGRES_LEADER} -n ${NAMESPACE} -c postgres -it -- bash
root@cray-smd-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
postgres=# ALTER USER hmsdsuser WITH PASSWORD 'ABCXYZ';
ALTER ROLE
postgres=#
```
Continue the above process until all ${POSTGRESQL}.credentials secrets have been updated in the database.

6. Restart the postgresql cluster
```
ncn-w001# kubectl delete pod "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2" -n ${NAMESPACE}

ncn-w001# while [ $(kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq -r '.status.PostgresClusterStatus') != "Running" ]; do echo "waiting for ${POSTGRESQL} to start running"; sleep 2; done
```

7. Scale the client service back to 3
```
ncn-w001# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=3

ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start running"; sleep 2; done
```
