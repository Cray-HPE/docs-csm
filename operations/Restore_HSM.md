# Restore from Backup of HMS Items for reinstall

## Pre-procedure

Place tar file from [Backup](Backup_HMS.md)
on the system to restore. (mw-ncn#)

Set name of backup file (without `.tar.gz`):

```bash
BACKUP_FILE=hms-backup_2023-06-28_11-12-24
```

Untar file:

```bash
tar -xf $BACKUP_FILE.tar.gz
cd $BACKUP_FILE
ls -la
```

Set up token:

```bash
export TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
```

Set up Docs directory:

```
DOCS_DIR=/usr/share/doc/csm/scripts
```

## Restore Roles and Subroles

```bash
kubectl replace -f cray-hms-base-config_$BACKUP_FILE.yaml
$DOCKS_DIR/operations/hardware_state_manager/restoreroles.py cray-smd-components-dump_$BACKUPDIR.json
```

Run Verify Membership Script:
If script returns no issues, then there is no need to restore locks, groups, and partitions.
If script returns differences, then restore locks, groups, and/or partitions as needed.

```bash
$DOCS_DIR/operations/hardware_state_manager/verifymembership.py cray-smd-memberships-dump_$BACKUPDIR.json
```

## Restore Locks

```bash
LOCKS_FILE=cray-smd-locks-dump_$BACKUP_FILE.json
echo $LOCKS_FILE
LOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/lock
UNLOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/unlock
for xname in `cat $LOCKS_FILE | jq '.[][] | select(.Locked)' | jq -r .ID`; do echo; echo $xname; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d '{"ComponentIDs":["'$xname'"], "Verify":false}' $LOCK_URL; done
for xname in `cat $LOCKS_FILE | jq '.[][] | select(.Locked|not)' | jq -r .ID`; do echo; echo $xname; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d '{"ComponentIDs":["'$xname'"], "Verify":false}' $UNLOCK_URL; done
```

## Restore Groups

```bash
GROUPS_FILE=cray-smd-groups-dump_$BACKUP_FILE.json
echo $GROUPS_FILE
GROUP_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/groups
IFS_SAVE=$IFS
IFS=$'\n'
for x1 in `cat $GROUPS_FILE | jq -c .[]`; do echo; echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $GROUP_URL; done
IFS=$IFS_SAVE
curl -k -s -H "Authorization: Bearer ${TOKEN}" $GROUP_URL | jq
```

## Restore Partitions

```bash
PARTITIONS_FILE=cray-smd-partitions-dump_$BACKUP_FILE.json
PARTITION_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/partitions
IFS_SAVE=$IFS
IFS=$'\n'
for x1 in `cat $PARTITIONS_FILE | jq -c .[]`; do echo; echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $PARTITION_URL;  done
IFS=$IFS_SAVE
curl -k -s -H "Authorization: Bearer ${TOKEN}" $PARTITION_URL | jq
```

Run Verify Membership Script if you restored groups, locks, or partitions:

```bash
$DOCS_DIR/operations/hardware_state_manager/verifymembership.py
```
