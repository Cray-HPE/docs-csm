# Collecting NCN MAC Addresses

This procedure will detail how to collect the NCN MAC addresses from an HPE Cray EX system. The MAC addresses needed for the `Bootstrap MAC`, `Bond0 MAC0`, and `Bond0 MAC1` columns in `ncn_metadata.csv` will be collected.

The Bootstrap MAC address will be used for identification of this node during the early part of the PXE boot process before the bonded interface can be established.

The `Bond0 MAC0` and `Bond0 MAC1` are the MAC addresses for the physical interfaces that the node will use for the various VLANs.
`Bond0 MAC0` and `Bond0 MAC1` should be on the different network cards in order to establish redundancy for a failed network card.
On the other hand, this is not an absolute requirement. If the node has only a single network card, then this will force `MAC1` and `MAC0` to reside on the same physical card; this will still produce a valid configuration.

## Sections

- [Procedure: iPXE consoles](#procedure-ipxe-consoles)
  - [Requirements](#requirements)
  - [MAC address collection](#mac-collection)
- [Procedure: Serial consoles](#procedure-serial-consoles)
- [Procedure: Recovering from an incorrect `ncn_metadata.csv` file](#procedure-recovering-from-an-incorrect-ncn_metadatacsv-file)

The easy way to do this leverages the NIC information dumping provided by the `metal-ipxe` package. This page will walk through
booting NCNs and collecting their MAC addresses from the ConMan console logs.

> The alternative is to use serial cables (or SSH) to collect the MAC addresses from the switch ARP tables; this can become exponentially difficult for large systems.
> If this is the only way, then proceed to the bottom of this page.

<a name="procedure-ipxe-consoles"></a>

## Procedure: iPXE consoles

This procedure is faster for those with the LiveCD (CRAY Pre-Install Toolkit). It can be used to quickly
boot nodes and have them dump network device information without an operating system. This works by accessing the PCI configuration space.

<a name="requirements"></a>

### Requirements

> If CSI does not work because of a file requirement, then file a ticket. By default, `dnsmasq`
> and ConMan are already running on the LiveCD, but `bond0` needs to be configured. `dnsmasq` needs to
> serve and listen over `bond0`, and ConMan needs the BMC information.

1. LiveCD `dnsmasq` is configured for the `bond0`/metal network (NMN/HMN/CAN do not matter)
1. BMC MAC addresses already collected
1. LiveCD ConMan is configured for each BMC

For help with any of those, see [LiveCD Setup](bootstrap_livecd_remote_iso.md).

<a name="mac-collection"></a>

### MAC address collection

1. (Optional) Prevent the nodes from fully PXE booting.

    Modify the boot so nodes stop booting after dumping their network devices. Removing the iPXE script will prevent network booting. Be aware that the nodes may still disk boot.

    ```bash
    pit# mv -v /var/www/boot/script.ipxe /var/www/boot/script.ipxe.bak
    ```

1. Verify that consoles are active.

    The following command lists all nodes for which ConMan is configured:

    ```bash
    pit# conman -q
    ```

    Example output:

    ```text
    ncn-m002-mgmt
    ncn-m003-mgmt
    ncn-s001-mgmt
    ncn-s002-mgmt
    ncn-s003-mgmt
    ncn-w001-mgmt
    ncn-w002-mgmt
    ncn-w003-mgmt
    ```

1. Set the nodes to PXE boot, power them off, and then power them on.

    1. Set necessary variables.

        > `read -s` is used in order to prevent the credentials from being displayed on the screen or recorded in the shell history.

        ```bash
        pit# USERNAME=root
        pit# read -s IPMI_PASSWORD
        pit# export IPMI_PASSWORD
        ```

    1. Set the nodes to PXE boot.

        ```bash
        pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
                xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} chassis bootdev pxe options=efiboot,persistent
        ```

    1. Power off the nodes.

        ```bash
         pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
                xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
        ```

    1. After 10 seconds, power on the nodes.

        ```bash
        pit# sleep 10 && grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u |
                xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power on
        ```

1. Wait for the nodes to network boot.

    - This can be monitored using ConMan.
    - `conman -m` follows the console output in read-only mode.
    - `conman -j` joins an interactive console session.
    - The available console names were listed earlier by running `conman -q`.
    - In order to see a ConMan help screen for all supported escape sequences, type `&?`.
    - The boot usually starts in less than 3 minutes, after which log data should start flowing through ConMan.

    ```console
    pit# conman -m ncn-m002-mgmt
    <ConMan> Connection to console [ncn-m002-mgmt] opened.
      << hardware-dependent boot log messages >>
    ```

1. Exit ConMan.

    Exit by typing `&.`

    ```console
      << hardware-dependent boot log messages >>
    &.
    <ConMan> Connection to console [ncn-m002-mgmt] closed.
    pit#
    ```

1. Print off what has been found in the console logs.

    This snippet will omit duplicates from multiple boot attempts:

    ```bash
    pit# for file in /var/log/conman/*; do
            echo $file
            grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI && echo -----
         done
    ```

1. Collect the `Bond0 MAC0` and `Bond0 MAC1` addresses from the previous output.

    - The first MAC address for `bond0` (**`Bond0 MAC0`**) must be the first port of the first PCIe card, specifically the port connecting the NCN to the lower spine.
      - For example, if connected to `sw-spine-001` and `sw-spine-002`, then this is going to be the port connected to `sw-spine-001`.
      - If connected to `sw-spine-007` and `sw-spine-008`, then this is going to be the port connected to `sw-spine-007`.
    - The second MAC address for `bond0` (**`Bond0 MAC1`**) is the first port of the second PCIe card, or second port of the first, when only one card exists.
    - Use the table provided in [NCN Networking](../background/ncn_networking.md) for referencing commonly seen devices.
    - Worker nodes also have the high-speed network cards. If these cards are known, filter their device IDs out from the above output using this snippet:

        ```bash
        pit# unset did # clear it if you used it.
        pit# did=1017 # ConnectX-5 example.
        pit# for file in /var/log/conman/*; do
               echo $file
               grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI | grep -Ev "$did" && echo -----
             done
        ```

    - To filter out onboard NICs, or site-link cards, omit their device IDs as well. Use the above snippet but add the other IDs:

        **This snippet prints out only `mgmt` MAC addresses; the `did` is the HSN and onboard NICs that are being ignored.**

        ```bash
        pit# unset did # clear it if you used it.
        pit# did='(1017|8086|ffff)'
        pit# for file in /var/log/conman/*; do
               echo $file
               grep -Eoh '(net[0-9] MAC .*)' $file | sort -u | grep PCI | grep -Ev "$did" && echo -----
             done
        ```

    - Example: One PCIe card with two ports, for a total of two ports per node.

        ```text
        -----
        /var/log/conman/console.ncn-w003-mgmt
        net2 MAC b8:59:9f:d9:9e:2c PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac0 (0x2c < 0x2d)
        net3 MAC b8:59:9f:d9:9e:2d PCI.DeviceID 1013 PCI.VendorID 15b3 <-bond0-mac1
        -----
        ```

        The above output identified `MAC0` and `MAC1` of the bond as `b8:59:9f:d9:9e:2c` and `b8:59:9f:d9:9e:2d` respectively.

    - Example: Two PCIe cards with two ports each, for a total of four ports per node.

        ```text
        -----
        /var/log/conman/console.ncn-w006-mgmt
        net0 MAC 94:40:c9:5f:b5:df PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac0 (0xdf < 0xe0)
        net1 MAC 94:40:c9:5f:b5:e0 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
        net2 MAC 14:02:ec:da:b9:98 PCI.DeviceID 8070 PCI.VendorID 1077 <-bond0-mac1 (0x98 < 0x99)
        net3 MAC 14:02:ec:da:b9:99 PCI.DeviceID 8070 PCI.VendorID 1077 (future use)
        -----
        ```

        The above output identified `MAC0` and `MAC1` of the bond as `94:40:c9:5f:b5:df` and `14:02:ec:da:b9:99` respectively.

1. Collect the NCN MAC addresses for the PIT node.

    This information will be used to populate the MAC addresses for `ncn-m001`.

    ```bash
    pit# cat /proc/net/bonding/bond0  | grep Perm
    ```

    Example output:

    ```text
    Permanent HW addr: b8:59:9f:c7:12:f2 <-bond0-mac0
    Permanent HW addr: b8:59:9f:c7:12:f3 <-bond0-mac1
    ```

1. Update `ncn_metadata.csv` with the collected MAC addresses for `Bond0` from all of the management NCNs.

    > **NOTE:** The NCNs are listed in descending numerical order in `ncn_metadata.csv` (that is, `ncn-s003` is earlier in the file than `ncn-s002`, for example).

    For each NCN, update the corresponding row in `ncn_metadata` with the values for `Bond0 MAC0` and `Bond0 MAC1`. The `Bootstrap MAC` should have the same value as the `Bond0 MAC0`.

    ```csv
    Xname,Role,Subrole,BMC MAC,Bootstrap MAC,Bond0 MAC0,Bond0 MAC1
    x3000c0s9b0n0,Management,Worker,94:40:c9:37:77:26,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f2,b8:59:9f:c7:12:f3
    ```

    ```text
                                                      ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^
                                                      bond0-mac0        bond0-mac0        bond0-mac1
    ```

    ```bash
    pit# vi ncn_metadata.csv
    ```

1. Power off the NCNs.

    ```bash
    pit# grep -oP "($mtoken|$stoken|$wtoken)" /etc/dnsmasq.d/statics.conf | sort -u | xargs -t -i ipmitool -I lanplus -U $USERNAME -E -H {} power off
    ```

1. If the `script.ipxe` file was renamed in the first step of this procedure, then restore it to its original location.

    ```bash
    pit# [[ -s /var/www/boot/script.ipxe.bak ]] && mv -v /var/www/boot/script.ipxe.bak /var/www/boot/script.ipxe
    ```

<a name="procedure-serial-consoles"></a>

## Procedure: Serial consoles

Pick out the MAC addresses for the `BOND` from both the `sw-spine-001` and `sw-spine-002` switches, following the [Collecting BMC MAC Addresses](collecting_bmc_mac_addresses.md) procedure.

> **NOTE:** The node must be booted into an operating system in order for the bond MAC addresses to appear on the spine switches.
>
> A PCIe card with dual-heads may go to either spine switch, meaning `MAC0` must be collected from
> `spine-01`. Refer to the cabling diagram or the actual rack (in-person).

1. Follow `Metadata BMC` on each spine switch that `port1` and `port2` of the bond are plugged into.

1. Usually the MAC addresses on a PCIe card will be sequential hexadecimal numbers.

   Collection is quicker if this can be easily confirmed.

<a name="procedure-recovering-from-an-incorrect-ncn_metadata_csv-file"></a>

## Procedure: Recovering from an incorrect `ncn_metadata.csv` file

If the `ncn_metadata.csv` file is incorrect, then the NCNs will be unable to deploy properly. This section details a recovery procedure in case that happens.

1. Validate that the `SYSTEM_NAME` and `PITDATA` variables are set.

    Normally by this point of an install, they should both be set in `/etc/environment`, and therefore be set in every new shell session.

    ```bash
    pit# echo -e "SYSTEM_NAME=${SYSTEM_NAME}\nPITDATA=${PITDATA}"
    ```

1. Move the incorrectly generated configuration directory.

    ```bash
    pit# mv -v ${PITDATA}/prep/${SYSTEM_NAME} ${PITDATA}/prep/${SYSTEM_NAME}.$(date +%Y-%m-%d_%H-%M-%S)
    ```

    > It is recommended that the renamed directory be retained, at least temporarily, in case information from it is later needed for debugging purposes.

1. Manually edit `ncn_metadata.csv`, replacing the bootstrap MAC address with `Bond0 MAC0` address for the afflicted nodes.

1. Re-run `csi config init` with the required flags.

1. Copy all of the newly generated files into place.

    ```bash
    pit# cp -pv ${PITDATA}/prep/${SYSTEM_NAME}/dnsmasq.d/* /etc/dnsmasq.d/ &&
         cp -pv ${PITDATA}/prep/${SYSTEM_NAME}/basecamp/* ${PITDATA}/configs/ &&
         cp -pv ${PITDATA}/prep/${SYSTEM_NAME}/conman.conf /etc/ &&
         cp -pv ${PITDATA}/prep/${SYSTEM_NAME}/pit-files/* /etc/sysconfig/network/
    ```

1. Update the CA certificates on the copied `data.json` file.

    Provide the path to the `data.json`, `customizations.yaml`, and `sealed_secrets.key` files. The
    paths in the following example are the usual default locations during a CSM install.

    ```bash
    pit# csi patch ca \
            --cloud-init-seed-file ${PITDATA}/configs/data.json \
            --customizations-file ${PITDATA}/prep/site-init/customizations.yaml \
            --sealed-secret-key-file ${PITDATA}/prep/site-init/certs/sealed_secrets.key
    ```

1. Restart everything to apply the new configurations:

    ```bash
    pit# wicked ifreload all &&
         systemctl restart dnsmasq conman basecamp &&
         systemctl restart nexus
    ```

1. Ensure system-specific settings generated by CSI are merged into `customizations.yaml`:

    > The `yq` tool used in the following procedures is available under `${PITDATA}/prep/site-init/utils/bin` once the `SHASTA-CFG` repository has been cloned during
    > the [Prepare Site Init](prepare_site_init.md) procedure.

    ```bash
    pit# alias yq="${PITDATA}/prep/site-init/utils/bin/$(uname | awk '{print tolower($0)}')/yq" ; \
         yq merge -xP -i ${PITDATA}/prep/site-init/customizations.yaml <(yq prefix -P "${PITDATA}/prep/${SYSTEM_NAME}/customizations.yaml" spec)
    ```

1. Wipe the disks before relaunching the NCNs.

   See [full wipe from Wipe NCN Disks for Reinstallation](wipe_ncn_disks_for_reinstallation.md#full-wipe).

1. Set BMCs to DHCP, if needed.

   For any NCNs which booted far enough to begin running `cloud-init`, set their BMCs to DHCP. If in doubt, it does no
   harm to perform this step. See [Set node BMCs to DHCP](prepare_management_nodes.md#set_node_bmcs_to_dhcp).
