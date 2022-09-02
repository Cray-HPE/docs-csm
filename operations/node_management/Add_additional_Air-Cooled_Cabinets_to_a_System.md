# Add additional Air-Cooled Cabinets to a System

This procedure adds one or more air-cooled cabinets and all associated hardware within the cabinet except for management NCNs.

**`NOTES`**

- This procedure is intended to be used in conjunction with the top level [Add additional Air-Cooled Cabinets to a System](../node_management/Add_additional_Air-Cooled_Cabinets_to_a_System.md) procedure.

## Prerequisites

- The system's SHCD file has been updated with the new cabinets and cabling changes.
- The new cabinets have been cabled to the system, and the system's cabling has been validated to be correct.
- Follow the procedure [Create a Backup of the SLS Postgres Database](../system_layout_service/Create_a_Backup_of_the_SLS_Postgres_Database.md).
- Follow the procedure [Create a Backup of the HSM Postgres Database](../hardware_state_manager/Create_a_Backup_of_the_HSM_Postgres_Database.md).
- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation is installed on the system. See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

1. (`ncn-mw`) Set the systems name:

    ```bash
    SYSTEM_NAME=eniac
    ```

1. (`ncn-mw`) [Validate the systems SHCD](../../operations/network/management_network/validate_shcd.md) using CANU to generate an updated CCJ file.

   **Note do not** perform the step `Proceed to generate topology files` as it is not required.

1. (`ncn-mw`) Once the validation is completed ensure the systems CCJ file is present in the current directory, and set the `CCJ_FILE` environment variable to the name of the file:

    ```bash
    CCJ_FILE=${SYSTEM_NAME}-full-paddle.json
    ```

1. (`ncn-mw`) Retrieve an API token:

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                  -d client_id=admin-client \
                  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

    ```

1. Determine the version of the latest hardware-topology-assistant:

    ```bash
    HTA_VERSION=$(curl https://registry.local/v2/artifactory.algol60.net/csm-docker/stable/hardware-topology-assistant/tags/list | jq -r .tags[] | sort -V | tail -n 1)
    echo $HTA_VERSION
    ```

    Example output:

    ```bash
    0.1.0
    ```

1. Perform a dry run of the hardware-topology-assistant.

    Each invocation of the hardware-topology-assistant creates a new folder in the current directory  named similarly to `hardware-topology-assistant_TIMESTAMP` containing files with the following data:
    - Log output from the hardware-topology-assistant run.
       - `topology_changes.json` which enumerates the changes made to SLS:
    - Added river hardware, except for management NCNs
       - Modified networks.
       - Added IP address reservations.
    - Backups of the following before any changes are applied
       - BSS boot parameters for each existing management NCN.
       - Management NCN Global BSS boot parameters.
       - Dumpstate of SLS before any changes were applied.

    > **Reminder** new management NCNs are not handled by this tool. They will be handled by a different procedure referenced in the last step of this procedure.

    ```bash
    podman run --rm -it --name hardware-topology-assistant -v "$(realpath .)":/work -e TOKEN \
        registry.local/artifactory.algol60.net/csm-docker/stable/hardware-topology-assistant:$HTA_VERSION \
        update $CCJ_FILE --dry-run
    ```

    If prompted to fill in the generated application node metadata nodes having `~~FIXME~~` values, then follow the directions in the command output to update the application node metadata file. This is an optional file that is only required if
    application nodes are being added to the system. If no new application nodes are being added to the system, then this fill is not required

    ```console
    2022/08/11 12:33:54 Application node x3001c0s16b0n0 has SubRole of ~~FIXME~~
    2022/08/11 12:33:54 Application node x3001c0s16b0n0 has Alias of ~~FIXME~~
    2022/08/11 12:33:54 
    2022/08/11 12:33:54 New Application nodes are being added to the system which requires additional metadata to be provided.
    2022/08/11 12:33:54 Please fill in all of the ~~FIXME~~ values in the application node metadata file.
    2022/08/11 12:33:54 
    2022/08/11 12:33:54 Application node metadata file is now available at: application_node_metadata.yaml
    2022/08/11 12:33:54 Add --application-node-metadata=application_node_metadata.yaml to the command line arguments and try again.
    ```

    The following is an example entry in the `application_node_metadata.yaml` file that requires additional information to be filled in. **Do not** change any of the SubRole or aliases values for other application nodes.

    ```yaml
    x3001c0s16b0n0:
      subrole: ~~FIXME~~
      aliases:
      - ~~FIXME~~
    ```

    The following is the above example entry with its `~~FIXME~~` values filled with values to designate the node `x3001c0s16b0n0` as an `UAN` with the alias `uan10`.

    ```yaml
    x3001c0s16b0n0:
      subrole: UAN
      aliases:
      - uan10
    ```

    > Valid HSM SubRoles can be viewed with the following command. To add additional sub roles to HSM refer to [Add Custom Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md#add-custom-roles-and-subroles).
    >
    > ```bash
    > cray hsm service values subrole list
    > ```
    >
    > Example output:
    >
    > ```toml
    > SubRole = [ "Visualization", "UserDefined", "Master", "Worker", "Storage", "UAN", "Gateway", "LNETRouter",]
    > ```

    Add the `--application-node-metadata=application_node_metadata.yaml` to the list of CLI arguments, and attempt the dry run again.

1. (`ncn-mw`) Perform changes on the system, by removing the `--dry-run` flag:

    ```bash
    podman run --rm -it --name hardware-topology-assistant -v "$(realpath .)":/work -e TOKEN \
        registry.local/artifactory.algol60.net/csm-docker/stable/hardware-topology-assistant:$HTA_VERSION \
        update $CCJ_FILE
    ```

1. (`ncn-mw`) Locate the `toplogy_changes.json` file that was generated by the `hardware-topology-assistant` from the last run.

    ```bash
    TOPOLOGY_CHANGES_JSON="$(find . -name 'hardware-topology-assistant_*' | sort -V | tail -n 1)/topology_changes.json"
    echo $TOPOLOGY_CHANGES_JSON
    ```

    Example output:

    ```text
    ./hardware-topology-assistant_2022-08-19T19-09-27Z/topology_changes.json
    ```

1. (`ncn-mw`) Update `/etc/hosts` on the management NCNs for any newly added management switches:

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/Add_River_Cabinets/update_ncn_etc_hosts.py $TOPOLOGY_CHANGES_JSON
    ```

1. (`ncn-mw`) Update cabinet routes on management NCNs:

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/update-ncn-cabinet-routes.sh
    ```

1. Reconfigure management network by following the [CANU Added Hardware](../network/management_network/added_hardware.md) procedure.

    **DISCLAIMER:** This procedure is for standard River cabinet network configurations and does not account for any site customizations that have been made to the management network.
    Site administrators and support teams are responsible for knowing the customizations in effect in Shasta/CSM and configuring CANU to respect them when generating new network configurations.

    See examples of using CANU custom switch configurations and examples of other CSM features that require custom configurations in the following documentation:

    - [Manual Switch Configuration Example](../network/management_network/manual_switch_config.md)
    - [Custom Switch Configuration Example](https://github.com/Cray-HPE/canu#generate-switch-configs-including-custom-configurations)

1. Verify that new hardware has been discovered.

    Perform the [Hardware State Manager Discovery Validation](../validate_csm_health.md#22-hardware-state-manager-discovery-validation) procedure.

    After the management network has been reconfigured, it may take up to 10 minutes for the hardware in the new cabinets to become discovered.

    To help troubleshoot why new hardware may be in `HTTPsGetFailed` the following script can check for some common problems against all of the RedfishEndpoints that are currently in `HTTPsGetFailed`. These common problems include:
       - The hostname of the BMC resolves in DNS.
       - The BMC is configured with the expected root user credentials. Here are some common causes of this issue:
       - Root user is not configured on the BMC.
       - Root user is exists on the BMC, but with an unexpected password.

    ```bash
    /usr/share/doc/csm/scripts/operations/node_management/Add_River_Cabinets/verify_bmc_credentials.sh 
    ```

    Potential scenarios:
     1. The BMC has no connection to the HMN network. This is typically expected seen with the BMC of `ncn-m001`, as its BMC is connected to the customers site network.

          ```text
          ------------------------------------------------------------
          Redfish Endpoint x3000c0s1b0 has discovery state HTTPsGetFailed
          Has no connection to HMN, ignoring
          ```

     1. The BMC credentials present in Vault do not match the `root` user credentials on the BMC.

        ```text
        ------------------------------------------------------------
        Redfish Endpoint x3000c0s3b0 has discovery state HTTPsGetFailed
        Checking to see if $endpoint resolves in DNS
            Hostname resolves
        Retrieving BMC credentials for $endpoint from SCSD/Vault
        Testing stored BMC credentials against the BMC
            ERROR Received 401 Unauthorized. BMC credentials in Vault do not match current BMC credentials.
        ```

        If the root user credentials do not work then following procedures:
         1. For HPE iLO BMCs follow [Configure root user on HPE iLO BMCs](../security_and_authentication/Configure_root_user_on_HPE_iLO_BMCs.md)
         1. For Gigabit BMCs and CMCs follow [Add Root Service Account for Gigabyte Controllers](../security_and_authentication/Add_Root_Service_Account_for_Gigabyte_Controllers.md)
         1. For HPE PDUs follow [HPE PDU Admin procedures](../hpe_pdu/hpe_pdu_admin_procedures.md).
         1. For ServerTech PDUs follow [Change Credentials on ServerTech PDUs](../security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).

1. Validate BIOS and BMC firmware levels in the new nodes.

    Perform the procedures in [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md). Perform updates as needed with FAS.

    > Slingshot switches are updated with procedures from the *HPE Slingshot Operations Guide*.

1. Continue on to the *HPE Slingshot Operations Guide* to bring up the additional cabinets in the fabric.

1. Update workload manager configuration to include any new added compute nodes to the system.

   1. **If Slurm is the installed workload manager**, then see section *10.3.1 Add a New or Configure an Existing Slurm Template* in the *HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX Systems (S-8003)* to regenerate the Slurm
      configuration to include any new compute nodes added to the system.
   1. **If PBS Pro is the installed workload manager**: *Coming soon*

1. **For each** management NCN being added to the system please follow [Add Remove Replace NCNs](../node_management/Add_Remove_Replace_NCNs.md) to add these additional management NCNs one at a time.
