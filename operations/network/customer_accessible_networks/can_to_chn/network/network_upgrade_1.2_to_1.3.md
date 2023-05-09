# Management Network Upgrade CSM 1.2 to 1.3

- [Management Network Upgrade CSM 1.2 to 1.3](#management-network-upgrade-csm-12-to-13)
  - [Management network changelog](#management-network-changelog)
  - [When to perform switch upgrades](#when-to-perform-switch-upgrades)
  - [Prerequisites](#prerequisites)
  - [Upgrade CANU to the latest version](#upgrade-canu-to-the-latest-version)
  - [Backup running switch configurations](#backup-running-switch-configurations)
  - [Retrieve SLS data](#retrieve-sls-data)
  - [Generate CSM 1.3 switch configurations](#generate-csm-13-switch-configurations)
  - [Discover CSM 1.2 to CSM 1.3 configuration changes](#discover-csm-12-to-csm-13-configuration-changes)
  - [Test the network prior to update](#test-the-network-prior-to-update)
  - [Apply and save the new switch configurations](#apply-and-save-the-new-switch-configurations)
  - [Test the network after update](#test-the-network-after-update)

## Management network changelog

CSM 1.3 includes full support for the Bifurcated CAN feature, specifically deployment of user traffic on the high speed network (CHN). Other switch related changes for the release are minimal.

- Removal of CMN VLAN from UAN to complete BICAN cut-over
- Addition of ACLS to prevent CAN traffic on the CMN after CSM 1.2 installs/upgrades
- Addition of ACLs to prevent cross-network load balancer access: NMN to HMNLB and HMN to NMNLB

**Note** As of CSM 1.3 CANU generates edge router (Arista) configurations, but only those required for CSM.

Switch configuration upgrades for CSM 1.3 should be completed by a networking subject matter expert.
While addition of ACLs is a relatively safe process, the migration of user traffic from the management network CAN to the high speed network CHN is sequence dependent and not without risk.
Strict attention to the cut-over sequence will minimize downtime to UAN NCNs.

## When to perform switch upgrades

At the end of the CSM 1.3 upgrade process or at the end of the process to [migrate](chn_enable.md) from CAN to CHN.

Unlike most upgrades, the CSM 1.3 management network switch configuration changes come at the end of the system upgrade, not at the beginning. This allows the continued operations of services during upgrade.
Additionally, UAN can be operated normally and any reboot or rebuild operations can be scheduled between between administrators and UAN users.

## Prerequisites

- **IMPORTANT** If conversion from CAN to CHN is required, the [SLS update procedure](chn_enable.md) must have been applied prior to running this procedure.
- An up-to-date and validated copy of the system [CCJ/Paddle JSON topology file](https://github.com/Cray-HPE/canu/blob/main/docs/templates/quickstart.md) (preferred), or an up-to-date and validated [SHCD spreadsheet](https://github.com/Cray-HPE/canu/blob/main/docs/network_configuration_and_upgrade/validate_shcd.md).
  - The SHCD should be used as starting data over the CCJ/Paddle file only when node, network or cabling changes have taken place on the system.
  - A correct cabling and network topology must be reflected to ensure working switch configurations.
- An [up-to-date custom configurations](https://github.com/Cray-HPE/canu/blob/main/docs/network_configuration_and_upgrade/custom_config.md) YAML file to be used in CANU switch configuration generation with the `--custom-config` flag.
  - These custom configurations are critical to preserve site uplinks and any configurations which extend beyond plan-of-record.
  - This file should have been created during the CSM 1.2 system install or upgrade process and is required to ensure working switch configurations.

## Upgrade CANU to the latest version

- In a browser, navigate to [CANU Releases](https://github.com/Cray-HPE/canu/releases) and copy the latest release RPM URL
- (`ncn-m001#`) Download the latest CANU RPM with the release RPM URL
- (`ncn-m001#`) Upgrade CANU with `rpm -Uvh <release RPM URL>`

## Backup running switch configurations

- (`ncn-m001#`) Use CANU to backup the switch running configurations.

    Enter the switch administrative password when prompted.

     ```bash
     mkdir switch-configs-csm-1.3
     cd switch-configs-csm-1.3
     canu backup network --folder running
     ```

## Retrieve SLS data

- (`ncn-m001#`) Pull SLS data from the system.

  ```bash
  cray sls dumpstate list --format json | jq -S . > sls_input_file.json
  ```

## Generate CSM 1.3 switch configurations

- (`ncn-m001#`) Use CANU to [generate new switch configurations](https://github.com/Cray-HPE/canu/blob/main/docs/network_configuration_and_upgrade/generate_config.md). Shown below is an example using the preferred CCJ/Paddle file.

   ```bash
   canu generate network config --csm 1.3 --architecture <full|tds|v1> --ccj <system-ccj.json> --custom-config <system-custom-config.yaml> --folder generated --sls-file sls_input_file.json
   ```

  - `full` architecture is defined as Aruba switches with leaf switches connected to spines - no NCNs on spines.
  - `tds` architecture is defined as Aruba switches with NCNs connected directly to the spine switches.
  - `v1` architecture is defined as any system with Mellanox and Dell switches.

## Discover CSM 1.2 to CSM 1.3 configuration changes

For *each* switch in the system, determine the configuration differences.

- (`ncn-m001#`) Use CANU to see the differences between the 1.2 and 1.3 switch configurations.

    ```bash
    canu validate switch config --running ./running/<switch.cfg> --generated ./generated/<switch.cfg> --vendor <aruba|mellanox|dell> --remediation
    ```

## Test the network prior to update

- (`ncn-m001#`) **Only** during 1.2 to 1.3 upgrades.

   ```bash
   canu test --csm 1.2
   ```

- (`ncn-m001#`) During [CAN to CHN migration](chn_enable.md).

   ```bash
   canu test --csm 1.3
   ```

- All tests should pass or have a known and explainable reason for failing.

## Apply and save the new switch configurations

For *each* switch in the system, apply the configuration changes in two stages:

1. Apply just the `prefix-list` and `route-maps`.
1. Apply the remaining configuration.

**Important** In addition to complete `spine`, `leaf` and `leaf-bmc` configurations, CANU now generates Arista edge router configurations required for CSM. These configurations must be applied as well if CHN is used.

- (`ncn-m001#`) Set the switch configuration version string to be placed in `<CONFIG VERSION STRING>`.

   ```bash
   echo "CSM_1_3_$(canu --version | tr -d ',' | cut -f 1,3 -d ' ' | tr ' .' '_' | tr '[:lower:]' '[:upper:]')"
   ```

- (`switch#`) Save the configuration. Replace `<CONFIG VERSION STRING>` with the value shown in the previous step.

   ```text
   write memory
   copy running-config checkpoint <CONFIG VERSION STRING>
   ```

## Test the network after update

- (`ncn-m001#`) Use CANU to test the network.

   ```bash
   canu test --csm 1.3
   ```

   All tests should pass or have a known and explainable reason for failing.
