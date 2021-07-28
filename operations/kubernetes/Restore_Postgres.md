## Restore Postgres

Below are the service specific steps required to restore data to a Postgres cluster.

Restore Postgres Procedures by Service:
- [Restore Postgres for Spire](#spire)


<a name="spire"> </a>
### Restore Postgres for Spire

In the event that the spire Postgres cluster is in a state that the cluster must be rebuilt and the data restored, the following procedures are recommended.  This assumes that a dump of the database exists. 

1. Copy the database dump to an accessible location.

    - If a manual dump of the database was taken, check that the dump file exists in a location off the Postgres cluster.  It will be needed in the steps below.

    - If the database is being auto backed up, then the most recent version of the dump and the secrets should exist in the postgres-backup s3 bucket.  These will be needed in the steps below.  To copy dump and secrets out of the s3 bucket, the python3 script below can be used. Note that the .psql file contains the database dump and the .manifest file contains the secrets. The aws_access_key_id and aws_secret_access_key will need to be set based on the postgres-backup-s3-credentials secret.

    To find the name of the dump and secrets file that was created if auto backup is enabled and a backup has run, check the logs from the db-backup pod.
    
    ```bash
    ncn-w001# NAMESPACE=spire

    ncn-w001# kubectl get pods -n ${NAMESPACE} | grep spire | grep db-backup
    spire-postgresql-db-backup-1626973200-h2dvh   0/1     Completed   0          5h34m

    ncn-w001# kubectl logs spire-postgresql-db-backup-1626973200-h2dvh -n ${NAMESPACE} | grep "Keys for db"
    2021-07-22 17:00:17,731 - INFO    - root - Keys for db 'spire-postgres': ['spire-postgres-spire-postgres-2021-07-21T19:03:18.manifest', 'spire-postgres-spire-postgres-2021-07-21T19:03:18.psql']
    ```

    ```bash
    ncn-w001# export S3_ACCESS_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.access_key}' | base64 --decode`

    ncn-w001# export S3_SECRET_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.secret_key}' | base64 --decode`
    ```

    ```bash
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

    response = s3_client.download_file('postgres-backup', 'spire-postgres-2021-07-21T19:03:18.manifest', 'spire-    postgres-2021-07-21T19:03:18.manifest')
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
    ncn-w001# kubectl get postgresql ${POSTGRESQL} -n ${NAMESPACE} -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.yaml

    ncn-w001# kubectl delete -f postgres-cr.yaml

    # Wait for the pods to terminate
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 0 ] ; do echo "  waiting for pods to terminate"; sleep 2; done
    ```

4. Create a new single instance spire Postgres cluster.

    ```bash
    ncn-w001# cp postgres-cr.yaml postgres-orig-cr.yaml
    ncn-w001# jq '.spec.numberOfInstances = 1' postgres-orig-cr.yaml > postgres-cr.yaml
    ncn-w001# kubectl create -f postgres-cr.yaml

    # Wait for pods and Postgres cluster to start running
    ncn-w001# while [ $(kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n ${NAMESPACE} | grep -v NAME | wc -l) != 1 ] ; do echo "  waiting for pods to start running"; sleep 2; done

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

7. Either update or re-create the spire-postgres secrets.

  - Update the secrets in Postgres.

    If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

    Based off the four spire-postgres secrets, collect the password for each Postgres username: postgres, service_account, spire, standby. Then exec into the Postgres pod and update the password for each user. For example:

    ```bash 
    ncn-w001# for secret in postgres.spire-postgres.credentials service-account.spire-postgres.credentials spire.spire-postgres.credentials standby.spire-postgres.credentials; do echo -n "secret ${secret} username & password: "; echo -n "`kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.username}' | base64 -d` "; echo `kubectl get secret ${secret} -n ${NAMESPACE} -ojsonpath='{.data.password}'| base64 -d`; done

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
    postgres=# ALTER USER service-account WITH PASSWORD 'ABC123';
    ALTER ROLE
    postgres=#ALTER USER spire WITH PASSWORD 'XYZ123';
    ALTER ROLE
    postgres=#ALTER USER standby WITH PASSWORD '123456';
    ALTER ROLE
    postgres=#
    ```
  
  - Re-create secrets in Kubernetes.

    If the Postgres secrets were auto-backed up, then re-create the secrets in Kubernetes.

    Delete and re-create the four spire-postgres secrets using the manifest that was copied from s3 in Step 1 above.

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

9. Scale the Postgres Cluster back to 3 Instances.

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

11. Restart the spire-agent on all the nodes.

    ```bash
    ncn-w001# pdsh -w ncn-m00[1-3] 'systemctl restart spire-agent'
    ncn-w001# pdsh -w ncn-w00[1-3] 'systemctl restart spire-agent'
    ncn-w001# pdsh -w ncn-s00[1-3] 'systemctl restart spire-agent'
    ```

12. Verify the service is working. The following should return a token.

    ```bash
    ncn-w001:# /usr/bin/heartbeat-spire-agent api fetch jwt -socketPath=/root/spire/agent.sock -audience test
    ```
