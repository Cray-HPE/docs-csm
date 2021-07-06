## Troubleshoot Postgres Databases with the Patroni Tool

The patronictl tool is used to call a REST API that interacts with Postgres databases. It handles a variety of tasks, such as listing cluster members and the replication status, configuring and restarting databases, and more.

The tool is installed in the database containers:

```bash
ncn-w001# kubectl exec -it -n services keycloak-postgres-0 -c postgres -- su postgres
```

Use the following command for more information on the patronictl command:

```bash
postgres@keycloak-postgres-0:~$ patronictl --help
```

### Check if a Database is Down

It is a good idea to check if Patroni has marked a database as unavailable. If there are no endpoints for the main service, Patroni has marked it as unavailable.

The following is an example for `keycloak-postgres`. There are no endpoints listed, which means it is unavailable.

```bash
ncn-w001# kubectl get endpoints -n services keycloak-postgres
NAME                ENDPOINTS         AGE
keycloak-postgres                     3d22h
```

### Check if the Disk is Full

If the disk for the Postgres database is filled up, the pods for a given service will not be able to start.

The example below was in the log for one of the `keycloak-postgres` pods:

```bash
2019-12-16 21:02:31 UTC [76812]: [1-1] 5df7f0e7.12c0c 0     FATAL:  could not write lock file "postmaster.pid": No space left on device
```

Use the df parameter for the container to see if the disk is full:

```bash
ncn-w001# kubectl exec -it -n services -c postgres keycloak-postgres-1 -- df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/rbd3       976M  960M     0 100% /home/postgres/pgdata
...
```

Use the du parameter to check what is filling up the disk. In the example below, it is the wal directory.

```bash
ncn-w001# kubectl exec -it -n services -c postgres keycloak-postgres-1 \
-- du -h --max-depth 1 /home/postgres/pgdata/pgroot/data/pg_wal
4.0K    /home/postgres/pgdata/pgroot/data/pg_wal/archive_status
833M    /home/postgres/pgdata/pgroot/data/pg_wal
```

In this case, the wal directory is full because replication was not working. Postgres does not delete any wal files in order to get the failed replica back to an operational state.

### Recover a Database if the wal Directory is Full

Delete all of the files out of wal directory to recover the database.

**CAUTION:** This method might result in unintended consequences for the Postgres database and long service downtime, so do not use unless there is a known procedure for repopulating any needed Postgres data.

```bash
E=$(kubectl exec -n services -c postgres keycloak-postgres-1 -- /bin/ls /home/postgres/pgdata/pgroot/data/pg_wal/)
for F in $E; do
  echo $F
  kubectl exec -it -n services -c postgres keycloak-postgres-1 -- rm /home/postgres/pgdata/pgroot/data/pg_wal/$F
done
```

After the files are deleted, delete the Postgres and operator pods to restart them.

```bash
ncn-w001# kubectl delete pod -n services keycloak-postgres-0 keycloak-postgres-1 keycloak-postgres-2
ncn-w001# kubectl delete pod -n services cray-postgres-operator-67d5467444-ffdc6
```

### Check if Replication is Working

When services have a Postgres cluster of pods, they need to be able to replicate data between them. When the pods are not able to replicate data, the database will become full. The patronictl list command will show the status of replication:

```bash
postgres@keycloak-postgres-0:~$ patronictl list
+-------------------+---------------------+------------+--------+---------+----+-----------+
|      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+------------+--------+---------+----+-----------+
| keycloak-postgres | keycloak-postgres-0 | 10.40.0.23 | Leader | running |  1 |         0 |
| keycloak-postgres | keycloak-postgres-1 | 10.42.0.25 |        | running |  1 |         0 |
| keycloak-postgres | keycloak-postgres-2 | 10.42.0.29 |        | running |  1 |         0 |
+-------------------+---------------------+------------+--------+---------+----+-----------+
```

The following is an example where replication is broken:

```bash
+-------------------+---------------------+--------------+--------+----------+----+-----------+
|      Cluster      |        Member       |     Host     |  Role  |  State   | TL | Lag in MB |
+-------------------+---------------------+--------------+--------+----------+----+-----------+
| keycloak-postgres | keycloak-postgres-0 | 10.42.10.22  |        | starting |    |   unknown |
| keycloak-postgres | keycloak-postgres-1 | 10.40.11.191 | Leader | running  | 47 |         0 |
| keycloak-postgres | keycloak-postgres-2 | 10.40.11.190 |        | running  | 14 |       608 |
+-------------------+---------------------+--------------+--------+----------+----+-----------+
```

### Recover Replication

In the event that a state of broken Postgres replication persists and the space allocated for the WAL files fills-up, the affected database will likely shut down and create a state where it cannot be brought up again. This can impact the reliability of the related service and can require that it be redeployed with data repopulation procedures.

A reinitialize will get the lagging replica member re-synced and replicating again. This should be done as soon as replication lag is detected. In the preceding example, keycloak-postgres-0 and keycloak-postgres-2 were not replicating properly. To reinitialize a member, run the following commands.

This example is for the keycloak-postgres-2 member, and the same commands were run for the keycloak-postgres-0 member, where keycloak-postgres-1 is the leader pod. Exec into the leader pod and reinitialize the keycloak-postgres cluster member that is not replicating.

```bash
ncn-w001# kubectl exec -it -n services -c postgres keycloak-postgres-1 -- bash
root@keycloak-postgres-1:/home/postgres# patronictl reinit keycloak-postgres keycloak-postgres-2
Are you sure you want to reinitialize members keycloak-postgres-2? [y/N]: y
Failed: reinitialize for member keycloak-postgres-2, status code=503, (restarting after failure already in progress)
Do you want to cancel it and reinitialize anyway? [y/N]: y
Success: reinitialize for member keycloak-postgres-2
```

Verify that replication has recovered:

```bash
postgres@keycloak-postgres-2:~$ patronictl list
+-------------------+---------------------+--------------+--------+---------+----+-----------+
|      Cluster      |        Member       |     Host     |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+--------------+--------+---------+----+-----------+
| keycloak-postgres | keycloak-postgres-0 | 10.42.10.22  |        | running | 47 |         0 |
| keycloak-postgres | keycloak-postgres-1 | 10.40.11.191 | Leader | running | 47 |         0 |
| keycloak-postgres | keycloak-postgres-2 | 10.40.11.190 |        | running | 47 |           |
+-------------------+---------------------+--------------+--------+---------+----+-----------+
```



