# FAS Use Cases

Use the Firmware Action Service (FAS) to update the firmware on supported hardware devices. Each procedure includes the prerequisites and example recipes required to update the firmware.

When updating an entire system, walk down the device hierarchy component type by component type, starting first with Routers (switches), proceeding to Chassis, and then finally to Nodes. While this is not strictly necessary, it does help eliminate confusion.

Refer to [FAS Filters](FAS_Filters.md) for more information on the content used in the example JSON files.

1. [Update Liquid-Cooled Compute Node BMC, FPGA, and BIOS](#liquidcooled)
1. [Update Air-Cooled Compute Node BMC, BIOS, iLO 5, and System ROM](#aircooled)
2. [Update Chassis Management Module (CMM) Firmware](#cmm)
3. [Update NCN BIOS and BMC Firmware with FAS](#ncn-bios-bmc)
5. [Compute Node BIOS Workaround for HPE CRAY EX425](#cn-workaround)

*NOTE* to update Switch Controllers \(sC\) or RouterBMC refer to the Rosetta Documentation

---

<a name="liquidcooled"></a>

### Update Liquid-Cooled Nodes BMC, FPGA, and Node BIOS

Update firmware for a liquid-cooled node controller \(nC\) using FAS.
This section includes templates for JSON files that can be used and the procedure for running the update.

All of the example JSON files below are set to run a dry-run. Update the overrideDryrun value to `true` to update the firmware.

This procedure updates the following hardware:
-   Node controller \(nC\) firmware

#### Prerequisites
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

#### Liquid-Cooled Nodes Update Procedures

**Manufacturer: Cray | Device Type: NodeBMC | Target: BMC**

BMC firmware with FPGA updates require the nodes to be off.
If the nodes are not off when the update command is issued, the update will get deferred until the next power cycle of the BMC, which may be a long period of time.

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Olympus node BMCs"
  }
}
```

**Manufacturer: Cray | Device Type: NodeBMC | Target: Redstone FPGA**

**IMPORTANT**: The Nodes themselves must be powered **on** in order to update the firmware of the Redstone FPGA on the nodes.

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"    ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "Node0.AccFPGA0",
      "Node1.AccFPGA0"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Node Redstone FPGA"
  }
}
```

**Manufacturer: Cray | Device Type : NodeBMC | Target : NodeBIOS**

There are two nodes that must be updated on each BMC, these have the targets `Node0.BIOS` and `Node1.BIOS`.
The targets can be run in the same action (as shown in the example) or run separately by only including one target in the action.
On larger systems, it is recommended to run as two actions one after each other as the output will be shorter.

#### Prerequisites
-   The Cray nodeBMC device needs to be updated before the nodeBIOS because the nodeBMC adds a new field Redfish \(softwareId\) that the NodeX.BIOS update will require. See [Update Liquid-Cooled Node Firmware](#liquidcooled) for more information.
-   Compute node BIOS updates require the nodes to be off. If nodes are not off when the update command is issued, it will report as a failed update.

**IMPORTANT**: The Nodes themselves must be powered **off** in order to update the BIOS on the nodes. The BMC will still have power and will perform the update.

**IMPORTANT:** When the BMC is updated or rebooted after updating the Node0.BIOS and/or Node1.BIOS liquid-cooled nodes, the node BIOS version will not report the new version string until the nodes are powered back on.
It is recommended that the Node0/1 BIOS be updated in a separate action, either before or after a BMC update and the nodes are powered back on after a BIOS update.

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"    ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"targetFilter": {
    "targets": [
      "Node0.BIOS",
      "Node1.BIOS"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Node BIOS"
  }
}
```

#### Procedure

1.  Create a JSON file using one of the example recipes with the command parameters required for updating the firmware or node BIOS.

2.  Initiate a dry-run to verify that the firmware can be updated.

    1.  Create the dry-run session.

        The `overrideDryrun = false` value indicates that the command will do a dry run.

        ```bash
        ncn-w001# cray fas actions create nodeBMC.json
        overrideDryrun = false
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        ```

    2.  Describe the `actionID` for firmware update dry-run job.

        Replace the actionID value with the string returned in the previous step. In this example, `"fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"` is used.

        ```bash
        ncn-w001# cray fas actions describe {actionID}
        blockedBy = []
        state = "completed"
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        startTime = "2020-08-31 15:49:44.568271843 +0000 UTC"
        snapshotID = "00000000-0000-0000-0000-000000000000"
        endTime = "2020-08-31 15:51:35.426714612 +0000 UTC"

        [command]
        description = "Update Cray Node BMCs Dryrun"
        tag = "default"
        restoreNotPossibleOverride = true
        timeLimit = 10000
        version = "latest"
        overrideDryrun = false
        ```

        If `state = "completed"`, the dry-run has found and checked all the nodes. Check the following sections for more information:

        -   Lists the nodes that have a valid image for updating:

            ```bash
            [operationSummary.succeeded]
            ```

        -   Lists the nodes that will not be updated because they are already at the correct version:

            ```bash
            [operationSummary.noOperation]
            ```

        -   Lists the nodes that had an error when attempting to update:

            ```bash
            [operationSummary.failed]
            ```

        -   Lists the nodes that do not have a valid image for updating:

            ```bash
            [operationSummary.noSolution]
            ```

3.  Update the firmware after verifying that the dry-run worked as expected.

    1.  Edit the JSON file and update the values so an actual firmware update can be run.

        The following example is for the nodeBMC.json file. Update the following values:

        ```bash
        "overrideDryrun":true,
        "description":"Update Cray Node BMCs"
        ```

    2.  Run the firmware update.

        The returned `overrideDryrun = true` indicates that an actual firmware update job was created. A new `actionID` will also be returned.

        ```bash
        ncn-w001# cray fas actions create nodeBMC.json
        overrideDryrun = true
        actionID = "bc40f10a-e50c-4178-9288-8234b336077b"
        ```

        The time it takes for a firmware action to finish varies. It can be a few minutes or over 20 minutes depending on response time.

        The liquid-cooled node BMC automatically reboots after the BMC firmware has been loaded.

4.  Retrieve the operationID and verify that the update is complete.

    ```bash
    ncn-w001# cray fas actions describe {actionID}
    [operationSummary.failed]
    [[operationSummary.failed.operationKeys]]
    stateHelper = "unexpected change detected in firmware version. Expected nc.1.3.10-shasta-release.arm.2020-07-21T23:58:22+00:00.d479f59 got: nc.cronomatic-dev.arm.2019-09-24T13:20:24+00:00.9d0f8280"
    fromFirmwareVersion = "nc.cronomatic-dev.arm.2019-09-24T13:20:24+00:00.9d0f8280"
    xname = "x1005c6s4b0"
    target = "BMC"
    operationID = "e910c6ad-db98-44fc-bdc5-90477b23386f"
    ```

5.  View more details for an operation using the operationID from the previous step.

    Check the list of nodes for the `failed` or `completed` state.

    ```bash
    ncn-w001# cray fas operations describe {operationID}
    ```

    For example:

    ```bash
    ncn-w001# cray fas operations describe "e910c6ad-db98-44fc-bdc5-90477b23386f"
    fromFirmwareVersion = "nc.cronomatic-dev.arm.2019-09-24T13:20:24+00:00.9d0f8280"
    fromTag = ""
    fromImageURL = ""
    endTime = "2020-08-31 16:40:13.464321212 +0000 UTC"
    actionID = "bc40f10a-e50c-4178-9288-8234b336077b"
    startTime = "2020-08-31 16:28:01.228524446 +0000 UTC"
    fromSemanticFirmwareVersion = ""
    toImageURL = ""
    model = "WNC_REV_B"
    operationID = "e910c6ad-db98-44fc-bdc5-90477b23386f"
    fromImageID = "00000000-0000-0000-0000-000000000000"
    target = "BMC"
    toImageID = "39c0e553-281d-4776-b68e-c46a2993485e"
    toSemanticFirmwareVersion = "1.3.10"
    refreshTime = "2020-08-31 16:40:13.464325422 +0000 UTC"
    blockedBy = []
    toTag = ""
    state = "failed"
    stateHelper = "unexpected change detected in firmware version. Expected nc.1.3.10-shasta-release.arm.2020-07-21T23:58:22+00:00.d479f59 got: nc.cronomatic-dev.arm.2019-09-24T13:20:24+00:00.9d0f8280"
    deviceType = "NodeBMC"
    ```

    Once firmware / BIOS is updated, the compute nodes can be turned back on.

---

<a name="cmm"></a>

### Update Chassis Management Module Firmware

Update the Chassis Management Module \(CMM\) controller \(cC\) firmware using FAS. This procedure uses the dry-run feature to verify that the update will be successful.

The CMM firmware update process also checks and updates the Cabinet Environmental Controller \(CEC\) firmware.

#### Prerequisites
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

#### Example Recipes
**Manufacturer: Cray | Device Type: ChassisBMC | Target: BMC**

**IMPORTANT**: Before updating a CMM, make sure all slot and rectifier power is off and discovery job is stopped (see procedure below).

```json
{
"inventoryHardwareFilter": {
    "manufacturer": "cray"
    },
"stateComponentFilter": {
    "deviceTypes": [
      "chassisBMC"
    ]
},
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Cray Chassis Controllers"
  }
}
```

#### Procedure
1.  Power off the liquid-cooled chassis slots and chassis rectifiers.

    1.  Disable the `hms-discovery` Kubernetes cronjob:

        ```bash
        ncn# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : true }}'
        ```

    2.  Power off all the components; for example, in chassis 0-7, cabinets 1000-1003.

        ```bash
        ncn# cray capmc xname_off create --xnames x[1000-1003]c[0-7] --recursive true --continue true
        ```

        This command powers off all the node cards, then all the compute blades, then all the Slingshot switch ASICS, then all the Slingshot switch enclosures, and finally all chassis enclosures in cabinets 1000-1003.

        When power is removed from a chassis, the high-voltage DC rectifiers that support the chassis are powered off. If a component is not populated, the `--continue` option enables the command to continue instead of returning error messages.

2.  Create a JSON file using the example recipe above with the command parameters required for updating the CMM firmware.

3.  Initiate a dry-run to verify that the firmware can be updated.

    1.  Create the dry-run session.

        The `overrideDryrun = false` value indicates that the command will do a dry-run.

        ```bash
        ncn# cray fas actions create chassisBMC.json
        overrideDryrun = false
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        ```

    2.  Describe the `actionID` to see the firmware update dry-run job status.

        Replace the actionID value with the string returned in the previous step. In this example, `"fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"` is used.

        ```bash
        ncn# cray fas actions describe {actionID}
        blockedBy = []
        state = "completed"
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        startTime = "2020-08-31 15:49:44.568271843 +0000 UTC"
        snapshotID = "00000000-0000-0000-0000-000000000000"
        endTime = "2020-08-31 15:51:35.426714612 +0000 UTC"

        [command]
        description = "Update Cray Chassis Management Module controllers Dryrun"
        tag = "default"
        restoreNotPossibleOverride = true
        timeLimit = 10000
        version = "latest"
        overrideDryrun = false
        ```

        If `state = "completed"`, the dry-run has found and checked all the nodes. Check the following sections for more information:

        -   Lists the nodes that have a valid image for updating:

            ```bash
            [operationSummary.succeeded]
            ```

        -   Lists the nodes that will not be updated because they are already at the correct version:

            ```bash
            [operationSummary.noOperation]
            ```

        -   Lists the nodes that had an error when attempting to update:

            ```bash
            [operationSummary.failed]
            ```

        -   Lists the nodes that do not have a valid image for updating:

            ```bash
            [operationSummary.noSolution]
            ```

4.  Update the firmware after verifying that the dry-run worked as expected.

    1.  Edit the JSON file and update the values so an actual firmware update can be run.

        The following example is for the chassisBMC.json file. Update the following values:

        ```bash
        "overrideDryrun":true,
        "description":"Update Cray Chassis Management Module controllers"
        ```

    2.  Run the firmware update.

        The returned `overrideDryrun = true` indicates that an actual firmware update job was created. A new `actionID` will also be returned.

        ```bash
        ncn# cray fas actions create chassisBMC.json
        overrideDryrun = true
        actionID = "bc40f10a-e50c-4178-9288-8234b336077b"
        ```

        The time it takes for a firmware update varies. It can be a few minutes or over 20 minutes depending on response time.

5.  Restart the `hms-discovery` cronjob.

    ```bash
    ncn# kubectl -n services patch cronjobs hms-discovery -p '{"spec" : {"suspend" : false }}'
    ```

    The `hms-discovery` cronjob will run within 5 minutes of being unsuspended and start powering on the chassis enclosures, switches, and compute blades. If components are not being powered back on, then power them on manually:

    ```bash
    ncn# cray capmc xname_on create --xnames x[1000-1003]c[0-7]r[0-7],x[1000-1003]c[0-7]s[0-7] --prereq true --continue true
    ```

    The `--prereq` option ensures all required components are powered on first. The `--continue` option allows the command to complete in systems without fully populated hardware.

6.  Bring up the Slingshot Fabric.
    Refer to the following documentation for more information on how to bring up the Slingshot Fabric:
    -  The *Slingshot Administration Guide* PDF for HPE Cray EX systems.
    -  The *Slingshot Troubleshooting Guide* PDF.

7.  After the components have powered on, boot the nodes using the Boot Orchestration Services \(BOS\).

---

<a name="aircooled"></a>

### Update Air-Cooled Compute Node BMC, BIOS, iLO 5, and System ROM

Gigabyte and HPE compute nodes firmware and BIOS can be updated with FAS.
This section includes templates for JSON files that can be used and the procedure for running the update.

All of the example JSON files below are set to run a dry-run. Update the overrideDryrun value to `true` to update the firmware.

After updating the BIOS or System ROM, the compute node will need to be rebooted before the new version will be displayed in the Redfish output.

This procedure updates the following hardware:
-   Node controller \(nC\) firmware


Procedure for updating NCNs:
1. For `HPE` NCNs, check the DNS servers by running the script `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H x3000c0s10b0 -s` (`x3000c0s10b0` is the component name (xname) of the NCN BMC)-
   See [Configure DNS and NTP on Each BMC](../../install/redeploy_pit_node.md#configure-dns-and-ntp-on-each-bmc)
2. Run a dryrun for all NCNs first to determine which NCNs and targets need updating.
3. For each NCN requiring updates to target `BMC` or `iLO5`
   (Update of `BMC` and `iLO 5` will not affect the nodes):
   1. Unlock the NCN BMC -
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md)
   2. Run the FAS action on the NCN
   3. Relock the NCN BMC -
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md)
4. For each NCN requiring updates to target `BIOS` or `System ROM`:
   1. Unlock the NCN BMC -
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md)
   2. Run the FAS action on the NCN
   3. Reboot the Node -
   See [Reboot NCNs](../node_management/Reboot_NCNs.md)
   4. For `HPE` NCNs, run the script `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh` -
   See [Configure DNS and NTP on Each BMC](../../install/redeploy_pit_node.md#configure-dns-and-ntp-on-each-bmc)
   5. Relock the NCN BMC -
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md)

#### Prerequisites
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.


#### Gigabyte

**Device Type: NodeBMC | Target: BMC**

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "gigabyte"
    },
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 4000,
    "description": "Dryrun upgrade of Gigabyte node BMCs"
  }
}
```

**IMPORTANT**: The *timeLimit* is `4000` because the Gigabytes can take a lot longer to update.

**Troubleshooting**:
 If a node failed to update with the output:
`stateHelper = "Firmware Update Information Returned Downloading – See /redfish/v1/UpdateService"`
FAS has incorrectly marked this node as failed.
It most likely will complete the update successfully.
To resolve this issue, do either of the following actions:
* Check the update status by looking at the Redfish `FirmwareInventory (/redfish/v1/UpdateService/FirmwareInventory/BMC)`
* RE-run FAS to verify that the BMC firmware was updated.
Make sure you have waited for the current firmware to be updated before starting a new FAS action on the same node.

**Device Type: NodeBMC | Target: BIOS**
```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "gigabyte"
    },
"targetFilter": {
    "targets": [
      "BIOS"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 4000,
    "description": "Dryrun upgrade of Gigabyte node BIOS"
  }
}
```

**IMPORTANT**: The *timeLimit* is `4000` because the Gigabytes can take a lot longer to update.

#### HPE

**Device Type: NodeBMC | Target: `iLO 5` aka BMC**

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "iLO 5"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node iLO 5"
  }
}
```

**Device Type: NodeBMC | Target: `System ROM` aka BIOS**

**IMPORTANT:** If updating the System ROM of an NCN, the NTP and DNS server values will be lost and must be restored. For NCNs **other than ncn-m001** this can be done using the `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh` script. Use the `-h` option to get a list of command line options required to restore the NTP and DNS values.
See [Configure DNS and NTP on Each BMC](../../install/redeploy_pit_node.md#configure-dns-and-ntp-on-each-bmc)

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "NodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "System ROM"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node system rom"
  }
}
```
#### Procedure

1.  Create a JSON file using one of the example recipes with the command parameters required for updating the firmware or node BIOS.

2.  Initiate a dry-run to verify that the firmware can be updated.

    1.  Create the dry-run session.

        The `overrideDryrun = false` value indicates that the command will do a dry run.

        ```bash
        ncn-w001# cray fas actions create nodeBMC.json
        overrideDryrun = false
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        ```

    2.  Describe the `actionID` for firmware update dry-run job.

        Replace the actionID value with the string returned in the previous step. In this example, `"fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"` is used.

        ```bash
        ncn-w001# cray fas actions describe {actionID}
        blockedBy = []
        state = "completed"
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        startTime = "2020-08-31 15:49:44.568271843 +0000 UTC"
        snapshotID = "00000000-0000-0000-0000-000000000000"
        endTime = "2020-08-31 15:51:35.426714612 +0000 UTC"

        [command]
        description = "Update of HPE Node iLO5"
        tag = "default"
        restoreNotPossibleOverride = true
        timeLimit = 10000
        version = "latest"
        overrideDryrun = false
        ```

        If `state = "completed"`, the dry-run has found and checked all the nodes. Check the following sections for more information:

        -   Lists the nodes that have a valid image for updating:

            ```bash
            [operationSummary.succeeded]
            ```

        -   Lists the nodes that will not be updated because they are already at the correct version:

            ```bash
            [operationSummary.noOperation]
            ```

        -   Lists the nodes that had an error when attempting to update:

            ```bash
            [operationSummary.failed]
            ```

        -   Lists the nodes that do not have a valid image for updating:

            ```bash
            [operationSummary.noSolution]
            ```

3.  Update the firmware after verifying that the dry-run worked as expected.

    1.  Edit the JSON file and update the values so an actual firmware update can be run.

        The following example is for the nodeBMC.json file. Update the following values:

        ```bash
        "overrideDryrun":true,
        "description":"Update of HPE node iLO 5"
        ```

    2.  Run the firmware update.

        The returned `overrideDryrun = true` indicates that an actual firmware update job was created. A new `actionID` will also be returned.

        ```bash
        ncn-w001# cray fas actions create nodeBMC.json
        overrideDryrun = true
        actionID = "bc40f10a-e50c-4178-9288-8234b336077b"
        ```

        The time it takes for a firmware action to finish varies. It can be a few minutes or over 20 minutes depending on response time.

        The air-cooled node BMC automatically reboots after the BMC or iLO 5 firmware has been loaded.

4.  Retrieve the operationID and verify that the update is complete.

    ```bash
    ncn-w001# cray fas actions describe {actionID}
    [operationSummary.failed]
    [[operationSummary.failed.operationKeys]]
    stateHelper = "unexpected change detected in firmware version. Expected 2.46 May 11 2021 got: 2.32 Apr 27 2020"
    fromFirmwareVersion = "2.32 Apr 27 2020"
    xname = "x1005c6s4b0"
    target = "iLO 5"
    operationID = "e910c6ad-db98-44fc-bdc5-90477b23386f"
    ```

5.  View more details for an operation using the operationID from the previous step.

    Check the list of nodes for the `failed` or `completed` state.

    ```bash
    ncn-w001# cray fas operations describe {operationID}
    ```

    For example:

    ```bash
    ncn-w001# cray fas operations describe "e910c6ad-db98-44fc-bdc5-90477b23386f"
    fromFirmwareVersion = "2.32 Apr 27 2020"
    fromTag = ""
    fromImageURL = ""
    endTime = "2020-08-31 16:40:13.464321212 +0000 UTC"
    actionID = "bc40f10a-e50c-4178-9288-8234b336077b"
    startTime = "2020-08-31 16:28:01.228524446 +0000 UTC"
    fromSemanticFirmwareVersion = ""
    toImageURL = ""
    model = "ProLiant DL325 Gen10 Plus"
    operationID = "e910c6ad-db98-44fc-bdc5-90477b23386f"
    fromImageID = "00000000-0000-0000-0000-000000000000"
    target = "iLO 5"
    toImageID = "39c0e553-281d-4776-b68e-c46a2993485e"
    toSemanticFirmwareVersion = "2.46.0"
    refreshTime = "2020-08-31 16:40:13.464325422 +0000 UTC"
    blockedBy = []
    toTag = ""
    state = "failed"
    stateHelper = "unexpected change detected in firmware version. Expected 2.46 May 11 2021 got: 2.32 Apr 27 2020"
    deviceType = "NodeBMC"
    ```

---

<a name="ncn-bios-bmc"></a>

### Update Non-Compute Node (NCN) BIOS and BMC Firmware

Gigabyte and HPE non-compute nodes \(NCNs\) firmware can be updated with FAS. This section includes templates for JSON files that can be used to update firmware with the `cray fas actions create` command.

After creating the JSON file for the device being upgraded, use the following command to run the FAS job:

```bash
ncn-w001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
```

All of the example JSON files below are set to run a dry-run. Update the overrideDryrun value to True to update the firmware.

**WARNING:** Rebooting more than one NCN at a time **MAY** cause system instability. Be sure to follow the correct process for updating NCNs. Firmware updates have the capacity to harm the system.

After updating the BIOS, the NCN will need to be rebooted. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure.

Due to networking, FAS cannot update `ncn-m001`.  See [Updating Firmware on m001](Updating_Firmware_m001.md)

#### Gigabyte

**Device Type: NodeBMC | Target: BMC**

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "gigabyte"
    },
"targetFilter": {
    "targets": [
      "BMC"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 4000,
    "description": "Dryrun upgrade of Gigabyte node BMCs"
  }
}
```

**IMPORTANT**: The *timeLimit* is `4000` because the Gigabytes can take a lot longer to update.

You may receive a node failed to update with the output:
`stateHelper = "Firmware Update Information Returned Downloading – See /redfish/v1/UpdateService"`
FAS has incorrectly marked this node as failed.
It most likely will complete the update successfully.
You can check the update status by looking at the Redfish `FirmwareInventory (/redfish/v1/UpdateService/FirmwareInventory/BMC)`
or rerunning FAS to verify that the BMC firmware was updated.
Make sure you have waited for the current firmware to be updated before starting a new FAS action on the same node.

**Device Type: NodeBMC | Target: BIOS**
```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "gigabyte"
    },
"targetFilter": {
    "targets": [
      "BIOS"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 4000,
    "description": "Dryrun upgrade of Gigabyte node BIOS"
  }
}
```

**IMPORTANT**: The *timeLimit* is `4000` because the Gigabytes can take a lot longer to update.

#### HPE

**Device Type: NodeBMC | Target: `iLO 5` aka BMC**

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "iLO 5"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node iLO 5"
  }
}
```

**Device Type: NodeBMC | Target: `System ROM` aka BIOS**

**IMPORTANT:** If updating the System ROM of an NCN, the NTP and DNS server values will be lost and must be restored. For NCNs **other than ncn-m001** this can be done using the `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh` script. Use the `-h` option to get a list of command line options required to restore the NTP and DNS values.
See [Configure DNS and NTP on Each BMC](../../install/redeploy_pit_node.md#configure-dns-and-ntp-on-each-bmc).

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "NodeBMC"
    ],
    "xnames": [
      "x3000c0s1b0"
    ]
},
"inventoryHardwareFilter": {
    "manufacturer": "hpe"
    },
"targetFilter": {
    "targets": [
      "System ROM"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of HPE node system rom"
  }
}
```

The NCN must be rebooted after updating the BIOS firmware. Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) procedure.

#### Procedure for updating NCNs:
1. For `HPE` NCNs, check the DNS servers by running the script `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh ilo -H XNAME -s`.  Replace `XNAME` with the xname of the NCN BMC.
   See [Configure DNS and NTP on Each BMC](../../install/redeploy_pit_node.md#configure-dns-and-ntp-on-each-bmc) for more information.
2. Run a dryrun for all NCNs first to determine which NCNs and targets need updating.
3. For each NCN requiring updates to target `BMC` or `iLO 5`:
   **NOTE:** Update of `BMC` and `iLO 5` will not affect the nodes.
   1. Unlock the NCN BMC.
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md).
   2. Run the FAS action on the NCN.
   3. Relock the NCN BMC.
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md).
4. For each NCN requiring updates to target `BIOS` or `System ROM`:
   1. Unlock the NCN BMC.
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md).
   2. Run the FAS action on the NCN.
   3. Reboot the Node.
   See [Reboot NCNs](../node_management/Reboot_NCNs.md).
   4. For `HPE` NCNs, run the script `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh`.
   See [Configure DNS and NTP on Each BMC](../../install/redeploy_pit_node.md#configure-dns-and-ntp-on-each-bmc).
   5. Relock the NCN BMC.
See [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md).

---

<a name="cn-workaround"></a>

### Compute Node BIOS Workaround for HPE CRAY EX425

Correct an issue where the model of the liquid-cooled compute node BIOS is the incorrect name. The name has changed from `WNC-ROME` to `HPE CRAY EX425` or `HPE CRAY EX425 (ROME)`.

#### Prerequisites
-   The system is running HPE Cray EX release v1.4 or higher.
-   The system has completed the Cray System Management \(CSM\) installation.
-   A firmware upgrade has been done following [Update Liquid-Cooled Compute Node BIOS Firmware](#cn-bios).
    -   The result of the upgrade is that the `NodeX.BIOS` has failed as `noSolution` and the `stateHelper` field for the operation states: `"No Image Available"`.
    -   The BIOS in question is running a version less than or equal to `1.2.5` as reported by Redfish or described by the `noSolution` operation in FAS.
-   The hardware model reported by Redfish is `wnc-rome`, which is now designated as `HPE CRAY EX425`.

    If the Redfish model is different \(ignoring casing\) and the blades in question are not `Windom`, contact customer support. To find the model reported by Redfish:

    ```bash
    ncn# cray fas operations describe {operationID} --format json
    {
       "operationID":"102c949f-e662-4019-bc04-9e4b433ab45e",
       "actionID":"9088f9a2-953a-498d-8266-e2013ba2d15d",
       "state":"noSolution",
       "stateHelper":"No Image available",
       "startTime":"2021-03-08 13:13:14.688500503 +0000 UTC",
       "endTime":"2021-03-08 13:13:14.688508333 +0000 UTC",
       "refreshTime":"2021-03-08 13:13:14.722345901 +0000 UTC",
       "expirationTime":"2021-03-08 15:59:54.688500753 +0000 UTC",
       "xname":"x9000c1s0b0",
       "deviceType":"NodeBMC",
       "target":"Node1.BIOS",
       "targetName":"Node1.BIOS",
       "manufacturer":"cray",
       "model":"WNC-Rome",
       "softwareId":"",
       "fromImageID":"00000000-0000-0000-0000-000000000000",
       "fromSemanticFirmwareVersion":"",
       "fromFirmwareVersion":"wnc.bios-1.2.5",
       "fromImageURL":"",
       "fromTag":"",
       "toImageID":"00000000-0000-0000-0000-000000000000",
       "toSemanticFirmwareVersion":"",
       "toFirmwareVersion":"",
       "toImageURL":"",
       "toTag":"",
       "blockedBy":[

       ]
    }
    ```

    The model in this example is `WNC-Rome` and the firmware version currently running is `wnc.bios-1.2.5`.

#### Procedure

1. Search for a FAS image record with `cray` as the manufacturer, `Node1.BIOS` as the target, and `HPE CRAY EX425` as the model.

   ```bash
   ncn# cray fas images list --format json | jq '.images[] | select(.manufacturer=="cray") \
   | select(.target=="Node1.BIOS") | select(any(.models[]; contains("EX425")))'
   {
       "imageID": "e23f5465-ed29-4b18-9389-f8cf0580ca60",
       "createTime": "2021-03-04T00:04:05Z",
       "deviceType": "nodeBMC",
       "manufacturer": "cray",
       "models": [
         "HPE CRAY EX425"
       ],
       "softwareIds": [
         "bios.ex425.."
       ],
       "target": "Node1.BIOS",
       "tags": [
         "default"
       ],
       "firmwareVersion": "ex425.bios-1.4.3",
       "semanticFirmwareVersion": "1.4.3",
       "pollingSpeedSeconds": 30,
       "s3URL": "s3:/fw-update/2227040f7c7d11eb9fa00e2f2e08fd5d/ex425.bios-1.4.3.tar.gz"
     }
   ```

     Take note of the returned imageID value to use in the next step.

2. Create a JSON file to override the existing image with the corrected values.

   **IMPORTANT:** The `imageID` must be changed to match the identified image ID in the previous step.

   ```json
   {
      "stateComponentFilter":{
         "deviceTypes":[
            "nodeBMC"
         ]
      },
      "inventoryHardwareFilter":{
         "manufacturer":"cray"
      },
      "targetFilter":{
         "targets":[
            "Node0.BIOS",
            "Node1.BIOS"
         ]
      },
      "imageFilter":{
         "imageID":"e23f5465-ed29-4b18-9389-f8cf0580ca60",
         "overrideImage":true
      },
      "command":{
         "version":"latest",
         "tag":"default",
         "overrideDryrun":true,
         "restoreNotPossibleOverride":true,
         "timeLimit":1000,
         "description":" upgrade of Node BIOS"
      }
   }
   ```

3. Run a firmware upgrade using the updated parameters defined in the new JSON file.

   ```bash
   ncn# cray fas actions create UPDATED_COMMAND.json
   ```

4. Get a high-level summary of the job to verify the changes corrected the issue.

   Use the returned actionID from the `cray fas actions create` command.
   ```bash
   ncn# cray fas actions create UPDATED_COMMAND.json
   ```
