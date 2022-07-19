# Removing a Liquid-cooled blade from a System

This procedure will remove a liquid-cooled blades from an HPE Cray EX system.

## Perquisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system.

- Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).

- The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.

- The System Layout Service (SLS) must have the desired HSN configuration.

- Check the status of the high-speed network (HSN) and record link status before the procedure.

- The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
  - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
  - Review the *HPE Cray EX Hand Pump User Guide H-6200*

## Procedure

### 1. Prepare the source system blade for removal

1. Using the work load manager (WLM), drain running jobs from the affected nodes on the blade. Refer to the vendor documentation for the WLM for more information.

1. (`ncn#`) Use Boot Orchestration Services (BOS) to shut down the affected nodes in the source blade (in this example, `x9000c3s0`). Specify the appropriate component name (xname) and BOS template for the node type in the following command.

    ```bash
    BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    cray bos session create --template-uuid $BOS_TEMPLATE --operation shutdown --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
    ```

### 2. Disable the Redfish endpoints for the nodes

1. (`ncn#`) Temporarily disable the Redfish endpoints for `NodeBMCs` present in the blade.

    ```bash
    cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b0
    cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b1
    ```

### 3. Clear the node controller settings

1. (`ncn#`) Remove the system specific settings from each node controller on the blade.

   ```bash
   curl -k -u root:PASSWORD -X POST -H \
     'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' \
     https://x9000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset

   curl -k -u root:PASSWORD -X POST -H \
     'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' \
     https://x9000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
   ```

   Use Ctrl-C to return to the prompt if command does not return.

### 4. Power off the chassis slot

1. (`ncn#`) Suspend the `hms-discovery` cron job.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    1. (`ncn#`) Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `True`).

        ```bash
        kubectl get cronjobs -n services hms-discovery
        NAME             SCHEDULE        SUSPEND     ACTIVE   LAST   SCHEDULE  AGE
        hms-discovery    */3 * * * *     True         0       117s             15d
        ```

    1. (`ncn#`)Power off the chassis slot. This examples powers off slot 0, chassis 3, in cabinet 9000.

        ```bash
        cray capmc xname_off create --xnames x9000c3s0 --recursive true
        ```

### 5. Disable the chassis slot

1. (`ncn#`) Disable the chassis slot. Disabling the slot prevents `hms-discovery` from automatically powering on the slot. This example disables slot 0, chassis 3, in cabinet 9000.

    ```bash
    cray hsm state components enabled update --enabled false x9000c3s0
    ```

### 6. Record MAC and IP addresses for nodes

**IMPORTANT**: Record the node management network (NMN) MAC and IP addresses for each node in the blade (labeled `Node Maintenance Network`). To prevent disruption in the data virtualization service (DVS) when over operating the NMN, these addresses must
be maintained in the HSM when the blade is swapped and discovered.

The `NodeBMC` MAC and IP addresses are assigned algorithmically and *must not be deleted* from the HSM.

1. (`ncn#`) **Skip this step if DVS is operating over the HSN, otherwise proceed with this step.** Query HSM to determine the `ComponentID`, MAC, and IP addresses for each node in the blade.
   The prerequisites show an example of how to gather HSM values and store them to a file.

    ```bash
    cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b0n0 --format json
    [
        {
        "ID": "0040a6836339",
        "Description": "Node Maintenance Network",
        "MACAddress": "00:40:a6:83:63:39",
        "LastUpdate": "2021-04-09T21:51:04.662063Z",
        "ComponentID": "x9000c3s0b0n0",
        "Type": "Node",
        "IPAddresses": [
            {
            "IPAddress": "10.100.0.10"
            }
        ]
        }
    ]
    ```

    1. Record the following values for the blade:

        ```bash
        `ComponentID: "x9000c3s0b0n0"`
        `MACAddress: "00:40:a6:83:63:39"`
        `IPAddress: "10.100.0.10"`
        ```

    2. Repeat the command to record the ComponentID, MAC, and IP addresses for the `Node Maintenance Network` the other nodes in the blade.

### 7. Cleanup Hardware State Manager

1. (`ncn#`) Set environment corresponding the chassis slot of the blade.

    ```bash
    export CHASSIS_SLOT=x9000c3s0
    ```

1. (`ncn#`) Delete the Redfish endpoints for each node.

    ```bash
    for xname in $(cray hsm inventory redfishEndpoints list --format json | jq -r --arg CHASSIS_SLOT $CHASSIS_SLOT '.RedfishEndpoints[] | select(.ID | startswith($CHASSIS_SLOT)) | .ID'); do
        echo "Removing $xname from HSM Inventory RedfishEndpoints"
        cray hsm inventory redfishEndpoints delete "$xname"
    done
    ```

1. (`ncn#`) Remove entries from state components.

    ```bash
    for xname in $(cray hsm state components list --class Mountain --format json |  jq -r --arg CHASSIS_SLOT $CHASSIS_SLOT '.Components[] | select((.ID | startswith($CHASSIS_SLOT)) and (.ID != $CHASSIS_SLOT)) | .ID' ); do
        echo "Removing $xname from HSM State components"
        cray hsm state components delete "$xname"
    done
    ```

1. (`ncn#`) Delete the NMN MAC and IP addresses each node in the blade from the HSM. *Do not delete the MAC and IP addresses for the node BMC*.

    ```bash
    for mac in $(cray hsm inventory ethernetInterfaces list --type Node --format json | jq -r --arg CHASSIS_SLOT $CHASSIS_SLOT '.[] | select(.ComponentID | startswith($CHASSIS_SLOT)) | .ID'); do
        echo "Removing $mac from HSM Inventory EthernetInterfaces"
        cray hsm inventory ethernetInterfaces delete $mac
    done
    ```

1. (`ncn#`) Restart KEA.

    ```bash
    kubectl delete pods -n services -l app.kubernetes.io/name=cray-dhcp-kea
    ```

### 8. Remove the blade

1. Remove the blade from the source location.
    - Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades. These procedures can be found on the [HPE Support Center](https://internal.support.hpe.com/).

1. Drain the coolant from the blade and fill with fresh coolant to minimize cross-contamination of cooling systems.
    - Review *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200*. These procedures can be found on the [HPE Support Center](https://internal.support.hpe.com/).

1. Install the blade from the source system in a storage rack or leave it on the cart.

1. (`ncn#`) Un-suspend the `hms-discovery` cron job if no more liquid-cooled blades are planned to be removed from the system.

    ```bash
    kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

    Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `False`).

    ```bash
    kubectl get cronjobs -n services hms-discovery
    NAME            SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    hms-discovery   */3 * * * *   False     1        46s             15d
    ```
