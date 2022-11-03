# Upgrade and validate Switch Configurations

## Prerequisites

* SSH access to the switches or the running configuration file
* Upgrade or install latest version of CANU [Install/Upgrade CANU](../../operations/network/management_network/canu_install_update.md)
  * Run `canu --version` to see version
  * CANU installed with version 1.6.13 or greater.
* Use the paddle file (CCJ) if available, or validate an up-to-date SHCD [Validate SHCD](../../operations/network/management_network/validate_shcd.md)
* System Layout Service (SLS) input file. [Collect Data](../../operations/network/management_network/collect_data.md)

> **CAUTION:** All of these steps should be done using an out-of-band connection. This process is disruptive and will require downtime.

## Generate Configuration Files

Ensure that the correct architecture (`-a` parameter) is selected for the setup in use.

The following are the different architectures that can be specified:

* `Tds` – Aruba-based Test and Development System. These are small systems characterized by Kubernetes NCNs cabled directly to the spine switches.
* `Full` – Aruba-based Leaf-Spine systems. These are usually customer production systems.
* `V1` – Any Dell and Mellanox based systems.

Generating a configuration file can be done for a single switch, or for the full system. Below are example commands for both scenarios:

**Important:** Modify the following items in your command:

* `--csm` : Which CSM version configuration do you want to use? For example, `1.2` or `1.0`
NOTE: Only major and minor versions of CSM are tracked at this time. CANU bug fixes are captured in the latest CANU version and do not align with CSM bug fix versions.
* `--a`   : What is the system architecture? (See above)
* `--ccj` : Match the `ccj.json` file to the one you created for your system.
* `--sls` : Match the `sls_file.json` to the one you created for your system.
* `--custom-config` : Pass in a switch configuration file that CANU will inject into the generated configuration. For more information, see the [CANU documentation](https://github.com/Cray-HPE/canu#generate-switch-configs-including-custom-configurations).

* Generate switch configuration files for the entire system:

    ```console
    ncn# canu generate network config --csm 1.2 -a full --ccj system-ccj.json  --sls-file sls_file.json --custom-config system-custom-config.yaml --folder generated
    ```

## Compare the generated CSM 1.2 switch configurations with running configurations

Compare the current running configuration with the generated configuration.

Essentially this would be to backup current configuration to your workstation and comparing it against the CANU generated configuration.

Example of CANU pulling configuration.

```bash
ncn# canu validate switch config --vendor <aruba/dell/mellanox> --ip <192.168.1.1> --username USERNAME --password PASSWORD --generated ./generated/sw-spine-001.cfg
```

Doing file comparisons on your local machine:

* Comparing configuration file for single switch:

```bash
ncn# canu validate switch config --running ./running/sw-spine-001.cfg --generated ./generated/sw-spine-001.cfg
```

* Example of output of the validate switch configuration:

```bash
ncn# canu validate switch config --running ./running/sw-spine-001.cfg --generated ./generated/sw-spine-001.cfg
Please enter the vendor (Aruba, Dell, Mellanox): Mellanox
- interface mlag-port-channel 6 shutdown
- interface mlag-port-channel 5 shutdown
+ interface mlag-port-channel 6 no shutdown
+ interface mlag-port-channel 5 no shutdown
-------------------------------------------------------------------------

Config differences between running config and generated config


lines that start with a minus "-" and RED: Config that is present in running config but not in generated config
lines that start with a plus "+" and GREEN: Config that is present in generated config but not in running config.
```

CANU-generated switch configurations will not include any ports or devices not defined in the model. These were previously discussed in the
"Validate the SHCD section" but include edge uplinks (CAN/CMN) and custom configurations applied by the customer. When looking at the generated
configurations being applied against existing running configurations CANU will recommend removal of some critical configurations. It is vital
that these devices and configurations be identified and protected. This can be accomplished in three ways:

* Generate Switch configuration including custom configurations. [Custom configuration](https://github.com/Cray-HPE/canu/blob/develop/readme.md#generate-switch-configs-including-custom-configurations)

* Based on experienced networking knowledge, manually reorder the proposed upgrade configurations. This may require manual exclusion of required
  configurations which the CANU analysis says to remove.

* Some devices may be used by multiple sites and may not currently be in the CANU architecture and configuration. If a device type is more
  universally used on several sites, then it should be added to the architectural and configuration definitions via the CANU code and
  Pull Request (PR) process.

## Analyze CSM 1.2.1 configuration upgrade

Configuration updates depend on the current version of network configuration. Upgrading from CSM 1.2 configuration to CSM 1.2.1 should be fairly straight forward.

Always before making configuration changes, analyze the changes shown in the above configuration diff section.

:exclamation: All of these steps should be done using an out of band connection. This process is disruptive and will require downtime :exclamation:

## Caveats and known issues

* Mellanox and Dell configuration remediation support is limited.
* Some configuration may need to be applied in a certain order.
  * Example: `Customer VRF` needs to be applied before adding interfaces/routes to the VRF.
* When applying certain configuration it may wipe out pre-existing configuration.
  * An example of this would be adding a VRF to a port.

## Warnings

Understanding the switch configuration changes is critical. The following configurations risk a network outage, if not applied correctly:

* Generating switch configuration without preserving site-specific values (by using the `--custom-configuration` flag).
* Changes to ISL (MAGP, VSX, etc.) configurations.
* Changes to Spanning Tree.
* Changes to ACLs or ACL ordering.
* Changes to VRF.
* Changes to default route.
* Changes to MLAG/LACP.

[Return to CSM 1.2.1 Patch Installation Instructions](README.md)
