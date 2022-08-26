# Add Root Service Account for Gigabyte Controllers

By default, Gigabyte BMC and CMC controllers have the `admin` service
account configured. In order to discover this type of hardware, the
`root` service account needs to be configured.

## Prerequisites

The `root` service account is not already configured for the controller.

1. (`ncn#`) Set an environment variable containing the hostname or current IP Address of the BMC. If coming from the [Add Worker, Storage or Master NCNs](../node_management/Add_Remove_Replace_NCNs.md#add-worker-storage-master)
    procedure, then the IP address of should stored in the `BMC_IP` environment variable.

    Via hostname:

    ```bash
    export BMC=x3000c0s3b0
    ```

    Via IP address:

    ```bash
    export BMC=10.254.1.9
    ```

1. (`ncn#`) Set and export the `admin` password of the BMC. Contact HPE Cray service in order to obtain the default password.

     > NOTE: `read -s` is used to prevent the password from echoing to the screen or
     > being saved in the shell history.

     ```bash
     read -r -s -p "${BMC} admin password: " IPMI_PASSWORD
     export IPMI_PASSWORD
     ```

1. (`ncn#`) Check which service accounts are currently configured.

    ```bash
    curl -s -k -u admin:"$IPMI_PASSWORD" https://<xname>/redfish/v1/AccountService/Accounts | jq ".Members"
    ```

    ```json
    [
      {
        "@odata.id": "/redfish/v1/AccountService/Accounts/1"
      }
    ]
    ```

1. (`ncn#`) Verify that none of the accounts listed are for `root`.

    ```bash
    curl -s -k -u admin:"$IPMI_PASSWORD" https://<xname>/redfish/v1/AccountService/Accounts/1 | jq '. | { Name: .Name, UserName: .UserName, RoleId: .RoleId }'
    ```

    ```json
    {
      "Name": "admin",
      "UserName": "admin",
      "RoleId": "Administrator"
    }
    ```

The `root` account is not configured in the example shown above. If `root` is already configured, do not proceed with the following steps.

### Procedure

1. (`ncn#`) Retrieve the root user password for this BMC.

    1. **If configuring a BMC already present in the system**, retrieve the the device specific root user password from Vault:

        ```bash
        BMC=x3000c0s3b0
        EXPECTED_ROOT_PASSWORD=$(cray scsd bmc creds list --targets $BMC --format json | jq .Targets[].Password -r)
        ```

        If the following output indicates that Vault does not contain a device specific root user password for the specified BMC. Please use the system default air-cooled BMC root password described in the step below.

        ```text
        jq: error (at <stdin>:3): Cannot iterate over null (null)
        ```

    1. **If configuring a new BMC being added to the system**, retrieve the system's default air-cooled BMC root user password from Vault:

        ```bash
        VAULT_PASSWD=$(kubectl -n vault get secrets cray-vault-unseal-keys -o json |
                            jq -r '.data["vault-root"]' |  base64 -d)
        EXPECTED_ROOT_PASSWORD=$(kubectl -n vault exec -it cray-vault-0 -c vault -- env \
            VAULT_TOKEN=$VAULT_PASSWD VAULT_ADDR=http://127.0.0.1:8200 VAULT_FORMAT=json \
            vault kv get secret/reds-creds/defaults | jq .data.Cray.password -r)
        ```

1. (`ncn#`) Verify the contents of `EXPECTED_ROOT_PASSWORD`:

    ```bash
    echo $EXPECTED_ROOT_PASSWORD
    ```

1. (`ncn#`) Run the following commands to configure the `root` service account for the controller:

    ```bash
    ipmitool -U admin -E -I lanplus -H $BMC user set name 4 root
    ipmitool -U admin -E -I lanplus -H $BMC user set password 4 "$EXPECTED_ROOT_PASSWORD"
    ipmitool -U admin -E -I lanplus -H $BMC user priv 4 4 1
    ipmitool -U admin -E -I lanplus -H $BMC user enable 4
    ipmitool -U admin -E -I lanplus -H $BMC channel setaccess 1 4 callin=on ipmi=on link=on
    ```

    Example output:

    ```text
    Set User Password command successful (user 4)
    Set Privilege Level command successful (user 4)
    Set User Access (channel 1 id 4) successful.
    ```

1. (`ncn#`) Additionally, if the target controller is a BMC and not a CMC, run the following command:

    ```bash
    ipmitool -U admin -E -I lanplus -H $BMC sol payload enable 1 4
    ```

1. (`ncn#`) Verify that the `root` service account is now configured.

    1. List the current accounts on the BMC:

        ```bash
        curl -s -k -u admin:"$IPMI_PASSWORD" https://$BMC/redfish/v1/AccountService/Accounts | jq ".Members"
        ```

        Expected output:

        ```json
        [
          {
            "@odata.id": "/redfish/v1/AccountService/Accounts/4"
          },
          {
            "@odata.id": "/redfish/v1/AccountService/Accounts/1"
          }
        ]
        ```

    1. View the `root` user account account on the BMC:

        ```bash
        curl -s -k -u admin:"$IPMI_PASSWORD" https://$BMC/redfish/v1/AccountService/Accounts/4 | jq '. | { Name: .Name, UserName: .UserName, RoleId: .RoleId }'
        ```

        Expected output:

        ```json
        {
          "Name": "root",
          "UserName": "root",
          "RoleId": "Administrator"
        }
        ```

1. (`ncn#`) Confirm the new credentials can be used with Redfish:

    ```bash
    curl -k -u "root:$EXPECTED_ROOT_PASSWORD" https://$BMC/redfish/v1/Managers -i  | head -1
    ```

    Expected output:

    ```text
    HTTP/1.1 200 OK
    ```

Now the `root` service account is configured.
