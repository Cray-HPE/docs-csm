# Create a Backup of HMS Items for reinstall

## Pre-procedure

Create a directory for the contents to reside.

```bash
BACKUPDIR=hms-backup_`date '+%Y-%m-%d_%H-%M-%S'`
mkdir $BACKUPDIR
cd $BACKUPDIR
```

## HSM

Create backup of postgres database

```bash
BACKUP_LOCATION=`pwd`
export BACKUP_NAME=cray-smd-postgres-$BACKUPDIR
export BACKUP_FOLDER=${BACKUP_LOCATION}/${BACKUP_NAME}
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

Create backups of locks, groups, partitions, membership, and hardware inventory

```bash
cray hsm locks status list --format json > cray-smd-locks-dump_$BACKUPDIR.json
cray hsm groups list --format json > cray-smd-groups-dump_$BACKUPDIR.json
cray hsm partitions list --format json > cray-smd-partitions-dump_$BACKUPDIR.json
cray hsm memberships list --format json > cray-smd-memberships-dump_$BACKUPDIR.json
cray hsm inventory hardware history list --format json > cray-smd-hardware-history-dump_$BACKUPDIR.json
ls -la
```

Create backup of roles, sub-roles, and cray-hms-base-config

```bash
kubectl -n services get configmap cray-hms-base-config -o yaml | sed '/resourceVersion:/d' | sed '/uid:/d' > cray-hms-base-config_$BACKUPDIR.yaml
cray hsm state components list --format json > cray-smd-components-dump_$BACKUPDIR.json
ls -la
```

## SLS

Create backup of SLS postgres database

```bash
BACKUP_LOCATION=`pwd`
export BACKUP_NAME=cray-sls-postgres-$BACKUPDIR
export BACKUP_FOLDER=${BACKUP_LOCATION}/${BACKUP_NAME}
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
BACKUP_NAME=cray-sls-s3-$BACKUPDIR
BACKUP_FOLDER=${BACKUP_LOCATION}/${BACKUP_NAME}
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
cray sls dumpstate list --format json > cray-sls-dump_$BACKUPDIR.json
cp cray-sls-dump_$BACKUPDIR.json sls_input_file.json
ls -la
```

## FAS

Create a backup of the etcd database

```bash
SERVICE=cray-fas
BACKUP_NAME=$SERVICE-etcd-$BACKUPDIR
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

## BSS

Create a backup of the etcd database

```bash
SERVICE=cray-bss
BACKUP_NAME=$SERVICE-etcd-$BACKUPDIR
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

Create a backup of the BSS Boot Parameters:

```bash
cray bss bootparameters list --format json > cray-bss-boot-parameters-dump_$BACKUPDIR.json
ls -la
```

Create a backup of the BSS Boot Parameters for only Compute Nodes:

```bash
xnames=`cray hsm state components list --type Node --role Compute --format json | jq -r '.[] | map(.ID) | join(",")'`
echo $xnames
cray bss bootparameters list --name $xnames --format json > cray-bss-compute-boot-parameters-dump_$BACKUPDIR.json
ls -la
```

## Create Tar file

```bash
cd ..
tar -czvf $BACKUPDIR.tar.gz $BACKUPDIR
```
