# Restore SLS Postgres Database from Backup

This procedure can be used to restore the SLS Postgres database from a previously taken backup.
This can be a manual backup created by the [Create a Backup of the SLS Postgres Database](Create_a_Backup_of_the_SLS_Postgres_Database.md) procedure, or an automatic backup created
by the `cray-sls-postgresql-db-backup` Kubernetes cronjob.

## Prerequisites

* Healthy Postgres Cluster.
    > Use `patronictl list` on the SLS Postgres cluster to determine the current state of the cluster, and a healthy cluster will look similar to the following:
    >
    > ```bash
    > ncn# kubectl exec cray-sls-postgres-0 -n services -c postgres -it -- patronictl list
    > + Cluster: cray-sls-postgres (6975238790569058381) ---+----+-----------+
    > |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
    > +---------------------+------------+--------+---------+----+-----------+
    > | cray-sls-postgres-0 | 10.44.0.40 | Leader | running |  1 |           |
    > | cray-sls-postgres-1 | 10.36.0.37 |        | running |  1 |         0 |
    > | cray-sls-postgres-2 | 10.42.0.42 |        | running |  1 |         0 |
    > +---------------------+------------+--------+---------+----+-----------+
    > ```

* Previously taken backup of the SLS Postgres cluster either a manual or automatic backup.
    > Check for any available automatic SLS Postgres backups:
    >
    > ```bash
    > ncn# cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("sls"))'
    > cray-sls-postgres-2021-07-11T23:10:08.manifest
    > cray-sls-postgres-2021-07-11T23:10:08.psql
    > ```

## Procedure

1. Retrieve a previously taken SLS Postgres backup.
   This can be either a previously taken manual SLS backup or an automatic Postgres backup in the `postgres-backup` S3 bucket.

    * From a previous manual backup:
        1. Copy over the folder or tarball containing the Postgres back up to be restored. If it is a tarball extract it.

        2. Set the environment variable `POSTGRES_SQL_FILE` to point toward the `.psql` file in the backup folder:

            ```bash
            ncn# export POSTGRES_SQL_FILE=/root/cray-sls-postgres-backup_2021-07-07_16-39-44/cray-sls-postgres-backup_2021-07-07_16-39-44.psql
            ```

        3. Set the environment variable `POSTGRES_SECRET_MANIFEST` to point toward the `.manifest` file in the backup folder:

            ```bash
            ncn# export POSTGRES_SECRET_MANIFEST=/root/cray-sls-postgres-backup_2021-07-07_16-39-44/cray-sls-postgres-backup_2021-07-07_16-39-44.manifest
            ```

    * From a previous automatic Postgres backup:
        1. Check for available backups:

            ```bash
            ncn# cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("sls"))'
            cray-sls-postgres-2021-07-11T23:10:08.manifest
            cray-sls-postgres-2021-07-11T23:10:08.psql
            ```

            Then set the following environment variables for the name of the files in the backup:

            ```bash
            ncn# export POSTGRES_SECRET_MANIFEST_NAME=cray-sls-postgres-2021-07-11T23:10:08.manifest
            ncn# export POSTGRES_SQL_FILE_NAME=cray-sls-postgres-2021-07-11T23:10:08.psql
            ```

        2. Download the `.psql` file for the postgres backup:

            ```bash
            ncn# cray artifacts get postgres-backup "$POSTGRES_SQL_FILE_NAME" "$POSTGRES_SQL_FILE_NAME"
            ```

        3. Download the `.manifest` file for the SLS backup:

            ```bash
            ncn# cray artifacts get postgres-backup "$POSTGRES_SECRET_MANIFEST_NAME" "$POSTGRES_SECRET_MANIFEST_NAME"
            ```

        4. Setup environment variables pointing to the full path of the `.psql` and `.manifest` files:

            ```bash
            ncn# export POSTGRES_SQL_FILE=$(realpath "$POSTGRES_SQL_FILE_NAME")
            ncn# export POSTGRES_SECRET_MANIFEST=$(realpath "$POSTGRES_SECRET_MANIFEST_NAME")
            ```

2. Verify the `POSTGRES_SQL_FILE` and `POSTGRES_SECRET_MANIFEST` environment variables are set correctly:

    ```bash
    ncn# echo "$POSTGRES_SQL_FILE"
    /root/cray-sls-postgres-backup_2021-07-07_16-39-44/cray-sls-postgres-backup_2021-07-07_16-39-44.psql

    ncn# echo "$POSTGRES_SECRET_MANIFEST"
    /root/cray-sls-postgres-backup_2021-07-07_16-39-44/cray-sls-postgres-backup_2021-07-07_16-39-44.manifest
    ```

3. Re-run the SLS loader job:

    ```bash
    ncn# kubectl -n services get job cray-sls-init-load -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | kubectl replace --force -f -
    ```

    Wait for the job to complete:

    ```bash
    ncn# kubectl wait -n services job cray-sls-init-load --for=condition=complete --timeout=5m
    ```

4. Determine leader of the Postgres cluster:

    ```bash
    ncn# export POSTGRES_LEADER=$(kubectl exec cray-sls-postgres-0 -n services -c postgres -t -- patronictl list -f json | jq  -r '.[] | select(.Role == "Leader").Member')
    ```

    Check the environment variable to see the current leader of the Postgres cluster:

    ```bash
    ncn# echo $POSTGRES_LEADER
    cray-sls-postgres-0
    ```

5. Determine the database schema version of the currently running SLS database and verify that it matches the database schema version from the Postgres backup:

    Database schema of the currently running SLS Postgres instance.

    ```bash
    ncn# kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U slsuser -d sls -c 'SELECT * FROM schema_migrations'"
    ```

    Example output:

    ```text
     version | dirty
    ---------+-------
           3 | f
    (1 row)
    ```

    > The output above shows the database schema is at version 3.

    Database schema version from the Postgres backup:

    ```bash
    ncn# cat "$POSTGRES_SQL_FILE" | grep "COPY public.schema_migrations" -A 2
    ```

    Example output:

    ```text
    COPY public.schema_migrations (version, dirty) FROM stdin;
    3       f
    \.
    ```

    > The output above shows the database schema is at version 3.

    If the database schema versions match, proceed to the next step.
    Otherwise, the Postgres backup taken is not applicable to the currently running instance of SLS.

    __WARNING__: If the database schema versions do not match the version of the SLS deployed will need to be either upgraded/downgraded to a version with a compatible database schema version.
    Ideally to the same version of SLS that was used to create the Postgres backup.

6. Restore the database from the backup using the `restore_sls_postgres_from_backup.sh` script. This script requires the `POSTGRES_SQL_FILE` and `POSTGRES_SECRET_MANIFEST` environment variables to be set.
    > __THIS WILL DELETE AND REPLACE THE CURRENT CONTENTS OF THE SLS DATABASE__

    ```bash
    ncn# /usr/share/doc/csm/scripts/operations/system_layout_service/restore_sls_postgres_from_backup.sh
    ```

7. Verify the health of the SLS Postgres cluster by running the `ncnPostgresHealthChecks.sh` script. Follow the [`ncnPostgresHealthChecks` topic in Validate CSM Health document](../validate_csm_health.md#pet-ncnpostgreshealthchecks).

8. Verify that the service is functional:

    ```bash
    ncn# cray sls version list
    ```

    Example output:

    ```text
    Counter = 5
    LastUpdated = "2021-04-05T22:51:36.575276Z"
    ```

    Get the number of hardware objects stored in SLS:

    ```bash
    ncn# cray sls hardware list --format json | jq .[].Xname | wc -l
    ```

    Get the name of networks stored in SLS:

    > If the system does not have liquid cooled hardware, the `HMN_MTN` and `NMN_MTN` networks may not be present.

    ```bash
    ncn# cray sls networks list --format json | jq -r .[].Name
    ```

    Example output:

    ```text
    HMN_MTN
    HMN_RVR
    NMNLB
    NMN
    NMN_MTN
    NMN_RVR
    CAN
    HMN
    HMNLB
    HSN
    MTL
    ```
