# Create a Backup of the Spire Postgres Database

Perform a manual backup of the contents of the Spire Postgres database. This backup can be used to restore the contents of the Spire Postgres database at a later point
in time using the [Restore Spire Postgres from Backup](../kubernetes/Restore_Postgres.md#restore-postgres-for-spire) procedure.

## Prerequisites

- Healthy Spire Postgres Cluster.

  Use `patronictl list` on the Spire Postgres cluster to determine the current state of the cluster and note which member is the `Leader`. A healthy cluster will look similar to the following:

  ```bash
  ncn-mw# kubectl exec spire-postgres-0 -n spire -c postgres -it -- patronictl list
  ```

  Example output:

  ```text
  + Cluster: spire-postgres (7062403223429402699) -----+----+-----------+
  |      Member      |     Host     |  Role  |  State  | TL | Lag in MB |
  +------------------+--------------+--------+---------+----+-----------+
  | spire-postgres-0 | 10.44.43.64  |        | running | 12 |         0 |
  | spire-postgres-1 | 10.33.92.221 | Leader | running | 12 |           |
  | spire-postgres-2 | 10.32.55.219 |        | running | 12 |         0 |
  +------------------+--------------+--------+---------+----+-----------+
  ```

- Healthy Spire Service.

  Verify all 3 Spire replicas are up and running:

  ```bash
  ncn-mw# kubectl -n spire get pods -l application=spilo,cluster-name=spire-postgres
  ```

  Example output:

  ```text
  NAME                                     READY   STATUS    RESTARTS   AGE
  spire-postgres-0                         3/3     Running   0          11d
  spire-postgres-1                         3/3     Running   0          11d
  spire-postgres-2                         3/3     Running   0          11d
  ```

## Procedure

1. Set the Spire variables including the `Leader` which for this case is the member `spire-postgres-1`.

    ```bash
    ncn-mw# CLIENT=spire-server
    ncn-mw# POSTGRESQL=spire-postgres
    ncn-mw# NAMESPACE=spire
    ncn-mw# POSTGRES_LEADER=spire-postgres-1
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
