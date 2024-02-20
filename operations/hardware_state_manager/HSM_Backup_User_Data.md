# Backup/Restore HSM User Data (Locks, Groups, and Partitions)

## Backup locks to `json` file

1. (`ncn-mw#`) Set locks dump filename (can be anything you would like, suggested format below).

    ```bash
    LOCKS_FILE=cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
    echo $LOCKS_FILE
    ```

1. (`ncn-mw#`) Set up token.

    ```bash
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Store Locks.

    ```bash
    LOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/status
    curl -k -s -H "Authorization: Bearer ${TOKEN}" $LOCK_URL | jq > $LOCKS_FILE
    ```

### Restore Locks from `json` file

1. (`ncn-mw#`) Set locks dump filename.

    ```bash
    LOCKS_FILE=cray-smd-locks-dump_2023-03-09_15-59-35.json
    ```

1. (`ncn-mw#`) Set up token.

    ```bash
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Restore Locks.

    ```bash
    LOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/lock
    UNLOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/unlock
    for xname in `cat $LOCKS_FILE | jq '.[][] | select(.Locked)' | jq -r .ID`; do echo; echo $xname; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d '{"ComponentIDs":["'$xname'"], "Verify":false}' $LOCK_URL; done
    for xname in `cat $LOCKS_FILE | jq '.[][] | select(.Locked|not)' | jq -r .ID`; do echo; echo $xname; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d '{"ComponentIDs":["'$xname'"], "Verify":false}' $UNLOCK_URL; done
    ```

    You may receive errors which just indicates the xname was already locked/unlocked before running the procedure.

    ```json
    {"type":"about:blank","title":"Bad Request","detail":"Component is Locked","status":400}
    {"type":"about:blank","title":"Bad Request","detail":"Component is Unlocked","status":400}
    ```

## Backup groups to `json` file

1. (`ncn-mw#`) Set group dump filename (can be anything you would like, suggested format below).

    ```bash
    GROUPS_FILE=cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
    echo $GROUPS_FILE
    ```

1. (`ncn-mw#`) Set up token.

    ```bash
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Store Groups.

    ```bash
    GROUP_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/groups
    curl -k -s -H "Authorization: Bearer ${TOKEN}" $GROUP_URL | jq > $GROUPS_FILE
    ```

### Restore Groups from `json` file

1. (`ncn-mw#`) Set groups filename with dump file.

    ```bash
    GROUPS_FILE=cray-smd-groups-dump_2023-03-09_16-17-28.json
    ```

1. (`ncn-mw#`) Set up token.

    ```bash
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Restore Groups.

    ```bash
    GROUP_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/groups
    IFS_SAVE=$IFS
    IFS=$'\n'
    for x1 in `cat $GROUPS_FILE | jq -c .[]`; do echo; echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $GROUP_URL; done
    IFS=$IFS_SAVE
    curl -k -s -H "Authorization: Bearer ${TOKEN}" $GROUP_URL | jq
    ```

## Backup partitions to `json` file

1. (`ncn-mw#`) Set partition dump filename (can be anything you would like, suggested format below).

    ```bash
    PARTITIONS_FILE=cray-smd-partitions-dump_`date '+%Y-%m-%d_%H-%M-%S'`.json
    echo $PARTITIONS_FILE
    ```

1. (`ncn-mw#`) Set up token.

    ```bash
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Store Partitions.

    ```bash
    PARTITION_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/partitions
    curl -k -s -H "Authorization: Bearer ${TOKEN}" $PARTITION_URL | jq > $PARTITIONS_FILE
    ```

### Restore Partitions from `json` file

1. (`ncn-mw#`) Set partition filename with dump file.

    ```bash
    PARTITIONS_FILE=cray-smd-partitions-dump_2023-04-25_14-31-19.json
    ```

1. (`ncn-mw#`) Set up token.

    ```bash
    TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Restore Partitions.

    ```bash
    PARTITION_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/partitions
    IFS_SAVE=$IFS
    IFS=$'\n'
    for x1 in `cat $PARTITIONS_FILE | jq -c .[]`; do echo; echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $PARTITION_URL;  done
    IFS=$IFS_SAVE
    curl -k -s -H "Authorization: Bearer ${TOKEN}" $PARTITION_URL | jq
    ```
