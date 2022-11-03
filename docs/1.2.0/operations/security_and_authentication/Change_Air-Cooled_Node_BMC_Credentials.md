# Change Air-Cooled Node BMC Credentials

This procedure will use the System Configuration Service (SCSD) to change all air-cooled Node BMCs in the system to the same global credential.

### Limitations

All air-cooled and liquid-cooled BMCs share the same global credentials. The air-cooled Slingshot switch controllers (Router BMCs) must have the same credentials as the liquid-cooled Slingshot switch controllers.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   Review procedures for SCSD in the [Cray System Management (CSM) Administration Guide](../index.md#system-configuration-service)

### Procedure

1.  Set the `NEW_BMC_CREDENTIAL` to specify the new root user password for air-cooled node BMCs:
    ```bash
    ncn-m001# read -s NEW_BMC_CREDENTIAL
    ncn-m001# echo $NEW_BMC_CREDENTIAL
    ```

    Expected output:
    ```
    new.root.password
    ```

2.  Create an SCSD payload file to change all air-cooled node BMCs to the same global credential:
    ```bash
    ncn-m001# cat > bmc_creds_glb.json <<DATA
    {
        "Force":false,
        "Username": "root",
        "Password": "$NEW_BMC_CREDENTIAL",
        "Targets":
        $(cray hsm state components list --class River --type NodeBMC --format json | jq -r '[.Components[] | .ID]')
    }
    DATA
    ```

    Inspect the generated SCSD payload file:
    ```bash
    ncn-m001# cat bmc_creds_glb.json | jq
    ```

3.  Apply the new BMC credentials:
    ```bash
    ncn-m001# cray scsd bmc globalcreds create ./bmc_creds_glb.json
    ```

    **Troubleshooting:** If the above command has any components that do not have the status of OK, they must be retried until they work, or the retries are exhausted and noted as failures. Failed modules need to be taken out of the system until they are fixed.
