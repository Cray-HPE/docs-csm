# Removing a Liquid-cooled blade from a System Using SAT

This procedure will remove a liquid-cooled blade from an HPE Cray EX system.

## Prerequisites

- The Cray command line interface \(CLI\) tool is initialized and configured on the system. See [Configure the Cray Command Line Interface](../configure_cray_cli.md).

- Knowledge of whether DVS is operating over the Node Management Network (NMN) or the High Speed Network (HSN).

- The Slingshot fabric must be configured with the desired topology for desired state of the blades in the system.

- The System Layout Service (SLS) must have the desired HSN configuration.

- Check the status of the high-speed network (HSN) and record link status before the procedure.

- The blades must have the coolant drained and filled during the swap to minimize cross-contamination of cooling systems.
  - Review procedures in *HPE Cray EX Coolant Service Procedures H-6199*
  - Review the *HPE Cray EX Hand Pump User Guide H-6200*

- The System Admin Toolkit \(SAT\) is installed and configured on the system.

## Prepare the system blade for removal

1. Using the work load manager (WLM), drain running jobs from the affected nodes on the blade.

   Refer to the vendor documentation for the WLM for more information.

1. Determine which Boot Orchestration Service \(BOS\) templates to use to shut down nodes on the target blade.

   There will be separate session templates for UANs and computes nodes.

   1. List all the session templates.

      If it is unclear which session template is in use, proceed to the next substep.

      ```bash
      cray bos sessiontemplate list
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
      cray bos session describe BOS_SESSION | grep templateName
      ```

      Example output:

      ```toml
      templateName = "compute-nid1-4-sessiontemplate"
      ```

   1. Determine the list of xnames associated with the desired boot session template.

      ```bash
      cray bos sessiontemplate describe SESSION_TEMPLATE_NAME | grep node_list
      ```

      Example output:

      ```toml
      node_list = [ "x9000c3s0b1n0", "x9000c3s0b2n0", "x9000c3s0b3n0", "x9000c3s0b4n0",]
      ```

1. Shut down the nodes on the target blade.

   Use the `sat bootsys` command to shut down the nodes on the target blade.
   Specify the appropriate component name (xname) for the slot, and a comma-separated list of the BOS session templates determined in the previous step.

   ```bash
   BOS_TEMPLATES=cos-2.0.30-slurm-healthy-compute
   sat bootsys shutdown --stage bos-operations --bos-limit x9000c3s0 --recursive --bos-templates $BOS_TEMPLATES
   ```

## Use SAT to remove the blade from hardware management

1. (`ncn#`) Clear out the existing Redfish event subscriptions from the BMCs on the blade.

    1. Set the environment variable `SLOT` to the blade's location.

        ```bash
        SLOT=x9000c3s0
        ```

    1. Clear the Redfish event subscriptions.

        ```bash
        for BMC in $(cray hsm inventory  redfishEndpoints list --type NodeBMC --format json | jq .RedfishEndpoints[].ID -r | grep ${SLOT}); do
            PASSWD=$(cray scsd bmc creds list --targets ${BMC} --format json | jq .Targets[].Password -r)
            SUBS=$(curl -sk -u root:"${PASSWD}" https://${BMC}/redfish/v1/EventService/Subscriptions | jq -r '.Members[]."@odata.id"')
            for SUB in ${SUBS}; do
                echo "Deleting event subscription: https://${BMC}${SUB}" 
                curl -i -sk -u root:"${PASSWD}" -X DELETE https://${BMC}${SUB}
            done
        done
        ```

        Each event subscription deleted that was deleted will have output like the following:

        ```text
        Deleting event subscription: https://x1005c3s0b0/redfish/v1/EventService/Subscriptions/1
        HTTP/2 204
        access-control-allow-credentials: true
        access-control-allow-headers: X-Auth-Token
        access-control-allow-origin: *
        access-control-expose-headers: X-Auth-Token
        cache-control: no-cache, must-revalidate
        content-type: text/html; charset=UTF-8
        date: Tue, 19 Jan 2038 03:14:07 GMT
        odata-version: 4.0
        server: Cray Embedded Software Redfish Service
        ```

1. Power off the slot and delete blade information from HSM.

   Use the `sat swap` command to power off the slot and delete the blade's Ethernet interfaces and Redfish endpoints from HSM.

   ```bash
   sat swap blade --action disable x9000c3s0
   ```

   This command will also save the MAC addresses, IP addresses, and node component names (xnames) from the blade to a JSON document.
   The document is stored in a file with the following naming convention:

   ```text
   ethernet-interface-mappings-<blade_xname>-<current_year>-<current_month>-<current_day>.json
   ```

   If a mapping file already exists with the above name, then a numeric suffix will be appended to the file name in front of the `.json` extension.

## Remove the blade

1. Remove the blade from the source system.
   Review the *Remove a Compute Blade Using the Lift* procedure in *HPE Cray EX Hardware Replacement Procedures H-6173* for detailed instructions for replacing liquid-cooled blades ([HPE Support](https://internal.support.hpe.com/)).
1. Drain the coolant from the blade and fill with fresh coolant to minimize cross-contamination of cooling systems.
   Review *HPE Cray EX Coolant Service Procedures H-6199*. If using the hand pump, review procedures in the *HPE Cray EX Hand Pump User Guide H-6200* ([HPE Support](https://internal.support.hpe.com/)).
1. Install the blade from the source system in a storage rack or leave it on the cart.
