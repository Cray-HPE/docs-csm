# Backup and Restore VCS Data

This document describes how to perform backups and restores of the Version Control Service (VCS) data.
For general information, see [Version Control Service (VCS)](Version_Control_Service_VCS.md).

* [Overview](#overview)
* [Backup procedure](#backup-procedure)
    1. [Manually backup Postgres data](#1-manually-backup-postgres-data)
    1. [Backup PVC data](#2-backup-pvc-data)
* [Restore procedure](#restore-procedure)
    1. [Restore Postgres data](#1-restore-postgres-data)
    1. [Restore PVC data](#2-restore-pvc-data)
* [Alternative backup/restore strategy](#alternative-backuprestore-strategy)
  * [Alternative export method](#alternative-export-method)
  * [Alternative import method](#alternative-import-method)

## Overview

Data for Gitea is stored in two places: Git content is stored directly in a PVC, while structural data, such as Gitea users and the list and attributes of repositories, is stored
in a Postgres database. Because of this, both sources must be backed up and restored together. **A full restore is not possible without backups of both the PVC and Postgres data.**
CSM performs automatic periodic backups of the Postgres data, but the PVC data is not automatically backed up by CSM. Administrators are recommended to take periodic backups, using
one of the methods outlined on this page.

## Backup procedure

Remember that backups of both the Postgres and PVC data are necessary in order to perform a complete restore of VCS data.

1. [Manually backup Postgres data](#1-manually-backup-postgres-data)
1. [Manually backup PVC data](#2-manually-backup-pvc-data)

### 1. Manually backup Postgres data

1. Determine which Postgres member is the leader.

    ```bash
    ncn-mw# kubectl exec gitea-vcs-postgres-0 -n services -c postgres -it -- patronictl list
    ```

    Example output:

    ```text
    + Cluster: gitea-vcs-postgres (6995618180238446669) -----+----+-----------+
    |        Member        |     Host     |  Role  |  State  | TL | Lag in MB |
    +----------------------+--------------+--------+---------+----+-----------+
    | gitea-vcs-postgres-0 |  10.45.0.21  | Leader | running |  1 |           |
    | gitea-vcs-postgres-1 | 10.46.128.19 |        | running |  1 |         0 |
    | gitea-vcs-postgres-2 |  10.47.0.21  |        | running |  1 |         0 |
    +----------------------+--------------+--------+---------+----+-----------+
    ```

1. Log into the leader pod and dump the data to a local file.

    ```bash
    ncn-mw# POSTGRES_LEADER=gitea-vcs-postgres-0
    ncn-mw# kubectl exec -it ${POSTGRES_LEADER} -n services -c postgres -- pg_dumpall -c -U postgres > gitea-vcs-postgres.sql
    ```

1. Determine what secrets are associated with the PostgreSQL credentials:

    ```bash
    ncn-mw# kubectl get secrets -n services | grep gitea-vcs-postgres.credentials
    ```

    Example output:

    ```text
    postgres.gitea-vcs-postgres.credentials                   Opaque                                2      13d
    service-account.gitea-vcs-postgres.credentials            Opaque                                2      13d
    standby.gitea-vcs-postgres.credentials                    Opaque                                2      13d
    ```

1. Export each secret to a manifest file.

    The `creationTimestamp`, `resourceVersion`, `selfLink`, and `uid` metadata fields are removed from each
    secret as they are exported.

    ```bash
    ncn-mw# SECRETS="postgres service-account standby"
    ncn-mw# tmpfile=$(mktemp)
    ncn-mw# echo "---" > gitea-vcs-postgres.manifest && for secret in $SECRETS; do
                kubectl get secret "${secret}.gitea-vcs-postgres.credentials" -n services -o yaml > "${tmpfile}"
                for field in creationTimestamp resourceVersion selfLink uid; do
                    yq d -i "${tmpfile}" "metadata.${field}"
                done
                cat "${tmpfile}" >> gitea-vcs-postgres.manifest
                echo "---" >> gitea-vcs-postgres.manifest
            done ; rm "${tmpfile}"
    ```

1. Copy all files to a safe location.

### 2. Backup PVC data

The VCS Postgres backups should be accompanied by backups of the VCS PVC. The export process can be run at any time
while the service is running using the following commands:

```bash
ncn-mw# POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
ncn-mw# kubectl -n services exec ${POD} -- tar -cvf /tmp/vcs.tar /data/ &&
        kubectl -n services cp ${POD}:/tmp/vcs.tar ./vcs.tar
```

Be sure to save the resulting `tar` file to a safe location.

## Restore procedure

In order to completely restore the VCS data, first the Postgres data must be restored, then the PVC data must be restored.

### 1. Restore Postgres data

1. Copy the database dump to an accessible location.

    * If a manual dump of the database was taken, then check that the dump file exists in a location off the Postgres cluster. It will be needed in the steps below.
    * If the database is being automatically backed up, then the most recent version of the dump and the secrets should exist in the `postgres-backup` S3 bucket.
      These will be needed in the steps below. List the files in the `postgres-backup` S3 bucket and if the files exist, download the dump and secrets out of the S3 bucket.
      The `python3` scripts below can be used to help list and download the files.
      Note that the `.psql` file contains the database dump and the `.manifest` file contains the secrets.
      The `aws_access_key_id` and `aws_secret_access_key` will need to be set based on the `postgres-backup-s3-credentials` secret.

        ```bash
        ncn-mw# export S3_ACCESS_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.access_key}' | base64 --decode`

        ncn-mw# export S3_SECRET_KEY=`kubectl get secrets postgres-backup-s3-credentials -ojsonpath='{.data.secret_key}' | base64 --decode`
        ```

        `list.py`:

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

        `download.py`:

        Update the script for the specific `.manifest` and `.psql` files to be downloaded from S3.

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

1. Set helper variables.

    ```bash
    ncn-mw# DUMPFILE=gitea-vcs-postgres-2021-07-21T19:03:18.sql
    ncn-mw# MANIFEST=gitea-vcs-postgres-2021-07-21T19:03:18.manifest
    ncn-mw# SERVICE=gitea-vcs
    ncn-mw# SERVICELABEL=vcs
    ncn-mw# NAMESPACE=services
    ncn-mw# POSTGRESQL=gitea-vcs-postgres
    ```

1. Scale the VCS service to 0.

    ```bash
    ncn-mw# kubectl scale deployment ${SERVICE} -n "${NAMESPACE}" --replicas=0
    ```

1. Wait for the pods to terminate.

    ```bash
    ncn-mw# while kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name="${SERVICELABEL}" | grep -qv NAME ; do
                echo "  waiting for pods to terminate"; sleep 2
            done
    ```

1. Delete the VCS Postgres cluster.

    ```bash
    ncn-mw# kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq 'del(.spec.selector)' |
                jq 'del(.spec.template.metadata.labels."controller-uid")' | jq 'del(.status)' > postgres-cr.json
    ncn-mw# kubectl delete -f postgres-cr.json
    ```

1. Wait for the pods to terminate.

    ```bash
    ncn-mw# while kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n "${NAMESPACE}" | grep -qv NAME ; do
                echo "  waiting for pods to terminate"; sleep 2
            done
    ```

1. Create a new single instance VCS Postgres cluster.

    ```bash
    ncn-mw# cp postgres-cr.json postgres-orig-cr.json
    ncn-mw# jq '.spec.numberOfInstances = 1' postgres-orig-cr.json > postgres-cr.json
    ncn-mw# kubectl create -f postgres-cr.json
    ```

1. Wait for the pod to start.

    ```bash
    ncn-mw# while ! kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n "${NAMESPACE}" | grep -qv NAME ; do
                echo "  waiting for pod to start"; sleep 2
            done
    ```

1. Wait for the Postgres cluster to start running.

    ```bash
    ncn-mw# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ]
            do
                echo "  waiting for postgresql to start running"; sleep 2
            done
    ```

1. Copy the database dump file to the Postgres member.

    ```bash
    ncn-mw# kubectl cp "./${DUMPFILE}" "${POSTGRESQL}-0:/home/postgres/${DUMPFILE}" -c postgres -n services
    ```

1. Restore the data.

    ```bash
    ncn-mw# kubectl exec "${POSTGRESQL}-0" -c postgres -n services -it -- psql -U postgres < "${DUMPFILE}"
    ```

    Errors such as `... already exists` can be ignored; the restore can be considered successful when it completes.

1. Either update or re-create the `gitea-vcs-postgres` secrets.

   * Update the secrets in Postgres.

        If a manual dump was done, and the secrets were not saved, then the secrets in the newly created Postgres cluster will need to be updated.

        1. From the three `gitea-vcs-postgres` secrets, collect the password for each Postgres username:
           `postgres`, `service_account`, and `standby`.

            ```bash
            ncn-mw# for secret in postgres.gitea-vcs-postgres.credentials service-account.gitea-vcs-postgres.credentials \
                        standby.gitea-vcs-postgres.credentials
                    do
                        echo -n "secret ${secret} username & password: "
                        echo -n "`kubectl get secret "${secret}" -n "${NAMESPACE}" -ojsonpath='{.data.username}' | base64 -d` "
                        echo `kubectl get secret "${secret}" -n "${NAMESPACE}" -ojsonpath='{.data.password}'| base64 -d`
                    done
            ```

            Example output:

            ```text
            secret postgres.gitea-vcs-postgres.credentials username & password: postgres ABCXYZ
            secret service-account.gitea-vcs-postgres.credentials username & password: service_account ABC123
            secret standby.gitea-vcs-postgres.credentials username & password: standby 123456
            ```

        1. `kubectl exec` into the Postgres pod.

            ```bash
            ncn-mw# kubectl exec "${POSTGRESQL}-0" -n "${NAMESPACE}" -c postgres -it -- bash
            ```

        1. Open a Postgres console.

            ```bash
            pod# /usr/bin/psql postgres postgres
            ```

        1. Update the password for each user to match the values found in the secrets.

            1. Update the password for the `postgres` user.

                ```console
                postgres# ALTER USER postgres WITH PASSWORD 'ABCXYZ';
                ```

                Example of successful output:

                ```text
                ALTER ROLE
                ```

            1. Update the password for the `service_account` user.

                ```console
                postgres# ALTER USER service_account WITH PASSWORD 'ABC123';
                ```

                Example of successful output:

                ```text
                ALTER ROLE
                ```

            1. Update the password for the `standby` user.

                ```console
                postgres# ALTER USER standby WITH PASSWORD '123456';
                ```

                Example of successful output:

                ```text
                ALTER ROLE
                ```

        1. Exit the Postgres console with the `\q` command.

        1. Exit the Postgres pod with the `exit` command.

   * Re-create secrets in Kubernetes.

        If the Postgres secrets were auto-backed up, then re-create the secrets in Kubernetes.

        Delete and re-create the three `gitea-vcs-postgres` secrets using the manifest that was copied from S3 earlier.

        ```bash
        ncn-mw# kubectl delete secret postgres.gitea-vcs-postgres.credentials \
                    service-account.gitea-vcs-postgres.credentials standby.gitea-vcs-postgres.credentials -n services
        ncn-mw# kubectl apply -f "${MANIFEST}"
        ```

1. Restart the Postgres cluster.

    ```bash
    ncn-mw# kubectl delete pod -n "${NAMESPACE}" "${POSTGRESQL}-0"
    ```

1. Wait for the `postgresql` pod to start.

    ```bash
    ncn-mw# while ! kubectl get pods -l "application=spilo,cluster-name=${POSTGRESQL}" -n "${NAMESPACE}" | grep -qv NAME ; do
                echo "  waiting for pods to start"; sleep 2
            done
    ```

1. Scale the Postgres cluster back to 3 instances.

    ```bash
    ncn-mw# kubectl patch postgresql "${POSTGRESQL}" -n "${NAMESPACE}" --type='json' \
                -p='[{"op" : "replace", "path":"/spec/numberOfInstances", "value" : 3}]'
    ```

1. Wait for the `postgresql` cluster to start running.

    ```bash
    ncn-mw# while [ $(kubectl get postgresql "${POSTGRESQL}" -n "${NAMESPACE}" -o json | jq -r '.status.PostgresClusterStatus') != "Running" ]
            do
                echo "  waiting for postgresql to start running"; sleep 2
            done
    ```

1. Scale the Gitea service back up.

    ```bash
    ncn-mw# kubectl scale deployment ${SERVICE} -n "${NAMESPACE}" --replicas=1
    ```

1. Wait for the Gitea pods to start.

    ```bash
    ncn-mw# while ! kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name="${SERVICELABEL}" | grep -qv NAME ; do
                echo "  waiting for pods to start"; sleep 2
            done
    ```

### 2. Restore PVC data

**IMPORTANT:** Only do this if necessary. One does not always restore after a backup; sometimes the documentation dictates performing the backup procedure as a precautionary step.

When restoring the VCS Postgres database, the PVC should also be restored to the same point in time. The restore
process can be run at any time while the service is running using the following commands:

```bash
ncn-mw# POD=$(kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o json | jq -r '.items[] | .metadata.name')
ncn-mw# kubectl -n services cp ./vcs.tar ${POD}:/tmp/vcs.tar &&
        kubectl -n services exec ${POD} -- tar -C / -xvf /tmp/vcs.tar &&
        kubectl -n services rollout restart deployment gitea-vcs
```

## Alternative backup/restore strategy

An alternative to the separate backups of the Postgres and PVC data is to backup the Git data. This has the advantage that only one backup is needed and that the Git backups can
be imported into any Git server, not just Gitea. This has the disadvantage that some information about the Gitea deployment is lost (such as user and organization information)
and may need to be recreated manually if the VCS deployment is lost.

The following scripts create and use a `vcs-content` directory that contains all Git data. This should be copied to a safe location after export, and moved back to the system before import.

### Alternative export method

> **WARNING:** The following example uses the VCS `admin` username and password in plaintext on the command line, meaning it will be stored in the shell history as
> well as be visible to all users on the system in the process table. These dangers can be avoided by modifying or replacing the `curl` command (such as
> supplying the credentials to `curl` using the `--netrc-file` argument instead of the `--user` argument, or replacing it with a simple Python script).

Use the following commands to do the export:

```bash
ncn-mw# RESULTS=vcs-content
ncn-mw# mkdir $RESULTS
ncn-mw# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn-mw# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn-mw# git config --global credential.helper store
ncn-mw# echo "https://${VCS_USER}:${VCS_PASSWORD}@api-gw-service-nmn.local" > ~/.git-credentials
ncn-mw# for repo in $(curl -s https://api-gw-service-nmn.local/vcs/api/v1/orgs/cray/repos --user ${VCS_USER}:${VCS_PASSWORD}| jq -r '.[] | .name') ; do
            git clone --mirror https://api-gw-service-nmn.local/vcs/cray/${repo}.git
            cd ${repo}.git
            git bundle create ${repo}.bundle --all
            cp ${repo}.bundle ../$RESULTS
            cd ..
            rm -r $repo.git
        done
```

### Alternative import method

Use the following commands to do the import:

```bash
ncn-mw# SOURCE=vcs-content
ncn-mw# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn-mw# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn-mw# git config --global credential.helper store
ncn-mw# echo "https://${VCS_USER}:${VCS_PASSWORD}@api-gw-service-nmn.local" > ~/.git-credentials
ncn-mw# for file in $(ls $SOURCE); do
            repo=$(echo $file | sed 's/.bundle$//')
            git clone --mirror ${SOURCE}/${repo}.bundle
            cd ${repo}.git
            git remote set-url origin https://api-gw-service-nmn.local/vcs/cray/${repo}.git
            git push
            cd ..
            rm -r ${repo}.git
        done
```

Prior to import, the repository structure may need to be recreated if it has not already been by an install.

Adjust the repository list as necessary, if any additional repositories are present. Repository settings such as `public` or `private` will also need to be manually set, if applicable.

For example:

> **WARNING:** The following example uses the VCS `admin` username and password in plaintext on the command line, meaning it will be stored in the shell history as
> well as be visible to all users on the system in the process table. These dangers can be avoided by modifying or replacing the `curl` command (such as
> supplying the credentials to `curl` using the `--netrc-file` argument instead of the `--user` argument, or replacing it with a simple Python script).

```bash
ncn-mw# VCS_USER=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_username}} | base64 --decode)
ncn-mw# VCS_PASSWORD=$(kubectl get secret -n services vcs-user-credentials --template={{.data.vcs_password}} | base64 --decode)
ncn-mw# REPOS="analytics-config-management cos-config-management cpe-config-management slurm-config-management sma-config-management uan-config-management csm-config-management"
ncn-mw# for repo in $REPOS ; do
            curl -X POST https://api-gw-service-nmn.local/vcs/api/v1/orgs/cray/repos -u ${VCS_USER}:${VCS_PASSWORD} -d name=${repo}
        done
```
