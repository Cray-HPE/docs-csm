# Backup/Restore HSM User Data (Locks, Groups, and Partitions)

## Locks

Backup Locks to json file (mw#-ncn):

```bash
cray hsm locks status list --format json > cray-smd-locks-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
```

Restore Locks from json file (mw#-ncn):

```bash
LOCK_JSON=cray-smd-locks-dump_2023-03-09_15-59-35.json
for xname in `cat $LOCK_JSON | jq '.[][] | select(.Locked)' | jq -r .ID`; do echo $xname; cray hsm locks lock create --component-ids $xname; done
for xname in `cat $LOCK_JSON | jq '.[][] | select(.Locked|not)' | jq -r .ID`; do echo $xname; cray hsm locks unlock create --component-ids $xname; done
```

## Groups

Backup Groups to json file (mw#-ncn):

```bash
cray hsm groups list --format json > cray-smd-groups-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
```

Restore Groups from json file (mw#-ncn):

```bash
TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
GROUP_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/groups
GROUPS_FILE=cray-smd-groups-dump_2023-03-09_16-17-28.json
IFS_SAVE=$IFS
IFS=$'\n'
for x1 in `cat $GROUPS_FILE | jq -c .[]`; do echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $GROUP_URL;  done
IFS=$IFS_SAVE
curl -k -s -H "Authorization: Bearer ${TOKEN}" $GROUP_URL | jq
```

## Partitions

Backup Partitions to json file (mw#-ncn):

```bash
cray hsm partitions list --format json > cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
```

Resotre Partitions from json file (mw#-ncn):

```bash
TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
PARTITION_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/partitions
PARTITIONS_FILE=savepart.json
IFS_SAVE=$IFS
IFS=$'\n'
for x1 in `cat $PARTITIONS_FILE | jq -c .[]`; do echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $PARTITION_URL;  done
IFS=$IFS_SAVE
curl -k -s -H "Authorization: Bearer ${TOKEN}" $PARTITION_URL | jq
```
