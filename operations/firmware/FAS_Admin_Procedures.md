## FAS Admin Procedures

Procedures for leveraging the Firmware Action Service (FAS) CLI to manage firmware.

### Topics

1. [Warning for Non-Compute Nodes (NCNs)](#warning)
2. [Ignore Nodes within FAS](#ignore)
3. [Use the `cray-fas-loader` Kubernetes Job](#k8s)
4. [Override an Image for an Update](#overrideImage)
5. [Load Firmware into FAS Manually](#manualLoad)
6. [Check for New Firmware Versions with a Dry-Run](#dryrun)

---

<a name="warning"></a>

### Warning for Non-Compute Nodes (NCNs)</a>

**WARNING:** NCNs should be locked with the HSM locking API to ensure they are not unintentionally updated by FAS. Research [NCN and Management Node Locking](../hardware_state_manager/NCN_and_Management_Node_Locking.md) for more information. Failure to lock the NCNs could result in unintentional update of the NCNs if FAS is not used correctly; this will lead to system instability problems.

---

<a name="ignore"></a>

### Ignore Nodes within FAS

The default configuration of FAS no longer ignores `management` nodes, which prevents FAS from firmware updating the NCNs. To reconfigure the FAS deployment to exclude non-compute nodes (NCNs) and ensure they cannot have their firmware upgraded, the `NODE_BLACKLIST` value must be manually enabled

Nodes can also be locked with the Hardware State Manager (HSM) API. Refer to [NCN and Management Node Locking](../hardware_state_manager/NCN_and_Management_Node_Locking.md) for more information.

#### Procedure

1. Check that there are no FAS actions that are running.

    ```
    ncn-m001# cray fas actions list	
    ```

2. Edit the cray-fas deployment.

    ```
    ncn-m001# kubectl -n services edit deployment cray-fas	
    ```

3. Change the `NODE_BLACKLIST` value from `ignore_ignore_ignore` to `management`.

4. Save and quit the deployment. This will restart FAS.

---

<a name="k8s"></a>

### Use the cray-fas-loader Kubernetes Job

FAS requires image data in order to load firmware into different devices in the system. Firmware images bundles are retrieved by the system via Nexus in order to be used by FAS. This process is managed by the cray-fas-loader Kubernetes job.

The workflow for the cray-fas-loader is shown below:

1. It pulls firmware bundled (currently RPMs) from Nexus. The firmware is in the *shasta-firmware* repository.
2. It extracts the RPM and gets the JSON imagefile.
3. It uploads the binaries into S3 and loads the data from the imagefile into FAS using the S3 reference. The binaries have the `public-read` ACL applied so that Redfish devices do not have to authenticate against s3.

#### Re-run the cray-fas-loader Job

If new firmware is available in Nexus, the cray-fas-loader job needs to be re-run. This should only occur if there is a new release or patch.

#### Procedure

To re-run the cray-fas-loader job:

1. Identify the current `cray-fas-loader` job.

    ```
    ncn-w001# kubectl -n services get jobs | grep fas-loader
    ...
    cray-fas-loader-1	1/1	8m57s	7d15h
    ```

    Note the returned job name in the previous command, which is *cray-fas-loader-1* in this example.

2. Re-create the job.  
   
   Use the same job name as identified in the previous step.

   ```
   ncn-w001# kubectl -n services get job cray-fas-loader-1 -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels."controller-uid")' | kubectl replace --force -f -
   
   ```

---

<a name="overrideImage"></a>

### Override an Image for an Update

If an update fails because of `"No Image available"`, it may be caused by FAS unable to match the data on the node to find an image in the image list.

### Procedure

1. Find the available image in FAS.

   Change *TARGETNAME* to the actual target being searched.

   ```bash
   ncn-m001# cray fas images list --format json | jq '.[] | .[] | select(.target=="TARGETNAME")'
   ```

   This command would display one or more images available for updates.

   ```
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

2. Use the imageID from the `cray images list` in the previous step and add the following line to the action JSON file, replacing *IMAGEID* with the imageID.

     In this example, the value would be: `ff268e8a-8f73-414f-a9c7-737a34bb02fc`.

   ```json
       "imageFilter": {
         "imageID":"IMAGEID",
         "overrideImage":true
       }
   ```

   Example actions JSON file with imageFilter added:

   ``` json
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

3. Verify the correct image ID was found.

   ``` bash
   ncn-m001# cray fas images describe imageID
   ```

   **WARNING:** FAS will force a flash of the device, using incorrect firmware may make it inoperable.

Re-run the FAS actions command using the updated json file. **It is strongly recommended to run a dry-run (overrideDryrun=false) first and check the actions output.**

---

<a name="manualLoad"></a>

### Load Firmware into FAS Manually

The firmware image file must be on the system to update. Firmware file can be extracted from the FAS RPM with the command `rpm2cpio firmwarefile.rpm | cpio -idmv`.

#### Procedure

1. Upload the firmware image into S3.

   The S3 bucket is `fw-update` and the path in the example is `slingshot`, but it can be any directory. The image file in the example below is `controllers-1.4.409.itb`.

   ```bash
   ncn-m001# cray artifacts create fw-update slingshot/controllers-1.4.409.itb controllers-1.4.409.itb
   artifact = "slingshot/controllers-1.4.409.itb"
   Key = "slingshot/controllers-1.4.409.itb"

2. Create FAS image record (example: slingshotImage.json). 

     **NOTE:** This is slightly different from the image meta file in the RPM.

     Use the image record of the previous release as a reference.

     Update to match current version of software:

   ``` json
           "firmwareVersion": "sc.1.4.409-shasta-release.arm64.2021-02-06T06:06:52+00:00.957b64c",
           "semanticFirmwareVersion": "1.4.409",
           "s3URL": "s3:/fw-update/slingshot/controllers-1.4.409.itb"
   ```

   ``` json
         {
           "deviceType": "RouterBMC",
           "manufacturer": "cray",
           "models": [
             "ColoradoSwitchBoard_REV_A",
             "ColoradoSwitchBoard_REV_B",
             "ColoradoSwitchBoard_REV_C",
             "ColoradoSwtBrd_revA",
             "ColoradoSwtBrd_revB",
             "ColoradoSwtBrd_revC",
             "ColoradoSWB_revA",
             "ColoradoSWB_revB",
             "ColoradoSWB_revC",
             "101878104_",
             "ColumbiaSwitchBoard_REV_A",
             "ColumbiaSwitchBoard_REV_B",
             "ColumbiaSwitchBoard_REV_D",
             "ColumbiaSwtBrd_revA",
             "ColumbiaSwtBrd_revB",
             "ColumbiaSwtBrd_revD",
             "ColumbiaSWB_revA",
             "ColumbiaSWB_revB",
             "ColumbiaSWB_revD"
           ],
           "target": "BMC",
           "tags": [
             "default"
           ],
           "softwareIds": [
             "sc:*:*"
           ],
           "firmwareVersion": "sc.1.4.409-shasta-release.arm64.2021-02-06T06:06:52+00:00.957b64c",
           "semanticFirmwareVersion": "1.4.409",
           "pollingSpeedSeconds": 30,
           "s3URL": "s3:/fw-update/slingshot/controllers-1.4.409.itb"
         }

3. Upload image record to FAS.

   ``` bash
   ncn-m001# cray fas images create slingshotImage.json
   imageID = "b6e035ec-2f42-4024-b544-32f7b4d035cf"
   ```

   To verify image, use the imageID returned from the images create command:

   ```bash
   ncn-m001# cray fas images describe "b6e035ec-2f42-4024-b544-32f7b4d035cf"

4. Run the FAS loader to set permissions on file uploaded.

   ```bash
   ncn-m001# kubectl -n services get jobs | grep fas-loader
   cray-fas-loader-1  1/1  8m57s  7d15h
   ````
   **NOTE:** In the above example, the returned job name is cray-fas-loader-1, hence that is the job to re-run.

   ```bash
   ncn-m001# kubectl -n services get job cray-fas-loader-1 -o json | jq 'del(.spec.selector)' \
   | jq 'del(.spec.template.metadata.labels."controller-uid")' \
   | kubectl replace --force -f -
   ```

5. Update firmware using FAS as normal.

     It is recommended to run a dry-run to make sure the correct firmware is selected before attempting an update.

---

<a name="dryrun"></a>

### Check for New Firmware Versions with a Dry-Run

Use the Firmware Action Service \(FAS\) dry-run feature to determine what firmware can be updated on the system. Dry-runs are enabled by default, and can be configured with the overrideDryrun parameter. A dry-run will create a query according to the filters requested by the admin. It will initiate an update sequence to determine what firmware is available, but will not actually change the state of the firmware.

**Warning:** It is crucial that an admin is familiar with the release notes of any firmware. The release notes will indicate what new features the firmware provides and if there are any incompatibilities. FAS does not know about incompatibilities or dependencies between versions. The admin assumes full responsibility for this knowledge.

It is likely that when performing a firmware update, that the current version of firmware will not be available. This means that after successfully upgrading, the firmware cannot be downgraded.

This procedure includes information on how check the firmware versions for the entire system, as well as how to target specific manufacturers, xnames, and targets.

#### Procedure

1. Run a dry-run firmware update.

	The following command parameters should be included in dry-run JSON files:

	- overrideDryrun: The overrideDryrun parameter is set to false by default. FAS will only update the system if this is parameter is set to true.
	- restoreNotPossibleOverride: FAS will not perform an update if the currently running firmware is not available in the images repository. Set to true to allow FAS to update firmware, even if the current firmware is unavailable on the system.
	- description: A brief description that helps admins distinguish between actions.
	- version: Determine if the firmware should be set to the `latest`, the `earliest` semantic version, or set to a specific firmware version.

	Use one of the options below to run on a dry-run on every system device or on targeted devices:

	**Option 1:** Determine the available firmware for every device on the system:
   
    1. Create a JSON file for the command parameters.

        ``` json
        {
        "command": {
          "restoreNotPossibleOverride": true,
          "timeLimit": 1000,
          "description": "full system dryrun 2020623_0"
        }

    1. Run the dry-run for the full system.

        ```bash
        ncn-m001# cray fas actions create COMMAND.json
        ```

        Proceed to the next step to determine if any firmware needs to be updated.

	**Option 2:** Determine the available firmware for specific devices:

    1. Create a JSON file with the specific device information to target when doing a dry-run.

       ``` json
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

    2. Run a dry-run on the targeted devices.

       ``` bash
       ncn-m001# cray fas actions create CUSTOM_DEVICE_PARAMETERS.json 
       ```

       Proceed to the next step to determine if any firmware needs to be updated.

2.  View the status of the dry-run to determine if any firmware updates can be made.

	The following returned messages will help determine if a firmware update is needed.

  	-   `NoOperation`: Nothing to do, already at version.
  	-   `NoSolution`: No image is available or data is missing.
  	-   `succeeded`: A firmware version that FAS can update the firmware to is available and it should work when actually updating the firmware.
  	-   `failed`: There is something that FAS could do, but it likely would fail; most likely because the file is missing.

  	1. Get a high-level summary of the FAS job to determine if there are any upgradeable firmware images available.

		Use the returned `actionID` from the cray fas actions create command.

		In the example below, there are two operations in the `succeeded` state, indicating there is an available firmware version that FAS can use to update firmware.

     	```bash
       ncn-m001# cray fas actions status describe actionID
       blockedBy = []
       state = "completed"
       actionID = "0a305f36-6d89-4cf8-b4a1-b9f199afaf3b" startTime = "2020-06-23 15:43:42.939100799 +0000 UTC"
       snapshotID = "00000000-0000-0000-0000-000000000000"
       endTime = "2020-06-23 15:48:59.586748151 +0000 UTC"

       [actions.command]
       description = "upgrade of x9000c1s3b1 Nodex.BIOS to WNC 1.1.2" tag = "default"
       restoreNotPossibleOverride = true timeLimit = 1000
       version = "latest" overrideDryrun = false [actions.operationCounts] noOperation = 0
       succeeded = 2 
       verifying = 0
       unknown = 0
       configured = 0
       initial = 0
       failed = 0
       noSolution = 0
       aborted = 0
       needsVerified = 0
       total = 2
       inProgress = 0
       blocked = 0 [[actions]] blockedBy = [] state = "completed"
       actionID = "0b9300d6-8f06-4019-a8fa-7b3ff65e5aa8" startTime = "2020-06-18 03:06:25.694573366 +0000 UTC"
       snapshotID = "00000000-0000-0000-0000-000000000000"
       endTime = "2020-06-18 03:11:06.806297546 +0000 UTC"
       ```

       The action is still in progress if the state field is not completed or aborted.

	
    2. View the details of an action to get more information on each operation in the FAS action.

		In the example below, there is an operation for an xname in the failed state, indicating there is something that FAS could do, but it likely would fail. A common cause for an operation failing is because the firmware image file is missing.

       ```bash
       ncn-m001# cray fas actions describe actionID --format json
       {
             "parameters": {
               "stateComponentFilter": {
                 "deviceTypes": [
                   "routerBMC"
                 ]
               },
               "command": {
                 "dryrun": false,
                 "description": "upgrade of routerBMCs for cray",
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
               "description": "upgrade of routerBMCs for cray",
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

3. View the details for a specific operation.

   In this example, there is a device that is available for a firmware upgrade because the operation being viewed is a succeeded operation.

   ``` bash
   ncn-m001# cray fas operations describe operationID --format json
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

Update the firmware on any devices indicating a new version is needed.

