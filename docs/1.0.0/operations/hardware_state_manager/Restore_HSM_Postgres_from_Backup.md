# Restore Hardware State Manager (HSM) Postgres Database from Backup

This procedure can be used to restore the HSM Postgres database from a previously taken backup. This can be a manual backup created by the [Create a Backup of the HSM Postgres Database](Create_a_Backup_of_the_HSM_Postgres_Database.md) procedure, or an automatic backup created by the `cray-smd-postgresql-db-backup` Kubernetes cronjob.

### Prerequisites

- Healthy System Layout Service (SLS). Recovered first if also affected.

- Healthy HSM Postgres Cluster.

  Use `patronictl list` on the HSM Postgres cluster to determine the current state of the cluster, and a healthy cluster will look similar to the following:

  ```bash
  ncn# kubectl exec cray-smd-postgres-0 -n services -c postgres -it -- patronictl list
  + Cluster: cray-smd-postgres (6975238790569058381) ---+----+-----------+
  |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
  +---------------------+------------+--------+---------+----+-----------+
  | cray-smd-postgres-0 | 10.44.0.40 | Leader | running |  1 |           |
  | cray-smd-postgres-1 | 10.36.0.37 |        | running |  1 |         0 |
  | cray-smd-postgres-2 | 10.42.0.42 |        | running |  1 |         0 |
  +---------------------+------------+--------+---------+----+-----------+
  ```

- Previously taken backup of the HSM Postgres cluster either a manual or automatic backup.

  Check for any available automatic HSM Postgres backups:

  ```bash
  ncn# cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("smd"))'
  cray-smd-postgres-2021-07-11T23:10:08.manifest
  cray-smd-postgres-2021-07-11T23:10:08.psql
  ```

### Procedure

1. Retrieve a previously taken HSM Postgres backup. This can be either a previously taken manual HSM backup or an automatic Postgres backup in the `postgres-backup` S3 bucket.

    - From a previous manual backup:

        1. Copy over the folder or tarball containing the Postgres backup to be restored. If it is a tarball, extract it.

        2. Set the environment variable `POSTGRES_SQL_FILE` to point toward the `.psql` file in the backup folder:

            ```bash
            ncn# export POSTGRES_SQL_FILE=/root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.psql
            ```

        3. Set the environment variable `POSTGRES_SECRET_MANIFEST` to point toward the `.manifest` file in the backup folder:

            ```bash
            ncn# export POSTGRES_SECRET_MANIFEST=/root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.manifest
            ```

    - From a previous automatic Postgres backup:

        1. Check for available backups.

            ```bash
            ncn# cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("smd"))'
            cray-smd-postgres-2021-07-11T23:10:08.manifest
            cray-smd-postgres-2021-07-11T23:10:08.psql
            ```

            Set the following environment variables for the name of the files in the backup:

            ```bash
            ncn# export POSTGRES_SECRET_MANIFEST_NAME=cray-smd-postgres-2021-07-11T23:10:08.manifest
            ncn# export POSTGRES_SQL_FILE_NAME=cray-smd-postgres-2021-07-11T23:10:08.psql
            ```

        2. Download the `.psql` file for the Postgres backup.

            ```bash
            ncn# cray artifacts get postgres-backup "$POSTGRES_SQL_FILE_NAME" "$POSTGRES_SQL_FILE_NAME"
            ```

        3. Download the `.manifest` file for the HSM backup.

            ```bash
            ncn# cray artifacts get postgres-backup "$POSTGRES_SECRET_MANIFEST_NAME" "$POSTGRES_SECRET_MANIFEST_NAME"
            ```

        4. Setup environment variables pointing to the full path of the `.psql` and `.manifest` files.

            ```bash
            ncn# export POSTGRES_SQL_FILE=$(realpath "$POSTGRES_SQL_FILE_NAME")
            ncn# export POSTGRES_SECRET_MANIFEST=$(realpath "$POSTGRES_SECRET_MANIFEST_NAME")
            ```

2. Verify the `POSTGRES_SQL_FILE` and `POSTGRES_SECRET_MANIFEST` environment variables are set correctly.

    ```bash
    ncn# echo "$POSTGRES_SQL_FILE"
    /root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.psql

    ncn# echo "$POSTGRES_SECRET_MANIFEST"
    /root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.manifest
    ```

3. Scale HSM to 0.

    ```bash
    ncn-w001# CLIENT=cray-smd
    ncn-w001# POSTGRESQL=cray-smd-postgres
    ncn-w001# NAMESPACE=services

    ncn-w001# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=0
    deployment.apps/cray-smd scaled

    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

4. Re-run the HSM loader job.

    ```bash
    ncn# kubectl -n services get job cray-smd-init -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | kubectl replace --force -f -
    ```

    Wait for the job to complete:

    ```bash
    ncn# kubectl wait -n services job cray-smd-init --for=condition=complete --timeout=5m
    ```

5. Determine which Postgres member is the leader.

    ```bash
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

6. Determine the database schema version of the currently running HSM database, and then verify that it matches the database schema version from the Postgres backup:

    Database schema of the currently running HSM Postgres instance.

    ```bash
    ncn# kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U hmsdsuser -d hmsds -c 'SELECT * FROM system'"
     id | schema_version | system_info
    ----+----------------+-------------
      0 |             17 | {}
    (1 row)
    ```

    > The output above shows the database schema is at version 17.

    Database schema version from the Postgres backup:

    ```bash
    ncn# cat "$POSTGRES_SQL_FILE" | grep "COPY public.system" -A 2
    COPY public.system (id, schema_version, dirty) FROM stdin;
    0       17       f
    \.
    ```

    > The output above shows the database schema is at version 17.

    If the database schema versions match, proceed to the next step. Otherwise, the Postgres backup taken is not applicable to the currently running instance of HSM.

    **WARNING:** If the database schema versions do not match the version of HSM deployed, they will need to be either upgraded/downgraded to a version with a compatible database schema version. Ideally, it will be to the same version of HSM that was used to create the Postgres backup.

7. Delete and re-create the postgresql resource (which includes the PVCs).

    ```bash
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

8. Determine which Postgres member is the new leader.

    ```bash
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

9. Copy the dump taken above to the Postgres leader pod and restore the data.

    If the dump exists in a different location, adjust this example as needed.

    ```bash
    ncn-w001# kubectl cp ${POSTGRES_SQL_FILE} ${POSTGRES_LEADER}:/home/postgres/cray-smd-postgres-dumpall.sql -c postgres -n ${NAMESPACE}

    ncn-w001# kubectl exec ${POSTGRES_LEADER} -c postgres -n ${NAMESPACE} -it -- psql -U postgres < cray-smd-postgres-dumpall.sql
    ```

10. Clear out of sync data from tables in postgres.

    The backup will have restored tables that may contain out of date information. To refresh this data, it must first be deleted.

    Delete the entries in the EthernetInterfaces table. These will automatically get repopulated during rediscovery.

    ```bash
    ncn# kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U hmsdsuser -d hmsds -c 'DELETE FROM comp_eth_interfaces'"
    ```

11. Restore the secrets.

    Once the dump has been restored onto the newly built postgresql cluster, the Kubernetes secrets need to match with the postgresql cluster, otherwise the service will experience readiness and liveness probe failures because it will be unable to authenticate to the database.

    - With secrets manifest from an existing backup
        If the Postgres secrets were auto-backed up, then re-create the secrets in Kubernetes.

        Delete and re-create the four `cray-smd-postgres` secrets using the manifest set to `POSTGRES_SECRET_MANIFEST` in step 1 above.

        ```bash
        ncn-w001# kubectl delete secret postgres.cray-smd-postgres.credentials service-account.cray-smd-postgres.credentials hmsdsuser.cray-smd-postgres.credentials standby.cray-smd-postgres.credentials -n ${NAMESPACE}

        ncn-w001# kubectl apply -f ${POSTGRES_SECRET_MANIFEST}
        ```

    - Without the previous secrets from a backup
        If the Postgres secrets were not backed up, then update the secrets in Postgres.

        Determine which Postgres member is the leader.

        ```bash
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

        ```bash
        ncn-w001# kubectl get secrets -n ${NAMESPACE} | grep "${POSTGRESQL}.credentials"
        services            hmsdsuser.cray-smd-postgres.credentials                       Opaque                                2      31m
        services            postgres.cray-smd-postgres.credentials                        Opaque                                2      31m
        services            service-account.cray-smd-postgres.credentials                 Opaque                                2      31m
        services            standby.cray-smd-postgres.credentials                         Opaque                                2      31m
        ```

        For each secret above, get the username and password from Kubernetes and update the Postgres database with this information.

        For example (hmsdsuser.cray-smd-postgres.credentials):

        ```bash
        ncn-w001# kubectl get secret hmsdsuser.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d
        hmsdsuser

        ncn-w001# kubectl get secret hmsdsuser.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d
        ABCXYZ
        ```

        Exec into the leader pod to reset the user's password:

        ```bash
        ncn-w001# kubectl exec ${POSTGRES_LEADER} -n ${NAMESPACE} -c postgres -it -- bash
        root@cray-smd-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
        postgres=# ALTER USER hmsdsuser WITH PASSWORD 'ABCXYZ';
        ALTER ROLE
        postgres=#
        ```
        Continue the above process until all ${POSTGRESQL}.credentials secrets have been updated in the database.

12. Restart the postgresql cluster.

    ```bash
    ncn-w001# kubectl delete pod "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2" -n ${NAMESPACE}

    ncn-w001# while [ $(kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq -r '.status.PostgresClusterStatus') != "Running" ]; do echo "waiting for ${POSTGRESQL} to start running"; sleep 2; done
    ```

13. Scale the client service back to 3.

    ```bash
    ncn-w001# kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=3

    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start running"; sleep 2; done
    ```

14. Verify that the service is functional.

    ```bash
    ncn# cray hsm service ready
    code = 0
    message = "HSM is healthy"
    ```

    Get the number of node objects stored in HSM:

    ```bash
    ncn# cray hsm state components list --type node --format json | jq .[].ID | wc -l
    1000
    ```

15. Resync the component state and inventory.

    After restoring HSM's postgres from a back up, some of the transient data like component state and hardware inventory may be out of sync with reality. This involves kicking off an HSM rediscovery.

    ```bash
    ncn# endpoints=$(cray hsm inventory redfishEndpoints list --format json | jq -r '.[]|.[]|.ID')
    ncn# for e in $endpoints; do cray hsm inventory discover create --xnames ${e}; done
    ```

    Wait for discovery to complete. Discovery is complete after there are no redfishEndpoints left in the 'DiscoveryStarted' state

    ```bash
    ncn# cray hsm inventory redfishEndpoints list --format json | grep -c "DiscoveryStarted"
    0
    ```

16. Check for discovery errors.

    ```bash
    ncn# cray hsm inventory redfishEndpoints list --format json | grep LastDiscoveryStatus | grep -v -c "DiscoverOK"
    ```

    If any of the RedfishEndpoint entries have a `LastDiscoveryStatus` other than `DiscoverOK` after discovery has completed, refer to the [Troubleshoot Issues with Redfish Endpoint Discovery](../node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md) procedure for guidance.

