# Change Air-Cooled Node BMC Credentials

This procedure will use the System Configuration Service (SCSD) to change all air-cooled Node BMCs in the system to the same global credential.

## Limitations

All air-cooled and liquid-cooled BMCs share the same global credentials. The air-cooled Slingshot switch controllers (Router BMCs) must have the same credentials as the liquid-cooled Slingshot switch controllers.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See
  [Configure the Cray CLI](../configure_cray_cli.md).
- Review procedures for SCSD in the [Cray System Management (CSM) Administration Guide](../index.md#system-configuration-service).

## Procedure

1. Set the `NEW_BMC_CREDENTIAL` to specify the new `root` user password for air-cooled node BMCs.

    ```bash
    ncn-m001# read -s NEW_BMC_CREDENTIAL
    ncn-m001# echo $NEW_BMC_CREDENTIAL
    ```

    Expected output:

    ```text
    new.root.password
    ```

1. Create an SCSD payload file to change all air-cooled node BMCs to the same global credential.

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

1. Inspect the generated SCSD payload file.

    ```bash
    ncn-m001# cat bmc_creds_glb.json | jq
    ```

1. Apply the new BMC credentials.

    ```bash
    ncn-m001# cray scsd bmc globalcreds create ./bmc_creds_glb.json
    ```

    **Troubleshooting:** If the above command has any components that do not have the status of OK, they must be retried until
    they work, or the retries are exhausted and noted as failures. Failed modules need to be taken out of the system until they
    are fixed.

1. Perform a rediscovery on the BMCs that had their credentials changed.

    ```bash
    ncn-m001# cray hsm inventory discover create --xnames $(cat bmc_creds_glb.json | jq '.Targets | join(",")' -r)
    ```

1. Wait for `DiscoverOK` for all of the BMCs that had their credentials changed.

    The following command may need to be re-run multiple times until all BMCs are `DiscoverOK`.

    ```bash
    ncn-m001# for bmc in $(cat bmc_creds_glb.json | jq '.Targets[]' -r); do
                echo "Checking Discovery Status for $bmc"
                cray hsm inventory redfishEndpoints describe $bmc --format json | jq .DiscoveryInfo.LastDiscoveryStatus -r
              done
    ```

    Example output:

    ```text
    Checking Discovery Status for x3000c0s20b0
    DiscoverOK
    Checking Discovery Status for x3000c0s3b0
    DiscoverOK
    ```
