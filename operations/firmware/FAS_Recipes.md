# FAS Recipes

> **`NOTE`** This is a collection of various FAS recipes for performing updates.
> For step by step directions and commands, see [FAS Use Cases](FAS_Use_Cases.md).

The following example JSON files are useful to reference when updating specific hardware components. In all of these examples, the `overrideDryrun` field will be set to `false`; set them to `true` to perform a live update.

When updating an entire system, walk down the device hierarchy component type by component type, starting first with routers (switches), proceeding to chassis, and then finally to nodes.
While this is not strictly necessary, it does help eliminate confusion.

**NOTE**: Any node which is locked will remain in the state `inProgress` with the `stateHelper` message of `"failed to lock"` until the action times out, or the lock is released.
These nodes will report as `failed` with the `stateHelper` message of `"time expired; could not complete update"` if action times out.
This includes NCNs which are manually locked to prevent accidental rebooting and firmware updates.

Refer to [FAS Filters](FAS_Filters.md) for more information on the content used in the example JSON files.

## Manufacturer : Cray

### (Cray) Device Type: `ChassisBMC` | Target: BMC

> **IMPORTANT:** Before updating a CMM:
>
> - Make sure all slot and rectifier power is off.
> - The `hms-discovery` job must also be stopped before updates and restarted after updates are complete.
>   - (`ncn-mw#`) Stop `hms-discovery` job: `kubectl -n services patch cronjobs hms-discovery -p '{"spec":{"suspend":true}}'`
>   - (`ncn-mw#`) Start `hms-discovery` job: `kubectl -n services patch cronjobs hms-discovery -p '{"spec":{"suspend":false}}'`

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

### (Cray) Device Type: `NodeBMC` | Target: BMC

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

### (Cray) Device Type: `NodeBMC` | Target: `NodeBIOS`

> **IMPORTANT:**
>
> - The nodes themselves must be powered **off** in order to update their BIOS. The BMC will still have power and will perform the update.
> - When the BMC is updated or rebooted after updating the `Node0.BIOS` and/or `Node1.BIOS` on liquid-cooled nodes, the node BIOS version will not report the new version string until the nodes are
>   powered back on. It is recommended that the `Node0.BIOS` / `Node1.BIOS` be updated in a separate action, either before or after a BMC update, and that the nodes are powered back on after a BIOS
>   update. The liquid-cooled nodes must be powered off for the BIOS to be updated.

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

> **`NOTE`** If this update does not work as expected, follow the [Compute Node BIOS Workaround for HPE CRAY EX425](FAS_Use_Cases.md#compute-node-bios-workaround-for-hpe-cray-ex425) procedure.

### (Cray) Device Type: `NodeBMC` | Target: Redstone FPGA

> **IMPORTANT:**
>
> - The nodes themselves must be powered **on** in order to update the firmware of the Redstone FPGA on the nodes.
> - If updating FPGAs fails because of `No Image available`, update using the "Override an Image for an Update" procedure in [FAS Admin Procedures](FAS_Admin_Procedures.md):
>   - (`ncn-mw#`) Find the `imageID` using the following command: `cray fas images list --format json | jq '.[] | .[] | select(.target=="Node0.AccFPGA0")'`

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

## Manufacturer: HPE

### (HPE) Device Type: `NodeBMC` | Target: iLO 5 (BMC)

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "nodeBMC"
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

### (HPE) Device Type: `NodeBMC` | Target: System ROM (BIOS)

> **IMPORTANT:**
>
> - If updating the System ROM of an NCN, the NTP and DNS server values will be lost and must be restored. For NCNs **other than `ncn-m001`**, this can be done using the
>   `/opt/cray/csm/scripts/node_management/set-bmc-ntp-dns.sh` script. Use the `-h` option to get a list of command line options required to restore the NTP and DNS values.
>   See [Configure DNS and NTP on Each BMC](../../install/deploy_final_non-compute_node.md#7-configure-dns-and-ntp-on-each-bmc).
> - Node should be powered on for System ROM update and will need to be rebooted to use the updated BIOS.

```json
{
"stateComponentFilter": {
    "deviceTypes": [
      "NodeBMC"
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

> **`NOTE`** Update of System ROM may report as an error when it actually succeeded because of an incorrect string in the image metadata in FAS. Manually check the update version to get around this error.

## Manufacturer: Gigabyte

### (Gigabyte) Device Type: `NodeBMC` | Target: BMC

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
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

> **`NOTE`** The `timeLimit` is `4000` because the Gigabytes can take a lot longer to update.

#### Troubleshooting

A node may fail to update with the output:

```text
stateHelper = "Firmware Update Information Returned Downloading – See /redfish/v1/UpdateService"
```

FAS has incorrectly marked this node as failed.
It most likely will complete the update successfully.

To resolve this issue, do either of the following actions:

- Check the update status by looking at the Redfish `FirmwareInventory` (`/redfish/v1/UpdateService/FirmwareInventory/BMC`).
- Rerun FAS to verify that the BMC firmware was updated.

Make sure to wait for the current firmware to be updated before starting a new FAS action on the same node.

### (Gigabyte) Device Type: `NodeBMC` | Target: BIOS

```json
{
"stateComponentFilter": {

    "deviceTypes": [
      "nodeBMC"
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

## Update Non-Compute Nodes (NCNs)

See [Uploading BIOS and BMC Firmware for NCNs in FAS Use Cases](FAS_Use_Cases.md#update-non-compute-node-ncn-bios-and-bmc-firmware).
