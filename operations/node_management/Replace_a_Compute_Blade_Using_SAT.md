# Replace a Compute Blade Using SAT

Replace an HPE Cray EX liquid-cooled compute blade.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

- The Slingshot fabric must be configured with the desired topology.

- The System Layout Service (SLS) must have the desired HSN configuration.

- Check the status of the high-speed network (HSN) and record link status before the procedure.

- The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.

  - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
  - Review the *HPE Cray EX Hand Pump User Guide H-6200*

- The System Admin Toolkit \(SAT\) is installed and configured on the system.

- DVS must be running over the HSN.

## Shutdown nodes on the compute blade

1. Verify that the workload manager (WLM) is not using the affected nodes.

1. Determine which Boot Orchestration Service \(BOS\) templates to use to shut down nodes on the target blade.

   There will be separate session templates for UANs and computes nodes.

   1. List all the session templates.

      If it is unclear which session template is in use, proceed to the next substep.

      ```bash
      cray bos v1 sessiontemplate list
      ```

   1. Find the node xnames with `sat status`. In this example, the target blade is in slot `x9000c3s0`.

      ```bash
      sat status --filter 'xname=x9000c3s0*'
      ```

      Example output:

      ```text
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      | xname         | Type | NID      | State | Flag | Enabled | Arch | Class | Role        | Net      |
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      | x9000c3s0b1n0 | Node | 1        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b2n0 | Node | 2        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b3n0 | Node | 3        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      | x9000c3s0b4n0 | Node | 4        | Off   | OK   | True    | X86  | River | Compute     | Sling    |
      +---------------+------+----------+-------+------+---------+------+-------+-------------+----------+
      ```

   1. Find the `bos_session` value for each node via the Configuration Framework Service (CFS).

      ```bash
      cray cfs components describe x9000c3s0b1n0 | grep bos_session
      ```

      Example output:

      ```toml
      bos_session = "e98cdc5d-3f2d-4fc8-a6e4-1d301d37f52f"
      ```

   1. Find the required `templateName` value with BOS.

      ```bash
      cray bos v1 session describe BOS_SESSION | grep templateName
      ```

      Example output:

      ```toml
      templateName = "compute-nid1-4-sessiontemplate"
      ```

   1. Determine the list of xnames associated with the desired boot session template.

      ```bash
      cray bos v1 sessiontemplate describe SESSION_TEMPLATE_NAME | grep node_list
      ```

      Example output:

      ```toml
      node_list = [ "x9000c3s0b1n0", "x9000c3s0b2n0", "x9000c3s0b3n0", "x9000c3s0b4n0",]
      ```

1. Shut down the nodes on the target blade.

   Use the `sat bootsys` command to shut down the nodes on the target blade. Specify the appropriate component name (xname)
   for the slot, and a comma-separated list of the BOS session templates determined in the previous step.

   ```bash
   BOS_TEMPLATES=cos-2.0.30-slurm-healthy-compute
   sat bootsys shutdown --stage bos-operations --bos-limit x9000c3s0 --recursive --bos-templates $BOS_TEMPLATES
   ```

## Use SAT to remove the blade from hardware management

1. Power off the slot and delete blade information from HSM.

   Use the `sat swap` command to power off the slot and delete the blade's Ethernet interfaces and Redfish endpoints from HSM.

   ```bash
   sat swap blade --action disable x9000c3s0
   ```

## Replace the blade hardware

1. Replace the blade hardware.

   Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions.

   **CAUTION**: Always power off the chassis slot or device before removal. The best practice is to unlatch
   and unseat the device while the coolant hoses are still connected, then disconnect the coolant hoses.
   If this is not possible, disconnect the coolant hoses, then quickly unlatch/unseat the device (within 10
   seconds). Failure to do so may damage the equipment.

## Use SAT to add the blade to hardware management

1. Use the `sat swap` command to begin discovery for the blade and add it to hardware management.

   ```bash
   sat swap blade --action enable x9000c3s0
   ```

## Clear Redfish event subscriptions from BMCs on the blade

1. (`ncn#`) Set the environment variable `SLOT` to the blade's location.

    ```bash
    SLOT="x9000c3s0"
    ```

1. (`ncn#`) Clear the Redfish event subscriptions.

   ```bash
   export TOKEN=$(curl -s -S -d grant_type=client_credentials \
           -d client_id=admin-client \
           -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` \
           https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

   for BMC in $(cray hsm inventory  redfishEndpoints list --type NodeBMC --format json | jq .RedfishEndpoints[].ID -r | grep ${SLOT}); do
       /usr/share/doc/csm/scripts/operations/node_management/delete_bmc_subscriptions.py $BMC
   done
   ```

   Each BMC on the blade will have output like the following:

   ```text
   Clearing subscriptions from NodeBMC x3000c0s9b0
   Retrieving BMC credentials from SCSD
   Retrieving Redfish Event subscriptions from the BMC: https://x3000c0s9b0/redfish/v1/EventService/Subscriptions
   Deleting event subscription: https://x3000c0s9b0/redfish/v1/EventService/Subscriptions/1
   Successfully deleted https://x3000c0s9b0/redfish/v1/EventService/Subscriptions/1
   ```

## Perform updates and boot the nodes

1. Optional: If necessary, update the firmware. Review the [Firmware Action Service (FAS)](../firmware/FAS_Admin_Procedures.md) documentation.

   ```bash
   cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
   ```

1. Power on and boot the nodes.

   Use `sat bootsys` to power on and boot the nodes. Specify the appropriate BOS template for the node type.

    ```bash
    BOS_TEMPLATE=cos-2.0.30-slurm-healthy-compute
    sat bootsys boot --stage bos-operations --bos-limit x9000c3s0 --recursive --bos-templates $BOS_TEMPLATE
    ```
