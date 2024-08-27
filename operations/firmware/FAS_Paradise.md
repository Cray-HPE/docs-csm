# Updating Foxconn Paradise Nodes with FAS

Use the Firmware Action Service (FAS) to update the firmware on Foxconn Paradise devices. Each procedure includes the prerequisites and example recipes required to update the firmware.

**NOTE:** Any node that is locked remains in the state `inProgress` with the `stateHelper` message of `"failed to lock"` until the action times out, or the lock is released.
If the action is timed out, these nodes report as `failed` with the `stateHelper` message of `"time expired; could not complete update"`.
This includes NCNs which are manually locked to prevent accidental rebooting and firmware updates.

Refer to [FAS Filters](FAS_Filters.md) for more information on the content used in the example JSON files.

The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to perform default updates to firmware and BIOS.

## Prerequisites

* The Cray command line interface \(CLI\) tool is initialized and configured on the system.
See [Configure the Cray CLI](../configure_cray_cli.md).
* The firmware images are loaded into S3 and to the TFTP server.
See [Upload Paradise images to TFTP server](#upload-paradise-images-to-tftp-server)

The following targets can be updated with FAS on Paradise Nodes:

1. [`bmc_active`](#update-paradise-bmc_active-procedure)
1. [`bios_active`](#update-paradise-bios_active-procedure)
1. [`erot_active`](#update-paradise-erot_active-procedure)
1. [`fpga_active`](#update-paradise-fpga_active-procedure)
1. [`pld_active`](#update-paradise-pld_active-procedure)

## Update Paradise `bmc_active` procedure

NOTE: If a reset of the BMC is required, follow [this procedure](#reset-bmc) before and after the update of each node.  *Only do this if required!*

The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to update `bmc_active` - use recipe `foxconn_nodeBMC_bmc.json`

The BMC will reboot after the update is complete.

To update using a JSON file and the Cray CLI, use this example JSON file and follow the [Updating Paradise Firmware with JSON and the Cray CLI Procedure](#update-paradise-firmware-using-json-file-and-cray-cli)

```json
{
"stateComponentFilter": {
    "deviceTypes": [ "nodeBMC" ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "foxconn"
    },
"targetFilter": {
    "targets": [ "bmc_active" ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Foxconn bmc_active"
  }
}
```

**IMPORTANT:** There is a known bug that causes the hmcollector-poll service to lose event subscriptions
after BMC firmware is updated.  After updating BMC firmware, the hmcollector service must be restarted to
work around this issue.  After the update is complete, and you confirm the BMC has been rebooted, restart
the hmcollector-poll service with this command:

```bash
kubectl -n services rollout restart deployment cray-hms-hmcollector-poll
```

## Update Paradise `bios_active` procedure

The nodes must be **OFF** before updating the BIOS

**IMPORTANT:** After the update has completed, the nodes must be turned on and **REMAIN ON FOR AT LEAST 6 MINUTES**  

**NOTE:** The version number reported by Redfish will NOT be updated until the node has fully booted.

The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to update `bios_active` - use recipe `foxconn_nodeBMC_bios.json`

To update using a JSON file and the Cray CLI, use this example JSON file and follow the [Updating Paradise Firmware with JSON and the Cray CLI Procedure](#update-paradise-firmware-using-json-file-and-cray-cli)

```json
{
"stateComponentFilter": {
    "deviceTypes": [ "nodeBMC" ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "foxconn"
    },
"targetFilter": {
    "targets": [ "bios_active" ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Foxconn bios_active"
  }
}
```

## Update Paradise `erot_active` procedure

**NOTE:** After update of `erot_active` an AC power cycle is required for update to take affect.
To do an AC power cycle, run the following command (`ncn#`).

```bash
ssh admin@$(xname) "ipmitool raw 0x38 0x02"
```

The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to update `erot_active` - use recipe `foxconn_nodeBMC_erot.json`

To update using a JSON file and the Cray CLI, use this example JSON file and follow the [Updating Paradise Firmware with JSON and the Cray CLI Procedure](#update-paradise-firmware-using-json-file-and-cray-cli)

```json
{
"stateComponentFilter": {
    "deviceTypes": [ "nodeBMC" ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "foxconn"
    },
"targetFilter": {
    "targets": [ "erot_active" ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Foxconn bios_active"
  }
}
```

## Update Paradise `fpga_active` procedure

**NOTE:** After update of `fpga_active` an AC power cycle is required for update to take affect.
To do an AC power cycle, run the following command (`ncn#`).

```bash
ssh admin@$(xname) "ipmitool raw 0x38 0x02"
```

The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to update `fpga_active` - use recipe `foxconn_nodeBMC_fpga.json`

To update using a JSON file and the Cray CLI, use this example JSON file and follow the [Updating Paradise Firmware with JSON and the Cray CLI Procedure](#update-paradise-firmware-using-json-file-and-cray-cli)

```json
{
"stateComponentFilter": {
    "deviceTypes": [ "nodeBMC" ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "foxconn"
    },
"targetFilter": {
    "targets": [
        "fpga_active"
    ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Foxconn bios_active"
  }
}
```

## Update Paradise `pld_active` procedure

**IMPORTANT:** The update of the target `pld_active` should only be applied to blade 1 (i.e. `x3000c0s3b1`) - applying to other blades at the same time may cause issues.  To use the `FASUpdate.py script`, use the `--xnames` flag to specify `b1`.

The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to update `pld_active` - use recipe `foxconn_nodeBMC_pld.json`

To update using a JSON file and the Cray CLI, use this example JSON file and follow the [Updating Paradise Firmware with JSON and the Cray CLI Procedure](#update-paradise-firmware-using-json-file-and-cray-cli)

```json
{
"stateComponentFilter": {
    "xnames": [ "x3000c0s3b1" ],
    "deviceTypes": [ "nodeBMC" ]
  },
"inventoryHardwareFilter": {
    "manufacturer": "foxconn"
    },
"targetFilter": {
    "targets": [ "pld_active" ]
  },
"command": {
    "version": "latest",
    "tag": "default",
    "overrideDryrun": false,
    "restoreNotPossibleOverride": true,
    "timeLimit": 1000,
    "description": "Dryrun upgrade of Foxconn bios_active"
  }
}
```

## Update Paradise firmware using JSON file and Cray CLI

**NOTE:** The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to perform default updates to firmware and BIOS.

1. Create a JSON file using the example recipe.

1. Initiate a dry-run to verify the firmware that will be updated and the version it will update to.

    1. (`ncn#`) Create the dry-run session.

        The `overrideDryrun = false` value indicates that the command will do a dry run.

        ```bash
        cray fas actions create nodeBMC.json --format toml
        ```

        Example output:

        ```toml
        overrideDryrun = false
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        ```

    1. (`ncn#`) Describe the `actionID` for firmware update dry-run job.

        Replace the `actionID` value with the string returned in the previous step. In this example, `"fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"` is used.

        ```bash
        cray fas actions describe {actionID} --format toml
        ```

        Example output:

        ```toml
        blockedBy = []
        state = "completed"
        actionID = "fddd0025-f5ff-4f59-9e73-1ca2ef2a432d"
        startTime = "2020-08-31 15:49:44.568271843 +0000 UTC"
        snapshotID = "00000000-0000-0000-0000-000000000000"
        endTime = "2020-08-31 15:51:35.426714612 +0000 UTC"

        [command]
        description = "Update Foxconn Node BMCs Dryrun"
        tag = "default"
        restoreNotPossibleOverride = true
        timeLimit = 10000
        version = "latest"
        overrideDryrun = false
        ```

        If `state = "completed"`, the dry-run has found and checked all the nodes. Check the following sections for more information:

        * Lists the nodes that have a valid image for updating:

            ```toml
            [operationSummary.succeeded]
            ```

        * Lists the nodes that will not be updated because they are already at the correct version:

            ```toml
            [operationSummary.noOperation]
            ```

        * Lists the nodes that had an error when attempting to update:

            ```toml
            [operationSummary.failed]
            ```

        * Lists the nodes that do not have a valid image for updating:

            ```toml
            [operationSummary.noSolution]
            ```

1. Update the firmware after verifying that the dry-run worked as expected.

    1. Edit the JSON file and update the values so an actual firmware update can be run.

        The following example is for the `nodeBMC.json` file. Update the following values:

        ```json
        "overrideDryrun":true,
        "description":"Update Foxconn Node BMCs"
        ```

    1. (`ncn#`) Run the firmware update.

        The output `overrideDryrun = true` indicates that an actual firmware update job was created. A new `actionID` will also be displayed.

        ```bash
        cray fas actions create nodeBMC.json --format toml
        ```

        Example output:

        ```toml
        overrideDryrun = true
        actionID = "bc40f10a-e50c-4178-9288-8234b336077b"
        ```

        The time it takes for a firmware action to finish varies. It can be a few minutes or over 20 minutes.

        The BMC automatically reboots after the BMC firmware has been loaded.

1. Retrieve the `operationID` and verify that the update is complete.

    ```bash
    cray fas actions describe {actionID} --format toml
    ```

    Example output:

    ```toml
    [operationSummary.failed]
    [[operationSummary.failed.operationKeys]]
    stateHelper = "unexpected change detected in firmware version. Expected nc.1.3.10-shasta-release.arm.2020-07-21T23:58:22+00:00.d479f59 got: nc.cronomatic-dev.arm.2019-09-24T13:20:24+00:00.9d0f8280"
    fromFirmwareVersion = "nc.cronomatic-dev.arm.2019-09-24T13:20:24+00:00.9d0f8280"
    xname = "x1005c6s4b0"
    target = "BMC"
    operationID = "e910c6ad-db98-44fc-bdc5-90477b23386f"
    ```

1. (`ncn#`) View more details for an operation using the `operationID` from the previous step.

    Check the list of nodes for the `failed` or `completed` state.

    ```bash
    cray fas operations describe {operationID}
    ```

    For example:

    ```bash
    cray fas operations describe "e910c6ad-db98-44fc-bdc5-90477b23386f" --format toml
    ```

    Example output:

    ```toml
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

    Once the firmware and BIOS are updated, the compute nodes can be powered back on.

    If the nodes have never been powered on in the system before (they are being added during a hardware add procedure), then use the Boot Orchestration Service (BOS) to power them on.
    Using BOS will prepare the initial boot artifacts required to boot them.  If this is not the first time they have been powered on in this system, then you can use the Power Control Service \(PCS\) to power them on.

## Upload Paradise images to TFTP server

(`ncn#`) To check if a firmware is uploaded to the TFTP server:

```bash
kubectl -n services exec -it `kubectl get pods -n services -l app.kubernetes.io/instance=cms-ipxe -o custom-columns=NS:.metadata.name --no-headers | head -1` -- ls /shared_tftp
```

If the firmware file you need is not listed, run the following command to copy the file from S3 to the TFTP server (`ncn#`)

```bash
/usr/share/doc/csm/scripts/operations/firmware/upload_foxconn_images_tftp.py
```

## Reset BMC

This will reset the BMC to factory resets - including resetting the BMC username and password.
*Only do this if required!*

Before BMC firmware update (`ncn#`):

The nodes must be **OFF** before updating BMC (when doing a reset)

```bash
ssh admin@$(xname) 'fw_setenv openbmconce "factory-reset"'
```

**Update BMC firmware using one of the methods above**
NOTE: If the password changes after the boot of BMC, FAS will no longer be able to verify the update and will fail after the time limit.

After firmware update(`ncn#`):

If the password changed to something other than the what is stored in vault, update the BMC password:

```bash
ssh admin@$(xname) 'ipmitool user set password 1 "password"'
```

Boot the node.
