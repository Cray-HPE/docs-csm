# Prepare Configuration Payload

TODO will this become 2 separate files, each with a focus on one of these two paths?

* First Time Install of this Release
* Reinstall of this Release

TODO edit data from 002-CSM-INSTALL.md.  This should prepare the configuration payload.

This page will prepare you for a CSM install using the LiveCD in different scenarios.

* [CSM Install Prerequisites](#csm-install-prerequisites)
* [Starting an Installation](#starting-an-installation)

  * [Boot the LiveCD](#boot-the-livecd)

<a name="csm-install-prerequisites"></a>
# CSM Install Prerequisites

The prerequisites for each install scenario are defined here. **All prerequisites must be met
before commencing an installation**.

After finishing any of these prerequisite guides, an administrator may move
to [Starting an Installation](#starting-an-installation).

#### Available Installation Paths

  * [Prerequisites for Shasta v1.4 Installations on Bare-metal Systems](#prerequisites-for-shasta-v14-installations-on-bare-metal-systems)
  * [Prerequisites for Reinstalling Shasta v1.4](#prerequisites-for-reinstalling-shasta-v14)

---

<a name="prerequisites-for-shasta-v14-installations-on-bare-metal-systems"></a>
## Prerequisites for Shasta v1.4 Installations on Bare-metal Systems

Each item below defines a prerequisite necessary for a bare-metal installation to succeed.

> **`NOTE`** On bare-metal, the LiveCD tool will assist with these steps.

* [LiveCD Setup](#livecd-setup)
* [Collect Config Payload](#collect-config-payload)
* [Network Configuration and Firmware](#network-configuration-and-firmware)
* [Upgrading BIOS and Firmware](#upgrading-bios-and-firmware)

<a name="livecd-setup"></a>
### LiveCD Setup

A 1TB USB3.0 USB stick will be required in order to create a bootable LiveCD.

The LiveCD itself can be used out-of-the-box, and with only a little configuration it can serve for
the various bare-metal prerequisite tasks.

Experimental - See **[LiveCD Quick Setup](062-LIVECD-VIRTUAL-ISO-BOOT.md)** for either remote ISO path, this is useful for exploring a new system quickly. Other lab users may prefer a bootable USB stick to enable persistence, and for bringing artifacts for firmware updates.

Once you are booted into a LiveCD, proceed onto the next prerequisite steps for bare-metal.

<a name="collect-config-payload"></a>
### Collect Config Payload

New configuration files are needed for the installation of Shasta v1.4.

See the [Service Guides](300-SERVICE-GUIDES.md) for information regarding the four files.

<a name="network-configuration-and-firmware"></a>
### Network Configuration and Firmware

To complete this step, the network configuration needs to be applied. For information on bare
configurations, firmware, and more, see [Management network install](401-MANAGEMENT-NETWORK-INSTALL.md).

<a name="upgrading-bios-and-firmware"></a>
### Upgrading BIOS and Firmware

The management NCNs are expected to have certain minimum firmware installed for BMC, node BIOS, and PCIe card
firmware.  Where possible, the firmware should be updated prior to install.  Some firmware can be updated
during or after the Shasta v1.4 installation, but it is better to meet the minimum NCN firmware requirement
before starting.

1. Check the minimum required BIOS settings on management nodes.

   For setting each one, please refer to the vendor manuals for the systems inventory.
   
   > **`NOTE`** The table below declares desired settings; unlisted settings should remain at vendor-default. This table may be expanded as new settings are adjusted.
   
   | Common Name | Common Value | Memo | Menu Location
   | --- | --- | --- | --- |
   | Intel® Hyper-Threading (e.g. HT) | `Enabled` | Enables two-threads per physical core. | Within the Processor or the PCH Menu.
   | Intel® Virtualization Technology (e.g. VT-x, VT) and AMD Virtualization Technology (e.g. AMD-V)| `Enabled` | Enables Virtual Machine extensions. | Within the Processor or the PCH Menu.
   | PXE Retry Count | 1 or 2 (default: 1) | Attempts done on a single boot-menu option (note: 2 should be set for systems with unsolved network congestion). | Within the Networking Menu, and then under Network Boot.
   
   > **`NOTE`** **PCIe** options can be found in [PCIe : Setting Expected Values](304-NCN-PCIE-NET-BOOT-AND-RE-CABLE.md#setting-expected-values).

2. For minimum NCN firmware versions see [Node Firmware](252-FIRMWARE-NCN.md).

3. For minimum Network switch firmware versions see [Network Firmware](251-FIRMWARE-NETWORK.md).

4. For minimum Network switch configurations see [Management Network Install](401-MANAGEMENT-NETWORK-INSTALL.md).

> **`WARNING`** Skipping this on a system that is new to Shasta v1.4 (bare-metal or previously installed with Shasta v1.3 or earlier) can result in undesirable difficulties:
>
> - Misnamed interfaces (missing `hsn0`)
> - Malfunctioning bonds (`bond0`)
> - Link failures (i.e. QLogic cards set to 10Gbps fixed)
> - Malfunctioning or disabled Multi-Chassis LAGG
> - Back-firing work-around scripts


> Next: Starting an Installation

The system is now ready for [Starting an Installation](#starting-an-installation).

---

<a name="prerequisites-for-reinstalling-shasta-v14"></a>
## Prerequisites for Reinstalling Shasta v1.4

The following prerequisites must be completed in order to successfully reinstall Shasta v1.4.

* [Standing Kubernetes Down](#standing-kubernetes-down)
* [Prepare the Non-Compute Nodes](#prepare-the-non-compute-nodes)

<a name="standing-kubernetes-down"></a>
### Standing Kubernetes Down

Runtime DHCP services interfere with the LiveCD's bootstrap nature to provide DHCP leases to BMCs. To remove
edge-cases, disable the run-time cray-dhcp-kea pod.

Scale the deployment from either the LiveCD or any Kubernetes node

```bash
ncn# kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
```

<a name="prepare-the-non-compute-nodes"></a>
### Prepare the Non-Compute Nodes

> UANs and CNs do not need to be powered off.

The steps below detail how to prepare the NCNs.

<a name="degraded-system-notice"></a>
> #### Degraded System Notice
>
> If the system is degraded; CRAY services are down, or the NCNs are in inconsistent states then a cleanslate should be performed.  [basic wipe from Disk Cleanslate](wipe_ncn_disks_for_reinstallation.md#basic-wipe)

1. **REQUIRED** For each NCN, **excluding** ncn-m001, login and wipe it (this step uses the [basic wipe from Disk Cleanslate](wipe_ncn_disks_for_reinstallation.md#basic-wipe)):
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

TODO reference these files

301-NCN-METADATA-BMC.md Collecting the BMC MAC Addresses
302-NCN-METADATA-BONDX.md Collecting NCN MAC Addresses
303-NCN-METADATA-USB-SERIAL.md NCN Metadata over USB-Serial Cable
305-SWITCH-METADATA.md Switch Metadata
307-HMN-CONNECTIONS.md HMN Connections File
308-APPLICATION-NODE-CONFIG.md Application Node Config
310-CABINETS.md Cabinets

<a name="next-topic"></a>
# Next topic

   After completing this procedure the next step is to bootstrap the PIT node.

   * See [Bootstrap PIT Node](index.md#bootstrap_pid_node)

