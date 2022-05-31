# Troubleshoot Postgres Database

General Postgres Troubleshooting Topics
- [The `patronictl` Tool](#patronictl)
- [Is the Database Unavailable?](#unavailable)
- [Is the Database Disk Full?](#diskfull)
- [Is Replication Lagging?](#lag)
- [Is the Postgres status `SyncFailed`?](#syncfailed)
- [Is a Cluster Member missing?](#missing)
- [Is the Postgres Leader missing?](#leader)

<a name="patronictl"></a>
## The `patronictl` Tool

The `patronictl` tool is used to call a REST API that interacts with Postgres databases. It handles a variety of tasks, such as listing cluster members and the replication status, configuring and restarting databases, and more.

The tool is installed in the database containers:

```bash
ncn-mw# kubectl exec -it -n services keycloak-postgres-0 -c postgres -- su postgres
```

Use the following command for more information on the `patronictl` command:

```bash
postgres@keycloak-postgres-0:~$ patronictl --help
```

<a name="unavailable"></a>
## Is the Database Unavailable?

If there are no endpoints for the main service, Patroni will mark the database as unavailable.

The following is an example for `keycloak-postgres` where no endpoints are listed, which means the database is unavailable.

```bash
ncn-mw# kubectl get endpoints keycloak-postgres -n services
```

Example output:

```text
NAME                ENDPOINTS         AGE
keycloak-postgres   <none>            3d22h
```

If the database is unavailable, check if [Disk Full](#diskfull) is the cause of the issue. Otherwise, check the `postgres-operator` logs for errors.

```bash
ncn-mw# kubectl logs -l app.kubernetes.io/name=postgres-operator -n services
```

<a name="diskfull"></a>
## Is the Database Disk Full?

The following is an example for `keycloak-postgres`. One cluster member is failing to start because of a full `pgdata` disk. This was likely due to replication issues, which caused the `pg_wal` files to grow.

```bash
ncn-mw# POSTGRESQL=keycloak-postgres
ncn-mw# NAMESPACE=services
ncn-mw# kubectl exec "${POSTGRESQL}-1" -c postgres -it -n ${NAMESPACE} -- patronictl list
+-------------------+---------------------+------------+--------+--------------+----+-----------+
|      Cluster      |        Member       |    Host    |  Role  |    State     | TL | Lag in MB |
+-------------------+---------------------+------------+--------+--------------+----+-----------+
| keycloak-postgres | keycloak-postgres-0 | 10.42.0.11 |        | start failed |    |   unknown |
| keycloak-postgres | keycloak-postgres-1 | 10.44.0.7  |        |   running    |  4 |         0 |
| keycloak-postgres | keycloak-postgres-2 | 10.36.0.40 | Leader |   running    |  4 |           |
+-------------------+---------------------+------------+--------+--------------+----+-----------+

ncn-mw# for i in {0..2}; do echo "${POSTGRESQL}-${i}:"; kubectl exec "${POSTGRESQL}-${i}" -n ${NAMESPACE} -c postgres -- df -h pgdata; done;
keycloak-postgres-0:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sde        976M  960M     0 100% /home/postgres/pgdata
keycloak-postgres-1:
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd12      976M  152M  809M  16% /home/postgres/pgdata
keycloak-postgres-2:
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd3       976M  136M  825M  15% /home/postgres/pgdata

ncn-mw#  kubectl logs "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres | grep FATAL
2021-07-14 17:52:48 UTC [30495]: [1-1] 60ef2470.771f 0     FATAL:  could not write lock file "postmaster.pid": No space left on device

ncn-mw# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- du -h --max-depth 1 /home/postgres/pgdata/pgroot/data/pg_wal
```

To recover the cluster member that had failed to start because of disk pressure, attempt to reclaim some space on the `pgdata` disk.

`kubectl exec` into that pod, copy the logs off (optional), and then clear the logs in order to recover some disk space. Finally, restart the Postgres cluster and `postgres-operator`.

```bash
ncn-mw# kubectl cp "${POSTGRESQL}-1":/home/postgres/pgdata/pgroot/pg_log /tmp -c postgres -n ${NAMESPACE}
ncn-mw# kubectl exec "${POSTGRESQL}-1" -n ${NAMESPACE} -c postgres -it -- bash
root@cray-smd-postgres-1:/home/postgres# for i in {0..7}; do > /home/postgres/pgdata/pgroot/pg_log/postgresql-$i.csv; done
```

```bash
ncn-mw# kubectl delete pod "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2" -n ${NAMESPACE}
ncn-mw# kubectl delete pod -l app.kubernetes.io/name=postgres-operator -n services
```

If disk issues persist or exist on multiple nodes and the above does not resolve the issue, see the [Recover from Postgres WAL Event](Recover_from_Postgres_WAL_Event.md) procedure.

<a name="lag"></a>
## Is Replication Lagging?

Postgres replication lag can be detected with Prometheus alerts and alert notifications (See [Configure Prometheus Email Alert Notifications](../system_management_health/Configure_Prometheus_Email_Alert_Notifications.md)). If replication lag is not caught early, it can cause the disk mounted on `/home/postgres/pgdata` to fill up and the database to stop running. If this issue is caught before the database stops, it can be easily remediated using a patronictl command to reinitialize the lagging cluster member.

### Check if Replication is Working

When services have a Postgres cluster of pods, they need to be able to replicate data between them. When the pods are not able to replicate data, the database will become full. The `patronictl list` command will show the status of replication:

The following is an example where replication is working:

```bash
ncn-mw# kubectl exec keycloak-postgres-0 -c postgres -n services -it -- patronictl list
```

Example output:

```text
+-------------------+---------------------+------------+--------+---------+----+-----------+
|      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+------------+--------+---------+----+-----------+
| keycloak-postgres | keycloak-postgres-0 | 10.40.0.23 | Leader | running |  1 |           |
| keycloak-postgres | keycloak-postgres-1 | 10.42.0.25 |        | running |  1 |         0 |
| keycloak-postgres | keycloak-postgres-2 | 10.42.0.29 |        | running |  1 |         0 |
+-------------------+---------------------+------------+--------+---------+----+-----------+
```

The following is an example where replication is broken:

```
+-------------------+---------------------+--------------+--------+----------+----+-----------+
|      Cluster      |        Member       |     Host     |  Role  |  State   | TL | Lag in MB |
+-------------------+---------------------+--------------+--------+----------+----+-----------+
| keycloak-postgres | keycloak-postgres-0 | 10.42.10.22  |        | starting |    |   unknown |
| keycloak-postgres | keycloak-postgres-1 | 10.40.11.191 | Leader | running  | 47 |           |
| keycloak-postgres | keycloak-postgres-2 | 10.40.11.190 |        | running  | 14 |       608 |
+-------------------+---------------------+--------------+--------+----------+----+-----------+
```

### Recover Replication

In the event that a state of broken Postgres replication persists and the space allocated for the WAL files fills up, the affected database will likely shut down and create a state where it can be very difficult to recover. This can impact the reliability of the related service and may require that it be redeployed with data repopulation procedures. If replication lag is caught and remediated before the database shuts down, replication can be recovered using `patronictl reinit`.

A reinitialize will get the lagging replica member re-synced and replicating again. This should be done as soon as replication lag is detected. In the preceding example, `keycloak-postgres-0` and `keycloak-postgres-2` were not replicating properly (Lag>0 or `unknown`). To remediate, `kubectl exec` into the leader pod and use `patronictl reinit <cluster> <lagging cluster member>` to reinitialize the lagging member(s). For example:

```bash
ncn-mw# kubectl exec keycloak-postgres-1 -n services -it -- bash
root@keycloak-postgres-1:/home/postgres# patronictl reinit keycloak-postgres keycloak-postgres-0
```

Example output:

```text
Are you sure you want to reinitialize members keycloak-postgres-0? [y/N]: y
Failed: reinitialize for member keycloak-postgres-0, status code=503, (restarting after failure already in progress)
Do you want to cancel it and reinitialize anyway? [y/N]: y
Success: reinitialize for member keycloak-postgres-0
```

```bash
root@keycloak-postgres-1:/home/postgres# patronictl reinit keycloak-postgres keycloak-postgres-2
```

Example output:

```text
Are you sure you want to reinitialize members keycloak-postgres-2? [y/N]: y
Failed: reinitialize for member keycloak-postgres-2, status code=503, (restarting after failure already in progress)
Do you want to cancel it and reinitialize anyway? [y/N]: y
Success: reinitialize for member keycloak-postgres-2
```

Verify that replication has recovered:

```bash
ncn-mw# kubectl exec keycloak-postgres-0 -c postgres -n services -it -- patronictl list
```

Example output:

```text
+-------------------+---------------------+--------------+--------+---------+----+-----------+
|      Cluster      |        Member       |     Host     |  Role  |  State  | TL | Lag in MB |
+-------------------+---------------------+--------------+--------+---------+----+-----------+
| keycloak-postgres | keycloak-postgres-0 | 10.42.10.22  |        | running | 47 |         0 |
| keycloak-postgres | keycloak-postgres-1 | 10.40.11.191 | Leader | running | 47 |           |
| keycloak-postgres | keycloak-postgres-2 | 10.40.11.190 |        | running | 47 |         0 |
+-------------------+---------------------+--------------+--------+---------+----+-----------+
```

**Troubleshooting:**

- If `patronictl reinit` fails with `Failed: reinitialize for member` ... `status code=503, (Cluster has no leader, can not reinitialize)`:

    For example:

    ```bash
    ncn-mw# kubectl exec cray-console-data-postgres-0 -n services -- bash
    root@cray-console-data-postgres-0:~# patronictl reinit cray-console-data-postgres cray-console-data-postgres-1
    ```

    Example output:

    ```text
    + Cluster: cray-console-data-postgres (7072784871993835594) ---+----+-----------+
    |            Member            |    Host    |  Role  |  State  | TL | Lag in MB |
    +------------------------------+------------+--------+---------+----+-----------+
    | cray-console-data-postgres-0 | 10.39.0.74 | Leader | running |  1 |           |
    | cray-console-data-postgres-1 | 10.36.0.37 |        | running |  1 |        16 |
    | cray-console-data-postgres-2 | 10.32.0.1  |        | running |  1 |        16 |
    +------------------------------+------------+--------+---------+----+-----------+
    Are you sure you want to reinitialize members cray-console-data-postgres-1? [y/N]: y
    Failed: reinitialize for member cray-console-data-postgres-1, status code=503, (Cluster has no leader, can not reinitialize)
    ```

    1. Delete the Postgres leader pod and wait for the leader to restart.

        ```bash
        ncn-mw# kubectl delete pod cray-console-data-postgres-0 -n services
        ```

        ```bash
        ncn-mw# kubectl exec keycloak-postgres-0 -c postgres -n services -it -- patronictl list
        ```

        Example output:

        ```text
        + Cluster: cray-console-data-postgres (7072784871993835594) ---+----+-----------+
        |            Member            |    Host    |  Role  |  State  | TL | Lag in MB |
        +------------------------------+------------+--------+---------+----+-----------+
        | cray-console-data-postgres-0 | 10.39.0.80 | Leader | running |  2 |           |
        | cray-console-data-postgres-1 | 10.36.0.37 |        | running |  1 |        49 |
        | cray-console-data-postgres-2 | 10.32.0.1  |        | running |  1 |        49 |
        +------------------------------+------------+--------+---------+----+-----------+
        ```

    1. Re-run [Is Replication Lagging?](#lag) to `reinit` any lagging members.

    1. If the `reinit` still fails, then delete member pods that are still reporting lag. This should clear up any remaining lag.

       ```bash
        ncn-mw# kubectl exec cray-console-postgres-0 -c postgres -n services -it -- patronictl list
        ```

        Example output:

        ```text
        + Cluster: cray-console-data-postgres (7072784871993835594) ---+----+-----------+
        |            Member            |    Host    |  Role  |  State  | TL | Lag in MB |
        +------------------------------+------------+--------+---------+----+-----------+
        | cray-console-data-postgres-0 | 10.39.0.80 | Leader | running |  2 |           |
        | cray-console-data-postgres-1 | 10.36.0.37 |        | running |  1 |        49 |
        | cray-console-data-postgres-2 | 10.32.0.1  |        | running |  1 |        49 |
        +------------------------------+------------+--------+---------+----+-----------+
        ```

        ```bash
        ncn-mw# kubectl delete pod cray-console-data-postgres-1 cray-console-data-postgres-2 -n services
        ```

        Once the pods restart, verify that the lag has resolved:

        Example output:

        ```text
        + Cluster: cray-console-data-postgres (7072784871993835594) ---+----+-----------+
        |            Member            |    Host    |  Role  |  State  | TL | Lag in MB |
        +------------------------------+------------+--------+---------+----+-----------+
        | cray-console-data-postgres-0 | 10.39.0.80 | Leader | running |  2 |           |
        | cray-console-data-postgres-1 | 10.36.0.37 |        | running |  2 |         0 |
        | cray-console-data-postgres-2 | 10.32.0.1  |        | running |  2 |         0 |
        +------------------------------+------------+--------+---------+----+-----------+
        ```

- If a cluster member is `stopped` after a successful reinitialization, check for `pg_internal.init.*` files that may need to be cleaned up. This can occur if the `pgdata` disk was full prior to the reinitialization, leaving truncated `pg_internal.init.*` files in the `pgdata` directory.

    ```bash
    ncn-mw# kubectl exec keycloak-postgres-0 -c postgres -n services -it -- patronictl list
    ```

    Example output:

    ```text
    +-------------------+---------------------+--------------+--------+---------+----+-----------+
    |      Cluster      |        Member       |     Host     |  Role  |  State  | TL | Lag in MB |
    +-------------------+---------------------+--------------+--------+---------+----+-----------+
    | keycloak-postgres | keycloak-postgres-0 | 10.42.10.22  |        | running | 47 |         0 |
    | keycloak-postgres | keycloak-postgres-1 | 10.40.11.191 | Leader | running | 47 |           |
    | keycloak-postgres | keycloak-postgres-2 | 10.40.11.190 |        | stopped |    |   unknown |
    +-------------------+---------------------+--------------+--------+---------+----+-----------+
    ```

    `kubectl exec` into that pod that is `stopped` and check the most recent Postgres log for any `invalid segment number 0` errors relating to `pg_internal.init.*` files.

    ```bash
    ncn-mw# kubectl exec keycloak-postgres-2 -n services -it -- bash
    postgres@keycloak-postgres-2:~$ export LOG=`ls -t /home/postgres/pgdata/pgroot/pg_log/*.csv | head -1`
    postgres@keycloak-postgres-2:~$ grep pg_internal.init $LOG | grep "invalid segment number 0" | tail -1
    ```

    Example output:

    ```text
    2022-02-01 16:59:35.529 UTC,"standby","",227600,"127.0.0.1:42264",61f966f7.37910,3,"sending backup ""pg_basebackup base backup""",2022-02-01 16:59:35 UTC,7/0,0,ERROR,XX000,"invalid segment number 0 in file ""pg_internal.init.2239188""",,,,,,,,,"pg_basebackup"
    ```

    If the check above finds such files, first find any zero length `pg_internal.init.*` files.

    ```bash
    postgres@keycloak-postgres-2:~$ find /home/postgres/pgdata -name pg_internal.init.* -size 0
    ```

    Example output:

    ```text
    ./pgroot/data/base/16622/pg_internal.init.2239004
    ...
    ./pgroot/data/base/16622/pg_internal.init.2239010
    ```

    Then delete the zero length `pg_internal.init.*` files. Double check the syntax of the command in this step before executing it.

    ```bash
    postgres@keycloak-postgres-2:~$ find /home/postgres/pgdata -name pg_internal.init.* -size 0 -exec rm {} \;
    ```

    Next find any non-zero length `pg_internal.init.*` files that were truncated when the file system filled up.

    ```bash
    postgres@keycloak-postgres-2:~$ grep pg_internal.init $LOG | grep "invalid segment number 0" | tail -1
    ```

    Example output:

    ```text
    2022-02-01 16:59:35.529 UTC,"standby","",227600,"127.0.0.1:42264",61f966f7.37910,3,"sending backup ""pg_basebackup base backup""",2022-02-01 16:59:35 UTC,7/0,0,ERROR,XX000,"invalid segment number 0 in file ""pg_internal.init.2239188""",,,,,,,,,"pg_basebackup"
    ```

    Locate the non-zero length `pg_internal.init.*` file.

    ```bash
    postgres@keycloak-postgres-2:~$ find ~/pgdata -name pg_internal.init.2239188
    ```

    Example output:

    ```text
    /home/postgres/pgdata/pgroot/data/base/16622/pg_internal.init.2239188
    ```

    Then delete (or move to a different location) the non-zero length `pg_internal.init.*` file.

    ```bash
    postgres@keycloak-postgres-2:~$ rm /home/postgres/pgdata/pgroot/data/base/16622/pg_internal.init.2239188
    ```

    Iterate over the above steps to find, locate, and delete non-zero length `pg_internal.init.*` files until there are no more new `invalid segment number 0` messages. At this point, verify that the cluster member has started.

    ```bash
    ncn-mw# kubectl exec keycloak-postgres-0 -c postgres -n services -it -- patronictl list
    ```

    Example output:

    ```text
    +-------------------+---------------------+--------------+--------+---------+----+-----------+
    |      Cluster      |        Member       |     Host     |  Role  |  State  | TL | Lag in MB |
    +-------------------+---------------------+--------------+--------+---------+----+-----------+
    | keycloak-postgres | keycloak-postgres-0 | 10.42.10.22  |        | running | 47 |         0 |
    | keycloak-postgres | keycloak-postgres-1 | 10.40.11.191 | Leader | running | 47 |           |
    | keycloak-postgres | keycloak-postgres-2 | 10.40.11.190 |        | running | 47 |         0 |
    +-------------------+---------------------+--------------+--------+---------+----+-----------+
    ```

### Setup Alerts for Replication Lag

Alerts exist in Prometheus for the following:

- `PostgresqlReplicationLagSMA`
- `PostgresqlReplicationLagServices`
- `PostgresqlFollowerReplicationLagSMA`
- `PostgresqlFollowerReplicationLagServices`

When alert notifications are configured, replication issues can be detected quickly. If the replication issue persists such that the database becomes unavailable, recovery will likely be much more involved. Catching such issues as soon as possible is desired. See [Configure Prometheus Email Alert Notifications](../system_management_health/Configure_Prometheus_Email_Alert_Notifications.md).

<a name="syncfailed"></a>
## Is the Postgres status `SyncFailed`?

### Check all the `postgresql` resources

Check for any `postgresql` resource that has a `STATUS` of `SyncFailed`. `SyncFailed` generally means that there is something between the `postgres-operator` and the Postgres cluster that is out of sync. This does not always mean that the cluster is unhealthy. To determine the underlying sync issue, check the `postgres-operator` logs for messages to further root cause the issue.

Other `STATUS` values such as `Updating` are a non-issue. It is expected that this will eventually change to `Running` or possibly `SyncFailed` if the `postgres-operator` encounters issues syncing updates to the `postgresql` cluster.

1. Check for any `postgresql` resource that has a `STATUS` of `SyncFailed`.

    ```bash
    ncn-mw# kubectl get postgresql -A
    ```

    Example output:

    ```text
    NAMESPACE   NAME                         TEAM                VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE     STATUS
    services    cray-console-data-postgres   cray-console-data   11        3      2Gi                                     4h10m   Running
    services    cray-sls-postgres            cray-sls            11        3      1Gi                                     4h12m   SyncFailed
    services    cray-smd-postgres            cray-smd            11        3      30Gi     500m          8Gi              4h12m   Updating
    services    gitea-vcs-postgres           gitea-vcs           11        3      50Gi                                    4h11m   Running
    services    keycloak-postgres            keycloak            11        3      1Gi                                     4h13m   Running
    spire       spire-postgres               spire               11        3      20Gi     1             4Gi              4h10m   Running
    ```

1. Find the the `postgres-operator` pod name.

    ```bash
    ncn-mw# kubectl get pods -l app.kubernetes.io/name=postgres-operator -n services
    ```

    Example output:

    ```text
    NAME                                      READY   STATUS    RESTARTS   AGE
    cray-postgres-operator-6fffc48b4c-mqz7z   2/2     Running   0          5h26m
    ```

1. Check the logs for the `postgres-operator`.

    ```
    ncn-mw# kubectl logs cray-postgres-operator-6fffc48b4c-mqz7z -n services \
    -c postgres-operator | grep -i sync | grep -i msg
    ```

#### Case 1 : `msg="could not sync cluster: could not sync persistent volumes: could not sync volumes: could not resize EBS volumes: some persistent volumes are not compatible with existing resizing providers"`

This generally means that the `postgresql` resource was updated to change the volume size from the Postgres operator's perspective, but the additional step to resize the actual PVCs was not done so the operator and the Postgres cluster are not able to sync the resize change. The cluster is still healthy, but to complete the resize of the underlying Postgres PVCs, additional steps are needed.

The example below assumes that `cray-smd-postgres` is in `SyncFailed` and the volume size was recently increased to `100Gi` (possibly by editing the volume size of `postgresql` `cray-smd-postgres` resource), but the `pgdata-cray-smd-postgres` PVC's storage capacity was not updated to align with the change. To confirm this is the case:

```bash
ncn-mw# kubectl get postgresql cray-smd-postgres -n services -o jsonpath="{.spec.volume.size}"
100Gi

ncn-mw# kubectl get pvc -n services -l application=spilo,cluster-name=cray-smd-postgres
NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
pgdata-cray-smd-postgres-0   Bound    pvc-020cf339-e372-46ae-bc37-de2b55320e88   30Gi       RWO            k8s-block-replicated   70m
pgdata-cray-smd-postgres-1   Bound    pvc-3d42598a-188e-4301-a58e-0f0ce3944c89   30Gi       RWO            k8s-block-replicated   27m
pgdata-cray-smd-postgres-2   Bound    pvc-0d659080-7d39-409a-9ee5-1a1806971054   30Gi       RWO            k8s-block-replicated   27m
```

To resolve this `SyncFailed` case, resize the `pgdata` PVCs for the selected Postgres cluster. Create the following function in the shell and execute the function by calling it with the appropriate arguments. For this example the `pgdata-cray-smd-postgres` PVCs will be resized to `100Gi` to match that of the `postgresql` `cray-smd-postgres` volume size.

```bash
function resize-postgresql-pvc
{
    POSTGRESQL=$1
    PGDATA=$2
    NAMESPACE=$3
    PGRESIZE=$4

    # Check for required arguments
    if [ $# -ne 4 ]; then
        echo "Illegal number of parameters ($#). Function requires exactly 4 arguments."
        exit 2
    fi

    ## Check that PGRESIZE matches current postgresql volume size
    postgresql_volume_size=$(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o jsonpath="{.spec.volume.size}")
    if [ "${postgresql_volume_size}" != "${PGRESIZE}" ]; then
         echo "Invalid resize ${PGRESIZE}, expected ${postgresql_volume_size}"
         exit 2
    fi

    ## Scale the postgres cluster to 1 member
    kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 1}]'
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n "${NAMESPACE}" | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pods to terminate"
        sleep 2
    done

    ## Delete the inactive PVCs, resize the active PVC, and wait for the resize to complete
    kubectl delete pvc "${PGDATA}-1" "${PGDATA}-2" -n "${NAMESPACE}"
    kubectl patch -p '{"spec": {"resources": {"requests": {"storage": "'${PGRESIZE}'"}}}}' "pvc/${PGDATA}-0" -n "${NAMESPACE}"
    while [ -z '$(kubectl describe pvc "{PGDATA}-0" -n "${NAMESPACE}" | grep FileSystemResizeSuccessful' ] ; do
        echo "  waiting for PVC to resize"
        sleep 2
    done

    ## Scale the postgres cluster back to 3 members
    kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n "${NAMESPACE}" | grep -v NAME | grep -c "Running") != 3 ] ; do
        echo "  waiting for pods to restart"
        sleep 2
    done
}
```

```bash
ncn-mw# resize-postgresql-pvc cray-smd-postgres pgdata-cray-smd-postgres services 100Gi
```

In order to persist any Postgres PVC storage volume size changes, it is necessary that this change also be made to the customer-managed `customizations.yaml` file. See the Postgres PVC Resize information in the [Post Install Customizations](../CSM_product_management/Post_Install_Customizations.md#postgres_pvc_resize) document.

#### Case 2: `msg="could not sync cluster: could not sync roles: could not init db connection: could not init db connection: still failing after 8 retries"`

This generally means that some state in the Postgres operator is out of sync with that of the `postgresql` cluster, resulting in database connection issues. To resolve this `SyncFailed` case, restarting the Postgres operator by deleting the pod may clear up the issue.

```bash
ncn-mw# kubectl delete pod -l app.kubernetes.io/name=postgres-operator -n services
```

Wait for the `postgres-operator` to restart

```bash
ncn-mw# kubectl get pods -l app.kubernetes.io/name=postgres-operator -n services
NAME                                      READY   STATUS    RESTARTS   AGE
cray-postgres-operator-6fffc48b4c-mqz7z   2/2     Running   0           6m
```

If the database connection has been down for a long period of time and the `SyncFailed` persists after the above steps, a restart of the cluster and the `postgres-operator` may be needed for the service to reconnect to the Postgres cluster. For example, if the `cray-gitea` service is not able to connect to the Postgres database and the connection has been failing for many hours, restart the cluster and operator.

Scale the service to 0
```bash
ncn-mw# CLIENT=gitea-vcs
ncn-mw# POSTGRESQL=gitea-vcs-postgres
ncn-mw# NAMESPACE=services
ncn-mw# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=0
```

Restart the Postgres cluster and the `postgres-operator`

```bash
ncn-mw# kubectl delete pod "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2" -n ${NAMESPACE}
ncn-mw# kubectl delete pods -n services -lapp.kubernetes.io/name=postgres-operator
ncn-mw# while [ $(kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq -r '.status.PostgresClusterStatus') != "Running" ]; do echo "waiting for ${POSTGRESQL} to start running"; sleep 2; done
```

Scale the service back to 1 (for different services this may be to 3)

```bash
ncn-mw# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=1
```

#### Case 3: `msg="error while syncing cluster state: could not sync roles: could not init db connection: could not init db connection: pq: password authentication failed for user \<username\>"`

This generally means that the password for the given user is not the same as that specified in the Kubernetes secret. This can occur if the `postgresql` cluster was rebuilt and the data was restored, leaving the Kubernetes secrets out of sync with the Postgres cluster. To resolve this `SyncFailed` case, gather the username and password for the credential from Kubernetes, and update the database with these values. For example, if the user `postgres` is failing to authenticate between the `cray-smd` services and the `cray-smd-postgres` cluster, then get the password for the `postgres` user from the Kubernetes secret and update the password in the database.

1. Set necessary variables.

    ```bash
    ncn-mw# CLIENT=cray-smd
    ncn-mw# POSTGRESQL=cray-smd-postgres
    ncn-mw# NAMESPACE=services
    ```

1. Scale the service to 0

    ```bash
    ncn-mw# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=0
    ncn-mw# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do
                echo "  waiting for pods to terminate"
                sleep 2
            done
    ```

1. Determine what secrets are associated with the `postgresql` credentials.

    ```bash
    ncn-mw# kubectl get secrets -n ${NAMESPACE} | grep "${POSTGRESQL}.credentials"
    services            hmsdsuser.cray-smd-postgres.credentials                       Opaque                                2      31m
    services            postgres.cray-smd-postgres.credentials                        Opaque                                2      31m
    services            service-account.cray-smd-postgres.credentials                 Opaque                                2      31m
    services            standby.cray-smd-postgres.credentials                         Opaque                                2      31m
    ```

1. Gather the decoded username and password for the user that is failing to authenticate - for example:

    `postgres.cray-smd-postgres.credentials`:
    ```bash
    ncn-mw# kubectl get secret postgres.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d
    postgres
    ncn-mw# kubectl get secret postgres.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d
    ABCXYZ
    ```

1. `kubectl exec` into the postgres leader, and update the username and password in the database.

    ```bash
    ncn-mw# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    |      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    | cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 | Leader | running |  1 |           |
    | cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |        | running |    |         0 |
    | cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |        | running |    |         0 |
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    ncn-mw# POSTGRES_LEADER=cray-smd-postgres-0
    ncn-mw# kubectl exec ${POSTGRES_LEADER} -n ${NAMESPACE} -c postgres -it -- bash
    root@cray-smd-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
    postgres=# ALTER USER postgres WITH PASSWORD 'ABCXYZ';
    ALTER ROLE
    postgres=#
    ```

1. Restart the `postgresql` cluster.

    ```bash
    ncn-mw# kubectl delete pod "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2" -n ${NAMESPACE}
    ncn-mw# while [ $(kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq -r '.status.PostgresClusterStatus') != "Running" ]; do
                echo "waiting for ${POSTGRESQL} to start running"
                sleep 2
            done
    ```

1. Scale the service back to 3

    ```bash
    ncn-mw# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=3
    ncn-mw# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do
                echo "  waiting for pods to start running"
                sleep 2
            done
    ```

<a name="missing"></a>
## Is a Cluster Member missing?

Most services expect to maintain a Postgres cluster consisting of three pods for resiliency (SMA is one exception where only two pods are expected to exist).

### Determine if a cluster member is missing

For a given Postgres cluster, check how many pods are running.

```bash
ncn-mw# POSTGRESQL=keycloak-postgres
ncn-mw# NAMESPACE=services
ncn-mw# kubectl get pods -A -l "application=spilo,cluster-name=${POSTGRESQL}"
```

### Recover from a missing member

If the number of Postgres pods for the given cluster is more or less than expected, increase or decrease as needed. This example will patch the `keycloak-postgres` cluster resource so that three pods should be running.

1. Set the `POSTGRESQL` and `NAMESPACE` variables.

    ```bash
    ncn-mw# POSTGRESQL=keycloak-postgres
    ncn-mw# NAMESPACE=services
    ```

1. Patch the `keycloak-postgres` cluster resource to ensure three pods are running.

    ```bash
    ncn-mw# kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' \
    -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'
    ```

1. Confirm the number of cluster members, otherwise known as pods, by checking the `postgresql` resource.

    ```bash
    ncn-mw# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE}
    NAME                TEAM       VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
    keycloak-postgres   keycloak   11        3      10Gi                                    29m   Running
    ```

1. If a pod is starting but remains in `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`, or other non-`Running` states, describe the pod and/or get logs from the pod for further analysis.

    1. Find the pod name.

        ```bash
        ncn-mw# kubectl get pods -A -l "application=spilo,cluster-name=${POSTGRESQL}"
        ```

        Example output:

        ```text
        NAMESPACE   NAME                  READY   STATUS    RESTARTS   AGE
        services    keycloak-postgres-0   0/3     Pending   0          36m
        services    keycloak-postgres-1   3/3     Running   0          35m
        services    keycloak-postgres-2   3/3     Running   0          34m
        ```

    1. Describe the pod.

        ```
        ncn-mw# kubectl describe pod "${POSTGRESQL}-0" -n ${NAMESPACE}
        ```

    1. View the pod logs.

        ```
        ncn-mw# kubectl logs "${POSTGRESQL}-0" -c postgres -n ${NAMESPACE}
        ```

<a name="leader"></a>
## Is the Postgres Leader missing?

If a Postgres cluster no longer has a leader, the database will need to be recovered.

### Determine if the Postgres Leader is missing

1. Set the `POSTGRESQL` and `NAMESPACE` variables.

    ```bash
    ncn-mw# POSTGRESQL=cray-smd-postgres
    ncn-mw# NAMESPACE=services
    ```

1. Check if the leader is missing.

    ```
    ncn-mw# kubectl exec ${POSTGRESQL}-0 -n ${NAMESPACE} -c postgres -- patronictl list
    ```

    Example output:

    ```text
    +-------------------+---------------------+------------+------+--------------+----+-----------+
    |      Cluster      |        Member       |    Host    | Role |    State     | TL | Lag in MB |
    +-------------------+---------------------+------------+------+--------------+----+-----------+
    | cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 |      |  running     |    |   unknown |
    | cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |      | start failed |    |   unknown |
    | cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |      | start failed |    |   unknown |
    +-------------------+---------------------+------------+------+--------------+----+-----------+
    ```

### Recover from a missing Postgres Leader

See the [Recover from Postgres WAL Event](Recover_from_Postgres_WAL_Event.md) procedure.
