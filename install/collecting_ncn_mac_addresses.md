# Collecting NCN MAC Addresses

This procedure will detail how to collect the NCN MAC addresses from an HPE Cray EX system. The MAC addresses needed for the Bootstrap MAC, Bond0 MAC0, and Bond0 MAC1 columns in `ncn_metadata.csv` will be collected.

The Bootstrap MAC address will be used for identification of this node during the early part of the PXE boot process before the bonded interface can be established.

The Bond0 MAC0 and Bond0 MAC1 are the MAC addresses for the physical interfaces that the node will use for the various VLANs.
The Bond0 MAC0 and Bond0 MAC1 should be on the different network cards to establish redundancy for a failed network card.
On the other hand, if the node has only a single network card, then MAC1 and MAC0 will still produce a valid configuration if they do reside on the same physical card.

#### Sections

- [Collecting NCN MAC Addresses](#collecting-ncn-mac-addresses)
      - [Sections](#sections)
  - [Procedure: iPXE Consoles](#procedure-ipxe-consoles)
      - [Requirements](#requirements)
      - [MAC Collection](#mac-collection)
  - [Procedure: Serial Consoles](#procedure-serial-consoles)
  - [Procedure: Recovering from an incorrect `ncn_metadata.csv` file](#procedure-recovering-from-an-incorrect-ncn_metadatacsv-file)

The easy way to do this leverages the NIC-dump provided by the metal-ipxe package. This page will walk-through
booting NCNs and collecting their MACs from the ConMan console logs.

> The alternative is to use serial cables (or SSH) to collect the MACs from the switch ARP tables, this can become exponentially difficult for large systems.
> If this is the only way, please proceed to the bottom of this page.

<a name="procedure-ipxe-consoles"></a>
## Procedure: iPXE Consoles

This procedure is faster for those with the LiveCD (CRAY Pre-Install Toolkit). It can be used to quickly
boot-check nodes to dump network device information without an operating system. This works by accessing the PCI Configuration Space.

<a name="requirements"></a>
#### Requirements

> If CSI does not work because of a file requirement, please file a ticket. By default, dnsmasq
> and ConMan are already running on the LiveCD, but bond0 needs to be configured. dnsmasq needs to
> serve/listen over bond0, and ConMan needs the BMC information.

1. LiveCD dnsmasq is configured for the bond0/metal network (NMN/HMN/CAN do not matter)
2. BMC MAC addresses already collected
3. LiveCD ConMan is configured for each BMC

For help with either of those, see [LiveCD Setup](bootstrap_livecd_remote_iso.md).

<a name="mac-collection"></a>
#### MAC Collection

1. (Optional) Shim the boot so nodes bail after dumping their network devices.

   Removing the iPXE script will prevent network booting. Be aware that the nodes may disk boot.

   This will prevent the nodes from continuing to boot and end in undesired states.

    ```bash
    pit# mv /var/www/boot/script.ipxe /var/www/boot/script.ipxe.bak
    ```

2. Verify consoles are active with `conman -q`. The following command lists all nodes that ConMan is configured for,

    ```bash
    pit# conman -q
    ncn-m002-mgmt
    ncn-m003-mgmt
    ncn-s001-mgmt
    ncn-s002-mgmt
    ncn-s003-mgmt
    ncn-w001-mgmt
    ncn-w002-mgmt
    ncn-w003-mgmt
    ```

3. Set the nodes to PXE boot and (re)start them.

    ```bash
    pit# export USERNAME=root
    pit# export IPMI_PASSWORD=changeme
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=efiboot,persistent
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    pit# sleep 10
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
    ```
4. Wait for the nodes to netboot. You can follow them with ConMan - the `-m` option follows the console output in read-only mode or the `-j` option joins an interactive console session. The available node names were listed in step 2 above. The boot usually starts in less than 3 minutes and log data should start flowing through ConMan, speed depends on how quickly your nodes POST. To see a ConMan help screen for all supported escape sequences use `&?`.

    ```
    pit# conman -m ncn-m002-mgmt
    <ConMan> Connection to console [ncn-m002-mgmt] opened.
      << hardware dependent boot log messages >>
    ```
5. Exit ConMan by typing `&.`
    ```
      << hardware dependent boot log messages >>
    &.
    <ConMan> Connection to console [ncn-m002-mgmt] closed.
    pit#
    ```
6. Print off what has been found in the console logs, this snippet will omit duplicates from multiple boot attempts:
    ```bash
    pit# for file in /var/log/conman/*; do
        echo $file
        grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI && echo -----
    done
    ```

7. Use the output from the previous step to collect 2 MACs to use for bond0, and 2 more to use for bond1 based on the topology.

   **The `Bond0 MAC0` must be the first port** of the first PCIe card, specifically the port connecting the NCN to the lower spine. For example, if connected to spines01 and 02, this is going to sw-spine-001. If connected to sw-spine-007 and sw-spine-008, then this is sw-spine-007.

   **The 2nd MAC for `bond0` is the first port of the 2nd PCIe card, or 2nd port of the first when only one card exists**.

   Use the table provided on [NCN Networking](../background/ncn_networking.md) for referencing commonly seen devices.

   Worker nodes also have the high-speed network cards. If these cards are known, filter their device IDs out from the above output using this snippet:

   ```bash
   pit# unset did # clear it if you used it.
   pit# did=1017 # ConnectX-5 example.
   pit# for file in /var/log/conman/*; do
     echo $file
     grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI | grep -Ev "$did" && echo -----
   done
   ```
   To filter out onboard NICs, or site-link cards, omit their device IDs as well. Use the above snippet but add the other IDs:

   **This snippet prints out only mgmt MACs, the `did` is the HSN and onboard NICs that is being ignored.**

    ```bash
    pit# unset did # clear it if you used it.
    pit# did='(1017|8086|ffff)'
    pit# for file in /var/log/conman/*; do
        echo $file
        grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI | grep -Ev "$did" && echo -----
    done
    ```

8. Examine the output from `grep` to identify the MAC address that make up Bond0 for each management NCN. Use the lowest value MAC address per PCIe card.

    > Example: 1 PCIe card with 2 ports for a total of 2 ports per node.

    ```bash
    -----
    /var/log/conman/console.ncn-w003-mgmt
    net2 MAC b8:59:9f:d9:9e:2c PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac0 (0x2c < 0x2d)
    net3 MAC b8:59:9f:d9:9e:2d PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac1
    -----
    ```

    The above output identified MAC0 and MAC1 of the bond as b8:59:9f:d9:9e:2c and b8:59:9f:d9:9e:2d respectively.

    > Example: 2 PCIe cards with 2 ports each for a total of 4 ports per node.

    ```bash
    -----
    /var/log/conman/console.ncn-w006-mgmt
    net0 MAC 94:40:c9:5f:b5:df PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac0 (0xdf < 0xe0)
    net1 MAC 94:40:c9:5f:b5:e0 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    net2 MAC 14:02:ec:da:b9:98 PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac1 (0x98 < 0x99)
    net3 MAC 14:02:ec:da:b9:99 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
    -----
    ```

    The above output identified MAC0 and MAC1 of the bond as 94:40:c9:5f:b5:df and 14:02:ec:da:b9:99 respectively.

9. Collect the NCN MAC address for the PIT node. This information will be used to populate the MAC addresses for `ncn-m001`.

   ```bash
   pit# cat /proc/net/bonding/bond0  | grep Perm
   Permanent HW addr: b8:59:9f:c7:12:f2 <-bond0-mac0
   Permanent HW addr: b8:59:9f:c7:12:f3 <-bond0-mac1
   ```

10.  Update `ncn_metadata.csv` with the collected MAC addresses for Bond0 from all of the management NCNs.

    > **NOTE:** Mind the index (3, 2, 1.... ; not 1, 2, 3).

    For each NCN update the corresponding row in `ncn_metadata` with the values for Bond0 MAC0 and Bond0 MAC1. The Bootstrap MAC should have the same value as the Bond0 MAC0.

    ```
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Worker,94:40:c9:37:77:26,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f3
                                                      ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^
                                                      bond0-mac0        bond0-mac0        bond0-mac1
    ```

    ```bash
    pit# vi ncn_metadata.csv
    ```

11. If the `script.ipxe` file was renamed in the first step of this procedure, restore it to its original location.

    ```bash
    pit# mv /var/www/boot/script.ipxe.bak /var/www/boot/script.ipxe
    ```

<a name="procedure-serial-consoles"></a>
## Procedure: Serial Consoles

Pick out the MAC addresses for the BOND from both the sw-spine-001 and sw-spine-002 switch following the [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md) procedure.

> **NOTE:** The node must be booted into an operating system in order for the Bond MAC addresses to appear on the spine switches.

> A PCIe card with dual-heads may go to either spine switch, meaning MAC0 must be collected from
> spine-01. Please refer to the cabling diagram or the actual rack (in-person).

1. Follow "Metadata BMC" on each spine switch that port1 and port2 of the bond is plugged into.

2. Usually the 2nd/3rd/4th/Nth MAC on the PCIe card will be a 0x1 or 0x2 deviation from the first port.

   Collection is quicker if this can be easily confirmed.

<a name="procedure-recovering-from-an-incorrect-ncn_metadata_csv-file"></a>
## Procedure: Recovering from an incorrect `ncn_metadata.csv` file

If the  `ncn_metadata.csv` file is incorrect, the NCNs will be unable to deploy. This section details a recovery procedure in case that happens.

1. Remove the incorrectly generated configurations.

   Before deleting the incorrectly generated configurations, make a backup of them in case they need to be examined at a later time.

    > **`WARNING`** Ensure that the `SYSTEM_NAME` environment variable is correctly set. If `SYSTEM_NAME` is
    > not set the command below could potentially remove the entire prep directory.
    > ```bash
    > pit# export SYSTEM_NAME=eniac
    > ```

    ```bash
    pit# rm -rf /var/www/ephemeral/prep/$SYSTEM_NAME
    ```

2. Manually edit `ncn_metadata.csv`, replacing the bootstrap MAC address with Bond0 MAC0 address for the afflicted nodes that failed to boot.

3. Re-run `csi config init` with the required flags.

4. Copy all of the newly generated files into place.

    ```bash
    pit# \
    cp -p /var/www/ephemeral/prep/$SYSTEM_NAME/dnsmasq.d/* /etc/dnsmasq.d/*
    cp -p /var/www/ephemeral/prep/$SYSTEM_NAME/basecamp/* /var/www/ephemeral/configs/
    cp -p /var/www/ephemeral/prep/$SYSTEM_NAME/conman.conf /etc/
    cp -p /var/www/ephemeral/prep/$SYSTEM_NAME/pit-files/* /etc/sysconfig/network/
    ```

5. Update the CA Cert on the copied data.json file. Provide the path to the data.json, the path to the customizations.yaml file, and the sealed_secrets.key.

    ```bash
    pit# csi patch ca \
    --cloud-init-seed-file /var/www/ephemeral/configs/data.json \
    --customizations-file /var/www/ephemeral/prep/site-init/customizations.yaml \
    --sealed-secret-key-file /var/www/ephemeral/prep/site-init/certs/sealed_secrets.key
    ```

6. Restart everything to apply the new configurations:

    ```bash
    pit# \
    wicked ifreload all
    systemctl restart dnsmasq conman basecamp
    systemctl restart nexus
    ```

7. Ensure system-specific settings generated by CSI are merged into `customizations.yaml`:

    > The `yq` tool used in the following procedures is available under `/var/www/ephemeral/prep/site-init/utils/bin` once the `SHASTA-CFG` repo has been cloned.

    ```bash
    pit# alias yq="/var/www/ephemeral/prep/site-init/utils/bin/$(uname | awk '{print tolower($0)}')/yq"
    pit# yq merge -xP -i /var/www/ephemeral/prep/site-init/customizations.yaml <(yq prefix -P "/var/www/ephemeral/prep/${SYSTEM_NAME}/customizations.yaml" spec)
    ```

8. Wipe the disks before relaunching the NCNs.

   See [full wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#full-wipe).

