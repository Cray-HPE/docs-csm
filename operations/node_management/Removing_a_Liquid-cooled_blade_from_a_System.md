# Removing a Liquid-cooled blade from a System

This procedure will remove a liquid-cooled blades from a HPE Cray EX system. 

## Perquisites 
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

-   Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).

-   The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.

-   The System Layout Service (SLS) must have the desired HSN configuration.

-   Check the status of the high-speed network (HSN) and record link status before the procedure.

-   The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
    - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
    - Review the *HPE Cray EX Hand Pump User Guide H-6200*

## Procedure

### Prepare the source system blade for removal
1.  Using the work load manager (WLM), drain running jobs from the affected nodes on the blade. Refer to the vendor documentation for the WLM for more information.

2.  Use Boot Orchestration Services (BOS) to shut down the affected nodes in the source blade (in this example, `x9000c3s0`). Specify the appropriate component name (xname) and BOS template for the node type in the following command.

    ```bash
    ncn# BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    ncn# cray bos session create --template-uuid $BOS_TEMPLATE --operation shutdown --limit x9000c3s0b0n0,x9000c3s0b0n1,x9000c3s0b1n0,x9000c3s0b1n1
    ```

#### Disable the Redfish endpoints for the nodes
3.  Temporarily disable the Redfish endpoints for NodeBMCs present in the blade.

    ```bash
    ncn# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b0
    ncn# cray hsm inventory redfishEndpoints update --enabled false x9000c3s0b1
    ```

#### Clear the node controller settings
4. Remove the system specific settings from each node controller on the blade.

   ```bash
   ncn# curl -k -u root:PASSWORD -X POST -H \
     'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' \
     https://x9000c3s0b0/redfish/v1/Managers/BMC/Actions/Manager.Reset

   ncn# curl -k -u root:PASSWORD -X POST -H \
     'Content-Type: application/json' -d '{"ResetType":"StatefulReset"}' \
     https://x9000c3s0b1/redfish/v1/Managers/BMC/Actions/Manager.Reset
   ```
   Use Ctrl-C to return to the prompt if command does not return.


#### Power off the chassis slot
5.  Suspend the hms-discovery cron job.

    ```bash
    ncn# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
    ```

    1.  Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `True`).

        ```bash
        ncn# kubectl get cronjobs -n services hms-discovery
        NAME             SCHEDULE        SUSPEND     ACTIVE   LAST   SCHEDULE  AGE
        hms-discovery    */3 * * * *     True         0       117s             15d
        ```

    2.  Power off the chassis slot. This examples powers off slot 0, chassis 3, in cabinet 9000.

        ```bash
        ncn# cray capmc xname_off create --xnames x9000c3s0 --recursive true
        ```

#### Disable the chassis slot
6.  Disable the chassis slot. Disabling the slot prevents hms-discovery from automatically powering on the slot. This example disables slot 0, chassis 3, in cabinet 9000. 

    ```bash
    ncn# cray hsm state components enabled update --enabled false x9000c3s0
    ```

#### Record MAC and IP addresses for nodes
**IMPORTANT**: Record the node management network (NMN) MAC and IP addresses for each node in the blade (labeled `Node Maintenance Network`). To prevent disruption in the data virtualization service (DVS) when over operating the NMN, these addresses must be maintained in the HSM when the blade is swapped and discovered.

The NodeBMC MAC and IP addresses are assigned algorithmically and *must not be deleted* from the HSM.

7.  **Skip this step if DVS is operating over the HSN, otherwise proceed with this step.** Query HSM to determine the ComponentID, MAC, and IP addresses for each node in the blade.
   The prerequisites show an example of how to gather HSM values and store them to a file.

    ```bash
    ncn# cray hsm inventory ethernetInterfaces list --component-id x9000c3s0b0n0 --format json
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

    1.  Record the following values for the blade:

        ```bash
        `ComponentID: "x9000c3s0b0n0"`
        `MACAddress: "00:40:a6:83:63:39"`
        `IPAddress: "10.100.0.10"`
        ```

    2.  Repeat the command to record the ComponentID, MAC, and IP addresses for the `Node Maintenance Network` the other nodes in the blade.


#### Cleanup Hardware State Manager
8.  Set environment corresponding the chassis slot of the blade.
    ```bash
    ncn# export CHASSIS_SLOT=x9000c3s0
    ```

9.  Delete the Redfish endpoints for each node.

    ```bash
    ncn# for xname in $(cray hsm inventory redfishEndpoints list --format json | jq -r --arg CHASSIS_SLOT $CHASSIS_SLOT '.RedfishEndpoints[] | select(.ID | startswith($CHASSIS_SLOT)) | .ID'); do
        echo "Removing $xname from HSM Inventory RedfishEndpoints"
        cray hsm inventory redfishEndpoints delete "$xname"
    done
    ```

10. Remove entries from state components.
    ```bash
    for xname in $(cray hsm state components list --class Mountain --format json |  jq -r --arg CHASSIS_SLOT $CHASSIS_SLOT '.Components[] | select((.ID | startswith($CHASSIS_SLOT)) and (.ID != $CHASSIS_SLOT)) | .ID' ); do
        echo "Removing $xname from HSM State components"
        cray hsm state components delete "$xname"
    done
    ```

11. Delete the NMN MAC and IP addresses each node in the blade from the HSM. *Do not delete the MAC and IP addresses for the node BMC*.
    ```bash
    for mac in $(cray hsm inventory ethernetInterfaces list --type Node --format json | jq -r --arg CHASSIS_SLOT $CHASSIS_SLOT '.[] | select(.ComponentID | startswith($CHASSIS_SLOT)) | .ID'); do
        echo "Removing $mac from HSM Inventory EthernetInterfaces"
    done
    ```

12. Restart KEA.
    ```bash
    ncn# kubectl delete pods -n services -l app.kubernetes.io/name=cray-dhcp-kea
    ```

#### Remove the blade
13.  Remove the blade from the source location.
    - Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades (https://internal.support.hpe.com/).

14.  Drain the coolant from the blade and fill with fresh coolant to minimize cross-contamination of cooling systems.
    - Review *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200* (https://internal.support.hpe.com/).

15. Install the blade from the source system in a storage rack or leave it on the cart. 

16. Un-suspend the hms-discovery cron job if no more liquid-cooled blades are planned to be removed from the system.

    ```bash
    ncn# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

    Verify that the hms-discovery cron job has stopped (`ACTIVE` = `0` and `SUSPEND` = `False`).

    ```bash
    ncn# kubectl get cronjobs -n services hms-discovery
    NAME            SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    hms-discovery   */3 * * * *   False     1        46s             15d
    ```