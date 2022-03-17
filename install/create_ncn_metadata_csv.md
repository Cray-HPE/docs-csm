# Create NCN Metadata CSV

The information in the `ncn_metadata.csv` file identifies each of the management nodes, assigns the function
as a master, worker, or storage node, and provides the MAC address information needed to identify the BMC and
the NIC which will be used to boot the node.

Some of the data in the `ncn_metadata.csv` can be found in the SHCD in the HMN tab. However, the hardest data
to collect is the MAC addresses for the node's BMC, the node's bootable network interface, and the
pair of network interfaces which will become the bonded interface `bond0`.

### Topics:

   * [Introduction](#introduction)
      * [LACP Bonding](#lacp_bonding)
   * [PXE or BOOTSTRAP MAC](#pxe_or_bootstrap_mac)
   * [Sample `ncn_metadata.csv`](#sample_ncn_metadata_csv)
   * [Collection of MAC Addresses](#collection_of_mac_addresses)

## Details

<a name="introduction"></a>
### Introduction

Each of the management nodes is represented as a row in the `ncn_metadata.csv` file.

For example:

```
Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
x3000c0s9b0n0,Management,Storage,94:40:c9:37:77:26,14:02:ec:d9:76:88,14:02:ec:d9:76:88,94:40:c9:5f:b6:92
```

For each management node, the component name (xname), role, and subrole can be extracted from the SHCD in the HMN tab. However, the rest of the
MAC address information needs to be collected another way.

Check the description for component names while mapping names between the SHCD and the `ncn_metadata.csv` file.
See [Component Names (xnames)](../operations/Component_Names_xnames.md).

There are two interesting parts to the NCN metadata file:
- The MAC of the BMC
- The MAC(s) of the shasta-network interface(s)

The "shasta-network interface" is the interfaces, one or more, that comprise the NCNs' LACP link-aggregation ports.

<a name="lacp_bonding"></a>
#### LACP Bonding

NCNs may have one or more bond interfaces, which may be comprised from one or more physical interfaces. The
preferred default configuration is two physical network interfaces per bond. The number
of bonds themselves depends on the systems network topology.

For example, systems with 4 network interfaces on a given node could configure either of these
permutations (for redundancy minimums within Shasta cluster):

- One bond with 4 interfaces (`bond0`)
- Two bonds with 2 interfaces each (`bond0` and `bond1`)

For more information, see [NCN Networking](../background/ncn_networking.md) page for NCNs.

<a name="pxe_or_bootstrap_mac"></a>
### PXE or BOOTSTRAP MAC

In general this refers to the interface to be used when the node attempts to PXE boot. This varies between vintages
of systems; systems before "Spring 2020" often booted NCNs with onboard NICs, newer systems boot over their PCIe cards.

If the system is **booting over PCIe then the "bootstrap MAC" and the "bond0 MAC0" will be identical**. If the
system is **booting over onboard NICs then the "bootstrap MAC" and the "bond0 MAC0" will be different.**

> Other Nomenclature
- "BOND MACS" are the MAC addresses for the physical interfaces that the node will use for the various VLANs.
- BOND0 MAC0 and BOND0 MAC1 should **not** be on the same physical network card to establish redundancy for failed chips.
- On the other hand, if any nodes' capacity prevents it from being redundant, then MAC1 and MAC0 will still produce a valid configuration if they do reside on the same physical chip/card.
- The BMC MAC is the exclusive, dedicated LAN for the onboard BMC. It should not be swapped with any other device.

<a name="sample_ncn_metadata_csv"></a>
### Sample `ncn_metadata.csv`

The following are sample rows from a `ncn_metadata.csv` file:

* __Use case__: NCN with a single PCIe card (1 card with 2 ports):
    > Notice how the MAC address for `Bond0 MAC0` and `Bond0 MAC1` are only off by 1, which indicates that
    > they are on the same 2 port card.

    ```
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s6b0n0,Management,Worker,94:40:c9:37:77:b8,14:02:ec:da:bb:00,14:02:ec:da:bb:00,14:02:ec:da:bb:01
    ```

* __Use case__: NCN with a dual PCIe cards (2 cards with 2 ports each for 4 ports total):
* 
    > Notice how the MAC address for `Bond0 MAC0` and `Bond0 MAC1` have a difference greater than 1, which
    > indicates that they are on not on the same 2 port same card.

    ```
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Storage,94:40:c9:37:77:26,14:02:ec:d9:76:88,14:02:ec:d9:76:88,94:40:c9:5f:b6:92
    ```

Example `ncn_metadata.csv` file for a system that has been configured as follows:

 * Management NCNs are configured to boot over the PCIe NICs
 * Master and Storage management NCNs have two 2 port PCIe cards
 * Worker management NCNs have one 2 port PCIe card
  
> Because the NCNs have been configured to boot over their PCIe NICs, the `Bootstrap MAC` and `Bond0 MAC0` columns have the same value.

**IMPORTANT:** Mind the index for each group of nodes (3, 2, 1.... ; not 1, 2, 3). If storage nodes are `ncn-s001 x3000c0s7b0n0`, `ncn-s002 x3000c0s8b0n0`, `ncn-s003 x3000c0s9b0n0`, then their portion of the file would be ordered `x3000c0s9b0n0`, `x3000c0s8b0n0`, `x3000c0s7b0n0`.

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

<a name="collection_of_mac_addresses"></a>
### Collection of MAC Addresses

   Collect as much information as possible for the `ncn_metadata.csv` file before the PIT node is booted
   from the LiveCD and then get the rest later when directed. Having dummy MAC addresses, such as `de:ad:be:ef:00:00`,
   in the `ncn_metadata.csv` file is acceptable until the point during the install at which the management network
   switches have been configured and the PIT node can be used to collect the information. The correct MAC addresses
   are needed before attempting to boot the management nodes with their real image in
   [Deploy Management Nodes](index.md#deploy_management_nodes)

   * If the nodes are booted to Linux, then the data can be collected by `ipmitool lan print` for the BMC MAC,
   and the `ip address` command for the other NICs. This is rarely the case for a first time install.
   The PIT node examples of using these two commands could be extrapolated for other nodes which are booted to Linux.
   See the PIT node examples in [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md) and
   [Collecting NCN MAC Addresses](collecting_ncn_mac_addresses.md).


   * If the nodes are powered up and there is SSH access to the spine and leaf-bmc switches, it is possible to
   collect information from the spine and leaf-bmc switches.
      * The BMC MAC address can be collected from the switches using knowledge about the cabling of the HMN from the SHCD. See [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md).
      * The node MAC addresses cannot be collected until after the PIT node has booted from the LiveCD. At that point, a partial boot of the management nodes can be done to collect the remaining information from the conman console logs on the PIT node using the [Procedure: iPXE Consoles](collecting_ncn_mac_addresses.md#procedure-ipxe-consoles)

   * If the nodes are powered up and there is no SSH access to the spine and leaf switches, it is possible
   to connect to the spine and leaf switches using the method described in
   [Connect to Switch over USB-Serial Cable](connect_to_switch_over_usb_serial_cable.md).
      * The BMC MAC address can be collected from the switches using knowledge about the cabling of the HMN from the SHCD. See [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md).
      * The node MAC addresses cannot be collected until after the PIT node has booted from the LiveCD. At that point, a partial boot of the management nodes can be done to collect the remaining information from the conman console logs on the PIT node using the [Procedure: iPXE Consoles](collecting_ncn_mac_addresses.md#procedure-ipxe-consoles)

   * In all other cases, the full information needed for `ncn_metadata.csv` will not be available for collection
   until after the PIT node has been booted from the LiveCD. Having incorrect MAC addresses
   in the `ncn_metadata.csv` file as placeholders is acceptable until the point during the install at which the management
   network switches have been configured and the PIT node can be used to collect the information.

      * At that point in the installation workflow, the [Collect MAC Addresses for NCNs](collect_mac_addresses_for_ncns.md) procedure will be used.

   * Unless the system does not use or does not have onboard NICs on the management nodes, then this topic
   may be necessary before constructing the `ncn_metadata.csv` file.
      
      * See [Switch PXE Boot from Onboard NIC to PCIe](switch_pxe_boot_from_onboard_nic_to_pcie.md) for more information.

