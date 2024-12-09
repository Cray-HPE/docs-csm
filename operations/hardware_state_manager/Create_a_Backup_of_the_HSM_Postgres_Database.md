# Create a Backup of the HSM Postgres Database

Perform a manual backup of the contents of the Hardware State Manager (HSM) Postgres database.
This backup can be used to restore the contents of the HSM Postgres database at a later point in time using the [Restore HSM Postgres from Backup](Restore_HSM_Postgres_from_Backup.md) procedure.

## Prerequisites

- Healthy HSM Postgres Cluster.

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

- Healthy HSM Service.

  Verify all 3 HSM replicas are up and running:

  ```bash
  kubectl -n services get pods -l cluster-name=cray-smd-postgres
  ```

  Example output:

  ```text
  NAME                  READY   STATUS    RESTARTS   AGE
  cray-smd-postgres-0   3/3     Running   0          18d
  cray-smd-postgres-1   3/3     Running   0          18d
  cray-smd-postgres-2   3/3     Running   0          18d
  ```

## Procedure

1. Create a directory to store the HSM backup files.

    ```bash
    BACKUP_LOCATION="/root"
    export BACKUP_NAME="cray-smd-postgres-backup_`date '+%Y-%m-%d_%H-%M-%S'`"
    export BACKUP_FOLDER="${BACKUP_LOCATION}/${BACKUP_NAME}"
    mkdir -p "$BACKUP_FOLDER"
    ```

    The HSM backup will be located in the following directory:

    ```bash
    echo $BACKUP_FOLDER
    ```

    Example output:

    ```text
    /root/cray-smd-postgres-backup_2021-07-07_16-39-44
    ```

2. Run the `backup_smd_postgres.sh` script to take a backup of the HSM Postgres.

    ```bash
    /usr/share/doc/csm/operations/hardware_state_manager/scripts/backup_smd_postgres.sh
    ```

    Example output:

    ```text
    ~/cray-smd-postgres-backup_2021-07-07_16-39-44 ~
    HSM postgres backup file will land in /root/cray-smd-postgres-backup_2021-07-07_16-39-44
    Determining the postgres leader...
    The HSM postgres leader is cray-smd-postgres-0
    Using pg_dumpall to dump the contents of the HSM database...
    PSQL dump is available at /root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.psql
    Saving Kubernetes secret service-account.cray-smd-postgres.credentials
    Saving Kubernetes secret hmsdsuser.cray-smd-postgres.credentials
    Saving Kubernetes secret postgres.cray-smd-postgres.credentials
    Saving Kubernetes secret standby.cray-smd-postgres.credentials
    Removing extra fields from service-account.cray-smd-postgres.credentials.yaml
    Removing extra fields from hmsdsuser.cray-smd-postgres.credentials.yaml
    Removing extra fields from postgres.cray-smd-postgres.credentials.yaml
    Removing extra fields from standby.cray-smd-postgres.credentials.yaml
    Adding Kubernetes secret service-account.cray-smd-postgres.credentials to secret manifest
    Adding Kubernetes secret hmsdsuser.cray-smd-postgres.credentials to secret manifest
    Adding Kubernetes secret postgres.cray-smd-postgres.credentials to secret manifest
    Adding Kubernetes secret standby.cray-smd-postgres.credentials to secret manifest
    Secret manifest is located at /root/cray-smd-postgres-backup_2021-07-07_16-39-44/cray-smd-postgres-backup_2021-07-07_16-39-44.manifest
    HSM Postgres backup is available at: /root/cray-smd-postgres-backup_2021-07-07_16-39-44
    ```

3. Copy the backup folder off of the cluster, and store it in a secure location.

    The `BACKUP_FOLDER` environment variable is the name of the folder to backup.

    ```bash
    echo $BACKUP_FOLDER
    ```

    Optionally, create a tarball of the Postgres backup files:

    ```bash
    cd $BACKUP_FOLDER && cd ..
    tar -czvf $BACKUP_NAME.tar.gz $BACKUP_NAME
    ```
