# Restore Hardware State Manager (HSM) Postgres Database from Backup

This procedure can be used to restore the HSM Postgres database from a previously taken backup. This can be a manual backup created by the [Create a Backup of the HSM Postgres Database](Create_a_Backup_of_the_HSM_Postgres_Database.md) procedure, or an
automatic backup created by the `cray-smd-postgresql-db-backup` Kubernetes cronjob.

## Prerequisites

- Healthy System Layout Service (SLS). Recovered first if also affected.

- (`ncn#`) Healthy HSM Postgres Cluster.

  Use `patronictl list` on the HSM Postgres cluster to determine the current state of the cluster, and a healthy cluster will look similar to the following:

  ```bash
  kubectl exec cray-smd-postgres-0 -n services -c postgres -it -- patronictl list
  ```

  Example output:

  ```text
  + Cluster: cray-smd-postgres (6975238790569058381) ---+----+-----------+
  |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
  +---------------------+------------+--------+---------+----+-----------+
  | cray-smd-postgres-0 | 10.44.0.40 | Leader | running |  1 |           |
  | cray-smd-postgres-1 | 10.36.0.37 |        | running |  1 |         0 |
  | cray-smd-postgres-2 | 10.42.0.42 |        | running |  1 |         0 |
  +---------------------+------------+--------+---------+----+-----------+
  ```

- (`ncn#`) Previously taken backup of the HSM Postgres cluster either a manual or automatic backup.

  Check for any available automatic HSM Postgres backups:

  ```bash
  cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("smd"))'
  ```

  Example output:

  ```text
  cray-smd-postgres-2021-07-11T23:10:08.manifest
  cray-smd-postgres-2021-07-11T23:10:08.psql
  ```

## Procedure

1. (`ncn#`) Retrieve a previously taken HSM Postgres backup. This can be either a previously taken manual HSM backup or an automatic Postgres backup in the `postgres-backup` S3 bucket.

    - From a previous manual backup:

        1. Copy over the folder or tarball containing the Postgres backup to be restored. If it is a tarball, extract it.

        2. Set the environment variable `POSTGRES_SQL_FILE` to point toward the `.psql` file in the backup folder:

            ```bash
            export POSTGRES_SQL_FILE=/root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.psql
            ```

        3. Set the environment variable `POSTGRES_SECRET_MANIFEST` to point toward the `.manifest` file in the backup folder:

            ```bash
            export POSTGRES_SECRET_MANIFEST=/root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.manifest
            ```

    - From a previous automatic Postgres backup:

        1. Check for available backups.

            ```bash
            cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("smd"))'
            ```

            Example output:

            ```text
            cray-smd-postgres-2021-07-11T23:10:08.manifest
            cray-smd-postgres-2021-07-11T23:10:08.psql
            ```

            Set the following environment variables for the name of the files in the backup:

            ```bash
            export POSTGRES_SECRET_MANIFEST_NAME=cray-smd-postgres-2021-07-11T23:10:08.manifest
            export POSTGRES_SQL_FILE_NAME=cray-smd-postgres-2021-07-11T23:10:08.psql
            ```

        2. Download the `.psql` file for the Postgres backup.

            ```bash
            cray artifacts get postgres-backup "$POSTGRES_SQL_FILE_NAME" "$POSTGRES_SQL_FILE_NAME"
            ```

        3. Download the `.manifest` file for the HSM backup.

            ```bash
            cray artifacts get postgres-backup "$POSTGRES_SECRET_MANIFEST_NAME" "$POSTGRES_SECRET_MANIFEST_NAME"
            ```

        4. Setup environment variables pointing to the full path of the `.psql` and `.manifest` files.

            ```bash
            export POSTGRES_SQL_FILE=$(realpath "$POSTGRES_SQL_FILE_NAME")
            export POSTGRES_SECRET_MANIFEST=$(realpath "$POSTGRES_SECRET_MANIFEST_NAME")
            ```

1. (`ncn#`) Verify the `POSTGRES_SQL_FILE` environment variable is set correctly.

    ```bash
    echo "$POSTGRES_SQL_FILE"
    ```

    Example output:

    ```text
    /root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.psql
    ```

1. (`ncn#`) Verify the `POSTGRES_SECRET_MANIFEST` environment variable is set correctly.

    ```bash
    ncn# echo "$POSTGRES_SECRET_MANIFEST"
    ```

    Example output:

    ```text
    /root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.manifest
    ```

1. (`ncn#`) Scale HSM to 0.

    ```bash
    CLIENT=cray-smd
    POSTGRESQL=cray-smd-postgres
    NAMESPACE=services

    kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=0
    ```

    Expected output:

    ```text
    deployment.apps/cray-smd scaled
    ```

1. (`ncn#`) Wait for the HSM pods to terminate:

    ```bash
    while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

1. (`ncn#`) Re-run the HSM loader job.

    ```bash
    kubectl -n services get job cray-smd-init -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | kubectl replace --force -f -
    ```

    Wait for the job to complete:

    ```bash
    kubectl wait -n services job cray-smd-init --for=condition=complete --timeout=5m
    ```

1. (`ncn#`) Determine which Postgres member is the leader.

    ```bash
    kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
    ```

    Example output:

    ```text
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    |      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    | cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 | Leader | running |  1 |           |
    | cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |        | running |    |         0 |
    | cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |        | running |    |         0 |
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    ```

    Create a variable for the identified leader:

    ```bash
    POSTGRES_LEADER=cray-smd-postgres-0
    ```

1. (`ncn#`) Determine the database schema version of the currently running HSM database, and then verify that it matches the database schema version from the Postgres backup:

    Database schema of the currently running HSM Postgres instance.

    ```bash
    kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U hmsdsuser -d hmsds -c 'SELECT * FROM system'"
    ```

    Example output:

    ```text
     id | schema_version | system_info
    ----+----------------+-------------
      0 |             17 | {}
    (1 row)
    ```

    > The output above shows the database schema is at version 17.

    Database schema version from the Postgres backup:

    ```bash
    cat "$POSTGRES_SQL_FILE" | grep "COPY public.system" -A 2
    ```

    Example output:

    ```text
    COPY public.system (id, schema_version, dirty) FROM stdin;
    0       17       f
    \.
    ```

    > The output above shows the database schema is at version 17.

    If the database schema versions match, proceed to the next step. Otherwise, the Postgres backup taken is not applicable to the currently running instance of HSM.

    **WARNING:** If the database schema versions do not match the version of HSM deployed, they will need to be either upgraded/downgraded to a version with a compatible database schema version. Ideally, it will be to the same version of HSM that was used
    to create the Postgres backup.

1. (`ncn#`) Delete `postgresql` resource (which includes the PVCs).

    ```bash
    CLIENT=cray-smd
    POSTGRESQL=cray-smd-postgres
    NAMESPACE=services

    kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.yaml

    kubectl delete -f postgres-cr.yaml
    ```

    Expected output:

    ```text
    postgresql.acid.zalan.do "cray-smd-postgres" deleted
    ```

1. (`ncn#`) Wait for the Postgres pods to terminate.

    ```bash
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

1. (`ncn#`) Re-create `postgresql` resource.

    ```bash
    kubectl create -f postgres-cr.yaml
    ```

    Expected output:

    ```text
    postgresql.acid.zalan.do/cray-smd-postgres created
    ```

1. (`ncn#`) Wait for the Postgres cluster to start running.

    ```bash
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start running"; sleep 2; done
    ```

1. (`ncn#`) Determine which Postgres member is the new leader.

    ```bash
    kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
    ```

    Example output:

    ```text
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    |      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    | cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 | Leader | running |  1 |           |
    | cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |        | running |    |         0 |
    | cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |        | running |    |         0 |
    +-------------------+---------------------+------------+--------+---------+----+-----------+
    ```

    Set a variable for the new leader:

    ```text
    POSTGRES_LEADER=cray-smd-postgres-0
    ```

1. (`ncn#`) Copy the dump taken above to the Postgres leader pod and restore the data.

    If the dump exists in a different location, adjust this example as needed.

    ```bash
    cat ${POSTGRES_SQL_FILE} | kubectl exec ${POSTGRES_LEADER} -c postgres -n ${NAMESPACE} -it -- psql -U postgres
    ```

1. (`ncn#`) Clear out of sync data from tables in Postgres.

    The backup will have restored tables that may contain out of date information. To refresh this data, it must first be deleted.

    Delete the entries in the Ethernet Interfaces table. These will automatically get repopulated during rediscovery.

    ```bash
    kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U hmsdsuser -d hmsds -c 'DELETE FROM comp_eth_interfaces'"
    ```

1. (`ncn#`) Restore the secrets.

    Once the dump has been restored onto the newly built Postgres cluster, the Kubernetes secrets need to match with the Postgres cluster, otherwise the service will experience readiness and liveness probe failures because it will be unable to
    authenticate to the database.

    - With secrets manifest from an existing backup
        If the Postgres secrets were auto-backed up, then re-create the secrets in Kubernetes.

        Delete and re-create the four `cray-smd-postgres` secrets using the manifest set to `POSTGRES_SECRET_MANIFEST` in step 1 above.

        ```bash
        kubectl delete secret postgres.cray-smd-postgres.credentials service-account.cray-smd-postgres.credentials hmsdsuser.cray-smd-postgres.credentials standby.cray-smd-postgres.credentials -n ${NAMESPACE}

        kubectl apply -f ${POSTGRES_SECRET_MANIFEST}
        ```

    - Without the previous secrets from a backup
        If the Postgres secrets were not backed up, then update the secrets in Postgres.

        Determine which Postgres member is the leader.

        ```bash
        kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- patronictl list
        ```

        Example output:

        ```text
        +-------------------+---------------------+------------+--------+---------+----+-----------+
        |      Cluster      |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
        +-------------------+---------------------+------------+--------+---------+----+-----------+
        | cray-smd-postgres | cray-smd-postgres-0 | 10.42.0.25 | Leader | running |  1 |           |
        | cray-smd-postgres | cray-smd-postgres-1 | 10.44.0.34 |        | running |    |         0 |
        | cray-smd-postgres | cray-smd-postgres-2 | 10.36.0.44 |        | running |    |         0 |
        +-------------------+---------------------+------------+--------+---------+----+-----------+
        ```

        Set a variable for the leader:

        ```bash
        POSTGRES_LEADER=cray-smd-postgres-0
        ```

        Determine what secrets are associated with the Postgres credentials.

        ```bash
        kubectl get secrets -n ${NAMESPACE} | grep "${POSTGRESQL}.credentials"
        ```

        Example output:

        ```text
        services            hmsdsuser.cray-smd-postgres.credentials                       Opaque                                2      31m
        services            postgres.cray-smd-postgres.credentials                        Opaque                                2      31m
        services            service-account.cray-smd-postgres.credentials                 Opaque                                2      31m
        services            standby.cray-smd-postgres.credentials                         Opaque                                2      31m
        ```

        For each secret above, get the username and password from Kubernetes and update the Postgres database with this information.

        For example (hmsdsuser.cray-smd-postgres.credentials):

        ```bash
        kubectl get secret hmsdsuser.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d

        kubectl get secret hmsdsuser.cray-smd-postgres.credentials -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d
        ```

        Exec into the leader pod to reset the user's password:

        ```bash
        ncn# kubectl exec ${POSTGRES_LEADER} -n ${NAMESPACE} -c postgres -it -- bash
        root@cray-smd-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
        postgres=# ALTER USER hmsdsuser WITH PASSWORD 'ABCXYZ';
        ALTER ROLE
        postgres=#
        ```

        Continue the above process until all ${POSTGRESQL}.credentials secrets have been updated in the database.

1. (`ncn#`) Restart the Postgres cluster.

    ```bash
    kubectl delete pod "${POSTGRESQL}-0" "${POSTGRESQL}-1" "${POSTGRESQL}-2" -n ${NAMESPACE}

    while [ $(kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq -r '.status.PostgresClusterStatus') != "Running" ]; do echo "waiting for ${POSTGRESQL} to start running"; sleep 2; done
    ```

1. (`ncn#`) Scale the client service back to 3.

    ```bash
    kubectl scale deployment ${CLIENT} -n ${NAMESPACE} --replicas=3

    kubectl -n ${NAMESPACE} rollout status deployment ${CLIENT}
    ```

1. (`ncn#`) Verify that the service is functional.

    ```bash
    cray hsm service ready list
    ```

    Example output:

    ```text
    code = 0
    message = "HSM is healthy"
    ```

    Get the number of node objects stored in HSM:

    ```bash
    cray hsm state components list --type Node --format json | jq .Components[].ID | wc -l
    ```

1. (`ncn#`) Resync the component state and inventory.

    After restoring HSM's Postgres from a back up, some of the transient data like component state and hardware inventory may be out of sync with reality. This involves kicking off an HSM rediscovery.

    ```bash
    endpoints=$(cray hsm inventory redfishEndpoints list --format json | jq -r '.[]|.[]|.ID')
    for e in $endpoints; do cray hsm inventory discover create --xnames ${e}; done
    ```

    Wait for discovery to complete. Discovery is complete after there are no redfishEndpoints left in the 'DiscoveryStarted' state. A value of `0` will be returned.

    ```bash
    cray hsm inventory redfishEndpoints list --format json | grep -c "DiscoveryStarted"
    ```

1. (`ncn#`) Check for discovery errors.

    ```bash
    cray hsm inventory redfishEndpoints list --format json | grep LastDiscoveryStatus | grep -v -c "DiscoverOK"
    ```

    If any of the RedfishEndpoint entries have a `LastDiscoveryStatus` other than `DiscoverOK` after discovery has completed, refer to the
    [Troubleshoot Issues with Redfish Endpoint Discovery](../node_management/Troubleshoot_Issues_with_Redfish_Endpoint_Discovery.md) procedure for guidance.

1. (`ncn#`) **Perform this step only if the system has Intel management NCNs, otherwise for HPE or Gigabyte management NCNs skip this step.** Due to known firmware issues on Intel BMCs they do not report the MAC addresses of the management NICs via
    Redfish, and when the BMC is discovered after restoring from a Postgres backup the management NIC MACs in HSM will have an empty component ID. The following script will correct any Ethernet Interfaces for a Intel management NCN without a
    component ID.

    ```bash
    UNKNOWN_NCN_MAC_ADDRESSES=$(cray hsm inventory ethernetInterfaces list --component-id "" --format json | jq '.[] | select(.Description == "- kea") | .MACAddress'  -r)

    for UNKNOWN_MAC_ADDRESS in $UNKNOWN_NCN_MAC_ADDRESSES; do 
        XNAME=$(cray bss bootparameters list --format json | jq --arg MAC "${UNKNOWN_MAC_ADDRESS}" '.[] | select(.params != null) | select(.params | test($MAC)) | .hosts[]' -r)


        if [[ $(wc -l <<< $(printf $XNAME)) -ne 1 ]]; then
            echo "MAC Address ${UNKNOWN_MAC_ADDRESS} unexpected number matches found. Expected 1 match, but found: $(wc -l <<< $(printf $XNAME))"
            continue
        fi


        echo "MAC: ${UNKNOWN_MAC_ADDRESS} is ${XNAME}"
        EI_ID=$(echo "$UNKNOWN_MAC_ADDRESS" | sed 's/://g')
        echo "Updating ${EI_ID} in HSM EthernetInterfaces with component ID ${XNAME}"
        cray hsm inventory ethernetInterfaces update ${EI_ID} --component-id ${XNAME}
    done
    ```
