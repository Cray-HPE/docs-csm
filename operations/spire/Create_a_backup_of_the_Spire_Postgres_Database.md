# Create a Backup of the Spire Postgres Database

Perform a manual backup of the contents of the Spire Postgres database. This backup can be used to restore the contents of the Spire Postgres database at a later point
in time using the [Restore Spire Postgres from Backup](../kubernetes/Restore_Postgres.md#restore-postgres-for-spire) procedure.

## Prerequisites

- Healthy Spire Postgres Cluster.

  Use `patronictl list` on the Cray Spire Postgres cluster to determine the current state of the cluster and note which member is the `Leader`. A healthy cluster will look similar to the following:

  ```bash
  ncn-mw# kubectl exec cray-spire-postgres-0 -n spire -c postgres -it -- patronictl list
  ```

  Example output:

  ```text
  + Cluster: cray-spire-postgres (7393064515405455433) ------+----+-----------+
  | Member                | Host         | Role    | State   | TL | Lag in MB |
  +-----------------------+--------------+---------+---------+----+-----------+
  | cray-spire-postgres-0 | 10.33.0.48   | Leader  | running |  3 |           |
  | cray-spire-postgres-1 | 10.34.128.31 | Replica | running |  3 |         0 |
  | cray-spire-postgres-2 | 10.35.0.26   | Replica | running |  3 |         0 |
  +-----------------------+--------------+---------+---------+----+-----------+
  ```

- Healthy Spire Service.

  Verify all 3 Spire replicas are up and running:

  ```bash
  ncn-mw# kubectl -n spire get pods -l application=spilo,cluster-name=cray-spire-postgres
  ```

  Example output:

  ```text
  NAME                                     READY   STATUS    RESTARTS   AGE
  cray-spire-postgres-0                    3/3     Running   0          11d
  cray-spire-postgres-1                    3/3     Running   0          11d
  cray-spire-postgres-2                    3/3     Running   0          11d
  ```

## Procedure

1. Set the Spire variables including the `Leader` which for this case is the member `cray-spire-postgres-0`.

    ```bash
    ncn-mw# CLIENT=cray-spire-server
    ncn-mw# POSTGRESQL=cray-spire-postgres
    ncn-mw# NAMESPACE=spire
    ncn-mw# POSTGRES_LEADER=cray-spire-postgres-0
    ```

2. Scale the client service down.

    ```bash
    ncn-mw# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    ncn-mw# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do
                echo "  waiting for pods to terminate"; sleep 2
            done
    ```

3. Create a dump of the Spire Postgres database.

    ```bash
    ncn-mw# kubectl exec -it ${POSTGRES_LEADER} -n ${NAMESPACE} -c postgres -- pg_dumpall -c -U postgres > "${POSTGRESQL}-dumpall.sql"
    ```

4. Copy the `${POSTGRESQL}-dumpall.sql` file off of the cluster, and store it in a secure location.

5. Scale the client service back up.

    ```bash
    ncn-mw# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=3
    ```
