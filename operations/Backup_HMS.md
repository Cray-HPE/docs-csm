# Create a Backup of HMS Items for reinstall

## Pre-procedure

Create a directory for the contents to reside.

```bash
mkdir backup
cd backup
```

## HSM

Create backup of postgres database

```bash
BACKUP_LOCATION=`pwd`
export BACKUP_NAME="cray-smd-postgres-backup_`date '+%Y-%m-%d_%H-%M-%S'`"
export BACKUP_FOLDER="${BACKUP_LOCATION}/${BACKUP_NAME}"
mkdir -p "$BACKUP_FOLDER"
echo $BACKUP_FOLDER
/usr/share/doc/csm/operations/hardware_state_manager/scripts/backup_smd_postgres.sh
```
Check the output from the script that just ran, if successful make a tar file of the backup.

```bash
cd $BACKUP_FOLDER && cd ..
tar -czvf $BACKUP_NAME.tar.gz $BACKUP_NAME
rm -rf $BACKUP_NAME
ls -la
```

Create backups of locks, groups, partitions, and membership lists

```bash
cray hsm locks status list --format json > cray-smd-locks-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
cray hsm groups list --format json > cray-smd-groups-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
cray hsm partitions list --format json > cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
cray hsm memberships list --format json > cray-smd-memberships-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
ls -la
```

## SLS

Create backup of SLS postgres database

```bash
BACKUP_LOCATION=`pwd`
export BACKUP_NAME="cray-sls-postgres-backup_`date '+%Y-%m-%d_%H-%M-%S'`"
export BACKUP_FOLDER="${BACKUP_LOCATION}/${BACKUP_NAME}"
mkdir -p "$BACKUP_FOLDER"
echo $BACKUP_FOLDER
/usr/share/doc/csm/scripts/operations/system_layout_service/backup_sls_postgres.sh
```

Check the output from the script that just ran, if successful make a tar file of the backup.

```bash
cd $BACKUP_FOLDER && cd ..
tar -czvf $BACKUP_NAME.tar.gz $BACKUP_NAME
rm -rf $BACKUP_NAME
ls -la
```

Create a backup of the S3 data for SLS

```bash
BACKUP_LOCATION=`pwd`
BACKUP_NAME="cray-sls-s3-backup_`date '+%Y-%m-%d_%H-%M-%S'`"
BACKUP_FOLDER="${BACKUP_LOCATION}/${BACKUP_NAME}"
mkdir -p "$BACKUP_FOLDER"
cd $BACKUP_FOLDER
for file in `cray artifacts list sls --format json | jq -r .artifacts[].Key`; do echo $file; cray artifacts get sls $file $file; done
cd $BACKUP_FOLDER && cd ..
tar -czvf $BACKUP_NAME.tar.gz $BACKUP_NAME
rm -rf $BACKUP_NAME
ls -la
```

Dump the state of SLS

```bash
cray sls dumpstate list --format json > cray-sls-dump_`date '+%Y-%m-%d_%H-%M-%S'`
ls -la
```

## FAS

Create a backup of the etcd database

```bash
SERVICE=cray-fas
BACKUP_NAME=$SERVICE-etcd-backup_`date '+%Y-%m-%d_%H-%M-%S'`
JOB=$(kubectl exec -it -n operators  $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') -c util -- create_backup $SERVICE $BACKUP_NAME | cut -d " " -f 1); echo $JOB
```

Wait for the job to be completed by checking the status:

```bash
kubectl -n services get $JOB -o json | jq .status
```

Download the backup:

```bash
cray artifacts get etcd-backup $SERVICE/$BACKUP_NAME $BACKUP_NAME
ls -la
```

Make a backup of the Images stored in S3 and the image list from fas.
You may receive an error "cannot create directory" - which you can ignore.

```bash
BACKUP_LOCATION=`pwd`
BACKUP_NAME=cray-fas-images-backup_`date '+%Y-%m-%d_%H-%M-%S'`
BACKUP_FOLDER=${BACKUP_LOCATION}/${BACKUP_NAME}
mkdir -p "$BACKUP_FOLDER"
cd $BACKUP_FOLDER
for file in `cray fas images list --format json | jq -r '.[][].s3URL' | cut -d "/" -f 3-4`; do echo $file; mkdir `echo $file | cut -d "/" -f 1`; cray artifacts get fw-update $file $file; done
cd $BACKUP_FOLDER && cd ..
tar -czvf $BACKUP_NAME.tar.gz $BACKUP_NAME
rm -rf $BACKUP_NAME
cray fas images list --format json > cray-fas-images-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
ls -la
```

## BSS

Create a backup of the etcd database

```bash
SERVICE=cray-bss
BACKUP_NAME=$SERVICE-etcd-backup_`date '+%Y-%m-%d_%H-%M-%S'`
JOB=`kubectl exec -it -n operators  $(kubectl get pod -n operators | grep etcd-backup-restore | head -1 | awk '{print $1}') -c util -- create_backup $SERVICE $BACKUP_NAME`;echo $JOB
```

Wait for the job to be completed by checking the status:

```bash
kubectl -n services get $JOB -o json | jq .status
```

Download the backup:

```bash
cray artifacts get etcd-backup $SERVICE/$BACKUP_NAME $BACKUP_NAME
ls -la
```

Create a backup of the BSS Boot Parameters:

```bash
cray bss bootparameters list --format json > cray-bss-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
ls -la
```
