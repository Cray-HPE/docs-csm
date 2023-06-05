# Backup/Restore HSM User Data (Locks, Groups, and Partitions)

## Locks

### Backup Locks to json file (mw#-ncn):

First set locks dump filename (can be anything you would like, suggested format below)

```bash
LOCKS_FILE=cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
echo $LOCKS_FILE
```

```bash
cray hsm locks status list --format json > cray-smd-locks-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
LOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/status
curl -k -s -H "Authorization: Bearer ${TOKEN}" $LOCK_URL | jq > $LOCKS_FILE
```

### Restore Locks from json file (mw#-ncn):

```bash
LOCK_JSON=cray-smd-locks-dump_2023-03-09_15-59-35.json
for xname in `cat $LOCK_JSON | jq '.[][] | select(.Locked)' | jq -r .ID`; do echo $xname; cray hsm locks lock create --component-ids $xname; done
for xname in `cat $LOCK_JSON | jq '.[][] | select(.Locked|not)' | jq -r .ID`; do echo $xname; cray hsm locks unlock create --component-ids $xname; done
```

## Groups

### Backup Groups to json file (mw#-ncn):

First set group dump filename (can be anything you would like, suggested format below)

```bash
GROUPS_FILE=cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
echo $GROUPS_FILE
```

```bash
TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
GROUP_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/groups
curl -k -s -H "Authorization: Bearer ${TOKEN}" $GROUP_URL | jq > $GROUPS_FILE
```

### Restore Groups from json file (mw#-ncn):

First set groups filename with dump file

```bash
GROUPS_FILE=cray-smd-groups-dump_2023-03-09_16-17-28.json
```

```bash
TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
GROUP_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/groups
IFS_SAVE=$IFS
IFS=$'\n'
for x1 in `cat $GROUPS_FILE | jq -c .[]`; do echo; echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $GROUP_URL; done
IFS=$IFS_SAVE
curl -k -s -H "Authorization: Bearer ${TOKEN}" $GROUP_URL | jq
```

## Partitions

### Backup Partitions to json file (mw#-ncn):

First set partion dump filename (can be anything you would like, suggested format below)

```bash
PARTITIONS_FILE=cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
echo $PARTITIONS_FILE
```

```bash
TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
PARTITION_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/partitions
curl -k -s -H "Authorization: Bearer ${TOKEN}" $PARTITION_URL | jq > $PARTITIONS_FILE
```

### Resotre Partitions from json file (mw#-ncn):

First set partion filename with dump file

```bash
PARTITIONS_FILE=cray-smd-partitions-dump_2023-04-25_14-31-19.json
```

```bash
TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
PARTITION_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/partitions
IFS_SAVE=$IFS
IFS=$'\n'
for x1 in `cat $PARTITIONS_FILE | jq -c .[]`; do echo; echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $PARTITION_URL;  done
IFS=$IFS_SAVE
curl -k -s -H "Authorization: Bearer ${TOKEN}" $PARTITION_URL | jq
```
