# NCN Firmware

This page describes the non-compute node's (NCN) firmware; the minimum versions, and how to interrogate information from
an NCN.

* [Minimum versions](#minimum-versions)
* [BMC interrogation](#bmc-interrogation)

## Minimum versions

This section outlines the minimum firmware versions for a CSM install.

### Server

> ***NOTE*** **Minimum firmware versions** refers to versions that CSM has tested and verified to work for a CSM
> installation. Using older
> versions is not recommended, and user experience may vary.

The entries in this table may change as new features are added, bug fixes are adopted, or if/when newer Redfish®
versions are required.

> ***NOTE*** The values below match what is returned by Redfish® API calls.

| Manufacturer       | Board Model                    | BIOS Version                                | Firmware Version |
|:-------------------|:-------------------------------|:--------------------------------------------|:-----------------|
| Cray Inc           | `R272-Z30-00`                  | `C37`                                       | `12.84.17`       |
| HPE                | `ProLiant DL325 Gen10 Plus`    | `A43 v1.38 (10/30/2020)`                    | `iLO 5 v2.44`    |
| HPE                | `ProLiant DL325 Gen10 Plus v2` | `A43 v1.38 (10/30/2020)`                    | `iLO 5 v2.44`    |
| Intel Corporation  | `S2600WFT`                     | `SE5C620.86B.02.01.0012.C0001.070720200218` | `2.48.89b32e0d`  |

> ***NOTE*** "Cray Inc" is reported as the board manufacturer on Gigabyte boards.

### PCIe hardware - management network

This section covers drivers and firmware versions for management network hardware under CSM.

> ***NOTE*** This does not cover high-speed network hardware.

| Manufacturer | Model                   | Driver Version | Firmware Version |
|:-------------|:------------------------|:---------------|:-----------------|
| QLogic Corp  | FastLinQ QL41000 Series | `8.74.1.0`[^1] | `8.55.12`        |

[^1]: Failure to use the minimum driver will significantly increase the risk of network connectivity failures and chances of Kernel Panics on SLES-15-SP4 and newer.

#### Obtaining the firmware versions

> The following examples use QLogic Corp FastLinQ QL41000 series PCIe cards. Actual output will vary when using other
> vendor's hardware.

From Use `ethtool` to fetch the driver and firmware version from any NCN \(replace `mgmt0` with any interface name\):

```bash
ethtool -i mgmt0
```

Example output:

```text
driver: qede
version: 8.74.4.0 [storm 8.72.1.0]
firmware-version: mbi 8.55.12 [mfw 8.55.22.0]
expansion-rom-version:
bus-info: 0000:c6:00.0
supports-statistics: yes
supports-test: yes
supports-eeprom-access: yes
supports-register-dump: yes
supports-priv-flags: yes
```

Alternatively, target every NCN with \(replace `mgmt0` or append more commands to check additional interfaces\):

```bash
PDSH_SSH_ARGS_APPEND="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" pdsh -b -w $(grep -oP 'ncn-w\d+' /etc/hosts | sort -u |  tr -t '\n' ',') '
ethtool -i mgmt0
' | dshbak -c
```

## BMC interrogation

This section will assist an administrator in interrogating the BMCs on a system. It provides various methods for various
contexts.

> The viable endpoints to query for advanced Redfish® users are:
>
> * `redfish/v1/Managers/{ID} | jq -r '.Manufacturer, .BiosVersion , .Model'`
> * `redfish/v1/Systems/{ID} | jq -r .FirmwareVersion`
