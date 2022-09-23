# Restore Postgres

Below are the service-specific steps required to restore data to a Postgres cluster.

Restore Postgres procedures by service:

* [Restore Postgres for Spire](#restore-postgres-for-spire)
* [Restore Postgres for Keycloak](#restore-postgres-for-keycloak)
* [Restore Postgres for VCS](#restore-postgres-for-vcs)
* [Restore Postgres for HSM](../hardware_state_manager/Restore_HSM_Postgres_from_Backup.md)
* [Restore Postgres for SLS](../system_layout_service/Restore_SLS_Postgres_Database_from_Backup.md)

## Restore Postgres for Spire

In the event that the Spire Postgres cluster is in a state that the cluster must be rebuilt and the data restored, the following procedures are recommended.
This assumes that a dump of the database exists and the Cray command line interface \(CLI\) tool is initialized and configured on the system.

1. (`ncn-mw#`) Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, then check that the dump file exists in a location off the Postgres cluster. It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
    These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
    The `cray artifacts` CLI can be used list and download the files. Note that the `.psql` file contains the database dump and the .manifest file contains the secrets.

    1. List the available backups:

        ```bash
        cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("spire"))'
        ```

        Example output:

        ```text
        spire-postgres-2022-09-14T03:10:04.manifest
        spire-postgres-2022-09-14T03:10:04.psql
        ```

    1. Set the environment variables to the name of the backup files:

        ```bash
        MANIFEST=spire-postgres-2022-09-14T03:10:04.manifest
        DUMPFILE=spire-postgres-2022-09-14T03:10:04.psql
        ```

    1. Download the backup files:

        ```bash
        cray artifacts get postgres-backup "$DUMPFILE" "$DUMPFILE"
        cray artifacts get postgres-backup "$MANIFEST" "$MANIFEST"
        ```

    1. Due to a `kubectl cp` bug, rename the DUMPFILE file, replacing any `:` characters with `-`:

        ```bash
        TMP=$(echo "$DUMPFILE" | sed 's/:/-/g')
        mv $DUMPFILE $TMP
        DUMPFILE=$(echo $TMP)
        unset TMP
        ```

1. (`ncn-mw#`) Scale the Spire service to 0.

    ```bash
    CLIENT=spire-server
    NAMESPACE=spire
    POSTGRESQL=spire-postgres

    kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do
        echo "  waiting for pods to terminate"; sleep 2
    done
    ```

1. (`ncn-mw#`) Delete the Spire Postgres cluster.

    ```bash
    kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' |
        jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json

    kubectl delete -f postgres-cr.json

    # Wait for the pods to terminate
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do
        echo "  waiting for pods to terminate"; sleep 2
    done
    ```

1. (`ncn-mw#`) Create a new single instance Spire Postgres cluster.

    ```bash
    cp postgres-cr.json postgres-orig-cr.json
    jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    kubectl create -f postgres-cr.json

    # Wait for the pod and Postgres cluster to start running
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pod to start running"; sleep 2
    done

    while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do
        echo "  waiting for postgresql to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Copy the database dump file to the Postgres member.

    ```bash
    kubectl cp ./${DUMPFILE} "${POSTGRESQL}-0":/home/postgres/${DUMPFILE} -c postgres -n ${NAMESPACE}
    ```

1. (`ncn-mw#`) Restore the data.

    ```bash
    kubectl exec "${POSTGRESQL}-0" -c postgres -n ${NAMESPACE} -it -- psql -U postgres < ${DUMPFILE}
    ```

    Errors such as `... already exists` can be ignored; the restore can be considered successful when it completes.

1. (`ncn-mw#`) Either update or re-create the `spire-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        Based off the four `spire-postgres` secrets, collect the password for each Postgres username: `postgres`, `service_account`, `spire`, and `standby`. Then `kubectl exec` into the Postgres pod and update the password for each user. For example:

        ```bash
        for secret in postgres.spire-postgres.credentials service-account.spire-postgres.credentials spire.spire-postgres.credentials standby.spire-postgres.credentials; do
            echo -n "secret ${secret} username & password: "
            echo -n "`kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d` "
            echo `kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d`
        done
        ```

        Example output:

        ```text
        secret postgres.spire-postgres.credentials username & password: postgres ABCXYZ
        secret service-account.spire-postgres.credentials username & password: service_account ABC123
        secret spire.spire-postgres.credentials username & password: spire XYZ123
        secret standby.spire-postgres.credentials username & password: standby 123456
        ```

        ```bash
        kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- bash
        root@spire-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
        postgres=# ALTER USER postgres WITH PASSWORD 'ABCXYZ';
        ALTER ROLE
        postgres=# ALTER USER service_account WITH PASSWORD 'ABC123';
        ALTER ROLE
        postgres=#ALTER USER spire WITH PASSWORD 'XYZ123';
        ALTER ROLE
        postgres=#ALTER USER standby WITH PASSWORD '123456';
        ALTER ROLE
        postgres=#
        ```

   * Re-create secrets in Kubernetes.

        If the Postgres secrets were auto-backed up, then re-create the secrets in Kubernetes.

        Delete and re-create the four `spire-postgres` secrets using the manifest that was copied from S3 in step 1 above.

        ```bash
        kubectl delete secret postgres.spire-postgres.credentials service-account.spire-postgres.credentials spire.spire-postgres.credentials \
            standby.spire-postgres.credentials -n ${NAMESPACE}

        kubectl apply -f ${MANIFEST}
        ```

1. (`ncn-mw#`) Restart the Postgres cluster.

    ```bash
    kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0"

    # Wait for the postgresql pod to start
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pods to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Scale the Postgres cluster back to 3 instances.

    ```bash
    kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

    # Wait for the postgresql cluster to start running
    while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do
        echo "  waiting for postgresql to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Scale the Spire service back to 3 replicas.

    ```bash
    kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=3

    # Wait for the spire pods to start
    while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do
        echo "  waiting for pods to start"; sleep 2
    done
    ```

1. (`ncn-mw#`) Restart the `spire-agent` `daemonset` and the `spire-jwks` service.

    ```bash
    kubectl rollout restart daemonset spire-agent -n ${NAMESPACE}
    # Wait for the restart to complete
    kubectl rollout status daemonset spire-agent -n ${NAMESPACE}

    kubectl rollout restart deployment spire-jwks -n ${NAMESPACE}
    # Wait for the restart to complete
    kubectl rollout status deployment spire-jwks -n ${NAMESPACE}
    ```

1. (`ncn-mw#`) Restart the `spire-agent` on all the nodes.

    ```bash
    pdsh -w ncn-m00[1-3] 'systemctl restart spire-agent'
    pdsh -w ncn-w00[1-3] 'systemctl restart spire-agent'
    pdsh -w ncn-s00[1-3] 'systemctl restart spire-agent'
    ```

1. (`ncn-mw#`) Verify that the service is working.

    The following should return a token.

    ```bash
    /usr/bin/heartbeat-spire-agent api fetch jwt -socketPath=/root/spire/agent.sock -audience test
    ```

## Restore Postgres for Keycloak

In the event that the Keycloak Postgres cluster is in a state that the cluster must be rebuilt and the data restored, the following procedures are recommended.
This assumes that a dump of the database exists and the Cray command line interface \(CLI\) tool is initialized and configured on the system.

1. (`ncn-mw#`) Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, then check that the dump file exists in a location off the Postgres cluster. It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
    These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
    The `cray artifacts` CLI can be used list and download the files. Note that the `.psql` file contains the database dump and the .manifest file contains the secrets.

    1. Setup the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations needed while restoring the Keycloak database. See [Authenticate an Account with the Command Line](../security_and_authentication/Authenticate_an_Account_with_the_Command_Line.md).

    1. List the available backups:

        ```bash
        cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("keycloak"))'
        ```

        Example output:

        ```text
        keycloak-postgres-2022-09-14T02:10:05.manifest
        keycloak-postgres-2022-09-14T02:10:05.psql
        ```

    1. Set the environment variables to the name of the backup files:

        ```bash
        MANIFEST=keycloak-postgres-2022-09-14T02:10:05.manifest
        DUMPFILE=keycloak-postgres-2022-09-14T02:10:05.psql
        ```

    1. Download the backup files:

        ```bash
        cray artifacts get postgres-backup "$DUMPFILE" "$DUMPFILE"
        cray artifacts get postgres-backup "$MANIFEST" "$MANIFEST"
        ```

    1. Unset the `CRAY_CREDENTIALS` environment variable:

        ```bash
        unset CRAY_CREDENTIALS
        rm /tmp/my-token.json
        ```

    1. Due to a `kubectl cp` bug, rename the DUMPFILE file, replacing any `:` characters with `-`:

        ```bash
        TMP=$(echo "$DUMPFILE" | sed 's/:/-/g')
        mv $DUMPFILE $TMP
        DUMPFILE=$(echo $TMP)
        unset TMP
        ```

1. (`ncn-mw#`) Scale the Keycloak service to 0.

    ```bash
    CLIENT=cray-keycloak
    NAMESPACE=services
    POSTGRESQL=keycloak-postgres

    kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do
        echo "  waiting for pods to terminate"; sleep 2
    done
    ```

1. (`ncn-mw#`) Delete the Keycloak Postgres cluster.

    ```bash
    kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' |
        jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json

    kubectl delete -f postgres-cr.json

    # Wait for the pods to terminate
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do
        echo "  waiting for pods to terminate"; sleep 2
    done
    ```

1. (`ncn-mw#`) Create a new single instance Keycloak Postgres cluster.

    ```bash
    cp postgres-cr.json postgres-orig-cr.json
    jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    kubectl create -f postgres-cr.json

    # Wait for the pod and Postgres cluster to start running
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pod to start running"; sleep 2
    done

    while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do
        echo "  waiting for postgresql to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Copy the database dump file to the Postgres member.

    ```bash
    kubectl cp ./${DUMPFILE} "${POSTGRESQL}-0":/home/postgres/${DUMPFILE} -c postgres -n ${NAMESPACE}
    ```

    Errors such as `... already exists` can be ignored; the restore can be considered successful when it completes.

1. (`ncn-mw#`) Restore the data.

    ```bash
    kubectl exec "${POSTGRESQL}-0" -c postgres -n ${NAMESPACE} -it -- psql -U postgres < ${DUMPFILE}
    ```

1. (`ncn-mw#`) Either update or re-create the `keycloak-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        Based off the three `keycloak-postgres` secrets, collect the password for each Postgres username: `postgres`, `service_account`, and `standby`. Then `kubectl exec` into the Postgres pod and update the password for each user. For example:

        ```bash
        for secret in postgres.keycloak-postgres.credentials service-account.keycloak-postgres.credentials standby.keycloak-postgres.credentials; do
            echo -n "secret ${secret} username & password: "
            echo -n "`kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d` "
            echo `kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d`
        done
        ```

        Example output:

        ```text
        secret postgres.keycloak-postgres.credentials username & password: postgres ABCXYZ
        secret service-account.keycloak-postgres.credentials username & password: service_account ABC123
        secret standby.keycloak-postgres.credentials username & password: standby 123456
        ```

        ```bash
        kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- bash
        root@keycloak-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
        postgres=# ALTER USER postgres WITH PASSWORD 'ABCXYZ';
        ALTER ROLE
        postgres=# ALTER USER service_account WITH PASSWORD 'ABC123';
        ALTER ROLE
        postgres=#ALTER USER standby WITH PASSWORD '123456';
        ALTER ROLE
        postgres=#
        ```

   * Re-create secrets in Kubernetes.

        If the Postgres secrets were automatically backed up, then re-create the secrets in Kubernetes.

        Delete and re-create the three `keycloak-postgres` secrets using the manifest that was copied from S3 in step 1 above.

        ```bash
        kubectl delete secret postgres.keycloak-postgres.credentials service-account.keycloak-postgres.credentials standby.keycloak-postgres.credentials -n ${NAMESPACE}

        kubectl apply -f ${MANIFEST}
        ```

1. (`ncn-mw#`) Restart the Postgres cluster.

    ```bash
    kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0"

    # Wait for the postgresql pod to start
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pods to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Scale the Postgres cluster back to 3 instances.

    ```bash
    kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

    # Wait for the postgresql cluster to start running. This may take a few minutes to complete.
    while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do
        echo "  waiting for postgresql to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Scale the Keycloak service back to 3 replicas.

    ```bash
    kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=3

    # Wait for the keycloak pods to start
    while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do
        echo "  waiting for pods to start"; sleep 2
    done
    ```

    Also check the status of the Keycloak pods. If there are pods that do not show that both containers are ready (`READY` is `2/2`), then wait a few seconds and re-run the command until all containers are ready.

    ```bash
    kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}"
    ```

    Example output:

    ```text
    NAME              READY   STATUS    RESTARTS   AGE
    cray-keycloak-0   2/2     Running   0          35s
    cray-keycloak-1   2/2     Running   0          35s
    cray-keycloak-2   2/2     Running   0          35s
    ```

1. (`ncn-mw#`) Re-run the `keycloak-setup` and `keycloak-users-localize` jobs, and restart Keycloak gatekeeper.

    * Run the `keycloak-setup` job to restore the Kubernetes client secrets:

        ```bash
        kubectl get job -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak -o json > keycloak-setup.json
        cat keycloak-setup.json | jq '.items[0]' | jq 'del(.metadata.creationTimestamp)' | jq 'del(.metadata.managedFields)' |
            jq 'del(.metadata.resourceVersion)' | jq 'del(.metadata.selfLink)' | jq 'del(.metadata.uid)' |
            jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' | jq 'del(.status)' | kubectl replace --force -f -
        ```

        Check the status of the `keycloak-setup` job. If the `COMPLETIONS` value is not `1/1`, wait a few seconds and run the command again until the `COMPLETIONS` value is `1/1`.

        ```bash
        kubectl get jobs -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak
        ```

        Example output:

        ```text
        NAME               COMPLETIONS   DURATION   AGE
        keycloak-setup-2   1/1           59s        91s
        ```

    * Run the `keycloak-users-localize` job to restore the users and groups in S3 and the Kubernetes ConfigMap:

        ```bash
        kubectl get job -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak-users-localize -o json > cray-keycloak-users-localize.json
        cat cray-keycloak-users-localize.json | jq '.items[0]' | jq 'del(.metadata.creationTimestamp)' |
            jq 'del(.metadata.managedFields)' | jq 'del(.metadata.resourceVersion)' | jq 'del(.metadata.selfLink)' |
            jq 'del(.metadata.uid)' | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' |
            jq 'del(.status)' | kubectl replace --force -f -
        ```

        Check the status of the `cray-keycloak-users-localize` job. If the `COMPLETIONS` value is not `1/1`, wait a few minutes and run the command again until the `COMPLETIONS` value is `1/1`.

        ```bash
        kubectl get jobs -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak-users-localize
        ```

        Example output:

        ```text
        NAME                        COMPLETIONS   DURATION   AGE
        keycloak-users-localize-2   1/1           45s        49s
        ```

    * Restart the ingress oauth2-proxies:

        ```bash
        kubectl rollout restart -n ${NAMESPACE} deployment/cray-oauth2-proxies-customer-access-ingress
        kubectl rollout restart -n ${NAMESPACE} deployment/cray-oauth2-proxies-customer-high-speed-ingress
        kubectl rollout restart -n ${NAMESPACE} deployment/cray-oauth2-proxies-customer-management-ingress
        ```

1. (`ncn-mw#`) Verify the service is working.

    The following should return an `access_token` for an existing user. Replace the `<username>` and `<password>` as appropriate.

    ```bash
    curl -s -k -d grant_type=password -d client_id=shasta -d username=<username> -d password=<password> \
        https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token
    ```

## Restore Postgres for VCS

In the event that the VCS Postgres cluster is in a state that the cluster must be rebuilt and the data restored, the following procedures are recommended.
This assumes that a dump of the database exists, as well as a [backup of the VCS PVC](../configuration_management/Version_Control_Service_VCS.md#restore-pvc-data) and
the Cray command line interface \(CLI\) tool is initialized and configured on the system.

1. (`ncn-mw#`) Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, then check that the dump file exists in a location off the Postgres cluster. It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
    These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
    The `cray artifacts` CLI can be used list and download the files. Note that the `.psql` file contains the database dump and the .manifest file contains the secrets.

    1. List the available backups:

        ```bash
        cray artifacts list postgres-backup --format json | jq -r '.artifacts[].Key | select(contains("vcs"))'
        ```

        Example output:

        ```text
        gitea-vcs-postgres-2022-09-14T01:10:04.manifest
        gitea-vcs-postgres-2022-09-14T01:10:04.psql
        ```

    1. Set the environment variables to the name of the backup files:

        ```bash
        MANIFEST=gitea-vcs-postgres-2022-09-14T01:10:04.manifest
        DUMPFILE=gitea-vcs-postgres-2022-09-14T01:10:04.psql
        ```

    1. Download the backup files:

        ```bash
        cray artifacts get postgres-backup "$DUMPFILE" "$DUMPFILE"
        cray artifacts get postgres-backup "$MANIFEST" "$MANIFEST"
        ```

    1. Due to a `kubectl cp` bug, rename the DUMPFILE file, replacing any `:` characters with `-`:

        ```bash
        TMP=$(echo "$DUMPFILE" | sed 's/:/-/g')
        mv $DUMPFILE $TMP
        DUMPFILE=$(echo $TMP)
        unset TMP
        ```

1. (`ncn-mw#`) Scale the VCS service to 0.

    ```bash
    SERVICE=gitea-vcs
    SERVICELABEL=vcs
    NAMESPACE=services
    POSTGRESQL=gitea-vcs-postgres

    kubectl scale deployment ${SERVICE} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${SERVICELABEL}" | grep -v NAME | wc -l) != 0 ] ; do
        echo "  waiting for pods to terminate"; sleep 2
    done
    ```

1. (`ncn-mw#`) Delete the VCS Postgres cluster.

    ```bash
    kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' |
        jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json

    kubectl delete -f postgres-cr.json

    # Wait for the pods to terminate
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do
        echo "  waiting for pods to terminate"; sleep 2
    done
    ```

1. (`ncn-mw#`) Create a new single instance VCS Postgres cluster.

    ```bash
    cp postgres-cr.json postgres-orig-cr.json
    jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    kubectl create -f postgres-cr.json

    # Wait for the pod and Postgres cluster to start running
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pod to start running"; sleep 2
    done

    while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do
        echo "  waiting for postgresql to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Copy the database dump file to the Postgres member.

    ```bash
    kubectl cp ./${DUMPFILE} "${POSTGRESQL}-0":/home/postgres/${DUMPFILE} -c postgres -n services
    ```

    Errors such as `... already exists` can be ignored; the restore can be considered successful when it completes.

1. (`ncn-mw#`) Restore the data.

    ```bash
    kubectl exec "${SERVICE}-0" -c postgres -n services -it -- psql -U postgres < ${DUMPFILE}
    ```

1. (`ncn-mw#`) Either update or re-create the `gitea-vcs-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        Based off the three `gitea-vcs-postgres` secrets, collect the password for each Postgres username: `postgres`, `service_account`, and `standby`. Then `kubectl exec` into the Postgres pod and update the password for each user. For example:

        ```bash
        for secret in postgres.gitea-vcs-postgres.credentials service-account.gitea-vcs-postgres.credentials \
            standby.gitea-vcs-postgres.credentials
        do
            echo -n "secret ${secret} username & password: "
            echo -n "`kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d` "
            echo `kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d`
        done
        ```

        Example output:

        ```text
        secret postgres.gitea-vcs-postgres.credentials username & password: postgres ABCXYZ
        secret service-account.gitea-vcs-postgres.credentials username & password: service_account ABC123
        secret standby.gitea-vcs-postgres.credentials username & password: standby 123456
        ```

        ```bash
        kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- bash
        root@gitea-vcs-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
        postgres=# ALTER USER postgres WITH PASSWORD 'ABCXYZ';
        ALTER ROLE
        postgres=# ALTER USER service_account WITH PASSWORD 'ABC123';
        ALTER ROLE
        postgres=#ALTER USER standby WITH PASSWORD '123456';
        ALTER ROLE
        postgres=#
        ```

   * Re-create secrets in Kubernetes.

        If the Postgres secrets were auto-backed up, then re-create the secrets in Kubernetes.

        Delete and re-create the four `gitea-vcs-postgres` secrets using the manifest that was copied from S3 in step 1 above.

        ```bash
        kubectl delete secret postgres.gitea-vcs-postgres.credentials service-account.gitea-vcs-postgres.credentials standby.gitea-vcs-postgres.credentials -n services

        kubectl apply -f ${MANIFEST}
        ```

1. (`ncn-mw#`) Restart the Postgres cluster.

    ```bash
    kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0"

    # Wait for the postgresql pod to start
    while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pods to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Scale the Postgres cluster back to 3 instances.

    ```bash
    kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

    # Wait for the postgresql cluster to start running
    while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do
        echo "  waiting for postgresql to start running"; sleep 2
    done
    ```

1. (`ncn-mw#`) Scale the Gitea service back up.

    ```bash
    kubectl scale deployment ${SERVICE} -n ${NAMESPACE} --replicas=1

    # Wait for the gitea pods to start
    while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${SERVICELABEL}" | grep -v NAME | wc -l) != 1 ] ; do
        echo "  waiting for pods to start"; sleep 2
    done
    ```
