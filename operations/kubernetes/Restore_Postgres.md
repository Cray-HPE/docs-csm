# Restore Postgres

Below are the service specific steps required to restore data to a Postgres cluster.

Restore Postgres Procedures by Service:

* [Restore Postgres for Spire](#restore-postgres-for-spire)
* [Restore Postgres for Keycloak](#restore-postgres-for-keycloak)
* [Restore Postgres for VCS](#restore-postgres-for-vcs)
* [Restore Postgres for Capsules](#restore-postgres-for-capsules)
  * [Capsules Warehouse Server](#capsules-warehouse-server)
  * [Capsules Dispatch Server](#capsules-dispatch-server)

<a name="spire"> </a>

## Restore Postgres for Spire

In the event that the spire Postgres cluster is in a state that the cluster must be rebuilt and the data restored,
the following procedures are recommended. This assumes that a dump of the database exists.

1. Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, check that the dump file exists in a location off the Postgres cluster.
      It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
      These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
      The `python3` scripts below can be used to help list and download the files.
      Note that the `.psql` file contains the database dump and the `.manifest` file contains the secrets.
      The `aws_access_key_id` and `aws_secret_access_key` will need to be set based on the `postgres-backup-s3-credentials` secret.

        ```bash
        ncn-w001# export S3_ACCESS_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.access_key}' | base64 --decode`

        ncn-w001# export S3_SECRET_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.secret_key}' | base64 --decode`
        ```

        list.py:

        ```python
        import io
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to list keys in the postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3 = boto3.resource(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        backup_bucket = s3.Bucket('postgres-backup')
        for file in backup_bucket.objects.filter(Prefix='spire-postgres'):
            print(file.key)
        ```

        download.py:

        Update the script for the specific .manifest and .psql files you wish to download from S3.

        ```python
        import io
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to download from postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3_client = boto3.client(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        response = s3_client.download_file('postgres-backup', 'spire-postgres-2021-07-21T19:03:18.manifest', 'spire-postgres-2021-07-21T19:03:18.manifest')
        response = s3_client.download_file('postgres-backup', 'spire-postgres-2021-07-21T19:03:18.psql', 'spire-postgres-2021-07-21T19:03:18.psql')
        ```

2. Scale the spire service to 0.

    ```bash
    ncn-w001# CLIENT=spire-server
    ncn-w001# NAMESPACE=spire
    ncn-w001# POSTGRESQL=spire-postgres

    ncn-w001# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

3. Delete the spire Postgres cluster.

    ```bash
    ncn-w001# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json

    ncn-w001# kubectl delete -f postgres-cr.json

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

4. Create a new single instance spire Postgres cluster.

    ```bash
    ncn-w001# cp postgres-cr.json postgres-orig-cr.json
    ncn-w001# jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    ncn-w001# kubectl create -f postgres-cr.json

    # Wait for the pod and Postgres cluster to start running
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pod to start running"; sleep 2; done

    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

5. Copy the database dump file to the Postgres member.

    ```bash
    ncn-w001# DUMPFILE=spire-postgres-2021-07-21T19:03:18.psql

    ncn-w001# kubectl cp ./${DUMPFILE} "${POSTGRESQL}-0":/home/postgres/${DUMPFILE} -c postgres -n ${NAMESPACE}
    ```

6. Restore the data.

    ```bash
    ncn-w001# kubectl exec "${POSTGRESQL}-0" -c postgres -n ${NAMESPACE} -it -- psql -U postgres < ${DUMPFILE}
    ```

7. Either update or re-create the `spire-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        Based off the four `spire-postgres` secrets, collect the password for each Postgres username: `postgres`, `service_account`, `spire`, and `standby`. Then `kubectl exec` into the Postgres pod and update the password for each user. For example:

        ```bash
        ncn-w001# for secret in postgres.spire-postgres.credentials service-account.spire-postgres.credentials spire.
        spire-postgres.credentials standby.spire-postgres.credentials; do echo -n "secret ${secret} username & password: "; echo 
        -n "`kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d` "; echo `kubectl get secret $
        {secret} -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d`; done

        secret postgres.spire-postgres.credentials username & password: postgres ABCXYZ
        secret service-account.spire-postgres.credentials username & password: service_account ABC123
        secret spire.spire-postgres.credentials username & password: spire XYZ123
        secret standby.spire-postgres.credentials username & password: standby 123456
        ```

        ```bash
        ncn-w001# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- bash
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
        ncn-w001# MANIFEST=spire-postgres-2021-07-21T19:03:18.manifest

        ncn-w001# kubectl delete secret postgres.spire-postgres.credentials service-account.spire-postgres.credentials spire.spire-postgres.credentials standby.spire-postgres.credentials -n ${NAMESPACE}

        ncn-w001# kubectl apply -f ${MANIFEST}
        ```

8. Restart the Postgres cluster.

    ```bash
    ncn-w001# kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0"

    # Wait for the postgresql pod to start
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to start running"; sleep 2; done
    ```

9. Scale the Postgres cluster back to 3 instances.

    ```bash
    ncn-w001# kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

    # Wait for the postgresql cluster to start running
    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

10. Scale the spire service back to 3 replicas.

    ```bash
    ncn-w001# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=3

    # Wait for the spire pods to start
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start"; sleep 2; done
    ```

11. Restart the `spire-agent` daemonset and the `spire-jwks` service.

    ```bash
    ncn-w001# kubectl rollout restart daemonset spire-agent -n ${NAMESPACE}
    # Wait for the restart to complete
    ncn-w001# kubectl rollout status daemonset spire-agent -n ${NAMESPACE}

    ncn-w001# kubectl rollout restart deployment spire-jwks -n ${NAMESPACE}
    # Wait for the restart to complete
    ncn-w001# kubectl rollout status deployment spire-jwks -n ${NAMESPACE}
    ```

12. Restart the `spire-agent` on all the nodes.

    ```bash
    ncn-w001# pdsh -w ncn-m00[1-3] 'systemctl restart spire-agent'
    ncn-w001# pdsh -w ncn-w00[1-3] 'systemctl restart spire-agent'
    ncn-w001# pdsh -w ncn-s00[1-3] 'systemctl restart spire-agent'
    ```

13. Verify the service is working. The following should return a token.

    ```bash
    ncn-w001:# /usr/bin/heartbeat-spire-agent api fetch jwt -socketPath=/root/spire/agent.sock -audience test
    ```

<a name="keycloak"> </a>

## Restore Postgres for Keycloak

In the event that the Keycloak Postgres cluster is in a state that the cluster must be rebuilt and the data restored, the following procedures are recommended. This assumes that a dump of the database exists.

1. Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, check that the dump file exists in a location off the Postgres cluster.
      It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
      These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
      The `python3` scripts below can be used to help list and download the files.
      Note that the `.psql` file contains the database dump and the `.manifest` file contains the secrets.
      The `aws_access_key_id` and `aws_secret_access_key` will need to be set based on the `postgres-backup-s3-credentials` secret.

        ```bash
        ncn-w001# export S3_ACCESS_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.access_key}' | base64 --decode`

        ncn-w001# export S3_SECRET_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.secret_key}' | base64 --decode`
        ```

        list.py:

        ```python
        import io
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to list keys in the postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3 = boto3.resource(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        backup_bucket = s3.Bucket('postgres-backup')
        for file in backup_bucket.objects.filter(Prefix='keycloak-postgres'):
            print(file.key)
        ```

        download.py:

        Update the script for the specific .manifest and .psql files you wish to download from S3.

        ```python
        import io
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to download from postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3_client = boto3.client(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        response = s3_client.download_file('postgres-backup', 'keycloak-postgres-2021-07-29T17:56:07.manifest', 'keycloak-postgres-2021-07-29T17:56:07.manifest')
        response = s3_client.download_file('postgres-backup', 'keycloak-postgres-2021-07-29T17:56:07.psql', 'keycloak-postgres-2021-07-29T17:56:07.psql')
        ```

2. Scale the Keycloak service to 0.

    ```bash
    ncn-w001# CLIENT=cray-keycloak
    ncn-w001# NAMESPACE=services
    ncn-w001# POSTGRESQL=keycloak-postgres

    ncn-w001# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

3. Delete the Keycloak Postgres cluster.

    ```bash
    ncn-w001# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json

    ncn-w001# kubectl delete -f postgres-cr.json

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

4. Create a new single instance Keycloak Postgres cluster.

    ```bash
    ncn-w001# cp postgres-cr.json postgres-orig-cr.json
    ncn-w001# jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    ncn-w001# kubectl create -f postgres-cr.json

    # Wait for the pod and Postgres cluster to start running
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pod to start running"; sleep 2; done

    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

5. Copy the database dump file to the Postgres member.

    ```bash
    ncn-w001# DUMPFILE=keycloak-postgres-2021-07-29T17:56:07.psql

    ncn-w001# kubectl cp ./${DUMPFILE} "${POSTGRESQL}-0":/home/postgres/${DUMPFILE} -c postgres -n ${NAMESPACE}
    ```

6. Restore the data.

    ```bash
    ncn-w001# kubectl exec "${POSTGRESQL}-0" -c postgres -n ${NAMESPACE} -it -- psql -U postgres < ${DUMPFILE}
    ```

7. Either update or re-create the `keycloak-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        Based off the three `keycloak-postgres` secrets, collect the password for each Postgres username: `postgres`, `service_account`, and `standby`. Then `kubectl exec` into the Postgres pod and update the password for each user. For example:

        ```bash
        ncn-w001# for secret in postgres.keycloak-postgres.credentials service-account.keycloak-postgres.credentials standby.
        keycloak-postgres.credentials; do echo -n "secret ${secret} username & password: "; echo -n "`kubectl get secret $
        {secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d` "; echo `kubectl get secret ${secret} -n ${NAMESPACE} 
        -ojsonpath='{.data.password}'| base64 -d`; done

        secret postgres.keycloak-postgres.credentials username & password: postgres ABCXYZ
        secret service-account.keycloak-postgres.credentials username & password: service_account ABC123
        secret standby.keycloak-postgres.credentials username & password: standby 123456
        ```

        ```bash
        ncn-w001# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- bash
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
        ncn-w001# MANIFEST=keycloak-postgres-2021-07-29T17:56:07.manifest

        ncn-w001# kubectl delete secret postgres.keycloak-postgres.credentials service-account.keycloak-postgres.credentials standby.keycloak-postgres.credentials -n ${NAMESPACE}

        ncn-w001# kubectl apply -f ${MANIFEST}
        ```

8. Restart the Postgres cluster.

    ```bash
    ncn-w001# kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0"

    # Wait for the postgresql pod to start
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to start running"; sleep 2; done
    ```

9. Scale the Postgres cluster back to 3 instances.

    ```bash
    ncn-w001# kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

    # Wait for the postgresql cluster to start running. This may take a few minutes to complete.
    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

10. Scale the Keycloak service back to 3 replicas.

    ```bash
    ncn-w001# kubectl scale statefulset ${CLIENT} -n ${NAMESPACE} --replicas=3

    # Wait for the keycloak pods to start
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start"; sleep 2; done
    ```

    Also check the status of the Keycloak pods.
    If there are pods that do not show that both containers are ready (READY is `2/2`), wait a few seconds and re-run the command until all containers are ready.

    ```bash
    ncn-w001# kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}"

    NAME              READY   STATUS    RESTARTS   AGE
    cray-keycloak-0   2/2     Running   0          35s
    cray-keycloak-1   2/2     Running   0          35s
    cray-keycloak-2   2/2     Running   0          35s
    ```

11. Re-run the `keycloak-setup` and `keycloak-users-localize` jobs, and restart Keycloak gatekeeper.

    * Run the `keycloak-setup` job to restore the Kubernetes client secrets:

        ```bash
        ncn-w001# kubectl get job -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak -o json > keycloak-setup.json
        ncn-w001# cat keycloak-setup.json | jq '.items[0]' | jq 'del(.metadata.creationTimestamp)' | jq 'del(.metadata.
        managedFields)' | jq 'del(.metadata.resourceVersion)' | jq 'del(.metadata.selfLink)' | jq 'del(.metadata.uid)' | jq 'del(.
        spec.selector)' | jq 'del(.spec.template.metadata.labels)' | jq 'del(.status)' | kubectl replace --force -f -
        ```

        Check the status of the `keycloak-setup` job. If the `COMPLETIONS` value is not `1/1`,
        wait a few seconds and run the command again until the `COMPLETIONS` value is `1/1`.

        ```bash
        ncn-w001# kubectl get jobs -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak

        NAME               COMPLETIONS   DURATION   AGE
        keycloak-setup-2   1/1           59s        91s
        ```

    * Run the `keycloak-users-localize` job to restore the users and groups in S3 and the Kubernetes ConfigMap:

        ```bash
        ncn-w001# kubectl get job -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak-users-localize -o json > cray-keycloak-users-localize.json
        ncn-w001# cat cray-keycloak-users-localize.json | jq '.items[0]' | jq 'del(.metadata.creationTimestamp)' | jq 'del(.
        metadata.managedFields)' | jq 'del(.metadata.resourceVersion)' | jq 'del(.metadata.selfLink)' | jq 'del(.metadata.uid)' | 
        jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' | jq 'del(.status)' | kubectl replace --force -f -`
        ```

        Check the status of the `cray-keycloak-users-localize` job.
        If the `COMPLETIONS` value is not `1/1`, wait a few seconds and run the command again until the `COMPLETIONS` value is `1/1`.

        ```bash
        ncn-w001# kubectl get jobs -n ${NAMESPACE} -l app.kubernetes.io/instance=cray-keycloak-users-localize

        NAME                        COMPLETIONS   DURATION   AGE
        keycloak-users-localize-2   1/1           45s        49s
        ```

    * Restart Keycloak gatekeeper:

        ```bash
        ncn-w001# kubectl rollout restart -n ${NAMESPACE} deployment/cray-keycloak-gatekeeper-ingress
        ```

12. Verify the service is working. The following should return an `access_token` for an existing user. Replace the `<username>` and `<password>` as appropriate.

    ```bash
    ncn-w001:# curl -s -k -d grant_type=password -d client_id=shasta -d username=<username> -d password=<password> https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token

    {"access_token":"....
    ```

<a name="vcs"> </a>

## Restore Postgres for VCS

In the event that the VCS Postgres cluster is in a state that the cluster must be rebuilt and the data restored, the following procedures are recommended. This assumes that a dump of the database exists, as well as a backup of the VCS PVC.

1. Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, check that the dump file exists in a location off the Postgres cluster.
      It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
      These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
      The `python3` scripts below can be used to help list and download the files.
      Note that the `.psql` file contains the database dump and the `.manifest` file contains the secrets.
      The `aws_access_key_id` and `aws_secret_access_key` will need to be set based on the `postgres-backup-s3-credentials` secret.

        ```bash
        ncn-w001# export S3_ACCESS_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.access_key}' | base64 --decode`

        ncn-w001# export S3_SECRET_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.secret_key}' | base64 --decode`
        ```

        list.py:

        ```python
        import io
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to list keys in the postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3 = boto3.resource(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        backup_bucket = s3.Bucket('postgres-backup')
        for file in backup_bucket.objects.filter(Prefix='vcs-postgres'):
            print(file.key)
        ```

        download.py:

        Update the script for the specific .manifest and .psql files you wish to download from S3.

        ```python
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to download from postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3_client = boto3.client(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        response = s3_client.download_file('postgres-backup', 'vcs-postgres-2021-07-21T19:03:18.manifest', 'vcs-postgres-2021-07-21T19:03:18.manifest')
        response = s3_client.download_file('postgres-backup', 'vcs-postgres-2021-07-21T19:03:18.psql', 'vcs-postgres-2021-07-21T19:03:18.psql')
        ```

2. Scale the VCS service to 0.

    ```bash
    ncn-w001# SERVICE=gitea-vcs
    ncn-w001# SERVICELABEL=vcs
    ncn-w001# NAMESPACE=services
    ncn-w001# POSTGRESQL=gitea-vcs-postgres

    ncn-w001# kubectl scale deployment ${SERVICE} -n ${NAMESPACE} --replicas=0

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${SERVICELABEL}" | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

3. Delete the VCS Postgres cluster.

    ```bash
    ncn-w001# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json

    ncn-w001# kubectl delete -f postgres-cr.json

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

4. Create a new single instance VCS Postgres cluster.

    ```bash
    ncn-w001# cp postgres-cr.json postgres-orig-cr.json
    ncn-w001# jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    ncn-w001# kubectl create -f postgres-cr.json

    # Wait for the pod and Postgres cluster to start running
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pod to start running"; sleep 2; done

    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

5. Copy the database dump file to the Postgres member.

    ```bash
    ncn-w001# DUMPFILE=gitea-vcs-postgres-2021-07-21T19:03:18.sql

    ncn-w001# kubectl cp ./${DUMPFILE} "${SERVICE}-0":/home/postgres/${DUMPFILE} -c postgres -n services
    ```

6. Restore the data.

    ```bash
    ncn-w001# kubectl exec "${SERVICE}-0" -c postgres -n services -it -- psql -U postgres < ${DUMPFILE}
    ```

7. Either update or re-create the `gitea-vcs-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        Based off the three `gitea-vcs-postgres` secrets, collect the password for each Postgres username: `postgres`, `service_account`, and `standby`. Then `kubectl exec` into the Postgres pod and update the password for each user. For example:

        ```bash
        ncn-w001# for secret in postgres.gitea-vcs-postgres.credentials service-account.gitea-vcs-postgres.credentials gitea.
        gitea-vcs-postgres.credentials standby.gitea-vcs-postgres.credentials; do echo -n "secret ${secret} username & password: 
        "; echo -n "`kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d` "; echo `kubectl get 
        secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d`; done

        secret postgres.gitea-vcs-postgres.credentials username & password: postgres ABCXYZ
        secret service-account.gitea-vcs-postgres.credentials username & password: service_account ABC123
        secret gitea.gitea-vcs-postgres.credentials username & password: gitea XYZ123
        secret standby.gitea-vcs-postgres.credentials username & password: standby 123456
        ```

        ```bash
        ncn-w001# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- bash
        root@gitea-vcs-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
        postgres=# ALTER USER postgres WITH PASSWORD 'ABCXYZ';
        ALTER ROLE
        postgres=# ALTER USER service_account WITH PASSWORD 'ABC123';
        ALTER ROLE
        postgres=#ALTER USER gitea WITH PASSWORD 'XYZ123';
        ALTER ROLE
        postgres=#ALTER USER standby WITH PASSWORD '123456';
        ALTER ROLE
        postgres=#
        ```

   * Re-create secrets in Kubernetes.

        If the Postgres secrets were auto-backed up, then re-create the secrets in Kubernetes.

        Delete and re-create the four `gitea-vcs-postgres` secrets using the manifest that was copied from S3 in step 1 above.

        ```bash
        ncn-w001# MANIFEST=gitea-vcs-postgres-2021-07-21T19:03:18.manifest

        ncn-w001# kubectl delete secret postgres.gitea-vcs-postgres.credentials service-account.gitea-vcs-postgres.credentials standby.gitea-vcs-postgres.credentials -n services

        ncn-w001# kubectl apply -f ${MANIFEST}
        ```

8. Restart the Postgres cluster.

    ```bash
    ncn-w001# kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0"

    # Wait for the postgresql pod to start
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to start running"; sleep 2; done
    ```

9. Scale the Postgres cluster back to 3 instances.

    ```bash
    ncn-w001# kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

    # Wait for the postgresql cluster to start running
    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

10. Scale the Gitea service back up.

    ```bash
    ncn-w001# kubectl scale deployment ${SERVICE} -n ${NAMESPACE} --replicas=3

    # Wait for the gitea pods to start
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${SERVICELABEL}" | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start"; sleep 2; done
    ```

<a name="capsules"> </a>

## Restore Postgres for Capsules

### Capsules Warehouse Server

In the event that the Capsules Warehouse Postgres cluster is in a state that the cluster must be rebuilt and the data restored, the following procedures are recommended. This assumes that a dump of the database exists.

1. Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, check that the dump file exists in a location off the Postgres cluster.
      It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
      These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
      The `python3` scripts below can be used to help list and download the files.
      Note that the `.psql` file contains the database dump and the `.manifest` file contains the secrets.
      The `aws_access_key_id` and `aws_secret_access_key` will need to be set based on the `postgres-backup-s3-credentials` secret.

        ```bash
        ncn-w001# export S3_ACCESS_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.access_key}' | base64 --decode`

        ncn-w001# export S3_SECRET_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.secret_key}' | base64 --decode`
        ```

        list.py:

        ```python
        import io
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to list keys in the postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3 = boto3.resource(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        backup_bucket = s3.Bucket('postgres-backup')
        for file in backup_bucket.objects.filter(Prefix='capsules-warehouse-server-postgres'):
            print(file.key)
        ```

        download.py:

        Update the script for the specific .manifest and .psql files you wish to download from S3.

        ```python
        import io
        import boto3
        import os

        # postgres-backup-s3-credentials are needed to download from postgres-backup bucket

        s3_access_key = os.environ['S3_ACCESS_KEY']
        s3_secret_key = os.environ['S3_SECRET_KEY']

        s3_client = boto3.client(
            's3',
            endpoint_url='http://rgw-vip.nmn',
            aws_access_key_id=s3_access_key,
            aws_secret_access_key=s3_secret_key,
            verify=False)

        response = s3_client.download_file('postgres-backup', 'capsules-warehouse-server-postgres-2021-07-21T19:03:18.manifest', 'capsules-warehouse-server-postgres-2021-07-21T19:03:18.manifest')
        response = s3_client.download_file('postgres-backup', 'capsules-warehouse-server-postgres-2021-07-21T19:03:18.psql', 'capsules-warehouse-server-postgres-2021-07-21T19:03:18.psql')
        ```

2. Scale the capsules-warehouse-server service to 0.

    ```bash
    ncn-w001# CLIENT=capsules-warehouse-server
    ncn-w001# NAMESPACE=services
    ncn-w001# POSTGRESQL=capsules-warehouse-server-postgres

    ncn-w001# kubectl scale -n ${NAMESPACE} --replicas=0 deployment/${CLIENT}

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

3. Delete the capsules-warehouse-server Postgres cluster.

    ```bash
    ncn-w001# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json

    ncn-w001# kubectl delete -f postgres-cr.json

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

4. Create a new single instance capsules-warehouse-server Postgres cluster.

    ```bash
    ncn-w001# cp postgres-cr.json postgres-orig-cr.json
    ncn-w001# jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    ncn-w001# kubectl create -f postgres-cr.json

    # Wait for the pod and Postgres cluster to start running
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pod to start running"; sleep 2; done

    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

5. Copy the database dump file to the Postgres member.

    ```bash
    ncn-w001# DUMPFILE=capsules-warehouse-server-postgres-2021-07-21T19:03:18.psql

    ncn-w001# kubectl cp ./${DUMPFILE} "${POSTGRESQL}-0":/home/postgres/${DUMPFILE} -c postgres -n ${NAMESPACE}
    ```

6. Restore the data.

    ```bash
    ncn-w001# kubectl exec "${POSTGRESQL}-0" -c postgres -n ${NAMESPACE} -it -- psql -U postgres < ${DUMPFILE}
    ```

7. Either update or re-create the `capsules-warehouse-server-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        Based off the four `capsules-warehouse-server-postgres` secrets, collect the password for each Postgres username: `postgres`, `service_account`, and `standby`. Then `kubectl exec` into the Postgres pod and update the password for each user. For example:

        ```bash
        ncn-w001# for secret in postgres.capsules-warehouse-server-postgres.credentials service-account.
        capsules-warehouse-server-postgres.credentials standby.capsules-warehouse-server-postgres.credentials; do echo -n "secret 
        ${secret} username & password: "; echo -n "`kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | 
        base64 -d` "; echo `kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d`; done

        secret postgres.capsules-warehouse-server-postgres.credentials username & password: postgres ABCXYZ
        secret service-account.capsules-warehouse-server-postgres.credentials username & password: service_account ABC123
        secret standby.capsules-warehouse-server-postgres.credentials username & password: standby 123456
        ```

        ```bash
        ncn-w001# kubectl exec "${POSTGRESQL}-0" -n ${NAMESPACE} -c postgres -it -- bash
        root@capsules-warehouse-server-postgres-0:/home/postgres# /usr/bin/psql postgres postgres
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

        Delete and re-create the three `capsules-warehouse-server-postgres` secrets using the manifest that was copied from S3 in step 1 above.

        ```bash
        ncn-w001# MANIFEST=capsules-warehouse-server-postgres-2021-07-21T19:03:18.manifest

        ncn-w001# kubectl delete secret postgres.capsules-warehouse-server-postgres.credentials service-account.capsules-warehouse-server-postgres.credentials standby.capsules-warehouse-server-postgres.credentials -n ${NAMESPACE}

        ncn-w001# kubectl apply -f ${MANIFEST}
        ```

8. Restart the Postgres cluster.

    ```bash
    ncn-w001# kubectl delete pod -n ${NAMESPACE} "${POSTGRESQL}-0"

    # Wait for the postgresql pod to start
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to start running"; sleep 2; done
    ```

9. Scale the Postgres cluster back to 3 instances.

    ```bash
    ncn-w001# kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'

    # Wait for the postgresql cluster to start running
    ncn-w001# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ] ; do echo "  waiting for postgresql to start running"; sleep 2; done
    ```

10. Scale the capsules-warehouse-server service back to 3 replicas.

    ```bash
    ncn-w001# kubectl scale -n ${NAMESPACE} --replicas=3 deployment/${CLIENT}

    # Wait for the capsules-warehouse-server pods to start
    ncn-w001# while [ $(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name="${CLIENT}" | grep -v NAME | wc -l) != 3 ] ; do echo "  waiting for pods to start"; sleep 2; done
    ```

    Also check the status of the capsules-warehouse-server pods.
    If there are pods that do not show that both containers are ready (READY is `2/2`), wait a few seconds and re-run the command until all containers are ready.

    ```bash
    ncn-w001# kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance="${CLIENT}"

    NAME              READY   STATUS    RESTARTS   AGE
    capsules-warehouse-server-0   2/2     Running   0          35s
    capsules-warehouse-server-1   2/2     Running   0          35s
    capsules-warehouse-server-2   2/2     Running   0          35s
    ```

11. Verify Capsules services are accessible and contain the expected data.
    You may need to configure your default warehouse and default warehouse user as well as login though the Keycloak service depending on where you login from. It is recommended to use a UAN.

    ```bash
    ncn-w001# capsule list

    2 Capsules found:
      someusername/a-preexisting-capsule
      someusername/another-preexisting-capsule
    ```

#### Capsules Dispatch Server

The Capsules Dispatch Server can be restored in the same manner as the warehouse server by substituting
the keyword `warehouse` with `dispatch`; however, the dispatch server maintains temporary information for running Capsules Environments.
Therefore, restoring data to this service is not necessary. Using the analytics docs, you can instead cleanup existing jobs and skip this step.
