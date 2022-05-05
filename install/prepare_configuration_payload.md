# Prepare Configuration Payload

The configuration payload consists of the information which must be known about the HPE Cray EX system so it
can be passed to the `csi` (Cray Site Init) program during the CSM installation process.

Information gathered from a site survey is needed to feed into the CSM installation process, such as system name,
system size, site network information for the CAN, site DNS configuration, site NTP configuration, network
information for the node used to bootstrap the installation. More detailed component level information about the
system hardware is encapsulated in the SHCD (Shasta Cabling Diagram), which is a spreadsheet prepared by HPE Cray
Manufacturing to assemble the components of the system and connect appropriately labeled cables.

How the configuration payload is prepared depends on whether this is a first time installation of CSM
software on this system or the CSM software is being reinstalled. The *reinstall scenario* has the
advantage of being able to use the configuration payload from the previous CSM installation
and an additional configuration file which that installation generated. The *first time* install scenario requires
using the csi config tool to pass arguments to CSI as well as the creation of a number of
[Configuration Payload Files](#configuration_payload_files).

## Topics

* [Command Line Configuration Payload](#command_line_configuration_payload)
* [Configuration Payload Files](#configuration_payload_files)
* [First Time Install](#first_time_install)
* [Reinstall](#reinstall)
* [Next Topic](#next-topic)

<a name="command_line_configuration_payload"></a>
## Command Line Configuration Payload

The information from a site survey can be given to the `csi` command as command line arguments.
The information and options shown below are to explain what data is needed. It will not be used until moving
to the [Bootstrap PIT Node](index.md#bootstrap_pit_node) procedure.

The air-cooled cabinet is known to `csi` as a `river` cabinet. The liquid-cooled cabinets are either
`mountain` or `hill` (if a TDS system).

For more description of these settings and the default values, see
[Default IP Address Ranges](../introduction/csm_overview.md#default_ip_address_ranges) and the other topics in
[CSM Overview](../introduction/csm_overview.md). There are additional options not shown on this page that can be
seen by running `csi config init --help`.

| CSI option | Information |
| --- | --- |
| --bootstrap-ncn-bmc-user root | Administrative account for the management node BMCs |
| --bootstrap-ncn-bmc-pass changeme | Password for `bootstrap-ncn-bmc-user` account |
| --system-name eniac  | Name of the HPE Cray EX system |
| --mountain-cabinets 4 | Number of Mountain cabinets, but this could also be in `cabinets.yaml` |
| --starting-mountain-cabinet 1000 | Starting Mountain cabinet |
| --hill-cabinets 0 | Number of Hill cabinets, but this could also be in `cabinets.yaml` |
| --river-cabinets 1 | Number of River cabinets, but this could also be in `cabinets.yaml` |
| --can-cidr 10.103.11.0/24 | IP subnet for the CAN assigned to this system |
| --can-gateway 10.103.11.1 | Virtual IP address for the CAN (on the spine switches) |
| --can-static-pool 10.103.11.112/28 | MetalLB static pool on CAN |
| --can-dynamic-pool 10.103.11.128/25 | MetalLB dynamic pool on CAN |
| --cmn-cidr 10.103.12.0/24 | IP subnet for the CMN assigned to this system |
| --cmn-external-dns 10.103.12.113 | IP address on CMN for this system's DNS server |
| --cmn-gateway 10.103.12.1 | Virtual IP address for the CMN (on the spine switches) |
| --cmn-static-pool 10.103.12.112/28 | MetalLB static pool on CMN |
| --cmn-dynamic-pool 10.103.12.128/25 | MetalLB dynamic pool on CMN |
| --hmn-cidr 10.254.0.0/17 | Override the default cabinet IPv4 subnet for River HMN |
| --nmn-cidr 10.252.0.0/17 | Override the default cabinet IPv4 subnet for River NMN |
| --hmn-mtn-cidr 10.104.0.0/17 | Override the default cabinet IPv4 subnet for Mountain HMN |
| --nmn-mtn-cidr 10.100.0.0/17 | Override the default cabinet IPv4 subnet for Mountain NMN |
| --ntp-pool time.nist.gov | External NTP server for this system to use |
| --site-domain dev.cray.com | Domain name for this system |
| --site-ip 172.30.53.79/20 | IP address and netmask for the PIT node `lan0` connection |
| --site-gw 172.30.48.1 | Gateway for the PIT node to use |
| --site-nic p1p2 | NIC on the PIT node to become `lan0` |
| --site-dns 172.30.84.40 | Site DNS servers to be used by the PIT node |
| --install-ncn-bond-members p1p1,p10p1 | NICs on each management node to become `bond0` |
| --application-node-config-yaml application_node_config.yaml | Name of `application_node_config.yaml` |
| --cabinets-yaml cabinets.yaml | Name of `cabinets.yaml` |
| --primary-server-name primary | Desired name for the primary DNS server |
| --secondary-servers "" | Comma-separated list of FQDN/IP for all DNS servers to be notified on DNS zone update |
| --notify-zones "" | A comma-separated list of DNS zones to transfer |

   * This is a long list of options. It can be helpful to create a Bash script file to call the `csi` command with all of these options, and then edit that file to adjust the values for the particular system being installed.
   * The `bootstrap-ncn-bmc-user` and `bootstrap-ncn-bmc-pass` must match what is used for the BMC account and its password for the management nodes.
   * Set site parameters (`site-domain`, `site-ip`, `site-gw`, `site-nic`, `site-dns`) for the information which connects `ncn-m001` (the PIT node) to the site. The `site-nic` is the interface on this node connected to the site.
   * There are other interfaces possible, but the `install-ncn-bond-members` are typically:
      * `p1p1,p10p1` for HPE nodes
      * `p1p1,p1p2` for Gigabyte nodes
      * `p801p1,p801p2` for Intel nodes
   * The starting cabinet number for each type of cabinet (for example, `starting-mountain-cabinet`) has a default that can be overridden. See the `csi config init --help` output for more information.
   * An override to default cabinet IPv4 subnets can be made with the `hmn-mtn-cidr` and `nmn-mtn-cidr` parameters.
   * Several parameters (`can-gateway`, `can-cidr`, `can-static-pool`, `can-dynamic-pool`) describe the CAN (Customer Access network). The `can-gateway` is the common gateway IP address used for both spine switches and commonly referred to as the Virtual IP address for the CAN. The `can-cidr` is the IP subnet for the CAN assigned to this system. The `can-static-pool` and `can-dynamic-pool` are the MetalLB address static and dynamic pools for the CAN.
   * Several parameters (`cmn-gateway`, `cmn-cidr`, `cmn-static-pool`, `cmn-dynamic-pool`) describe the CMN (Customer Management network). The `cmn-gateway` is the common gateway IP address used for both spine switches and commonly referred to as the Virtual IP address for the CMN. The `cmn-cidr` is the IP subnet for the CMN assigned to this system. The `cmn-static-pool` and `cmn-dynamic-pool` are the MetalLB address static and dynamic pools for the CAN. The `cmn-external-dns` is the static IP address assigned to the DNS instance running in the cluster to which requests the cluster subdomain will be forwarded. The `cmn-external-dns` IP address must be within the `cnn-static-pool` range.
   * Set `ntp-pool` to a reachable NTP server.
   * The `application_node_config.yaml` file is required. It is used to describe the mapping between prefixes in `hmn_connections.csv` and HSM subroles. This file also defines aliases application nodes. For details, see [Create Application Node YAML](create_application_node_config_yaml.md).
   * For systems that use non-sequential cabinet id numbers, use `cabinets-yaml` to include the `cabinets.yaml` file. This file can include information about the starting ID for each cabinet type and number of cabinets which have separate command line options, but is a way to specify explicitly the id of every cabinet in the system. See [Create Cabinets YAML](create_cabinets_yaml.md).
  * The PowerDNS zone transfer arguments `primary-server-name`, `secondary-servers`, and `notify-zones` are optional unless zone transfer is being configured. For more information see the [PowerDNS Configuration Guide](../operations/network/dns/PowerDNS_Configuration.md#zone-transfer)

<a name="configuration_payload_files"></a>
## Configuration Payload Files

A few configuration files are needed for the installation of CSM. These are all provided to the `csi`
command during the installation process.

| Filename | Source | Information |
| --- | --- | --- |
| [`cabinets.yaml`](#cabinets_yaml) | SHCD | The number and type of air-cooled and liquid-cooled cabinets. cabinet IDs, and VLAN numbers |
| [`application_node_config.yaml`](#application_node_config_yaml) | SHCD | The number and type of application nodes with mapping from the name in the SHCD to the desired hostname |
| [`hmn_connections.json`](#hmn_connections_json) | SHCD | The network topology for HMN of the entire system |
| [`ncn_metadata.csv`](#ncn_metadata_csv) | SHCD, other| The number of master, worker, and storage nodes and MAC address information for BMC and bootable NICs |
| [`switch_metadata.csv`](#switch_metadata_csv) | SHCD | Inventory of all spine, leaf, CDU, and leaf-bmc switches |

Although some information in these files can be populated from site survey information, the SHCD prepared by
HPE Cray Manufacturing is the best source of data for `hmn_connections.json`. The `ncn_metadata.csv` does
require collection of MAC addresses from the management nodes because that information is not present in the SHCD.

<a name="cabinets_yaml"></a>
### `cabinets.yaml`

The `cabinets.yaml` file describes the type of cabinets in the system, the number of each type of cabinet,
and the starting cabinet ID for every cabinet in the system. This file can be used to indicate that a system
has non-contiguous cabinet ID numbers or non-standard VLAN numbers.

The component names (xnames) used in the other files should fit within the cabinet ids defined by the starting cabinet id for River
cabinets (modified by the number of cabinets). It is OK for management nodes not to be in x3000 (as the first River
cabinet), but they must be in one of the River cabinets. For example, x3000 with 2 cabinets would mean x3000 or x3001
should have all management nodes.

See [Create Cabinets YAML](create_cabinets_yaml.md) for instructions about creating this file.

<a name="application_node_config_yaml"></a>
### `application_node_config.yaml`

The `application_node_config.yaml` file controls how the `csi config init` command finds and treats
application nodes discovered in the `hmn_connections.json` file when building the SLS Input file.

Different node prefixes in the SHCD can be identified as Application nodes. Each node prefix
can be mapped to a specific HSM sub role. These sub roles can then be used as the targets of Ansible
plays run by CFS to configure these nodes. The component name (xname) for each Application node can be assigned one or
more hostname aliases.

See [Create Application Node YAML](create_application_node_config_yaml.md) for instructions about creating this file.

<a name="hmn_connections_json"></a>
### `hmn_connections.json`

The `hmn_connections.json` file is extracted from the HMN tab of the SHCD spreadsheet. The CSM release
includes the `hms-shcd-parser` container which can be used on the PIT node booted from the LiveCD (RemoteISO
or USB device) or a Linux system to do this extraction. Although some information in these files can be populated from site survey information, the SHCD prepared by HPE Cray Manufacturing is the best source of data for hmn_connections.json.

No action is required to create this file at this point, and it will be created when the PIT node is bootstrapped.

<a name="ncn_metadata_csv"></a>
### `ncn_metadata.csv`

The information in the `ncn_metadata.csv` file identifies each of the management nodes, assigns the function
as a master, worker, or storage node, and provides the MAC address information needed to identify the BMC and
the NIC which will be used to boot the node.

For each management node, the component name (xname), role, and subrole can be extracted from the SHCD. However, the rest of the
MAC address information needs to be collected another way. Collect as much information as possible
before the PIT node is booted from the LiveCD and then get the rest later when directed. See the scenarios
which enable partial data collection below in [First Time Install](#first_time_install).

See [Create NCN Metadata CSV](create_ncn_metadata_csv.md) for instructions about creating this file.

<a name="switch_metadata_csv"></a>
### `switch_metadata.csv`

The `switch_metadata.csv` file is manually created to include information about all spine, leaf, CDU,
and leaf-bmc switches in the system. None of the Slingshot switches for the HSN should be included in this file.

See [Create Switch Metadata CSV](create_switch_metadata_csv.md) for instructions about creating this file.

<a name="first_time_install"></a>
## First Time Install

The process to install for the first time must collect the information needed to create these files.

1. Collect data for `cabinets.yaml`.

   See [Create Cabinets YAML](create_cabinets_yaml.md) for instructions about creating this file.

1. Collect data for `application_node_config.yaml`.

   See [Create Application Node YAML](create_application_node_config_yaml.md) for instructions about creating this file.

1. Collect data for `ncn_metadata.csv`.

   See [Create NCN Metadata CSV](create_ncn_metadata_csv.md) for instructions about creating this file.

1. Collect data for `switch_metadata.csv`.

   See [Create Switch Metadata CSV](create_switch_metadata_csv.md) for instructions about creating this file.

<a name="reinstall"></a>
## Reinstall

The process to reinstall must have the configuration payload files available.

1. Collect Payload for Reinstall.

   1. These files from a previous install are needed to do a reinstall.

      - `application_node_config.yaml` (if used previously)
      - `cabinets.yaml` (if used previously)
      - `hmn_connections.json`
      - `ncn_metadata.csv`
      - `switch_metadata.csv`
      - `system_config.yaml`

      If the `system_config.yaml` is not available, then a reinstall cannot be done. Switch to the install process
      and generate any of the other files for the [Configuration Payload Files](#configuration_payload_files)
      which are missing.

   1. The command line options used to call `csi config init` are not needed.

      When doing a reinstall, all of the command line options which had been given to `csi config init` during the
      previous installation will be found inside the `system_config.yaml` file. This simplifies the reinstall process.

      When you are ready to bootstrap the LiveCD, it will indicate when to run this command without any
      extra command line options. It will expect to find all of the above files in the current working
      directory.

      > **`NOTE`**: For fresh installs and reinstalls of CSM 1.2 or later, it is recommended that the `install-ncn-bond-members` option be double-checked. Systems
      > with Mellanox PCIe cards will have new interface names.
      > 1. Compare the output of `lid` with the background document here for PCIe devices. Cross-reference the Vendor ID with the IDs in the table in [Vendor and Bus ID Identification](../background/ncn_networking.md#vendor-and-bus-id-identification).
      >
      >     ```bash
      >     <lan> <vid>:<did>
      >     pit# lid
      >     p238p1 8086:1521
      >     p238p2 8086:1521
      >     p238p3 15B3:1013
      >     p238p4 15B3:1013
      >     ```
      >
      > * Update `system_config.yaml`'s `install-ncn-bond-members` value with the interface names cross-referenced from the `lid` output.
      > * _Alternatively_, run `csi config init --install-ncn-bond-members` with the discovered interface names.

      ```bash
      linux# csi config init
      ```

<a name="next-topic"></a>
## Next Topic

After completing this procedure the next step is to prepare the management nodes. See [Prepare Management Nodes](index.md#prepare_management_nodes)

