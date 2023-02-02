# Add additional Air-Cooled Cabinets to a System

This procedure adds one or more air-cooled cabinets and all associated hardware within the cabinet except for management NCNs.

## Prerequisites

- The system's SHCD file has been updated with the new cabinets and cabling changes.
- The new cabinets have been cabled to the system, and the system's cabling has been validated to be correct.
- The following procedure has been completed: [Create a Backup of the SLS Postgres Database](../system_layout_service/Create_a_Backup_of_the_SLS_Postgres_Database.md).
- The following procedure has been completed: [Create a Backup of the HSM Postgres Database](../hardware_state_manager/Create_a_Backup_of_the_HSM_Postgres_Database.md).
- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).
- The latest CSM documentation is installed on the system. See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).

## Procedure

1. (`ncn-mw`) Extract the tarball containing artifacts and scripts to help facilitate adding air-cooled cabinets. **Note** the rest of the procedure assumes current working directory is in the extracted `add_river_cabinet_artifacts` folder.

    ```bash
    tar -xvf add_river_cabinet_artifacts.tar.gz
    cd add_river_cabinet_artifacts
    ```

1. Load the `hardware-topology-assistant` container image into the systems Nexus container registry. 

    ```bash
    TAR=hardware-topology-assistant-0.2.0-20230202201610.7307a41.tar
    IMAGE=artifactory.algol60.net/csm-docker/unstable/hardware-topology-assistant:0.2.0-20230202201610.7307a41 

    NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.username}} | base64 -d)"
    NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.password}} | base64 -d)"

    podman run --rm --network host \
        --volume $PWD:/mnt/images \
        quay.io/skopeo/stable copy \
        --src-tls-verify=false \
        --dest-tls-verify=false \
        --dest-username $NEXUS_USERNAME \
        --dest-password $NEXUS_PASSWORD \
        docker-archive:/mnt/images/$TAR \
        docker://registry.local/$IMAGE
    ```

1. (`ncn-mw`) [Validate the systems SHCD](../../operations/network/management_network/validate_shcd.md) using CANU to generate an updated CCJ file. **This step can be skipped if you already have an updated CCJ file**.

   **Note do not** perform the step `Proceed to generate topology files` because it is not required.

1. (`ncn-mw`) Once the validation is completed, ensure that the systems CCJ file is present in the current directory, and set the `CCJ_FILE` environment variable to the name of the file.

    Or if you have an existing file set it with:
    ```
    CCJ_FILE=paddle.json
    ```

1. (`ncn-mw`) Retrieve an API token:

    ```bash
    export TOKEN=$(curl -k -s -S -d grant_type=client_credentials \
                  -d client_id=admin-client \
                  -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
                  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

    ```

1. Perform a dry run of the hardware-topology-assistant. This will capture the changes needed to be made to the system.

    Each invocation of the hardware-topology-assistant creates a new folder in the current directory named similarly to `hardware-topology-assistant_TIMESTAMP`. This directory contains files with the following data:
    - Log output from the hardware-topology-assistant run.
       - `topology_changes.json` which enumerates the changes made to SLS.
         - Added River hardware, except for management NCNs
         - Modified networks.
           - Added IP address reservations.
           - Cabinet VLAN assignment.
       -  Modified version of the SLS state dataa. 
    - Backups of the following before any changes are applied
       - BSS boot parameters for each existing management NCN.
       - Management NCN global BSS boot parameters.
       - Dump state of SLS before any changes are applied.

    > **Reminder:** New management NCNs are not handled by this tool. They will be handled by a different procedure referenced in the last step of this procedure.

    ```bash
    podman run --rm -it --name hardware-topology-assistant -v "$(realpath .)":/work -e TOKEN \
        registry.local/artifactory.algol60.net/csm-docker/unstable/hardware-topology-assistant:0.2.0-20230202201610.7307a41 \
        update $CCJ_FILE --ignore-removed-hardware --application-node-metadata=application_node_metadata.yaml --dry-run
    ```

    If prompted to fill in the generated application node metadata nodes having `~~FIXME~~` values, then follow the directions in the command output to update the application node metadata file. This is an optional file that is only required if
    application nodes are being added to the system. If no new application nodes are being added to the system, then this is not required.

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

    The following is an example entry in the `application_node_metadata.yaml` file that requires additional information to be filled in. **Do not** change any of the SubRole or aliases values for other application nodes. The `canu_common_name` field contains the common name of the application node represented in the CANU CCJ/Paddle file. 

    ```yaml
    x3001c0s16b0n0:
      canu_common_name: login010
      subrole: ~~FIXME~~
      aliases:
      - ~~FIXME~~
    ```

    The following is the above example entry with its `~~FIXME~~` values filled with values to designate the node `x3001c0s16b0n0` as an `UAN` with the alias `uan10`.

    ```yaml
    x3001c0s16b0n0:
      canu_common_name: login010
      subrole: UAN
      aliases:
      - uan10
    ```

    > Valid HSM SubRoles can be viewed with the following command. To add additional sub roles to HSM refer to [Add Custom Roles and Subroles](../hardware_state_manager/HSM_Roles_and_Subroles.md#add-custom-roles-and-subroles).
    >
    > ```bash
    > cray hsm service values subrole list --format toml
    > ```
    >
    > Example output:
    >
    > ```toml
    > SubRole = [ "Visualization", "UserDefined", "Master", "Worker", "Storage", "UAN", "Gateway", "LNETRouter",]
    > ```

    Add the `--application-node-metadata=application_node_metadata.yaml` to the list of CLI arguments, and attempt the dry run again.

1. Find the directory that was generated by the `hardware-topology-assistant` from the last run.

    ```bash
    HARDWARE_TOPOLOGY_ASSISTANT_FILES="$(find . -name 'hardware-topology-assistant_*' | sort -V | tail -n 1)"
    echo ${HARDWARE_TOPOLOGY_ASSISTANT_FILES}
    ```

1. **Optional**: If desired inspect the changes to SLS. Verify changes look reasonable for the hardware being added. For example, the only hardware from the new cabinets are added, and networking changes for any new UAN or management switches are present.

    ```bash
    vimdiff <(jq -S . "${HARDWARE_TOPOLOGY_ASSISTANT_FILES}/existing_sls_state.json") <(jq -S . "${HARDWARE_TOPOLOGY_ASSISTANT_FILES}/modified_sls_state.json")
    ```

    > The `jq -S . FILE_NAME` ensures the keys in the json files are in the same order. 

1. Perform an SLS load state operation to replace the contents of SLS with the updated SLS state from the `hardware-topology-assistant`:

    ```bash
    SLS_FILE="${HARDWARE_TOPOLOGY_ASSISTANT_FILES}/modified_sls_state.json"
    curl -X POST \
        https://api-gw-service-nmn.local/apis/sls/v1/loadstate \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "sls_dump=@${SLS_FILE}" -i
    ```

    Expected output:

    ```text
    HTTP/2 204
    date: Thu, 02 Feb 2023 20:29:28 GMT
    x-envoy-upstream-service-time: 197
    server: istio-envoy
    ```

1. Update BSS boot parameters. This will update two places in BSS to allow management NCNs to have the correct information when they are rebuilt.
    * Update the cabinet routes on a per management NCN basis.
    * Update the host records in the Global boot parameters which are used to generate `/etc/hosts` on management nodes. 


    ```bash
    for MODIFIED_BSS_BOOTPARAMETERS in $HARDWARE_TOPOLOGY_ASSISTANT_FILES/modified_bss*.json; do 
        echo "Updating BSS boot parameters with $MODIFIED_BSS_BOOTPARAMETERS"
        curl -i -H "Content-Type: application/json" -H "Authorization: Bearer ${TOKEN}" \
           "https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters" -X PUT -d "@${MODIFIED_BSS_BOOTPARAMETERS}"
    done
    ```

1. (`ncn-mw`) Locate the `topology_changes.json` file that was generated by the `hardware-topology-assistant` from the last run.

    ```bash
    TOPOLOGY_CHANGES_JSON="${HARDWARE_TOPOLOGY_ASSISTANT_FILES}/topology_changes.json"
    echo ${TOPOLOGY_CHANGES_JSON}
    ```

    Example output:

    ```text
    ./hardware-topology-assistant_2022-08-19T19-09-27Z/topology_changes.json
    ```

1. (`ncn-mw`) Update `/etc/hosts` on the management NCNs with any newly added management switches.

    ```bash
    ./scripts/operations/node_management/Add_River_Cabinets/update_ncn_etc_hosts.py "${TOPOLOGY_CHANGES_JSON}" --perform-changes
    ```

1. (`ncn-mw`) Update current cabinet routes on management NCNs.

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

    To help troubleshoot why new hardware may be in `HTTPsGetFailed`, the following script can check for some common problems against all of the Redfish Endpoints that are currently in `HTTPsGetFailed`. These common problems include:
       - The hostname of the BMC does not resolve in DNS.
       - The BMC is not configured with the expected root user credentials. Here are some common causes of this issue:
         - Root user is not configured on the BMC.
         - Root user exists on the BMC, but with an unexpected password.

    ```bash
    ./scripts/operations/node_management/Add_River_Cabinets/verify_bmc_credentials.sh 
    ```

    Potential scenarios:

    1. The BMC has no connection to the HMN network. This is typically seen with the BMC of `ncn-m001`, because its BMC is connected to the site network.

          ```text
          ------------------------------------------------------------
          Redfish Endpoint x3000c0s1b0 has discovery state HTTPsGetFailed
          Has no connection to HMN, ignoring
          ```

    1. The BMC credentials present in Vault do not match the root user credentials on the BMC.

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

        - For HPE iLO BMCs, follow [Configure root user on HPE iLO BMCs](../security_and_authentication/Configure_root_user_on_HPE_iLO_BMCs.md).
        - For Gigabit BMCs and CMCs, follow [Add Root Service Account for Gigabyte Controllers](../security_and_authentication/Add_Root_Service_Account_for_Gigabyte_Controllers.md).
        - For HPE PDUs, follow [HPE PDU Admin procedures](../hpe_pdu/hpe_pdu_admin_procedures.md).
        - For ServerTech PDUs, follow [Change Credentials on ServerTech PDUs](../security_and_authentication/Change_Credentials_on_ServerTech_PDUs.md).

1. Validate BIOS and BMC firmware levels in the new nodes.

    Perform the procedures in [Update Firmware with FAS](../firmware/Update_Firmware_with_FAS.md). Perform updates as needed with FAS.

    > Slingshot switches are updated with procedures from the *HPE Slingshot Operations Guide*.

1. Continue on to the *HPE Slingshot Operations Guide* to bring up the additional cabinets in the fabric.

1. Update workload manager configuration to include any newly added compute nodes to the system.

   - **If Slurm is the installed workload manager**, then see section *10.3.1 Add a New or Configure an Existing Slurm Template* in the *`HPE Cray Programming Environment Installation Guide: CSM on HPE Cray EX Systems (S-8003)`* to regenerate the Slurm
      configuration to include any new compute nodes added to the system.
   - **If PBS Pro is the installed workload manager**: *Coming soon*
