# Create a Backup of the SLS Postgres Database

Perform a manual backup of the contents of the SLS Postgres database.
This backup can be used to restore the contents of the SLS Postgres database at a later point in time using the
[Restoring SLS Postgres cluster from backup](Restore_SLS_Postgres_Database_from_Backup.md) procedure.

## Prerequisites

- Healthy SLS Postgres Cluster.

  Use `patronictl list` on the SLS Postgres cluster to determine the current state of the cluster, and a healthy cluster will look similar to the following:

  ```bash
  kubectl exec cray-sls-postgres-0 -n services -c postgres -it -- patronictl list
  ```

  Example output:

  ```text
  + Cluster: cray-sls-postgres (6975238790569058381) ---+----+-----------+
  |        Member       |    Host    |  Role  |  State  | TL | Lag in MB |
  +---------------------+------------+--------+---------+----+-----------+
  | cray-sls-postgres-0 | 10.44.0.40 | Leader | running |  1 |           |
  | cray-sls-postgres-1 | 10.36.0.37 |        | running |  1 |         0 |
  | cray-sls-postgres-2 | 10.42.0.42 |        | running |  1 |         0 |
  +---------------------+------------+--------+---------+----+-----------+
  ```

- Healthy SLS Service.
  Verify all 3 SLS replicas are up and running:

  ```bash
  kubectl -n services get pods -l cluster-name=cray-sls-postgres
  ```

  Example output:

  ```text
  NAME                  READY   STATUS    RESTARTS   AGE
  cray-sls-postgres-0   3/3     Running   0          18d
  cray-sls-postgres-1   3/3     Running   0          18d
  cray-sls-postgres-2   3/3     Running   0          18d
  ```

## Procedure

1. Create a directory to store the SLS backup files in:

    ```bash
    BACKUP_LOCATION="/root"
    export BACKUP_NAME="cray-sls-postgres-backup_`date '+%Y-%m-%d_%H-%M-%S'`"
    export BACKUP_FOLDER="${BACKUP_LOCATION}/${BACKUP_NAME}"
    mkdir -p "$BACKUP_FOLDER"
    ```

    The SLS backup will be located at the following directory:

    ```bash
    echo $BACKUP_FOLDER
    /root/cray-sls-postgres-backup_2021-07-07_16-39-44
    ```

2. Run the `backup_sls_postgres.sh` script to take a backup of the SLS Postgres:

    ```bash
    /usr/share/doc/csm/scripts/operations/system_layout_service/backup_sls_postgres.sh
    ```

    Example output:

    ```text
    ~/cray-sls-postgres-backup_2021-07-07_16-39-44 ~
    SLS postgres backup file will land in /root/cray-sls-postgres-backup_2021-07-07_16-39-44
    Determining the postgres leader...
    The SLS postgres leader is cray-sls-postgres-0
    Using pg_dumpall to dump the contents of the SLS database...
    PSQL dump is available at /root/cray-sls-postgres-backup_2021-07-07_16-39-44/cray-sls-postgres-backup_2021-07-07_16-39-44.psql
    Saving Kubernetes secret service-account.cray-sls-postgres.credentials
    Saving Kubernetes secret slsuser.cray-sls-postgres.credentials
    Saving Kubernetes secret postgres.cray-sls-postgres.credentials
    Saving Kubernetes secret standby.cray-sls-postgres.credentials
    Removing extra fields from service-account.cray-sls-postgres.credentials.yaml
    Removing extra fields from slsuser.cray-sls-postgres.credentials.yaml
    Removing extra fields from postgres.cray-sls-postgres.credentials.yaml
    Removing extra fields from standby.cray-sls-postgres.credentials.yaml
    Adding Kubernetes secret service-account.cray-sls-postgres.credentials to secret manifest
    Adding Kubernetes secret slsuser.cray-sls-postgres.credentials to secret manifest
    Adding Kubernetes secret postgres.cray-sls-postgres.credentials to secret manifest
    Adding Kubernetes secret standby.cray-sls-postgres.credentials to secret manifest
    Secret manifest is located at /root/cray-sls-postgres-backup_2021-07-07_16-39-44/cray-sls-postgres-backup_2021-07-07_16-39-44.manifest
    Performing SLS dumpstate...
    SLS dumpstate is available at /root/cray-sls-postgres-backup_2021-07-07_16-39-44/sls_dump.json
    SLS Postgres backup is available at: /root/cray-sls-postgres-backup_2021-07-07_16-39-44
    ```

3. Copy the backup folder off of the cluster, and store it in a secure location.

    The `BACKUP_FOLDER` environment variable is the name of the folder to backup.

    ```bash
    echo $BACKUP_FOLDER
    ```

    `/root/cray-sls-postgres-backup_2021-07-07_16-39-44` is the returned value in this example.

    Optionally, create a tarball of the Postgres backup files:

    ```bash
    cd $BACKUP_FOLDER && cd ..
    tar -czvf $BACKUP_NAME.tar.gz $BACKUP_NAME
    ```
