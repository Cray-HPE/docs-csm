# FAS Admin Procedures

Procedures for leveraging the Firmware Action Service (FAS) CLI to manage firmware.

**NEW**: The [`FASUpdate.py script`](FASUpdate_Script.md) can be used to perform default updates to firmware and BIOS.

## Topics

* [Warning for non-compute nodes (NCNs)](#warning-for-non-compute-nodes-ncns)
* [Declarative vs imperative FAS updates](#declarative-vs-imperative-fas-updates)
* [Exclude nodes from an update](#exclude-nodes-from-an-update)
* [Ignore management nodes within FAS](#ignore-management-nodes-within-fas)
* [Override an image for an update](#override-an-image-for-an-update)
* [Check for new firmware versions with a dry-run](#check-for-new-firmware-versions-with-a-dry-run)
* [Load firmware from Nexus](#load-firmware-from-nexus)
* [Load firmware from RPM or ZIP file](#load-firmware-from-rpm-or-zip-file)

---

## Warning for non-compute nodes (NCNs)

NCNs and their BMCs must be locked with the HSM locking API to ensure they are not unintentionally updated by FAS.
Research [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md) for more information.
Failure to lock the NCNs could result in unintentional update of the NCNs if FAS is not used correctly; this will lead to system instability problems.

**NOTE**: Any node that is locked remains in the state `inProgress` with the `stateHelper` message of `"failed to lock"` until the action times out, or the lock is released.
If the action is timed out, these nodes report as `failed` with the `stateHelper` message of `"time expired; could not complete update"`.
This includes NCNs which are manually locked to prevent accidental rebooting and firmware updates.

---

## Declarative vs imperative FAS updates

In most cases, FAS will update firmware on each node to the required version.
This version is determined by comparing the `semantic versions` for all valid images for each node and selecting the highest value.
Sometimes however, a different version is required for updating a node.
FAS can update a node to any uploaded version using the [Override an Image for an Update](#override-an-image-for-an-update) procedure.
If the required image is not installed, obtain the RPM or ZIP file and use the [Load Firmware from RPM or ZIP file](#load-firmware-from-rpm-or-zip-file) procedure.

---

## Exclude nodes from an update

The default behavior for FAS to update every node in the system that fits the specified action filters.

To exclude one or more nodes the following options are available:

1. Lock the nodes you do not want to update using the Hardware State Manager (HSM).
   Refer to [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md) for more information.
   Make sure to unlock these nodes once the update is complete.

1. Use the `xname` filter to only include the nodes that you wish to update.  **NOTE** When using FAS, the xname refers to the BMC, not the node.
   See [`stateComponentFilter`](FAS_Filters.md#statecomponentfilter) for more information.

## Ignore management nodes within FAS

The default configuration of FAS no longer ignores `management` nodes, which prevents FAS from firmware updating the NCNs.
To reconfigure the FAS deployment to exclude non-compute nodes (NCNs) and ensure they cannot have their firmware upgraded, the `NODE_BLACKLIST` value must be manually enabled

**Preferred Method:** Nodes can also be locked with the Hardware State Manager (HSM) API.
Refer to [Lock and Unlock Management Nodes](../hardware_state_manager/Lock_and_Unlock_Management_Nodes.md) for more information.

### Procedure to ignore management nodes

1. (`ncn-mw#`) Check that there are no FAS actions running.

    ```bash
    cray fas actions list
    ```

1. (`ncn-mw#`) Edit the `cray-fas` deployment.

    ```bash
    kubectl -n services edit deployment cray-fas
    ```

1. Change the `NODE_BLACKLIST` value from `ignore_ignore_ignore` to `management`.

1. Save and quit the deployment. This will restart FAS.

---

## Override an image for an update

In order to update to a firmware image other than the latest image found by FAS, the image for the update can be overridden.
This is also useful if an update fails because of `"No Image available"`, which happens when FAS is unable to match the data on the node to an image in the image list.

> **WARNING:** Make sure to select the correct image because FAS will force a flash of the device -- using incorrect firmware may make it inoperable.

It is strongly recommended to do a dryrun first and check the output.

### Procedure to override an image

1. (`ncn-mw#`) Find the available image in FAS.

   Change `TARGETNAME` to the actual target being searched.

   ```bash
   cray fas images list --format json | jq '.[] | .[] | select(.target=="TARGETNAME")'
   ```

   To narrow down the selection, update the select field to match multiple items. For example:

   ```bash
   cray fas images list --format json | jq '.[] | .[] | select(.target=="BMC" and .manufacturer=="cray" and .deviceType=="NodeBMC")'
   ```

   The example command displays one or more images available for updates.

   ```json
   {
         "imageID": "ff268e8a-8f73-414f-a9c7-737a34bb02fc",
         "createTime": "2021-02-24T02:25:03Z",
         "deviceType": "nodeBMC",
         "manufacturer": "cray",
         "models": [
           "HPE Cray EX235n",
           "GrizzlyPkNodeCard_REV_B"
         ],
         "softwareIds": [
           "fgpa:NVIDIA.HGX.A100.4.GPU:*:*"
         ],
         "target": "Node0.AccFPGA0",
         "tags": [
           "default"
         ],
         "firmwareVersion": "2.7",
         "semanticFirmwareVersion": "2.7.0",
         "pollingSpeedSeconds": 30,
         "s3URL": "s3:/fw-update/80a62641764711ebabe28e2b78a05899/accfpga_nvidia_2.7.tar.gz"
   }
   ```

   If the `firmwareVersion` from the FAS image matches the `fromFirmwareVersion` from the FAS action, the firmware is at the latest version and no update is needed.

1. Use the `imageID` from the `cray images list` in the previous step and add the following line to the action JSON file.

   Replace `IMAGEID` with the actual `imageID` value.
   In this example, the value would be: `ff268e8a-8f73-414f-a9c7-737a34bb02fc`.

   ```json
       "imageFilter": {
         "imageID":"IMAGEID",
         "overrideImage":true
       }
   ```

   Example actions JSON file with `imageFilter` added:

   ```json
       {
         "stateComponentFilter": {
           "deviceTypes":["nodeBMC"]
         },
         "inventoryHardwareFilter": {
           "manufacturer":"cray"
         },
         "imageFilter": {
           "imageID":"ff268e8a-8f73-414f-a9c7-737a34bb02fc",
           "overrideImage":true
         },
         "targetFilter": {
           "targets":["Node0.AccFPGA0","Node1.AccFPGA0"]
         },
         "command": {
           "overrideDryrun":false,
           "restoreNotPossibleOverride":true,
           "overwriteSameImage":false
         }
       }
   ```

1. (`ncn-mw#`) Verify that the correct image ID was found.

   ```bash
   cray fas images describe {imageID}
   ```

   > **WARNING:** FAS will force a flash of the device -- using incorrect firmware may make it inoperable.

Re-run the FAS actions command using the updated JSON file. **It is strongly recommended to run a dry-run (`overrideDryrun=false`) first and check the actions output.**

---

## Check for new firmware versions with a dry-run

Use the Firmware Action Service \(FAS\) dry-run feature to determine what firmware can be updated on the system.
Dry-runs are enabled by default, and can be configured with the `overrideDryrun` parameter.
A dry-run will create a query according to the filters requested by the administrator.
It will initiate an update sequence to determine what firmware is available, but will not actually change the state of the firmware.

> **WARNING:** It is crucial that an administrator is familiar with the release notes of any firmware.
> The release notes will indicate what new features the firmware provides and if there are any incompatibilities.
> FAS does not know about incompatibilities or dependencies between versions. The administrator assumes full responsibility for this knowledge.

It is likely that when performing a firmware update, that the current version of firmware will not be available.
This means that after successfully upgrading, the firmware cannot be downgraded.

This procedure includes information on how check the firmware versions for the entire system,
as well as how to target specific manufacturers, component names (xnames), and targets.

### Procedure to check for new firmware versions

1. (`ncn-mw#`) Run a dry-run firmware update.

   The following command parameters should be included in dry-run JSON files:

   * `overrideDryrun`: The `overrideDryrun` parameter is set to `false` by default. FAS will only update the system if this is parameter is set to `true`.
   * `restoreNotPossibleOverride`: FAS will not perform an update if the currently running firmware is not available in the images repository.
   Set this parameter to `true` in order to allow FAS to update firmware even if the current firmware is unavailable on the system.
   * `description`: A brief description that helps administrators distinguish between actions.
   * `version`: Determines if the firmware should be set to the `latest`, the `earliest` semantic version, or set to a specific firmware version.

   Use one of the options below to run on a dry-run on every system device or on targeted devices:

   * **Option 1:** Determine the available firmware for every device on the system:

      1. Create a JSON file for the command parameters.

         ```json
         {
           "command": {
             "restoreNotPossibleOverride": true,
             "timeLimit": 1000,
             "description": "full system dryrun 2020623_0"
           }
         }
         ```

      1. Run the dry-run for the full system.

         ```bash
         cray fas actions create COMMAND.json
         ```

      1. Proceed to the next step to determine if any firmware needs to be updated.

   * **Option 2:** Determine the available firmware for specific devices:

      1. Create a JSON file with the specific device information to target when doing a dry-run.

         ```json
         {
         "stateComponentFilter": {
             "xnames": [
               "x9000c1s3b1"
             ]
           },
         "inventoryHardwareFilter": {
             "manufacturer": "cray"
             },
         "targetFilter": {
             "targets": [
                "Node1.BIOS",
                "Node0.BIOS"
             ]
           },
         "command": {
             "version": "latest",
             "tag": "default",
             "overrideDryrun": false,
             "restoreNotPossibleOverride": true,
             "timeLimit": 1000,
             "description": "dryrun upgrade of x9000c1s3b1 Nodex.BIOS to WNC 1.1.2"
           }
         }
         ```

      1. Run a dry-run on the targeted devices.

         ```bash
         cray fas actions create CUSTOM_DEVICE_PARAMETERS.json
         ```

      1. Proceed to the next step to determine if any firmware needs to be updated.

1. (`ncn-mw#`) View the status of the dry-run to determine if any firmware updates can be made.

   The following returned messages will help determine if a firmware update is needed.

   * `noOperation`: Nothing to do; already at the requested version.
   * `noSolution`: No image is available or data is missing.
   * `succeeded`: A firmware version that FAS can update the firmware to is available and it should work when actually updating the firmware.
   * `failed`: There is something that FAS could do, but it likely would fail (most likely because the file is missing).

   1. Get a high-level summary of the FAS job to determine if there are any upgradable firmware images available.

      Use the returned `actionID` from the `cray fas actions create` command.

      In the example below, there are two operations in the `succeeded` state, indicating there is an available firmware version that FAS can use to update firmware.

      ```bash
      cray fas actions status list {actionID} --format toml
      ```

      Example output:

      ```toml
      actionID = "e6dc14cd-5e12-4d36-a97b-0dd372b0930f"
      snapshotID = "00000000-0000-0000-0000-000000000000"
      startTime = "2021-09-07 16:43:04.294233199 +0000 UTC"
      endTime = "2021-09-07 16:53:09.363233482 +0000 UTC"
      state = "completed"
      blockedBy = []

      [command]
      overrideDryrun = false
      restoreNotPossibleOverride = true
      overwriteSameImage = false
      timeLimit = 2000
      version = "latest"
      tag = "default"
      description = "Dryrun upgrade of Gigabyte node BMCs"

      [operationCounts]
      total = 14
      initial = 0
      configured = 0
      blocked = 0
      needsVerified = 0
      verifying = 0
      inProgress = 0
      failed = 0
      succeeded = 8
      noOperation = 6
      noSolution = 0
      aborted = 0
      unknown = 0
      ```

      The action is still in progress if the state field is not completed or aborted.

   1. View the details of an action to get more information on each operation in the FAS action.

      In the example below, there is an operation for a component name (xname) in the failed state, indicating there is something that FAS could do, but it likely would fail.
      A common cause for an operation failing is due to a missing firmware image file.

      ```bash
      cray fas actions describe {actionID} --format json
      ```

      Example output:

      ```json
      {
            "parameters": {
              "stateComponentFilter": {
                "deviceTypes": [
                  "nodeBMC"
                ]
              },
              "command": {
                "dryrun": false,
                "description": "upgrade of nodeBMCs for cray",
                "tag": "default",
                "restoreNotPossibleOverride": true,
                "timeLimit": 1000,
                "version": "latest"
              },
              "inventoryHardwareFilter": {
                "manufacturer": "cray"
              },
              "imageFilter": {
                "imageID": "00000000-0000-0000-0000-000000000000"
              },
              "targetFilter": {
                "targets": [
                  "BMC"
                ]
              }
            },
            "blockedBy": [],
            "state": "completed",
            "command": {
              "dryrun": false,
              "description": "upgrade of nodeBMCs for cray",
              "tag": "default",
              "restoreNotPossibleOverride": true,
              "timeLimit": 1000,
              "version": "latest"
            },
            "actionID": "e0cdd7c2-32b1-4a25-9b2a-8e74217eafa7",
            "startTime": "2020-06-26 20:03:37.316932354 +0000 UTC",
            "snapshotID": "00000000-0000-0000-0000-000000000000",
            "endTime": "2020-06-26 20:04:07.118243184 +0000 UTC",
            "operationSummary": {
              "succeeded": {
                "OperationsKeys": []
              },
              "verifying": {
                "OperationsKeys": []
              },
              "unknown": {
                "OperationsKeys": []
              },
              "configured": {
                "OperationsKeys": []
              },
              "initial": {
                "OperationsKeys": []
              },
              "failed": {
                "OperationsKeys": [
                  {
                    "stateHelper": "unexpected change detected in firmware version. Expected sc.1.4.35-prod- master.arm64.2020-06-26T08:36:42+00:00.0c2bb02 got: sc.1.3.307-prod-master.arm64.2020-06-13T00:28:26+00:00.f91edff",
                    "fromFirmwareVersion": "",
                    "xname": "x5000c1r7b0",
                    "target": "BMC",
                    "operationID": "0796eed0-e95d-45ea-bc71-8903d52cffde"
                  },
                ]
              },
              "noSolution": {
                "OperationsKeys": []
              },
              "aborted": {
                "OperationsKeys": []
              },
              "needsVerified": {
                "OperationsKeys": []
              },
              "noOperation": {
                "OperationsKeys": []
              },
              "inProgress": {
                "OperationsKeys": []
              },
              "blocked": {
                "OperationsKeys": []
              }
            }
          }
      ```

1. (`ncn-mw#`) View the details for a specific operation.

   In this example, there is a device that is available for a firmware upgrade because the operation being viewed is a succeeded operation.

   ```bash
   cray fas operations describe {operationID} --format json
   ```

   Example output:

   ```json
   {
      "fromFirmwareVersion": "", "fromTag": "",
      "fromImageURL": "",
      "endTime": "2020-06-24 14:23:37.544814197 +0000 UTC",
      "actionID": "f48aabf1-1616-49ae-9761-a11edb38684d", "startTime": "2020-06-24 14:19:15.10128214 +0000 UTC",
      "fromSemanticFirmwareVersion": "", "toImageURL": "",
      "model": "WindomNodeCard_REV_D",
      "operationID": "24a5e5fb-5c4f-4848-bf4e-b071719c1850", "fromImageID": "00000000-0000-0000-0000-000000000000",
      "target": "BMC",
      "toImageID": "71c41a74-ab84-45b2-95bd-677f763af168", "toSemanticFirmwareVersion": "",
      "refreshTime": "2020-06-24 14:23:37.544824938 +0000 UTC",
      "blockedBy": [],
      "toTag": "",
      "state": "succeeded",
      "stateHelper": "unexpected change detected in firmware version. Expected nc.1.3.8-shasta-release.arm.2020-06-15T22:57:31+00:00.b7f0725 got: nc.1.2.25-shasta-release.arm.2020-05-15T17:27:16+00:00.0cf7f51",
      "deviceType": "",
      "expirationTime": "",
      "manufacturer": "cray",
      "xname": "x9000c1s3b1",
      "toFirmwareVersion": ""
   }
   ```

Update the firmware on any devices indicating a new version is needed.

---

## Load firmware from Nexus

This procedure will read all RPMs in the Nexus repository and upload firmware images to [S3](../../glossary.md#simple-storage-service-s3) and create image records for firmware not already in FAS.

1. (`ncn-mw#`) Check the loader status.

    ```bash
    cray fas loader list --format toml | grep loaderStatus
    ```

    This will return a `ready` or `busy` status.

    ```toml
    loaderStatus = "ready"
    ```

    The loader can only run one job at a time, if the loader is `busy`, it will return an error on any attempt to create an additional job.

1. (`ncn-mw#`) Run the loader Nexus command.

    ```bash
    cray fas loader nexus create --format toml
    ```

    This will return an ID which will be used to check the status of the run.

    ```toml
    loaderRunID = "7b0ce40f-cd6d-4ff0-9b71-0f3c9686f5ce"
    ```

    > **`NOTE`** Depending on how many files are in Nexus and how large those files are, the loader may take several minutes to complete.

1. (`ncn-mw#`) Check the results of the loader run.

    ```bash
    cray fas loader describe {loaderRunID} --format json
    ```

    > **`NOTE`** `{loadRunID}` is the ID from step #2 above -- in that case `7b0ce40f-cd6d-4ff0-9b71-0f3c9686f5ce`.
    Use the `--format json` to make it easier to read.

    Example output:

    ```json
    {
      "loaderRunOutput": [
        "2021-07-20T18:17:58Z-FWLoader-INFO-Starting FW Loader, LOG_LEVEL: INFO; value: 20",
        "2021-07-20T18:17:58Z-FWLoader-INFO-urls: {'fas': 'http://cray-fas', 'fwloc': 'file://download/'}",
        "2021-07-20T18:17:58Z-INFO: LOG_LEVEL: DEBUG; value: 10",
        "2021-07-20T18:17:58Z-INFO: NEXUS_ENDPOINT: http://nexus.nexus.svc.cluster.local",
        "2021-07-20T18:17:58Z-INFO: NEXUS_REPO: shasta-firmware",
        "2021-07-20T18:17:58Z-INFO: Repomd URL: http://nexus.nexus.svc.cluster.local/repository/shasta-firmware/repodata/repomd.xml",
        "2021-07-20T18:17:58Z-DEBUG: Starting new HTTP connection (1): nexus.nexus.svc.cluster.local:80",
        "2021-07-20T18:17:58Z-DEBUG: http://nexus.nexus.svc.cluster.local:80 \"GET /repository/shasta-firmware/repodata/repomd.xml HTTP/1.1\" 200 3080",
        "2021-07-20T18:17:58Z-INFO: Packages URL: http://nexus.nexus.svc.cluster.local/repository/shasta-firmware/repodata/7f727fc9c4a8d0df528798dc85f1c5178128f3e00a0820a4d07bf9842ddcb6e1-primary.xml.gz",
        "2021-07-20T18:17:58Z-DEBUG: Starting new HTTP connection (1): nexus.nexus.svc.cluster.local:80",
        "2021-07-20T18:17:58Z-DEBUG: http://nexus.nexus.svc.cluster.local:80 \"GET /repository/shasta-firmware/repodata/7f727fc9c4a8d0df528798dc85f1c5178128f3e00a0820a4d07bf9842ddcb6e1-primary.xml.gz HTTP/1.1\" 200 6137",
        ...
        ...
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for e7b20c7ae98611eb880aa2c40cff7c62/nc-1.5.15.itb",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for ec324d05e98611ebbb9da2c40cff7c62/rom.ima_enc",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for e74c5977e98611eb8e9aa2c40cff7c62/cc-1.5.15.itb",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for e1feb6d6e98611eb877aa2c40cff7c62/accfpga_nvidia_2.7.tar.gz",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for dc830cb2e98611ebb4d2a2c40cff7c62/A48_2.40_02_24_2021.signed.flash",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for e28626d4e98611ebb0a7a2c40cff7c62/wnc.i210-p2sn01.tar.gz",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for eee87acde98611eba8f4a2c40cff7c62/image.RBU",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for de3d01bee98611eb9affa2c40cff7c62/A47_2.40_02_23_2021.signed.flash",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for e8ab6f61e98611eb913fa2c40cff7c62/ex235n.bios-1.1.1.tar.gz",
        "2021-07-20T18:19:04Z-FWLoader-INFO-update ACL to public-read for e8ab6f61e98611eb913fa2c40cff7c62/ex235n.bios-1.1.1.tar.gz",
        "2021-07-20T18:19:04Z-FWLoader-INFO-finished updating images ACL",
        "2021-07-20T18:19:04Z-FWLoader-INFO-*** Number of Updates: 24 ***"
      ]
    }
    ```

    A successful run will end with `*** Number of Updates: x ***`.

    > **`NOTE`** The FAS loader will not overwrite image records already in FAS.
    >`Number of Updates` will be the number of new images found in Nexus. If the number is 0, all images were already in FAS.

## Load firmware from RPM or ZIP file

This procedure will read a single local RPM (or ZIP) file and upload firmware images to S3 and create image records for firmware not already in FAS.

1. Copy the file to `ncn-m001` or one of the other NCNs.

1. (`ncn-mw#`) Check the loader status:

    ```bash
    cray fas loader list --format toml | grep loaderStatus
    ```

    This will return a `ready` or `busy` status.

    ```toml
    loaderStatus = "ready"
    ```

    The loader can only run one job at a time, if the loader is `busy`, it will return an error on any attempt to create an additional job.

1. (`ncn-mw#`) Run the `loader` command.

    `firmware.rpm` is the name of the RPM. If the file is not in the current directory, add the path to the filename.

    ```bash
    cray fas loader create --file firmware.RPM --format toml
    ```

    This will return an ID which will be used to check the status of the run.

    ```toml
    loaderRunID = "7b0ce40f-cd6d-4ff0-9b71-0f3c9686f5ce"
    ```

1. (`ncn-mw#`) Check the results of the loader run.

    ```bash
    cray fas loader describe {loaderRunID} --format json
    ```

    > **`NOTE`** `{loadRunID}` is the ID from step #2 above -- in that case `7b0ce40f-cd6d-4ff0-9b71-0f3c9686f5ce`.
    Use the `--format json` to make it easier to read.

    Example output:

    ```json
    {
      "loaderRunOutput": [
        "2021-04-28T14:40:45Z-FWLoader-INFO-Starting FW Loader, LOG_LEVEL: INFO; value: 20",
        "2021-04-28T14:40:45Z-FWLoader-INFO-urls: {'fas': 'http://localhost:28800', 'fwloc': 'file://download/'}",
        "2021-04-28T14:40:45Z-FWLoader-INFO-Using local file: /ilo5_241.zip",
        "2021-04-28T14:40:45Z-FWLoader-INFO-unzip /ilo5_241.zip",
        "Archive:  /ilo5_241.zip",
        "  inflating: ilo5_241.bin",
        "  inflating: ilo5_241.json",
        "2021-04-28T14:40:45Z-FWLoader-INFO-Processing files from file://download/",
        "2021-04-28T14:40:45Z-FWLoader-INFO-get_file_list(file://download/)",
        "2021-04-28T14:40:45Z-FWLoader-INFO-Processing File: file://download/ ilo5_241.json",
        "2021-04-28T14:40:45Z-FWLoader-INFO-Uploading b73a48cea82f11eb8c8a0242c0a81003/ilo5_241.bin",
        "2021-04-28T14:40:45Z-FWLoader-INFO-Metadata {'imageData': \"{'deviceType': 'nodeBMC', 'manufacturer': 'hpe', 'models': ['ProLiant XL270d Gen10', 'ProLiant DL325 Gen10', 'ProLiant DL325 Gen10 Plus',
        'ProLiant DL385 Gen10', 'ProLiant DL385 Gen10 Plus', 'ProLiant XL645d Gen10 Plus', 'ProLiant XL675d Gen10 Plus'],
        'targets': ['iLO 5'], 'tags': ['default'], 'firmwareVersion': '2.41 Mar 08 2021', 'semanticFirmwareVersion': '2.41.0', 'pollingSpeedSeconds': 30, 'fileName': 'ilo5_241.bin'}\"}",
        "2021-04-28T14:40:46Z-FWLoader-INFO-IMAGE: {\"s3URL\": \"s3:/fw-update/b73a48cea82f11eb8c8a0242c0a81003/ilo5_241.bin\", \"target\": \"iLO 5\", \"deviceType\": \"nodeBMC\", \"manufacturer\": \"hpe\",
        \"models\": [\"ProLiant XL270d Gen10\", \"ProLiant DL325 Gen10\", \"ProLiant DL325 Gen10 Plus\", \"ProLiant DL385 Gen10\", \"ProLiant DL385 Gen10 Plus\", \"ProLiant XL645d Gen10 Plus\", \"ProLiant XL675d Gen10 Plus\"],
        \"softwareIds\": [], \"tags\": [\"default\"], \"firmwareVersion\": \"2.41 Mar 08 2021\", \"semanticFirmwareVersion\": \"2.41.0\", \"allowableDeviceStates\": [], \"needManualReboot\": false, \"pollingSpeedSeconds\": 30}",
        "2021-04-28T14:40:46Z-FWLoader-INFO-Number of Updates: 1",
        "2021-04-28T14:40:46Z-FWLoader-INFO-Iterate images",
        "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for 5ab9f804a82b11eb8a700242c0a81003/wnc.bios-1.1.2.tar.gz",
        "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for 5ab9f804a82b11eb8a700242c0a81003/wnc.bios-1.1.2.tar.gz",
        "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for 53c060baa82a11eba26c0242c0a81003/controllers-1.3.317.itb",
        "2021-04-28T14:40:46Z-FWLoader-INFO-update ACL to public-read for b73a48cea82f11eb8c8a0242c0a81003/ilo5_241.bin",
        "2021-04-28T14:40:46Z-FWLoader-INFO-finished updating images ACL",
        "2021-04-28T14:40:46Z-FWLoader-INFO-removing local file: /ilo5_241.zip",
        "2021-04-28T14:40:46Z-FWLoader-INFO-*** Number of Updates: 1 ***"
      ]
    }
    ```

    A successful run will end with `*** Number of Updates: x ***`.

    > **`NOTE`** The FAS loader will not overwrite image records already in FAS.
    >`Number of Updates` will be the number of new images found in the RPM. If the number is 0, all images were already in FAS.
