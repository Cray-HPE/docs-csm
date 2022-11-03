# Site Survey Worksheet

This site survey worksheet identifies information which should be collected in advance of a CSM installation.

## Topics

1. [First master node](#first_master_node)
1. [Site time information](#site_site_information)
1. [Site DNS information](#site_DNS_information)
1. [CAN network ranges](#CAN_network_ranges)
1. [Default internal network ranges](#default_internal_network_ranges)
1. [SHCD](#SHCD)
1. [`csi` command line configuration payload](#csi_command_line_configuration_payload)
1. [`csi` configuration payload files](#csi_configuration_payload_files)
1. [`site-init` customizations](#site-init_customizations)
1. [Application nodes](#application_nodes)
1. [Filesystems](#filesystems)

<a name="system_nodes_and_networks"></a>

## 1. First master node (`ncn-m001`)

The first master node (`ncn-m001`) is also called the PIT node early in the installation process, but later becomes `ncn-m001`.

| Name | Value |
| ---- | ----- |
| Factory-installed Linux `root` password of `ncn-m001` | |
| Site-defined Linux `root` password of `ncn-m001` | |
| BMC or iLO username for `ncn-m001` | |
| BMC or iLO password for `ncn-m001` | |
| BMC or iLO IP address of `ncn-m001` on site BMC network | |
| BMC or iLO default route/gateway for `ncn-m001` on site BMC network | |
| BMC or iLO netmask for `ncn-m001` on site BMC network | |
| IP address for `ncn-m001` primary Ethernet on site network | |
| Default route/gateway for `ncn-m001` primary Ethernet on site network | |
| Netmask for `ncn-m001` primary Ethernet on site network | |
| Network interface `ncn-m001` primary Ethernet to become `lan0` | |

<a name="site_time_information"></a>

## 2. Site time information

| Name | Value |
| ---- | ----- |
| Time zone | |
| First site NTP server | |
| (Optional) Second site NTP server | |
| (Optional) Third site NTP server | |

<a name="site_DNS_information"></a>

## 3. Site DNS information

| Name | Value |
| ---- | ----- |
| Domain name | |
| System name | |
| First site DNS server IP address | |
| (Optional) Second site DNS server IP address | |
| (Optional) Third site DNS server IP address | |

   > Note: The name of the system becomes part of the subdomain which is used to access externally exposed services.
   > For example, if the system is named `testsystem`, and the domain name is `example.com`, the subdomain
   > would be `testsystem.example.com`. Site DNS would need to be configured to delegate requests for addresses in
   > this domain to the DNS IP address on CAN for resolution.

<a name="CAN_network_ranges"></a>

## 4. CAN network ranges

Site must provide an IP address range for the Customer Access Network (CAN) and its subnets.

| Name | Starting IP Address | Netmask
| ---- | ----- | --- |
| CAN | | |
| `can-static-pool` | | |
| `can-dynamic-pool` | | |
| DNS IP address on CAN| | |
| CAN gateway IP address | | |

   > Notes:
   >
   > - The DNS IP address on the CAN is the IP address used for the HPE Cray EX DNS service. Site DNS delegates the resolution
   >   for addresses in the HPE Cray EX Domain to this server. This IP address must be in the `can-static-pool` subnet.
   > - The CAN gateway IP address is the IP address assigned to a specific port on the spine switch or edge switch,
   >   which will act as the gateway between the CAN and the rest of the customer's internal networks. This address
   >   would be the last hop route to the CAN network.

<a name="default_internal_network_ranges"></a>

## 5. Default internal network ranges

The initial installation of the system creates default networks with default settings and with no external exposure.
These default IP address ranges ensure that no nodes in the system attempt to use the same IP address as a
Kubernetes service or pod, which would result in undefined behavior that is extremely difficult to reproduce or
debug.

The following table shows the default IP address ranges.

| Network | Default IP Address Range | Site Value (if not default) |
| --- | --- | --- |
| Kubernetes service network | `10.16.0.0/12` | |
| Kubernetes pod network | `10.32.0.0/12` | |
| Install network (MTL) | `10.1.0.0/16` | |
| Node Management Network (NMN) | `10.252.0.0/17` | |
| High Speed Network (HSN) | `10.253.0.0/16` | |
| Hardware Management Network (HMN) | `10.254.0.0/17` | |
| Mountain NMN allocate a `/22` from this range per liquid-cooled cabinet | `10.100.0.0/17` | |
| Mountain HMN allocate a `/22` from this range per liquid-cooled cabinet | `10.104.0.0/17` | |
| River NMN | `10.106.0.0/17` | |
| River HMN | `10.107.0.0/17` | |

> Note: Example NMN `10.100.0.0/17`and HMN `10.104.0.0/17` default IP address ranges for a Mountain system with three cabinets would be:
>
> | Cabinet number | NMN Default IP Address Range | Site Value (if not default) |
> | --- | --- | --- |
> | 1 | `10.100.0.0/22` | |
> | 2 | `10.100.4.0/22` | |
> | 3 | `10.100.8.0/22` | |
>
> | Cabinet number | HMN Default IP Address Range | Site Value (if not default) |
> | --- | --- | --- |
> | 1 | `10.104.0.0/22` | |
> | 2 | `10.104.4.0/22` | |
> | 3 | `10.104.8.0/22` | |

<a name="SHCD"></a>

## 6. SHCD

The Shasta Cabling Diagram (SHCD) is a multiple tab spreadsheet prepared by HPE Cray Manufacturing with much information about the
HPE Cray EX system and its components. Included in the SHCD are:

- A configuration summary with revision history
- Floor layout plan with cabinet ID numbers
- Type and location of components in the air-cooled cabinets
- Type and location of components in the liquid-cooled cabinets
- Device diagrams for switches and nodes in the cabinets
- List of source and destination of every HSN cable
- List of source and destination of every cable connected to the spine switches
- List of source and destination of every cable connected to the NMN
- List of source and destination of every cable connected to the HMN
- List of cabling for the KVM
- Routing of power to the PDUs

The installation of CSM software requires that the SHCD be available. Some information will be manually collected from
the SHCD, but some of the tabs can be extracted into CSV formatted files tor use as input to automatic configuration tools.

<a name="csi_command_line_configuration_payload"></a>

## 7. `csi` command line configuration payload

This information from a site survey can be given to the `csi` command as command line arguments.
The information is shown here to explain what data is needed.

The air-cooled cabinet is known to `csi` as a `river` cabinet. The liquid-cooled cabinets are either
`mountain` or `hill` (if a TDS system).

| CSI Option | Example | Information | Site Value |
| --- | --- | --- | --- |
| `--bootstrap-ncn-bmc-user` | `root` | Administrative account for the management node BMCs | |
| `--bootstrap-ncn-bmc-pass` | `changeme` | Password for `bootstrap-ncn-bmc-user` account | |
| `--system-name` | `eniac` | Name of the HPE Cray EX system | |
| `--mountain-cabinets` | `4` | Number of Mountain cabinets, but this could also be in `cabinets.yaml` | |
| `--starting-mountain-cabinet` | `1000` | Starting Mountain cabinet ID | |
| `--hill-cabinets` | `0` | Number of Hill cabinets, but this could also be in `cabinets.yaml` | |
| `--river-cabinets` | `1` | Number of River cabinets, but this could also be in `cabinets.yaml` | |
| `--can-cidr` | `10.103.11.0/24` | IP subnet for the CAN assigned to this system | |
| `--can-external-dns` | `10.103.11.113` | IP address on CAN for this system's DNS server | |
| `--can-gateway` | `10.103.11.1` | Virtual IP address for the CAN (on the spine switches) | |
| `--can-static-pool` | `10.103.11.112/28` | MetalLB static pool on CAN | |
| `--can-dynamic-pool` | `10.103.11.128/25` | MetalLB dynamic pool on CAN | |
| `--hmn-cidr` | `10.254.0.0/17` | Override the default cabinet IPv4 subnet for River HMN | |
| `--nmn-cidr` | `10.252.0.0/17` | Override the default cabinet IPv4 subnet for River NMN | |
| `--hmn-mtn-cidr` | `10.104.0.0/17` | Override the default cabinet IPv4 subnet for Mountain HMN | |
| `--nmn-mtn-cidr` | `10.100.0.0/17` | Override the default cabinet IPv4 subnet for Mountain NMN | |
| `--ntp-pools` | `time.nist.gov` | External NTP pool for pools for this system to use | |
| `--site-domain` | `dev.cray.com` | Domain name for this system | |
| `--site-ip` | `172.30.53.79/20` | IP address and netmask for the PIT node `lan0` connection | |
| `--site-gw` | `172.30.48.1` | Gateway for the PIT node to use | |
| `--site-nic` | `p1p2` | NIC on the PIT node to become `lan0` | |
| `--site-dns` | `172.30.84.40` | Site DNS servers to be used by the PIT node | |
| `--install-ncn-bond-members` | `p1p1,p10p1` | NICs on each management node to become `bond0` | |
| `--application-node-config-yaml` | `application_node_config.yaml` | Name of `application_node_config.yaml` | |
| `--cabinets-yaml` | `cabinets.yaml` | Name of `cabinets.yaml` | |
| `--bgp-peers` | `aggregation` | Override the default BGP peers, using aggregation switches instead of spines | |

- The `bootstrap-ncn-bmc-user` and `bootstrap-ncn-bmc-pass` must match what is used for the BMC account and its password for the management nodes.
- Set site parameters (`site-domain`, `site-ip`, `site-gw`, `site-nic`, `site-dns`) for the information which connects `ncn-m001` (the PIT node) to the site. The `site-nic` is the interface on this node connected to the site.
- There are other interfaces possible, but the `install-ncn-bond-members` are typically:
  - `p1p1,p10p1` for HPE nodes
  - `p1p1,p1p2` for Gigabyte nodes
  - `p801p1,p801p2` for Intel nodes
- The starting cabinet number for each type of cabinet (for example, `starting-mountain-cabinet`) has a default that can be overridden. See the `csi config init --help` output for more information.
- An override to default cabinet IPv4 subnets can be made with the `hmn-mtn-cidr` and `nmn-mtn-cidr` parameters.
- Several parameters (`can-gateway`, `can-cidr`, `can-static-pool`, `can-dynamic-pool`) describe the CAN (Customer Access network).
  - The `can-gateway` is the common gateway IP address used for both spine switches and commonly referred to as the Virtual IP address for the CAN.
  - The `can-cidr` is the IP subnet for the CAN assigned to this system.
  - The `can-static-pool` and `can-dynamic-pool` are the MetalLB address static and dynamic pools for the CAN.
  - The `can-external-dns` is the static IP address assigned to the DNS instance running in the cluster to which requests the cluster subdomain will be forwarded.
  - The `can-external-dns` IP address must be within the `can-static-pool` range.
- Set `ntp-pools` to reachable NTP pools.
- The `application_node_config.yaml` file is required. It is used to describe the mapping between prefixes in `hmn_connections.csv` and HSM `subroles`.
  This file also defines aliases application nodes. For details, see [Create Application Node YAML](../install/create_application_node_config_yaml.md).
- For systems that use non-sequential cabinet ID numbers, use `cabinets-yaml` to include the `cabinets.yaml` file. This file
  can include information about the starting ID for each cabinet type and number of cabinets which have separate command line
  options, but is a way to specify explicitly the ID of every cabinet in the system.
  See [../install/Create Cabinets YAML](../install/create_cabinets_yaml.md).

<a name="csi_configuration_payload_files"></a>

## `csi` configuration payload files

A few configuration files are needed for the installation of CSM. These are all provided to the `csi`
command during the installation process.

| Filename | Source | Information |
| --- | --- | --- |
| [`cabinets.yaml`](#cabinets_yaml) | SHCD | The number and type of air-cooled and liquid-cooled cabinets, cabinet IDs, and VLAN numbers |
| [`application_node_config.yaml`](#application_node_config_yaml) | SHCD | The number and type of application nodes with mapping from the name in the SHCD to the desired hostname |
| [`hmn_connections.json`](#hmn_connections_json) | SHCD | The network topology for HMN of the entire system |
| [`ncn_metadata.csv`](#ncn_metadata_csv) | SHCD, other| The number of master, worker, and storage nodes and MAC address information for BMC and bootable NICs |
| [`switch_metadata.csv`](#switch_metadata_csv) | SHCD | Inventory of all spine, aggregation, CDU, and leaf switches |

Although some information in these files can be populated from site survey information, the SHCD prepared by
HPE Cray Manufacturing is the best source of data for `hmn_connections.json`. The `ncn_metadata.csv` does
require collection of MAC addresses from the management nodes because that information is not present in the SHCD.

<a name="cabinets_yaml"></a>

### `cabinets.yaml`

The `cabinets.yaml` file describes the type of cabinets in the system, the number of each type of cabinet,
and the starting cabinet ID for every cabinet in the system. This file can be used to indicate that a system
has non-contiguous cabinet ID numbers or non-standard VLAN numbers.

The component names (xnames) used in the other files should fit within the cabinet IDs defined by the starting cabinet ID for River
cabinets (modified by the number of cabinets). It is OK for management nodes not to be in `x3000` (as the first River
cabinet), but they must be in one of the River cabinets. For example, `x3000` with two cabinets would mean `x3000` or `x3001`
should have all management nodes.

See [Create Cabinets YAML](../install/create_cabinets_yaml.md) for instructions about creating this file.

<a name="application_node_config_yaml"></a>

### `application_node_config.yaml`

The `application_node_config.yaml` file controls how the `csi config init` command finds and treats
application nodes discovered in the `hmn_connections.json` file when building the SLS input file.

Different node prefixes in the SHCD can be identified as application nodes. Each node prefix
can be mapped to a specific HSM `subrole`. These `subroles` can then be used as the targets of Ansible
plays run by CFS to configure these nodes. The component name (xname) for each application node can be assigned one or
more hostname aliases.

See [Create Application Node YAML](../install/create_application_node_config_yaml.md) for instructions about creating this file.

<a name="hmn_connections_json"></a>

### `hmn_connections.json`

The `hmn_connections.json` file is extracted from the HMN tab of the SHCD spreadsheet. The CSM release
includes the `hms-shcd-parser` container; this container can do the extraction on the PIT node booted from the LiveCD (RemoteISO
or USB device) or on a Linux system. Although some information in these files can be populated from site
survey information, the SHCD prepared by HPE Cray Manufacturing is the best source of data for `hmn_connections.json`.

No action is required to create this file at this point, and will be created when the PIT node is bootstrapped.

<a name="ncn_metadata_csv"></a>

### `ncn_metadata.csv`

The information in the `ncn_metadata.csv` file identifies each of the management nodes, assigns the function
as a master, worker, or storage node, and provides the MAC address information needed to identify the BMC and
the NIC which will be used to boot the node.

For each management node, the component name (xname), role, and `subrole` can be extracted from the SHCD. However, the rest of the
MAC address information needs to be collected another way. Collect as much information as possible
before the PIT node is booted from the LiveCD and then get the rest later when directed. See the scenarios
which enable partial data collection in [First Time Install](../install/prepare_configuration_payload.md#first_time_install).

See [Create NCN Metadata CSV](../install/create_ncn_metadata_csv.md) for instructions about creating this file.

<a name="switch_metadata_csv"></a>

### `switch_metadata.csv`

The `switch_metadata.csv` file is manually created to include information about all spine, aggregation, CDU,
and leaf switches in the system. None of the Slingshot switches for the HSN should be included in this file.

See [Create Switch Metadata CSV](../install/create_switch_metadata_csv.md) for instructions about creating this file.

<a name="site-init_customizations"></a>

## 9. `site-init` customizations

Several settings will be added to the `customizations.yaml` file in the `site-init` directory after `csi config init` has been run. Here is the additional information needed at that time.

For explanation of the names and sample settings see [Prepare Site Init](../install/prepare_site_init.md).

| Name | Value |
| ---- | ----- |
| `spec.kubernetes.sealed_secrets.cray_reds_credentials` `Username` | |
| `spec.kubernetes.sealed_secrets.cray_reds_credentials` `Password` | |
| `spec.kubernetes.sealed_secrets.cray_meds_credentials` `Username` | |
| `spec.kubernetes.sealed_secrets.cray_meds_credentials` `Password` | |
| `spec.kubernetes.sealed_secrets.cray_hms_rts_credentials` `Username` | |
| `spec.kubernetes.sealed_secrets.cray_hms_rts_credentials` `Password` | |

| PKI Certificate Authority (CA) | Value |
| ---- | ----- |
| `root_days` | |
| `int_days` | |
| `root_cn` | |
| `int_cn` | |
| Is a site (external) CA available? | |
| Is a site (external) CA private key available? | |
| Is a site (external) CA certificate available? | |

   > Note: Outside of a new installation of the CSM software, there is currently no supported method to rotate (change) the platform CA.
   > Ensure that validity periods are set accordingly for external CAs used in this process. The ability to rotate CAs is anticipated as part of a future release.

| (Optional) LDAP Settings | Value |
| ---- | ----- |
| Is a site LDAP server available? | |
| First site LDAP server | |
| First site LDAP server port | |
| (Optional) Second site LDAP server | |
| (Optional) Second site LDAP server port | |
| (Optional) Third site LDAP server | |
| (Optional) Third site LDAP server port | |
| Site LDAP `ldapSearchBase` | |
| Site LDAP `localRoleAssignments` | |

> Note: Setting `forwardZones` is needed if the site LDAP server is specified via a hostname rather than an IP address. See [Prepare Site Init](../install/prepare_site_init.md)

<a name="application_nodes"></a>

## 10.  Application nodes

Each application node can have specific information about it. Besides the CAN, some application nodes have additional network connections to Ethernet or InfiniBand.

The only predefined application node SHCD prefix and `subrole` is for UAN (User Access Node).

| Each Application Node | Value |
| ---- | ----- |
| BMC or iLO username | |
| BMC or iLO password | |
| SHCD prefix | |
| `subrole` | |
| Hostname alias or aliases | |
| Is CAN enabled for this node? | |
| CAN IP address | |
| CAN default route/gateway | |
| CAN netmask | |
| Network interface connected to CAN | |
| Is network interface (`net1`) enabled for this node? | |
| `net1` `bootproto` | |
| `net1` device | |
| `net1` IP address | |
| `net1` `startmode` | |
| `net1` `ifroute` route or routes | |
| `net1` `ifrule` rules | |
| Is network interface (`net2`) enabled for this node? | |
| `net2` `bootproto` | |
| `net2` device | |
| `net2` IP address | |
| `net2` `startmode` | |
| `net2` `ifroute` route or routes | |
| `net2` `ifrule` rules | |

Common settings for all User Access Nodes (UANs).  These could be set the same for all application nodes rather than being set only for UANs.

| Common UAN settings | Value |
| ---- | ----- |
| UAN global route or routes | |
| UAN external DNS `searchlist` | |
| UAN first external DNS server | |
| UAN second external DNS server | |
| UAN third external DNS server | |
| UAN external DNS options | |
| UAN LDAP enabled for login? | |
| UAN LDAP domain | |
| UAN LDAP `search_base` | |
| UAN LDAP server or servers | |
| UAN LDAP `chpass_uri` | |
| UAN AD groups | |
| UAN PAM modules | |

<a name="filesystems"></a>

## 11.  Filesystems

For clients of a filesystem, there is some common data needed to be able to mount it.
The filesystem type (`fstype`) could be Lustre, SpectrumScale (GPFS), or NFS.

| Each Filesystem | Value |
| ---- | ----- |
| Filesystem name | |
| Source IP address | |
| `fstype` | |
| Mount point | |
| Mount options | |
