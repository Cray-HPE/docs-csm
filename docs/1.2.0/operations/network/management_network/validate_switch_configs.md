# Validate Switch Configurations

## Prerequisites

* SSH access to the switches or the running configuration file.
* Generated switch configurations.
  * [Generate Switch Configurations](generate_switch_configs.md)
* CANU installed with version 1.1.11 or greater.
  * Run `canu --version` to see version.
  * If doing a CSM install or upgrade, a CANU RPM is located in the release tarball. For more information, see this procedure: [Update CANU From CSM Tarball](canu/update_canu_from_csm_tarball.md)

## Compare CSM 1.2 switch configurations with running configurations

Compare the current running configuration with the generated configuration.

For the comparison, because we have pulled the configuration to our working directory we can compare the files locally. CANU
can also pull the configuration from the switch by using the `--ip`, `--username`, and `--password` arguments.

Example of CANU pulling configuration.

```bash
ncn# canu validate switch config --ip 192.168.1.1 --username USERNAME --password PASSWORD --generated ./generated/sw-spine-001.cfg
```

Doing file comparisons on your local machine:

* Comparing configuration file for single switch:

```bash
ncn# canu validate switch config --running ./running/sw-spine-001.cfg --generated sw-spine-001.cfg
```

Please enter the vendor (Aruba, Dell, Mellanox): Aruba

* Comparing configuration files for full system:

```bash
ncn# canu validate network config --csm 1.2 --running ./running/ --generated ./generated/
```

CANU-generated switch configurations will not include any ports or devices not defined in the model. These were previously discussed in the
"Validate the SHCD section" but include edge uplinks (CAN/CMN) and custom configurations applied by the customer. When looking at the generated
configurations being applied against existing running configurations CANU will recommend removal of some critical configurations. It is vital
that these devices and configurations be identified and protected. This can be accomplished in three ways:

* Provide CANU validation of generated configurations against running configurations with an override or "blackout" configuration – a YAML file
which tells CANU to ignore customer-specific configurations. The process of creating this file was previously described in the This file will be
custom to every site and must be distributed with the analysis and configuration file bundle to be used in the future.

* Based on experienced networking knowledge, manually reorder the proposed upgrade configurations. This may require manual exclusion of required
  configurations which the CANU analysis says to remove.

* Some devices may be used by multiple sites and may not currently be in the CANU architecture and configuration. If a device type is more
  universally used on several sites, then it should be added to the architectural and configuration definitions via the CANU code and
  Pull Request (PR) process.

Note: A roadmap item for CANU is the ability to "inject" customer configurations into CANU and provide solid, repeatable configuration customization.

## Analyze CSM 1.2 configuration upgrade

Configuration updates depending on the current version of network configuration may be as easy as adding few lines or be a complete "rip and replace"
operation which may lead you to choosing to wipe the existing configuration or just simply adding few lines in the configuration.

Always before making configuration changes, analyze the changes shown in the above configuration diff section.

:exclamation: All of these steps should be done using an out of band connection. This process is disruptive and will require downtime :exclamation:

## Caveats and known issues

* Mellanox and Dell support is limited.
* Some configuration may need to be applied in a certain order.
  * Example: `Customer VRF` needs to be applied before adding interfaces/routes to the VRF.
* When applying certain configuration it may wipe out pre-existing configuration.
  * An example of this would be adding a VRF to a port.

For example:

```text
Config differences between running config and generated config

Safe Commands
These commands should be safe to run while the system is running.
-------------------------------------------------------------------------

interface 1/1/mgmt0
  no shutdown
interface 1/1/30
  mtu 9198
  description vsx isl
interface vlan 7
  ip ospf 1 area 0.0.0.0
router ospf 1 vrf Customer
  router-id 10.2.0.2
  default-information originate
  area 0.0.0.0

Manual Commands
These commands may cause disruption to the system and should be done only during a maintenance period.
It is recommended to have an out-of-band connection while running these commands.
-------------------------------------------------------------------------

interface 1/1/mgmt0
  vrf attach keepalive
  ip address 192.168.255.0/31
interface 1/1/30
  no vrf attach keepalive
  lag 256

-------------------------------------------------------------------------

Commands NOT classified as Safe or Manual
These commands include authentication as well as unique commands for the system.
These should be looked over carefully before keeping/applying.
-------------------------------------------------------------------------

no user admin group administrators password ciphertext AQBapa3xRMDxuA1PmoQJEc3kv1FjET4ix0HtN5hHGJDLa3PKYgAAAO7tAGcAlW6jst5Byl50ax+JA+ViqsHr8Sl1KCzSFzgBtaIYz3iTPD3zk5wmbJ1IKbMQ9+TcgFUO7baupypo7ftDMIbZhn+A7UaLALJzFj+W+NIqmWbOGfKw9ie0jTM5JUfl
no profile Leaf
no debug ospfv2 all
no snmp-server vrf default
no snmpv3 user testuser auth md5 auth-pass ciphertext AQBapflTKYh28GLx4x7Bp5XyAT0j2jnm9fDMNei1tR+BTyrqCQAAAITcQ4YsQX2noQ== priv des priv-pass ciphertext AQBapaNP67WbY49eqp0jL27tInN1FeAD9TjgkcbW31S85/SBCQAAAP6e+534mdJiaA==
no route-map CMN permit seq 10
no router ospf 2 vrf Customer
router bgp 65533
  vrf Customer
    no exit-address-family

-------------------------------------------------------------------------

Switch: sw-spine-001

Differences
-------------------------------------------------------------------------

In Generated Not In Running (+)     |  In Running Not In Generated (-)

-------------------------------------------------------------------------
Total Additions:                 6  |  Total Deletions:                33
Interface:                       1  |  Interface:                       3
Router:                          1  |  Router:                          2
```
