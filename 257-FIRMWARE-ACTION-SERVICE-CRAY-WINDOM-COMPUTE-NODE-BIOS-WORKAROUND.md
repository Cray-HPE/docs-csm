# Compute Node BIOS workaround for `WNC-rome` aka `HPE CRAY EX425`

## Problem Identification
The following conditions must be true in order to qualify for this problem:

1. The system running Shasta v1.4
2. The system has completed CSM installation
3. an upgrade via FAS of `Cray` - `Node1.BIOS`/`Node0.BIOS` has been completed following the recipes in [256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md](../256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md#cray-device-type-nodebmc-target-nodebios)
4. The result of the upgrade is that the `NodeX.BIOS` has failed as `noSolution` and the `stateHelper` field for the operation states: `"No Image Available"`
5. The BIOS in question is running a version <= `1.2.5` (as reported by Redfish; or by describing the `noSolution` operation in FAS).
6. The hardware model reported by Redfish is `wnc-rome`; this hardware's marketing designation is  `HPE CRAY EX425` .  Note if your Redfish model is different (ignoring casing); meaning the blade(s) in question are not `Windom` please reach out to technical support.
7. To find the model reported by redfish; drill into the `noSolution` operation using `FAS`: 

    ```bash
    linux# cray fas operations describe {operationID} --format json
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

  The model in this example is `WNC-Rome` and you can see the firmware version currently running is `wnc.bios-1.2.5`

## Workaround

1. Search for the `FAS` image records for a `cray` `HPE CRAY EX425` `Node1.BIOS`.

    ```bash
    linux# cray fas images list --format json | jq '.images[] | select(.manufacturer=="cray") | select(.target=="Node1.BIOS") | select(any(.models[]; contains("EX425")))'
    {
        "imageID": "e23f5465-ed29-4b18-9389-f8cf0580ca60",
        "createTime": "2021-03-04T00:04:05Z",
        "deviceType": "nodeBMC",
        "manufacturer": "cray",
        "models": [
          "HPE CRAY EX425"
        ],
        "softwareIds": [
          "bios.ex425.*.*"
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

2. Using the imageID from that record create an update command json file that will use the image override.

    >  **NOTE** YOU MUST CHANGE THE `imageID` to match your identified image ID

3. Using `FAS` as normal, launch the action referencing the new JSON file.
4. At this point you should use `FAS` as normal.  The expectation would be that the operations should be `succeeded` after using the new JSON file.

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