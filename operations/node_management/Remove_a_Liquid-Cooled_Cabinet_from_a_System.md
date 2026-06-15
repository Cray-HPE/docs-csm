# Remove a Liquid-Cooled Cabinet from a System

This procedure will remove an entire liquid-cooled cabinet from an HPE Cray EX system by iteratively removing each blade in the cabinet, then cleaning up the Chassis BMCs, HMS hardware inventory, and SLS data.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray CLI](../configure_cray_cli.md).

- The System Admin Toolkit \(SAT\) is installed and configured on the system.

- Knowledge of whether the Scalable Boot Projection Service (SBPS) is operating over the Node Management Network (NMN) or the High Speed Network (HSN).

- The Slingshot fabric must be configured with the desired topology for the desired state of the blades in the system.

- The System Layout Service (SLS) must have the desired HSN configuration.

- Check the status of the HSN and record link status before the procedure.

## Procedure

### 1. Identify all blades in the cabinet

1. (`ncn-mw#`) Set the cabinet xname.

    ```bash
    CABINET="x9000"
    ```

1. (`ncn-mw#`) Identify all populated slots in the cabinet.

    ```bash
    SLOTS=$(cray hsm state components list --type ComputeModule --format json | \
        jq -r --arg CABINET "${CABINET}" \
        '.Components[] | select(.ID | startswith($CABINET)) | .ID')
    echo "$SLOTS"
    ```

### 2. Suspend the `hms-discovery` cron job

1. (`ncn-mw#`) Suspend the `hms-discovery` cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

1. (`ncn-mw#`) Verify that the `hms-discovery` cron job has been suspended (`ACTIVE` = `0` and `SUSPEND` = `True`).

    ```bash
    kubectl get cronjobs -n services hms-discovery
    ```

    Example output:

    ```text
    NAME             SCHEDULE        SUSPEND     ACTIVE   LAST   SCHEDULE  AGE
    hms-discovery    */3 * * * *     True         0       117s             15d
    ```

### 3. Remove each blade from the cabinet

For each blade (slot) in the cabinet, follow one of the following procedures:

- [Removing a Liquid-cooled blade from a System](Removing_a_Liquid-cooled_blade_from_a_System.md)
- [Removing a Liquid-cooled blade from a System Using SAT](Removing_a_Liquid-cooled_blade_from_a_System_Using_SAT.md)

**NOTE**: Since the `hms-discovery` cron job has already been suspended in step 2, skip the steps in those procedures that suspend and un-suspend the `hms-discovery` cron job. Also skip the step that rediscovers the Chassis BMC, as that will not be needed when removing the entire cabinet.

Repeat the chosen procedure for every blade in the cabinet. For example, if the cabinet has chassis 0 through 7, each with slots 0 through 7:

```bash
for SLOT in $SLOTS; do
    echo "Removing blade: $SLOT"
done
```

Iterate through the list and perform the blade removal procedure for each slot.

### 4. Cleanup and remove Chassis BMCs

After all blades have been removed from the cabinet, clean up the Chassis BMC entries.

1. (`ncn-mw#`) Set the cabinet xname.

    ```bash
    CABINET="x9000"
    ```

1. (`ncn-mw#`) Identify all Chassis BMCs in the cabinet.

    ```bash
    CHASSIS_BMCS=$(cray hsm inventory redfishEndpoints list --type ChassisBMC --format json | \
        jq -r --arg CABINET "${CABINET}" \
        '.RedfishEndpoints[] | select(.ID | startswith($CABINET)) | .ID')
    echo "$CHASSIS_BMCS"
    ```

1. (`ncn-mw#`) Clear the Redfish event subscriptions from each Chassis BMC.

    ```bash
    export TOKEN=$(curl -s -S -d grant_type=client_credentials \
            -d client_id=admin-client \
            -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

    for BMC in $CHASSIS_BMCS; do
        /usr/share/doc/csm/scripts/operations/node_management/delete_bmc_subscriptions.py $BMC
    done
    ```

1. (`ncn-mw#`) Disable the Chassis BMC Redfish endpoints.

    ```bash
    for BMC in $CHASSIS_BMCS; do
        echo "Disabling Redfish endpoint for $BMC"
        cray hsm inventory redfishEndpoints update --enabled false "$BMC" --id "$BMC"
    done
    ```

1. (`ncn-mw#`) Delete the Chassis BMC Redfish endpoints from HSM.

    ```bash
    for BMC in $CHASSIS_BMCS; do
        echo "Removing Redfish endpoint for $BMC"
        cray hsm inventory redfishEndpoints delete "$BMC"
    done
    ```

1. (`ncn-mw#`) Remove the Chassis BMC state components from HSM.

    ```bash
    for BMC in $CHASSIS_BMCS; do
        echo "Removing state component for $BMC"
        cray hsm state components delete "$BMC"
    done
    ```

### 5. Cleanup HMS hardware inventory

Remove all remaining hardware inventory entries associated with the cabinet.

1. (`ncn-mw#`) Set the cabinet xname.

    ```bash
    CABINET="x9000"
    ```

1. (`ncn-mw#`) Remove all remaining Redfish endpoints associated with the cabinet.

    ```bash
    for xname in $(cray hsm inventory redfishEndpoints list --format json | \
                     jq -r --arg CABINET "${CABINET}" \
                       '.RedfishEndpoints[] | select(.ID | startswith($CABINET)) | .ID')
    do
        echo "Removing $xname from HSM Inventory RedfishEndpoints"
        cray hsm inventory redfishEndpoints delete "$xname"
    done
    ```

1. (`ncn-mw#`) Remove all remaining state components associated with the cabinet.

    ```bash
    for xname in $(cray hsm state components list --format json | \
                     jq -r --arg CABINET "${CABINET}" \
                       '.Components[] | select(.ID | startswith($CABINET)) | .ID')
    do
        echo "Removing $xname from HSM State Components"
        cray hsm state components delete "$xname"
    done
    ```

1. (`ncn-mw#`) Remove the hardware inventory entries for the cabinet.

    ```bash
    cray hsm inventory hardware delete "/Inventory/Hardware/${CABINET}"
    ```

### 6. Cleanup SLS data

Remove the cabinet and all associated components from the System Layout Service (SLS).
****Should cani be used here instead****??? - cani alpha remove cabinet x{cab} and cani alpha session apply?????

1. (`ncn-mw#`) Set the cabinet xname.

    ```bash
    CABINET="x9000"
    ```

1. (`ncn-mw#`) Retrieve the list of all SLS hardware entries for the cabinet.

    ```bash
    SLS_HARDWARE=$(cray sls hardware list --format json | \
        jq -r --arg CABINET "${CABINET}" \
        '.[] | select(.Xname | startswith($CABINET)) | .Xname')
    echo "$SLS_HARDWARE"
    ```

1. (`ncn-mw#`) Delete each SLS hardware entry associated with the cabinet.

    ```bash
    for xname in $SLS_HARDWARE; do
        echo "Removing $xname from SLS Hardware"
        cray sls hardware delete "$xname"
    done
    ```

1. (`ncn-mw#`) Verify that the cabinet has been removed from SLS.

    ```bash
    cray sls hardware list --format json | jq --arg CABINET "${CABINET}" \
        '.[] | select(.Xname | startswith($CABINET))'
    ```

    The command should return no results.

1. Delete the cabinet's network definitions/subnets from the relevant SLS Networks entries (HMN/NMN/CAN/CMN/CHN cabinet subnets) — these are not auto-removed when you delete the cabinet hardware.

**TODO**

1. (`ncn-mw#`) Remove all NodeBMC, ChassisBMC, RouterBMC ethernetInterfaces associated with the cabinet from HSM.

    ```bash
    for mac in $(cray hsm inventory ethernetInterfaces list --format json | \
                   jq -r --arg CABINET "${CABINET}" \
                     '.[] | select(.ComponentID | startswith($CABINET)) | .ID')
    do
        echo "Removing $mac from HSM Inventory EthernetInterfaces"
        cray hsm inventory ethernetInterfaces delete "$mac"
    done

or (better above option as it would delete any additional components if present like CabinetPDU/CabinetPDUController)

    ```bash
    for t in NodeBMC ChassisBMC RouterBMC; do
    for id in $(cray hsm inventory ethernetInterfaces list --type "$t" --format json \
                    | jq -r --arg c "$CAB" '.[] | select(.ComponentID | startswith($c)) | .ID'); do
        cray hsm inventory ethernetInterfaces delete "$id"
    done
    done
    ```

### 7. Vault cleanup

Delete secret/hms-creds/<bmc_xname> for every BMC in the cabinet (and any CEC/PDU creds rooted on that cabinet).

****Add a procedure for this****

Network/global cleanup that the blade procedure never touches:

Remove the cabinet's HMN/NMN VLAN subnets and any IP reservations from SLS Networks.
Rerun csi config init/network reconcile (or follow Updating_Cabinet_Routes_on_Management_NCNs.md) to drop static routes to the cabinet's HMN/NMN subnets from the management NCNs.
Restart cray-dhcp-kea, cray-dns-unbound, BSS, and SLS-dependent services so they reload the new topology.
kubectl -n services rollout restart deployment cray-dhcp-kea
kubectl -n services rollout restart deployment cray-dns-unbound-manager


### 8. Restart Kea and re-enable the `hms-discovery` cron job

1. (`ncn-mw#`) Restart Kea to pick up the DHCP changes.

    ```bash
    kubectl rollout restart deployment -n services cray-dhcp-kea
    ```

1. (`ncn-mw#`) Un-suspend the `hms-discovery` cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

1. (`ncn-mw#`) Verify that the `hms-discovery` cron job is active (`SUSPEND` = `False`).

    ```bash
    kubectl get cronjobs -n services hms-discovery
    ```

    Example output:

    ```text
    NAME            SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    hms-discovery   */3 * * * *   False     1        46s             15d
    ```

### 9. Remove CMM and CEC port configuration from CDU switches

Remove the CMM and CEC port configuration from the CDU switches that served the cabinet.

1. Update the SHCD to reflect the removal of the cabinet.

1. Use CANU to generate a new CCJ file from the updated SHCD.

    ```bash
    canu generate network config --csm 1.7 --ccj updated-ccj.json --shcd updated-shcd.xlsx
    ```

1. Use CANU to generate new network configuration using the new CCJ and SLS files.

    ```bash
    canu generate network config --csm 1.7 --ccj updated-ccj.json --sls-file sls_input_file.json --folder switch-configs
    ```

1. Apply the updated configuration to the target CDU switches.

    ```bash
    canu apply network config --config switch-configs/<switch-hostname>.cfg --host <switch-hostname> --password <password>
    ```

    Repeat for each CDU switch that had connections to the removed cabinet.

### 10. Remove the physical cabinet

1. Remove the blades from the cabinet (if not already done during step 3).

    Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions. These procedures can be found on the [HPE Support Center](https://support.hpe.com/).

1. Drain the coolant from all blades and the cabinet cooling system.

    Review *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200*. These procedures can be found on the [HPE Support Center](https://support.hpe.com/).

1. Disconnect all network and power connections to the cabinet.

1. Physically remove the cabinet from the facility.
