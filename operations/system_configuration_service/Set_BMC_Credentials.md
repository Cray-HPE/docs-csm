# Set BMC Credentials

Use the System Configuration Service \(SCSD\) to set the BMCs credentials to unique values, or set them all to the same value. Redfish BMCs get installed into the system with default credentials. Once the machine is shipped, the Redfish credentials must be changed on all BMCs. This is done using System Configuration Service \(SCSD\) through the Cray CLI.

**Important:** If the credentials for other devices need to be changed, refer to the following device-specific credential changing procedures:
- To change liquid-cooled BMC credentials, refer to [Change Cray EX Liquid-Cooled Cabinet Global Default Password](../security_and_authentication/Change_EX_Liquid-Cooled_Cabinet_Global_Default_Password.md).
- To change air-cooled Node BMC credentials, refer to [Change Air-Cooled Node BMC Credentials](../security_and_authentication/Change_Air-Cooled_Node_BMC_Credentials.md).
- To change ServerTech PDU credentials, refer to [Change Credentials on ServerTech PDUs](../security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).
- To change Slingshot switch BMC credentials, refer to "Change Rosetta Login and Redfish API Credentials" in the *Slingshot Operations Guide (> 1.6.0)*.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  Determine the live BMCs in the system.

    The list of BMCs must include air-cooled compute BMCs, air-cooled High Speed Network \(HSN\) switch BMCs, liquid-cooled compute BMCs, liquid-cooled switch BMCs, and liquid-cooled chassis BMCs.

    ```bash
    ncn-m001# for fff in `cray hsm inventory redfishEndpoints list --format json \
    | jq '.RedfishEndpoints[] | select(.FQDN | contains("-rts") | not) | \
    select(.DiscoveryInfo.LastDiscoveryStatus == "DiscoverOK") | select(.Enabled==true) \
    | .ID' | sed 's/"//g'`; do
        echo "Pinging ${fff}..." ;
        xxx=`curl -k https://${fff}/redfish/v1/`
        if [[ "${xxx}" != "" ]]; then
            echo "PRESENT"
        else
            echo "NOT PRESENT"
        fi
    done
    ```

2.  Create a new JSON file containing the BMC credentials for all BMCs returned in the previous step.

    Select one of the options below to set the credentials for the BMCs:

    -   Set all BMCs with the same credentials.

        ```bash
        ncn-m001# vi bmc_creds_glb.json
        {
          "Force": false,
          "Username": "root",
          "Password": "new.root.password"
          "Targets": [
            "x0c0s0b0",
            "x0c0s1b0"
          ]
        }
        ```

    -   Set all BMCs with different credentials.

        ```bash
        ncn-m001# vi bmc_creds_dsc.json
        {
          "Force": true,
          "Targets": [
            {
              "Xname": "x0c0s0b0",
              "Creds": {
                "Username": "root",
                "Password": "pw-x0c0s0b0"
              }
            },
            {
              "Xname": "x0c0s0b1",
              "Creds": {
                "Username": "root",
                "Password": "pw-x0c0s0b1"
              }
            }
          ]
        }
        ```

3.  Apply the new BMC credentials.

    Use only one of the following options depending on how the credentials are being set:

    -   Apply global credentials to BMCs with the same credentials.

        1.  Apply the new BMC credentials:
            ```bash
            ncn-m001# cray scsd bmc globalcreds create ./bmc_creds_glb.json
            ```

        1.  Perform a rediscovery on the BMCs that had their credentials changed:
            ```bash
            ncn-m001# cray hsm inventory discover create --xnames $(cat bmc_creds_glb.json | jq '.Targets | join(",")' -r)
            ```

        2.  Wait for DiscoverOK for all of the BMCs that had their credentials changed. You may need to re-run the command below until all BMCs are DiscoverOK:
            ```bash
            ncn-m001# for bmc in $(cat bmc_creds_glb.json | jq '.Targets[]' -r); do
                echo "Checking Discovery Status for $bmc"
                cray hsm inventory redfishEndpoints describe $bmc --format json | 
                    jq .DiscoveryInfo.LastDiscoveryStatus -r
            done
            ```

            Example output:
            ```
            Checking Discovery Status for x0c0s0b0
            DiscoverOK
            Checking Discovery Status for x0c0s1b0
            DiscoverOK
            ```

    -   Apply discrete credentials to BMCs with different credentials.

        1.  Apply the new BMC credentials:
            ```bash
            ncn-m001# cray scsd bmc discreetcreds create ./bmc_creds_dsc.json
            ```

        2.  Perform a rediscovery on the BMCs that had their credentials changed:
            ```bash
            ncn-m001# cray hsm inventory discover create --xnames $(cat bmc_creds_glb.json | jq '[.Targets[].Xname] | join(",")' -r)
            ```

        3.  Wait for DiscoverOK for all of the BMCs that had their credentials changed. You may need to re-run the command below until all BMCs are DiscoverOK:
            ```bash
            ncn-m001# for bmc in $(cat bmc_creds_glb.json | jq '[.Targets[].Xname] | join(",")' -r); do
                echo "Checking Discovery Status for $bmc"
                cray hsm inventory redfishEndpoints describe $bmc --format json | 
                    jq .DiscoveryInfo.LastDiscoveryStatus -r
            done
            ```

            Example output:
            ```
            Checking Discovery Status for x0c0s0b0
            DiscoverOK
            Checking Discovery Status for x0c0s0b1
            DiscoverOK
            ```

    **Troubleshooting:** If either command has any components that do not have the status of OK, they must be retried until they work, or the retries are exhausted and noted as failures. Failed modules need to be taken out of the system until they are fixed.

