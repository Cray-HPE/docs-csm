# Firmware

This page describes the non-compute node's (NCN) firmware; the minimum versions, and how to interrogate information from
an NCN.

* [Minimum Versions](#minimum-versions)
* [BMC Interrogation](#bmc-interrogation)

## Minimum Versions

This section outlines the minimum firmware versions for a CSM install.

> ***NOTE*** **Minimum firmware versions** refers to versions that CSM has tested and verified to work for a CSM
> installation. Using older
> versions is not recommended, and user experience may vary.

The entries in this table may change as new features are added, bug fixes are adopted, or if/when newer Redfish®
versions are required.

> ***NOTE*** The values below match what is returned by Redfish® API calls.

| Board Manufacturer | Board Model                    | BIOS Version                                | Firmware Version |
|:-------------------|:-------------------------------|:--------------------------------------------|:-----------------|
| Cray Inc           | `R272-Z30-00`                  | `C37`                                       | `12.84.17`       |
| HPE                | `ProLiant DL325 Gen10 Plus`    | `A43 v1.38 (10/30/2020)`                    | `iLO 5 v2.44`    |
| HPE                | `ProLiant DL325 Gen10 Plus v2` | `A43 v1.38 (10/30/2020)`                    | `iLO 5 v2.44`    |
| Intel Corporation  | `S2600WFT`                     | `SE5C620.86B.02.01.0012.C0001.070720200218` | `2.48.89b32e0d`  |

> ***NOTE*** "Cray Inc" is reported as the board manufacturer on Gigabyte boards.

## BMC Interrogation

This section will assist an administrator in interrogating the BMCs on a system. It provides various methods for various
contexts.

> ***NOTE*** This section is a *stub*, information will be added to this section soon for querying Redfish®.
> Right now, the viable endpoints to query for advanced Redfish® users are:
>
> * `redfish/v1/Managers/{ID} | jq -r '.Manufacturer, .BiosVersion , .Model'`
> * `redfish/v1/Systems/{ID} | jq -r .FirmwareVersion`
