# Configure root user on HPE iLO BMCs

By default, HPE BMC controllers have the `Administrator` user account. In order to discover this type of hardware, the `root` service account needs to be configured.

This procedure is applicable in the following situations:

- The root password is known and does not match the destination system default air-cooled BMC credentials.
  - For example, a node has been moved between systems and each system has different default global credentials.
- The root user does not exist.
- The root user exists with an unknown password.

## Prerequisites

- The BMC is accessible over the network via hostname or IP address.

## Procedure

1. (`ncn-mw#`) Retrieve the root user password for this BMC.

    - **If configuring a BMC already present in the system**, then retrieve the device-specific root user password from Vault.

        ```bash
        BMC=x3000c0s3b0
        EXPECTED_ROOT_PASSWORD=$(cray scsd bmc creds list --targets "${BMC}" --format json | jq .Targets[].Password -r)
        ```

        The following output indicates that Vault does not contain a device-specific root user password for the specified BMC. In this case, use the system default air-cooled BMC root password described in the step below.

        ```text
        jq: error (at <stdin>:3): Cannot iterate over null (null)
        ```

    - **If configuring a new BMC being added to the system**, then retrieve the system's default air-cooled BMC root user password from Vault.

        ```bash
        VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json |
                            jq -r '.data["vault-root"]' |  base64 -d)
        EXPECTED_ROOT_PASSWORD=$(kubectl -n vault exec -it cray-vault-0 -c vault -- env \
            VAULT_TOKEN="$VAULT_PASSWD" VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json \
            vault kv get secret/reds-creds/defaults | jq .data.Cray.password -r)
        ```

1. (`ncn-mw#`) If desired, verify the contents of `EXPECTED_ROOT_PASSWORD`.

    ```bash
    echo $EXPECTED_ROOT_PASSWORD
    ```

1. (`ncn-mw#`) Set an environment variable containing the hostname or current IP address of the BMC. If coming from the
    [Add Worker, Storage, or Master NCNs](../node_management/Add_Remove_Replace_NCNs/Add_Remove_Replace_NCNs.md#add-worker-storage-or-master-ncns)
    procedure, then the IP address should already be stored in the `BMC_IP` environment variable.

    - Via hostname:

        ```bash
        BMC=x3000c0s3b0
        ```

    - Via IP address:

        ```bash
        BMC=10.254.1.9
        ```

1. (`ncn-mw#`) Determine if the root user account is functional.

    ```bash
    curl -k -u "root:${EXPECTED_ROOT_PASSWORD}" "https://${BMC}/redfish/v1/Managers" -i  | head -1
    ```

    Expected output of a functional root user account:

    ```text
    HTTP/1.1 200 OK
    ```

    **If the above output is observed, then no further action is required to enable the root user account. In this case, skip the rest of this procedure.**

    If the following output is observed, then this indicates that the root user either does not exist or is configured with a different password. **In this case, continue this procedure to correct the root user credentials.**

    ```text
    HTTP/1.1 401 Unauthorized
    ```

1. (`ncn-mw#`) Determine the default user credentials.

    > `read -s` is used to read the password in order to prevent it from being echoed to the screen or saved in the shell history.
    > Note that the subsequent `curl` commands **will** do both of these things. If this is not desired, the call should be made in
    > another way.

    1. The default user name is `Administrator`. Default credentials for the Administrator user on HPE nodes can be found on the serial label pull out tab attached to the server. See [HPE server support documentation](https://support.hpe.com/hpesc/public/docDisplay?docId=sf000046874en_us&docLocale=en_US).

        ```bash
        DEFAULT_USERNAME=Administrator
        read -s DEFAULT_PASSWORD
        ```

    1. Verify the contents of `DEFAULT_USERNAME`.

        ```bash
        echo $DEFAULT_USERNAME
        ```

1. (`ncn-mw#`) Try to access the BMC with the default user credentials.

    ```bash
    curl -k -u "${DEFAULT_USERNAME}:${DEFAULT_PASSWORD}" "https://${BMC}/redfish/v1/Managers" -i | head -1
    ```

    If a `200 OK` status code is returned, then the default user account is configured correctly.

    ```text
    HTTP/1.1 200 OK
    ```

    If a `401 Unauthorized` status code is returned, then the default user is not configured correctly. The BMC needs to be factory reset to restore the default user credentials.

    ```text
    HTTP/1.1 401 Unauthorized
    ```

1. (`ncn-mw#`) **Only if a `401 Unauthorized` was observed in the previous step**, then reset BMCs back to factory defaults.

    1. Follow [this HPE support article](https://techlibrary.hpe.com/docs/iss/proliant-gen10-uefi/s_reset_ilo_defaults.html) to boot the node into its BIOS and perform a factory reset on the BMC.

        > **NOTE**: If this is a Apollo 6500 XL 645D Gen10 Plus node, then the BMC will need to be reconfigured with the expected network settings.
        > See [Configure HPE Apollo 6500 XL645d Gen10 Plus Compute Nodes](../../install/prepare_compute_nodes.md#configure-hpe-apollo-6500-xl645d-gen10-plus-compute-nodes) for more information.

    1. Verify that the BMC can be accessed with the default credentials after the factory reset has been performed.

        ```bash
        curl -k -u "${DEFAULT_USERNAME}:${DEFAULT_PASSWORD}" "https://${BMC}/redfish/v1/Managers" -i  | head -1
        ```

        Expected output:

        ```text
        HTTP/1.1 200 OK
        ```

1. (`ncn-mw#`) Configure the root user account.

    1. Determine if the root user account already exists.

        ```bash
        for account in $(curl -s -u "${DEFAULT_USERNAME}:${DEFAULT_PASSWORD}" -k "https://${BMC}/redfish/v1/AccountService/Accounts" | jq '.Members[]."@odata.id"' -r); do 
            echo "Checking $account"
            curl -k -s -u "${DEFAULT_USERNAME}:${DEFAULT_PASSWORD}" -k "https://${BMC}${account}" | jq '. | {Id: .Id, UserName: .UserName, RoleId: .RoleId}' -c
        done
        ```

        Example output if the root user exists:

        ```text
        Checking /redfish/v1/AccountService/Accounts/1
        {"Id":"1","UserName":"Administrator","RoleId":"Administrator"}
        Checking /redfish/v1/AccountService/Accounts/2
        {"Id":"2","UserName":"root","RoleId":"Administrator"}
        ```

        Example output if the root user does not exist:

        ```text
        Checking /redfish/v1/AccountService/Accounts/1
        {"Id":"1","UserName":"Administrator","RoleId":"Administrator"}
        ```

    1. **If the user does not exist**, then create the root user account.

        ```bash
        curl -k -u "${DEFAULT_USERNAME}:${DEFAULT_PASSWORD}" -X POST \
                -H 'Content-Type: application/json' \
                -d $(jq --arg PASSWORD "${EXPECTED_ROOT_PASSWORD}" -nc '{RoleId: "Administrator", UserName: "root", Password: $PASSWORD}') \
                "https://${BMC}/redfish/v1/AccountService/Accounts" | jq
        ```

        Expected output:

        ```json
        {
          "@odata.context": "/redfish/v1/$metadata#ManagerAccount.ManagerAccount",
          "@odata.etag": "W/\"7511709F\"",
          "@odata.id": "/redfish/v1/AccountService/Accounts/3",
          "@odata.type": "#ManagerAccount.v1_3_0.ManagerAccount",
          "Id": "3",
          "Description": "iLO User Account",
          "Links": {
            "Role": {
              "@odata.id": "/redfish/v1/AccountService/Roles/Administrator"
            }
          },
          "Name": "User Account",
          "Oem": {
            "Hpe": {
              "@odata.context": "/redfish/v1/$metadata#HpeiLOAccount.HpeiLOAccount",
              "@odata.type": "#HpeiLOAccount.v2_2_0.HpeiLOAccount",
              "LoginName": "root",
              "Privileges": {
                "HostBIOSConfigPriv": true,
                "HostNICConfigPriv": true,
                "HostStorageConfigPriv": true,
                "LoginPriv": true,
                "RemoteConsolePriv": true,
                "SystemRecoveryConfigPriv": false,
                "UserConfigPriv": true,
                "VirtualMediaPriv": true,
                "VirtualPowerAndResetPriv": true,
                "iLOConfigPriv": true
              },
              "ServiceAccount": false
            }
          },
          "Password": null,
          "PasswordChangeRequired": false,
          "RoleId": "Administrator",
          "UserName": "root"
        }
        ```

    1. **If the user exists**, then change the root password.

        1. Determine the ID associated with the root account. In the example output above, the root user ID is `2`.

             ```bash
             ROOT_USER_ACCOUNT_ID=2
             ```

        1. Using the default administrator credentials, change the root account password.

            ```bash
            curl -k -u "${DEFAULT_USERNAME}:${DEFAULT_PASSWORD}" -X PATCH \
                -H 'Content-Type: application/json' \
                -d $(jq --arg PASSWORD "${EXPECTED_ROOT_PASSWORD}" -nc '{Password: $PASSWORD}') \
                "https://${BMC}/redfish/v1/AccountService/Accounts/${ROOT_USER_ACCOUNT_ID}" | jq
            ```

            Expected output:

            ```json
            {
              "error": {
                "code": "iLO.0.10.ExtendedInfo",
                "message": "See @Message.ExtendedInfo for more information.",
                "@Message.ExtendedInfo": [
                  {
                    "MessageId": "Base.1.4.AccountModified"
                  }
                ]
              }
            }
            ```

1. (`ncn-mw#`) Confirm that the new credentials can be used with Redfish.

    ```bash
    curl -k -u "root:${EXPECTED_ROOT_PASSWORD}" "https://${BMC}/redfish/v1/Managers" -i  | head -1
    ```

    Expected output:

    ```text
    HTTP/1.1 200 OK
    ```
