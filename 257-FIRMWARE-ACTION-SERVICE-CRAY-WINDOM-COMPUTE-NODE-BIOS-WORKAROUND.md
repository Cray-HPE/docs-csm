# Compute Node Bios workaround for `WNC-rome` aka `HPE CRAY EX425`

## Problem Identification
The following conditions must be true in order to qualify for this problem:

1. The system running Shasta v1.4
2. The system has completed CSM installation
3. an upgrade via FAS of `Cray` - `Node1.BIOS`/`Node0.BIOS` has been completed:

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
4. The result of the upgrade is that the `NodeX.BIOS` has failed as `noSolution` and the `stateHelper` field for the operation states: `"No Image Available"`
5. The BIOS in question is running a version <= `1.2.5` (as reported by Redfish; or by describing the `noSolution` operation in FAS).
6. The hardware model reported by Redfish is `wnc-rome`; this hardware's marketing designation is  `HPE CRAY EX425` .  Note if your Redfish model is different (ignoring casing); meaning the blade(s) in question are not `Windom` please reach out to technical support.


## Workaround

1. Search for the `FAS` image records for a `cray` `HPE CRAY EX425` `Node1.BIOS`.  


	```json
	 cray fas images list --format json | jq '.images[] | select(.manufacturer=="cray") | select(.target=="Node1.BIOS") | select(any(.models[]; contains("EX425")))'
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
        "imageFilter": {
          "imageID": "your-image-id-will-be-unique-use-the-identified-id",
          "overrideImage": true
          },
	    "command": {
	        "version": "latest",
	        "tag": "default",
	        "overrideDryrun": true,
	        "restoreNotPossibleOverride": true,
	        "timeLimit": 1000,
	        "description": " upgrade of Node BIOS"
	      }
	    }
	```

3. Using `FAS` as normal, launch the action referencing the new JSON file.
4. At this point you should use `FAS` as normal.  The expectation would be that the operations should be `succeeded` after using the new JSON file.
