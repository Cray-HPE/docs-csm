# Change Air-Cooled Node BMC Credentials

This procedure will use the System Configuration Service (SCSD) to change all air-cooled Node BMCs in the system to the same global credential. 

**Limitation:** All air-cooled and liquid cooled BMCs should share the same global credentials. The air-cooled Slingshot Switch Controllers (Router BMCs) must have the same credentials as the liquid-cooled Slingshot switch controllers.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   Review procedures for SCSD in the [Cray System Management (CSM) Administration Guide](../index.md#system-configuration-service)

### Procedure

1.  Create a SCSD payload file to change all Air-Cooled Node BMCs to the same global credential:
    ```bash
    ncn-m001# export NEW_BMC_CREDENTIAL=new.root.password
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

2.  Apply the new BMC credentials:
    ```bash
    ncn-m001# cray scsd bmc globalcreds create ./bmc_creds_glb.json
    ```

    **Troubleshooting:** If the above command has any components that do not have the status of OK, they must be retried until they work, or the retries are exhausted and noted as failures. Failed modules need to be taken out of the system until they are fixed.
