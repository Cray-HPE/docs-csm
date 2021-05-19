# Prepare Configuration Payload

The configuration payload consists of the information which must be known about the HPE Cray EX system so it
can be passed to the `csi` (Cray Site Init) program during the CSM installation process.

Information gathered from a site survey is needed to feed into the CSM installation process, such as system name, system size, site network information for the CAN, site DNS configuration, site NTP configuration, network information for the node used to bootstrap the installation. More detailed component level information about the system hardware is encapsulated in the SHCD (Shasta Cabling Diagram), which is a spreadsheet prepared by HPE Cray Manufacturing to assemble the components of the system and connect appropriately labeled cables.

How the configuration payload is prepared depends on whether this is a first time install of CSM
software on this system or the CSM software is being reinstalled.  The reinstall scenario has the
advantage of being able to use the configuration payload from a previous first time install of CSM
and an extra configuration file which that generated.


### Topics:

   * [Command Line Configuration Payload](#command_line_configuration_payload)
   * [Configuration Payload Files](#configuration_payload_files)
   * [First Time Install](#first_time_install)
   * [Reinstall](#reinstall)

## Details

<a name="command_line_configuration_payload"></a>
### Command Line Configuration Payload

This information from a site survey can be given to the `csi` command as command line arguments.
The information is shown here to explain what data is needed.  It won't be used until moving
to the procedure [Bootstrap PIT Node](index.md#bootstrap_pit_node)

The air-cooled cabinet is known to `csi` as a `river` cabinet.  The liquid-cooled cabinets are either
`mountain` or `hill` (if a TDS system).

| CSI option | Information |
| --- | --- |
| --bootstrap-ncn-bmc-user root | Administrative account for the management node BMCs |
| --bootstrap-ncn-bmc-pass changeme | Password for bootstrap-ncn-bmc-user account |
| --system-name eniac  | Name of the HPE Cray EX system |
| --mountain-cabinets 4 | Number of Mountain cabinets, but this could also be in cabinets.yaml |
| --starting-mountain-cabinet 1000 | Starting Mountain cabinet |
| --hill-cabinets 0 | Number of Hill cabinets, but this could also be in cabinets.yaml |
| --river-cabinets 1 | Number of River cabinets, but this could also be in cabinets.yaml |
| --can-cidr 10.103.11.0/24 | IP subnet for the CAN assigned to this system |
| --can-external-dns 10.103.11.113 | IP on CAN for this system's DNS server |
| --can-gateway 10.103.11.1 | Virtual IP for the CAN (on the spine switches) |
| --can-static-pool 10.103.11.112/28 | MetalLB static pool on CAN |
| --can-dynamic-pool 10.103.11.128/25 | MetalLB dynamic pool on CAN |
| --hmn-cidr 10.254.0.0/17 | Override the default cabinet IPv4 subnet for River HMN |
| --nmn-cidr 10.252.0.0/17 | Override the default cabinet IPv4 subnet for River NMN |
| --hmn-mtn-cidr 10.104.0.0/17 | Override the default cabinet IPv4 subnet for Mountain HMN |
| --nmn-mtn-cidr 10.100.0.0/17 | Override the default cabinet IPv4 subnet for Mountain NMN |
| --ntp-pool time.nist.gov | External NTP server for this system to use |
| --site-domain dev.cray.com | Domain name for this system |
| --site-ip 172.30.53.79/20 | IP address and netmask for the PIT node lan0 connection |
| --site-gw 172.30.48.1 | Gateway for the PIT node to use |
| --site-nic p1p2 | NIC on the PIT node to become lan0 |
| --site-dns 172.30.84.40 | Site DNS servers to be used by the PIT node |
| --install-ncn-bond-members p1p1,p10p1 | NICs on each management node to become bond0 |
| --application-node-config-yaml application_node_config.yaml | Name of application_node_config.yaml |
| --cabinets-yaml cabinets.yaml | Name of application_node_config.yaml |


   * The bootstrap-ncn-bmc-user and bootstrap-ncn-bmc-pass must match what is used for the BMC account and its password for the management nodes.
   * Set site parameters (site-domain, site-ip, site-gw, site-nic, site-dns) for the information which connects the ncn-m001 (PIT) node to the site.  The site-nic is the interface on this node connected to the site.  
   * There are other interfaces possible, but the install-ncn-bond-members are typically:
      * p1p1,p10p1 for HPE nodes
      * p1p1,p1p2 for Gigabyte nodes
      * p801p1,p801p2 for Intel nodes
   * The starting cabinet number for each type of cabinet (for example, starting-mountain-cabinet) has a default that can be overridden.  See the "csi config init --help".
   * An override to default cabinet IPv4 subnets can be made with the hmn-mtn-cidr and nmn-mtn-cidr parameters.
   * Several parameters (can-gateway, can-cidr, can-static-pool, can-dynamic-pool) describe the CAN (Customer Access network).  The can-gateway is the common gateway IP used for both spine switches and commonly referred to as the Virtual IP for the CAN.  The can-cidr is the IP subnet for the CAN assigned to this system. The can-static-pool and can-dynamic-pool are the MetalLB address static and dynamic pools for the CAN. The can-external-dns is the static IP assigned to the DNS instance running in the cluster to which requests the cluster subdomain will be forwarded.   The can-external-dns IP must be within the can-static-pool range.
   * Set ntp-pool to a reachable NTP server.
   * The application_node_config.yaml file is optional, but if you have one describing the mapping between prefixes in hmn_connections.csv that should be mapped to HSM subroles, you need to include a command line option to have it used.  See [Create Application Node YAML](create_application_node_config_yaml.md).
   * For systems that use non-sequential cabinet id numbers, use cabinets-yaml to include the cabinets.yaml file.  This file can include information about the starting ID for each cabinet type and number of cabinets which have separate command line options, but is a way to explicitly specify the id of every cabinet in the system.  See [Create Cabinets YAML](create_cabinets_yaml.md).

<a name="configuration_payload_files"></a>
### Configuration Payload Files

A few configuration files are needed for the installation of Shasta v1.5.  These are all provided to the `csi`
command during the installation process.

| Filename | Source | Information |
| --- | --- | --- |
| [application_node_config.yaml](#application_node_config_yaml) | SHCD | The number and type of application nodes with mapping from the name in the SHCD to the desired hostname |
| [cabinets.yaml](#cabinets_yaml) | SHCD | The number and type of air-cooled and liquid-cooled cabinets. cabinet IDs, and VLAN numbers |
| [hmn_connections.json](#hmn_connections_json) | SHCD | The network topology for HMN of the entire system |
| [ncn_metadata.csv](#ncn_metadata_csv) | SHCD, other| The number of master, worker, and storage nodes and MAC address information for BMC and bootable NICs |
| [switch_metadata.csv](#switch_metadata_csv) | SHCD | Inventory of all spine, aggregation, CDU, and leaf switches |

Although some information in these files can be populated from site survey information, the SHCD prepared by
HPE Cray Manufacturing is the best source of data for hmn_connections.json.  The `ncn_metadata.csv` does
require collection of MAC addresses from the management nodes since that information is not present in the SHCD.

<a name="application_node_config_yaml"></a>
#### `application_node_config.yaml`

The `application_node_config.yaml` file controls how the `csi config init` command finds and treats
application nodes discovered in the `hmn_connections.json` file when building the SLS Input file. 

Different node prefixes in the SHCD can be identified as Application nodes.  Each node prefix
can be mapped to a specific HSM sub role.  These sub roles can then be used as the targets of Ansible
plays run by CFS to configure these nodes.  The xname for each Application node can be assigned one or
more hostname aliases.

See [Create Application Node YAML](create_application_node_config_yaml.md) for instructions about creating this file.

<a name="cabinets_yaml"></a>
#### `cabinets.yaml`

The `cabinets.yaml` file describes the type of cabinets in the system, the number of each type of cabinet,
and the starting cabinet ID for every cabinet in the system.  This file can be used to indicate that a system
has non-contiguous cabinet ID numbers or non-standard VLAN numbers.

See [Create Cabinets YAML](create_cabinets_yaml.md) for instructions about creating this file.

<a name="hmn_connections_json"></a>
#### `hmn_connections.json`

The `hmn_connections.json` file is extracted from the HMN tab of the SHCD spreadsheet.  The CSM release
includes the `hms-shcd-parser` container which can be used on the PIT node booted from the LiveCD (RemoteISO
or USB device) or a Linux system to do this extraction.

See [Create HMN Connections JSON](create_hmn_connections_json.md) for instructions about creating this file.

<a name="ncn_metadata_csv"></a>
#### `ncn_metadata.csv`

Each of the management nodes need to be represented as a row in the `ncn_metadata.csv` file. 

For example:
```
Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
x3000c0s9b0n0,Management,Storage,94:40:c9:37:77:26,14:02:ec:d9:76:88,14:02:ec:d9:76:88,94:40:c9:5f:b6:92
```

There are two interesting parts to the NCN metadata file:
- The MAC of the BMC
- The MAC(s) of the shasta-network interface(s)

The "shasta-network interface" is interfaces, one or more, that comprise the NCNs' LACP link-aggregation ports.

##### LACP Bonding
NCNs may have 1 or more bond interfaces, which may be comprised from one or more physical interfaces. The
preferred default configuration is two physical network interfaces per bond. The number
of bonds themselves depends on your systems network topology.

For example, systems with 4 network interfaces on a given node could configure either of these
permutations (for redundancy minimums within Shasta cluster):
- one bond with 4 interfaces (`bond0`)
- two bonds with 2 interfaces each (`bond0` and `bond1`)

For more information, see [NCN Networking](../background/ncn_networking.md) page for NCNs.

##### "PXE" or "BOOTSTRAP" MAC

In general this refers to the interface to be used when the node attempts to PXE boot. This varies between vintages
of systems; systems before "Spring 2020" often booted NCNs with onboard NICs, newer systems boot over their PCIe cards.

If the system is **booting over PCIe then the "bootstrap MAC" and the "bond0 MAC 0" will be identical**. If the
system is **booting over onboards then the "bootstrap MAC" and the "bond0 MAC 0" will be different.**

> Other Nomenclature
- "BOND MACS" are the MAC addresses for the physical interfaces that your node will use for the various VLANs.
- BOND0 MAC0 and BOND0 MAC1 should **not** be on the same physical network card to establish redundancy for failed chips.
- On the other hand, if any nodes' capacity prevents it from being redundant, then MAC1 and MAC0 will still produce a valid configuration if they do reside on the same physical chip/card.
- The BMC MAC is the exclusive, dedicated LAN for the onboard BMC. It should not be swapped with any other device.

##### Sample `ncn_metadata.csv`

The following are sample rows from a `ncn_metadata.csv` file:
* __Use case__: NCN with a single PCIe card (1 card with 2 ports):
    > Notice how the MAC address for `Bond0 MAC0` and `Bond0 MAC1` are only off by 1, which indicates that
    > they are on the same 2 port card.

    ```
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s6b0n0,Management,Worker,94:40:c9:37:77:b8,14:02:ec:da:bb:00,14:02:ec:da:bb:00,14:02:ec:da:bb:01
    ```
* __Use case__: NCN with a dual PCIe cards (2 cards with 2 ports each for 4 ports total):
    > Notice how the MAC address for `Bond0 MAC0` and `Bond0 MAC1` have a difference greater than 1, which
    > indicates that they are on not on the same 2 port same card.

    ```
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Storage,94:40:c9:37:77:26,14:02:ec:d9:76:88,14:02:ec:d9:76:88,94:40:c9:5f:b6:92
    ```

Example `ncn_metadata.csv` file for a system that has been configured as follows:
 * NCNs are configured to boot over the PCIe NICs
 * Master and Storage nodes have two 2 port PCIe cards
 * Worker nodes have one 2 port PCIe card
> Since the NCN have been configured to boot over their PCIe NICs the values for the columns `Bootstrap MAC` and `Bond0 MAC0` have the same value.

```
Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
x3000c0s9b0n0,Management,Storage,94:40:c9:37:77:26,14:02:ec:d9:76:88,14:02:ec:d9:76:88,94:40:c9:5f:b6:92
x3000c0s8b0n0,Management,Storage,94:40:c9:37:87:5a,14:02:ec:d9:7b:c8,14:02:ec:d9:7b:c8,94:40:c9:5f:b6:5c
x3000c0s7b0n0,Management,Storage,94:40:c9:37:0a:2a,14:02:ec:d9:7c:88,14:02:ec:d9:7c:88,94:40:c9:5f:9a:a8
x3000c0s6b0n0,Management,Worker,94:40:c9:37:77:b8,14:02:ec:da:bb:00,14:02:ec:da:bb:00,14:02:ec:da:bb:01
x3000c0s5b0n0,Management,Worker,94:40:c9:35:03:06,14:02:ec:d9:76:b8,14:02:ec:d9:76:b8,14:02:ec:d9:76:b9
x3000c0s4b0n0,Management,Worker,94:40:c9:37:67:60,14:02:ec:d9:7c:40,14:02:ec:d9:7c:40,14:02:ec:d9:7c:41
x3000c0s3b0n0,Management,Master,94:40:c9:37:04:84,14:02:ec:d9:79:e8,14:02:ec:d9:79:e8,94:40:c9:5f:b5:cc
x3000c0s2b0n0,Management,Master,94:40:c9:37:f9:b4,14:02:ec:da:b8:18,14:02:ec:da:b8:18,94:40:c9:5f:a3:a8
x3000c0s1b0n0,Management,Master,94:40:c9:37:87:32,14:02:ec:da:b9:98,14:02:ec:da:b9:98,14:02:ec:da:b9:99
```

<a name="switch_metadata_csv"></a>
#### `switch_metadata.csv`

The `switch_metadata.csv` file is manually created to include information about all spine, aggregation, CDU, 
and leaf switches in the system.  None of the Slingshot switches for the HSN should be included in this file.

See [Create Switch Metadata CSV](create_switch_metadata_csv.md) for instructions about creating this file.

> use case: 2 leaf switches and 2 spine switches
```
pit# cat example_switch_metadata.csv
Switch Xname,Type,Brand
x3000c0w38,Leaf,Dell
x3000c0w36,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h33s2,Spine,Mellanox
```
> use case: 2 CDU switches, 2 leaf switches, and 2 spines switches
```
pit# cat example_switch_metadata.csv
Switch Xname,Type,Brand
d0w1,CDU,Dell
d0w2,CDU,Dell
x3000c0w38,Leaf,Dell
x3000c0w36,Leaf,Dell
x3000c0h33s1,Spine,Mellanox
x3000c0h34s1,Spine,Mellanox
```

> use case: 2 CDU Switches, 2 leaf switches, 4 aggregation switches, and 2 spine switches
```
pit# cat example_switch_metadata.csv
Switch Xname,Type,Brand
d0w1,CDU,Aruba
d0w2,CDU,Aruba
x3000c0w31,Leaf,Aruba
x3000c0w32,Leaf,Aruba
x3000c0h33s1,Aggregation,Aruba
x3000c0h34s1,Aggregation,Aruba
x3000c0h35s1,Aggregation,Aruba
x3000c0h36s1,Aggregation,Aruba
x3000c0h37s1,Spine,Aruba
x3000c0h38s1,Spine,Aruba
```

<a name="first_time_install"></a>
### First Time Install of this Release

1. Collect data for `application_node_config.yaml`

   See [Create Application Node YAML](create_application_node_config_yaml.md) for instructions about creating this file.

1. Collect data for `cabinets.yaml`

   See [Create Cabinets YAML](create_cabinets_yaml.md) for instructions about creating this file.

1. Collect data for `hmn_connections.json`

   See [Create HMN Connections JSON](create_hmn_connections_json.md) for instructions about creating this file.

1. Collect data for `ncn_metadata.csv`

   Some of the data in the `ncn_metadata.csv` can be found in the SHCD.  However, the hardest data
   to collect is the MAC addresses for the node's BMC, the node's bootable network interface, and the
   pair of network interfaces which will become the bonded interface `bond0`.
   
   If the nodes are booted to Linux, then the data can be collected by `ipmitool lan print` for the BMC MAC,
   and the `ip a` command for the other NICs.  
   
   If the nodes are not booted and there is SSH access to the spine and leaf switches, it is possible to
   collect information from the spine and leaf switches.
   
   If the nodes are not booted and there is no SSH access to the spine and leaf switches, it is possible
   to connect to the spine and leaf switches using the method described in
   [NCN Metadata over USB-Serial Cable](303-NCN-METADATA-USB-SERIAL.md).

   Unless your system does not use or does not have onboard NICs on the management nodes, then these topics
   will be necessary before constructing the `ncn_metadata.csv` file.
      1. [Enabling Network Boots over Spine Switches](304-NCN-PCIE-NET-BOOT-AND-RE-CABLE.md)
      
      The following two topics will assist with creating `ncn_metadata.csv`.
      
      1. [Collecting BMC MAC Addresses](301-NCN-METADATA-BMC.md)
      2. [Collecting NCN MAC Addresses](302-NCN-METADATA-BONDX.md)

1. Collect data for `switch_metadata.csv`

   See [Create Switch Metadata CSV](create_switch_metadata_csv.md) for instructions about creating this file.

<a name="reinstall"></a>
### Reinstall 

1. [Collect Payload for Reinstall](#collect_payload_for_reinstall)
1. [Standing Kubernetes Down](#standing-kubernetes-down)
1. Prepare CNs and ANs
   * They don't need to be powered off
1. [Prepare the Non-Compute Nodes](#prepare-the-non-compute-nodes)
   1. basic wipe of disks (link) from PIT node or from ncn-m001
   1. power off each NCN from PIT node or from ncn-m001
   1. set NCN BMCs from static to DHCP from PIT node or from ncn-m001
   1. power off NCNs from PIT node or from ncn-m001
   1. power off PIT node or ncn-m001
  
<a name="collect_payload_for_reinstall"></a>
#### Collect Payload for Reinstall

1. How to collect data from previous install for this reinstall
   * which files are needed for a reinstall? save them somewhere else


<a name="standing-kubernetes-down"></a>
#### Standing Kubernetes Down

Runtime DHCP services interfere with the LiveCD's bootstrap nature to provide DHCP leases to BMCs. To remove
edge-cases, disable the run-time cray-dhcp-kea pod.

Scale the deployment from either the LiveCD or any Kubernetes node

```bash
ncn# kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
```

<a name="prepare-the-non-compute-nodes"></a>
#### Prepare the Non-Compute Nodes

The steps below detail how to prepare the NCNs.

<a name="degraded-system-notice"></a>
> #### Degraded System Notice
>
> If the system is degraded; CRAY services are down, or the NCNs are in inconsistent states then a cleanslate should be performed.  See [basic wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe)

1. **REQUIRED** For each NCN, **excluding** ncn-m001, login and wipe it (this step uses the [basic wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#basic-wipe)):
    > **`NOTE`** Pending completion of CASMINST-1659, the auto-wipe is insufficient for masters and workers. All administrators must wipe their NCNs with this step.
    - Wipe NCN disks from **LiveCD** (`pit`)
        ```bash
        pit# ncns=$(grep Bond0 /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F',' '{print $6}')
        pit# for h in $ncns; do
            read -r -p "Are you sure you want to wipe the disks on $h? [y/N] " response
            response=${response,,}
            if [[ "$response" =~ ^(yes|y)$ ]]; then
                 ssh $h 'wipefs --all --force /dev/sd* /dev/disk/by-label/*'
            fi
        done
        ```

    - Wipe NCN disks from **ncn-m001**
        ```bash
        ncn-m001# ncns=$(grep ncn /etc/hosts | grep nmn | grep -v m001 | awk '{print $3}')
        ncn-m001# for h in $ncns; do
            read -r -p "Are you sure you want to wipe the disks on $h? [y/N] " response
            response=${response,,}
            if [[ "$response" =~ ^(yes|y)$ ]]; then
                 ssh $h 'wipefs --all --force /dev/sd* /dev/disk/by-label/*'
            fi
        done
        ```

    In either case, for disks which have no labels, no output will be shown. If one or more disks have labels, output similar
    to the following is expected:
    ```
    ...
    Are you sure you want to wipe the disks on ncn-m003? [y/N] y
    /dev/sda: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sda: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdb: 8 bytes were erased at offset 0x00000200 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdb: 8 bytes were erased at offset 0x6fc86d5e00 (gpt): 45 46 49 20 50 41 52 54
    /dev/sdb: 2 bytes were erased at offset 0x000001fe (PMBR): 55 aa
    /dev/sdc: 6 bytes were erased at offset 0x00000000 (crypto_LUKS): 4c 55 4b 53 ba be
    /dev/sdc: 6 bytes were erased at offset 0x00004000 (crypto_LUKS): 53 4b 55 4c ba be
    ...
    ```

    The thing to verify is that there are no error messages in the output.

2. Power each NCN off using `ipmitool` from ncn-m001 (or the booted LiveCD if reinstalling an incomplete
install).

    - Shutdown from **LiveCD** (`pit`)
        ```bash
        pit# export username=root
        pit# export IPMI_PASSWORD=changeme
        pit# conman -q | grep mgmt | grep -v m001 | xargs -t -i  ipmitool -I lanplus -U $username -E -H {} power off
        ```

    - Shutdown from **ncn-m001**
        ```bash
        ncn-m001# export username=root
        ncn-m001# export IPMI_PASSWORD=changeme
        ncn-m001# grep ncn /etc/hosts | grep mgmt | grep -v m001 | sort -u | awk '{print $2}' | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
        ```

<a name="set-the-bmcs-on-the-systems-back-to-dhcp"></a>
3. Set the BMCs on the systems back to DHCP.
   > **`NOTE`** During the install of the NCNs their BMCs get set to static IP addresses. The installation expects the that the NCN BMCs are set back to DHCP before proceeding.
   
   If you have Intel nodes run:
   ```text
   # export lan=3
   ```
    
   Otherwise run:
   ```text
   # export lan=1
   ```

   * from the **LiveCD** (`pit`):
        > **`NOTE`** This step uses the old statics.conf on the system in case CSI changes IPs:

        ```bash
        pit# export username=root
        pit# export IPMI_PASSWORD=changeme

        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E lan set $lan ipsrc dhcp
        done
        ```

        The timing of this change can vary based on the hardware, so if the IP can no longer be reached after running the above command, run these commands.

        ```
        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E lan print $lan | grep Source
        done

        pit# for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E mc reset cold
        done
        ```

   * from **ncn-m001**:
        > **`NOTE`** This step uses to the `/etc/hosts` file on ncn-m001 to determine the IP addresses of the BMCs:

        ```bash
        ncn-m001# export username=root
        ncn-m001# export IPMI_PASSWORD=changeme
        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E lan set $lan ipsrc dhcp
        done
        ```

        The timing of this change can vary based on the hardware, so if the IP can no longer be reached after running the above command, run these commands.

        ```
        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E lan print $lan | grep Source
        done

        ncn-m001# for h in $( grep ncn /etc/hosts | grep mgmt | grep -v m001 | awk '{print $2}' )
        do
        ipmitool -U $username -I lanplus -H $h -E mc reset cold
        done
        ```

4. Powering Off LiveCD or ncn-m001 node
    > **`Skip this step if`** you are planning to use this node as a staging area to create the LiveCD. Lastly, shutdown the LiveCD or ncn-m001 node.
    ```bash
    ncn-m001# poweroff
    ```

<a name="next-topic"></a>
# Next Topic

   After completing this procedure the next step is to bootstrap the PIT node.

   * See [Bootstrap PIT Node](index.md#bootstrap_pit_node)

