# Update iLO 5 firmware above `v2.78`

This procedure is only required if the current version if iLO 5 is below `v2.78`.

iLO 5 versions above `v2.78` are larger than 32MB in size.  iLO 5 versions prior to `v2.78` will only accept 32MB size binary files.  iLO 5 `v2.78` removed this restriction.  To upgrade to a version after `v2.78`, iLO 5 must first be update to `v2.78`.

## Find Image Id for iLO 5 version 2.78

1. (`ncn-mw#`) Perform a search of the FAS images for version 2.78

```bash
cray fas images list --format json | jq '.[][] | select(.target == "iLO 5")' | jq 'select(.firmwareVersion | contains("2.78"))'
```

example output:

```json
{
  "imageID": "6fc274ee-6e7c-4b99-8954-4f0f31f03a18",
  "createTime": "2023-03-21T15:36:59Z",
  "deviceType": "nodeBMC",
  "manufacturer": "hpe",
  "models": [
    "ProLiant DL325 Gen10",
    "ProLiant DL325 Gen10 Plus",
    "ProLiant DL325 Gen10 Plus v2",
    "ProLiant DL385 Gen10",
    "ProLiant DL385 Gen10 Plus",
    "ProLiant XL645d Gen10 Plus",
    "ProLiant XL675d Gen10 Plus",
    "ProLiant XL645d Gen10",
    "ProLiant XL675d Gen10",
    "Apollo 6500 Gen10",
    "Apollo 6500 Gen10 Plus"
  ],
  "target": "iLO 5",
  "tags": [
    "default"
  ],
  "firmwareVersion": "2.78 Dec 16 2022",
  "semanticFirmwareVersion": "2.78.2",
  "pollingSpeedSeconds": 30,
  "s3URL": "s3:/fw-update/37dede53c7fe11edab1c86c549fb0239/ilo5_278.bin"
}
```

If more than one image is returned, use the image record with the largest semantic firmware version.

If no image record is returned, the `v2.78` FAS RPM needs to be downloaded and loaded into FAS
using the [Load Firmware from RPM or ZIP file](FAS_Admin_Procedures.md#load-firmware-from-rpm-or-zip-file) procedure.

## Upgrade iLO 5 firmware to version 2.78

Firmware can be updated using the FAS Update Script OR using a `json` file and running FAS from the Cray CLI.

### [Using the FAS Update Script](FASUpdate_Script.md)

Using the `imageID` from the output (in the example `6fc274ee-6e7c-4b99-8954-4f0f31f03a18`)
run the FAS Update Script (`ncn-mw#`).

```bash
/usr/share/doc/csm/scripts/operations/firmware/FASUpdate.py --file hpe_nodeBMC_iLO5.json --imageID 6fc274ee-6e7c-4b99-8954-4f0f31f03a18
```

You can update select xnames using the `--xnames XNAMES` option

This will run a dryrun on the system, to update the firmware, use the `--overrideDryun true` option

### Using a `json` file and running from the Cray CLI

Using the `imageID` from the output (in the example `6fc274ee-6e7c-4b99-8954-4f0f31f03a18`)
create a `json` file:

```json
{
  "inventoryHardwareFilter": {
    "manufacturer": "hpe"
  },
  "stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
    ]
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
    "description": "Upgrade of HPE node iLO 5 to v2.78 dryrun"
  },
  "imageFilter": {
    "imageID": "6fc274ee-6e7c-4b99-8954-4f0f31f03a18",
    "overrideImage": true
  }
}
```

Create a FAS actions using the created `json` file (`ncn-mw#`).

```bash
cray fas actions create ilo5v278.json
```

Check the action and change `overrideDryrun` to `true` to update the firmware.
