# Restore HSM

## Procedure

1. If `tar` file was placed in s3 from [Backup](Backup_HMS.md) copy to the system to restore.

    1. List objects in s3

        ```bash
        bucket=hms
        aws s3api list-objects --bucket $bucket --endpoint-url http://ncn-m001.nmn:8000
        ```

    1. (`ncn-mw#`) Set name of backup file (without `.tar.gz`). example:

        ```bash
        BACKUP_FILE=hms-backup_2023-06-28_11-12-24
        ```

    1. (`ncn-mw#`) To retrieve files from backup disk.

        ```bash
        file=$BACKUP_FILE.tar.gz
        aws s3api get-object --bucket $bucket --key $file $file --endpoint-url http://ncn-m001.nmn:8000
        file=sls_input_file.json
        aws s3api get-object --bucket $bucket --key $file $file --endpoint-url http://ncn-m001.nmn:8000
        ```

1. (`ncn-mw#`) Set name of backup file (without `.tar.gz`). example:

    ```bash
    BACKUP_FILE=hms-backup_2023-06-28_11-12-24
    ```

1. (`ncn-mw#`) Expand file.

    ```bash
    tar -xf $BACKUP_FILE.tar.gz
    cd $BACKUP_FILE
    ls -la
    ```

1. (`ncn-mw#`) Set up API token.

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d) https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
    ```

1. (`ncn-mw#`) Set helper variable.

    ```bash
    DOCS_DIR=/usr/share/doc/csm/scripts
    ```

1. (`ncn-mw#`) Restore HSM roles and subroles.

    ```bash
    kubectl replace -f cray-hms-base-config_$BACKUP_FILE.yaml
    sleep 60
    $DOCS_DIR/operations/hardware_state_manager/updateroles.py cray-smd-components-dump_$BACKUP_FILE.json
    ```

1. (`ncn-mw#`) Verify HSM roles and subroles.

    ```bash
    $DOCS_DIR/operations/hardware_state_manager/verifyroles.py cray-smd-components-dump_$BACKUP_FILE.json
    ```

1. (`ncn-mw#`) Check for missing locks, groups, or partitions.

    The following script compares the current system with the information in the backup file.

    ```bash
    $DOCS_DIR/operations/hardware_state_manager/verifymembership.py cray-smd-memberships-dump_$BACKUP_FILE.json
    ```

1. (`ncn-mw#`) If the `verifymembership.py` script reported differences in locks, then restore the locks.

    > Skip this step if no differences were reported for locks.

    ```bash
    LOCKS_FILE=cray-smd-locks-dump_$BACKUP_FILE.json
    echo $LOCKS_FILE
    LOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/lock
    UNLOCK_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/locks/unlock
    for xname in `cat $LOCKS_FILE | jq '.[][] | select(.Locked)' | jq -r .ID`; do echo; echo $xname; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d '{"ComponentIDs":["'$xname'"], "Verify":false}' $LOCK_URL; done
    for xname in `cat $LOCKS_FILE | jq '.[][] | select(.Locked|not)' | jq -r .ID`; do echo; echo $xname; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d '{"ComponentIDs":["'$xname'"], "Verify":false}' $UNLOCK_URL; done
    ```

1. (`ncn-mw#`) If the `verifymembership.py` script reported differences in groups, then restore the groups.

    > Skip this step if no differences were reported for groups.

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

1. (`ncn-mw#`) If the `verifymembership.py` script reported differences in partitions, then restore the partitions.

    > Skip this step if no differences were reported for partitions.

    ```bash
    PARTITIONS_FILE=cray-smd-partitions-dump_$BACKUP_FILE.json
    PARTITION_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/partitions
    IFS_SAVE=$IFS
    IFS=$'\n'
    for x1 in `cat $PARTITIONS_FILE | jq -c .[]`; do echo; echo $x1; curl -k -s -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d "$x1" $PARTITION_URL;  done
    IFS=$IFS_SAVE
    curl -k -s -H "Authorization: Bearer ${TOKEN}" $PARTITION_URL | jq
    ```

1. (`ncn-mw#`) Repeat the earlier `verifymembership.py` step to confirm that no differences are reported.

    ```bash
    $DOCS_DIR/operations/hardware_state_manager/verifymembership.py cray-smd-memberships-dump_$BACKUP_FILE.json
    ```

1. (`ncn-mw#`) Restore Boot Parameters.

    ```bash
    $DOCS_DIR/operations/boot_script_service/bss-restore-bootparameters.sh cray-bss-boot-parameters-dump_$BACKUP_FILE.json
    ```

1. (`ncn-mw#`) Disable nodes.

    ```bash
    COMPONENT_FILE=cray-smd-components-dump_$BACKUP_FILE.json
    ENABLE_URL=https://api-gw-service-nmn.local/apis/smd/hsm/v2/State/Components/BulkEnabled
    xnames=`cat $COMPONENT_FILE | jq '.[] | .[] | select(.Enabled==false)' | jq .ID | paste -sd, -`
    payload='{"ComponentIDs": ['$xnames'], "Enabled": false}'
    if [ ${#xnames} -gt 0 ]; then curl -k -s -X PATCH -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -d $payload $ENABLE_URL; echo $xnames; fi
    ```