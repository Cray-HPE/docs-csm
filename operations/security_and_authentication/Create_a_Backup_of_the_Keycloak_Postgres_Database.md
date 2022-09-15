# Create a Backup of the Keycloak Postgres Database

Perform a manual backup of the contents of the Keycloak Postgres database. This backup can be used to restore the contents of the Keycloak Postgres database at a later point
in time using the [Restore Keycloak Postgres from Backup](../kubernetes/Restore_Postgres.md#restore-postgres-for-keycloak) procedure.

## Prerequisites

- Healthy Keycloak Postgres Cluster.

  Use `patronictl list` on the Keycloak Postgres cluster to determine the current state of the cluster and note which member is the `Leader`. A healthy cluster will look similar to the following:

  ```bash
  ncn-mw# kubectl exec keycloak-postgres-0 -n services -c postgres -it -- patronictl list
  ```

  Example output:

  ```text
  + Cluster: keycloak-postgres (7062401252302942285) -----+----+-----------+
  |        Member       |     Host     |  Role  |  State  | TL | Lag in MB |
  +---------------------+--------------+--------+---------+----+-----------+
  | keycloak-postgres-0 | 10.32.55.217 | Leader | running | 13 |           |
  | keycloak-postgres-1 | 10.44.43.65  |        | running | 13 |         0 |
  | keycloak-postgres-2 | 10.33.92.236 |        | running | 13 |         0 |
  +---------------------+--------------+--------+---------+----+-----------+
  ```

- Healthy Keycloak Service.

  Verify all 3 Keycloak replicas are up and running:

  ```bash
  ncn-mw# kubectl -n services get pods -l cluster-name=keycloak-postgres
  ```

  Example output:

  ```text
  NAME                  READY   STATUS    RESTARTS   AGE
  keycloak-postgres-0   3/3     Running   0          12d
  keycloak-postgres-1   3/3     Running   0          12d
  keycloak-postgres-2   3/3     Running   0          12d
  ```

## Procedure

1. Set the Keycloak variables including the `Leader` which for this case is the member `keycloak-postgres-0`.

    ```bash
    ncn-mw# CLIENT=cray-keycloak
    ncn-mw# POSTGRESQL=keycloak-postgres
    ncn-mw# NAMESPACE=services
    ncn-mw# POSTGRES_LEADER=keycloak-postgres-0
    ```

2. Scale the client service down.

    ```bash
    ncn-mw# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    ncn-mw# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do 
                echo "  waiting for pods to terminate"; sleep 2
            done
    ```

3. Create a dump of the Keycloak Postgres database.

    ```bash
    ncn-mw# kubectl exec -it ${POSTGRES_LEADER} -n ${NAMESPACE} -c postgres -- pg_dumpall -c -U postgres > "${POSTGRESQL}-dumpall.sql"
    ```

4. Copy the `${POSTGRESQL}-dumpall.sql` file off of the cluster, and store it in a secure location.

5. Scale the client service back up.

    ```bash
    ncn-mw# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=3
    ```
