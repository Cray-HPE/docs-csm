# CSM Install

This page will prepare you for a CSM install using the LiveCD in different situations and contexts.

* [Install Pre-Requisites](#install-pre-requisites)
  * [Installing onto Shasta v1.3 Systems](#installing-onto-shasta-v13-systems) for previously
  * [Installing onto Bare-metal Systems](#installing-onto-bare-metal-systems) for new machines with no
  * [Reinstalling a Shasta v1.4 System](#reinstalling-a-shasta-v14-system) for previously deployed shasta-1.4
* [Starting an Installation](#starting-an-installation)
  * [Boot the LiveCD](#boot-the-livecd)

<a name="install-pre-requisites"></a>
# Install Pre-Requisites

The pre-requisites for each install context are defined here. **All pre-requisites must be met
before commencing an installation**.


After finishing either of these pre-requisite guides, an administrator may move
onto [Starting an Installation](#starting-an-installation).

---

<a name="installing-onto-shasta-v13-systems"></a>
## Installing onto Shasta v1.3 Systems


Each item below defines a pre-requisite that must be completed on systems with existing Shasta
v1.3 (or earlier)
installations. Optional steps are noted as such.

* [Collect Shasta-1.4 Config Payload](#collect-shasta-14-config-payload)
  * [Upgrading BIOS and Firmware](#upgrading-bios-and-firmware)
  * [Re-cabling](#re-cabling)
    * [Site Connections](#site-connections)
    * [PCIe Connections](#pcie-connections)
  * [Set the BMCs on the systems back to DHCP](#bmcs-back-to-dhcp)
  * [Powering off NCNs](#powering-off-ncns)

<a name="collect-shasta-14-config-payload"></a>
### Collect Shasta-1.4 Config Payload

New configuration files are needed and can be easier to collect from a running Shasta-1.3 system.

See the [service guides](300-SERVICE-GUIDES.md) for information regarding the three files.

<a name="upgrading-bios-and-firmware"></a>
### Upgrading BIOS and Firmware

BIOS and Firmware should be updated prior to install for various components such as NCNs.

For minimum NCN versions see [Node Firmware](252-FIRMWARE-NODE.md). For minimum Network Device
versions see [Network Firmware](251-FIRMWARE-NETWORK.md).

Not meeting the minimum versions can result in:

- Misnamed interfaces (missing `hsn0`)
- Malfunctioning bonds (`bond0`)
- Link failures (i.e. QLogic cards set to 10Gbps fixed)
- Malfunctioning or disabled Multi-Chassis LAGG

<a name="re-cabling"></a>
### Re-cabling

The Shasta-1.3 system needs a cable check for a few connections.

- [Site Connections](#site-connections)
- [PCIe Connections](#pcie-connections)

<a name="site-connections"></a>
#### Site Connections

Installs in Shasta v1.4 base out of m001 instead of wn001 (the "bis" node). Systems are required to upgrade their topology to match.

See [moving site connections](309-MOVE-SITE-CONNECTIONS.md) to complete this step.

<a name="pcie-connections"></a>
#### PCIe Connections

This **is strongly encouraged** to prevent overhead when adding new NCNs that the
existing NCNs are re-cabled to facilitate PCIe PXE booting and "keeping NCNs the same."

Installs for NCNs support PCIe PXE booting for deployment. Previous installations of Shasta v1.3 and
earlier used their onboard interfaces to start PXE, before pivoting to their faster PCIe ports for
SLES install. Now, everything is over the PCIe.

See [PCIe Net-boot and Re-cable](304-NCN-PCIE-NET-BOOT-AND-RE-CABLE.md) for information on enabling
PCIe PXE boot.

<a name="powering-off-ncns"></a>
### Powering off NCNs

> UANs and CNs do not need to power off.

NCNs hosting Kubernetes services need to be powered off to facilitate a 1.4 install. Wiping the node
will avoid boot mistakes, making the only viable option the PXE option.

> Assuming [site connections](#site-connections) were updated, the administrator will need to use m001 as
> a jump box.

Below, observe using Ansible for wiping and shutting down the NCNs.

  ```bash
  # jumpbox
  ncn-m001:~ # ssh ncn-w001

  # wipe all other nodes and power them off
  ncn-w001:~ # ansible ncn -m shell 'wipefs --all --force /dev/sd[a-z]'
  ncn-w001:~ # ansible ncn -m shell --limit='!ncn-w001' 'ipmitool power off'
  ncn-w001:~ # ipmitool power off
  ```

> Next: Starting an Installation

The system is now ready for [Starting an Installation](#starting-an-installation).

---

<a name="installing-onto-bare-metal-systems"></a>
## Installing onto Bare-metal Systems

Each item below defines a pre-requisite necessary for a bare-metal installation to succeed.

> **`NOTE`** On bare-metal, the LiveCD tool will assist with these steps.

* [LiveCD Setup](#livecd-setup)
* [Collect Config Payload](#collect-config-payload)
* [Network Configuration and Firmware](#network-configuration-and-firmware)
* [Upgrading BIOS and Firmware](#upgrading-bios-and-firmware)

<a name="livecd-setup"></a>
### LiveCD Setup

A 1TB USB3.0 USB stick will be required in order to create a bootable LiveCD.

The LiveCD itself can be used out-of-the-box, and with only a little configuration it can serve for
the various bare-metal pre-req tasks.

Experimental - See **[LiveCD Quick Setup](062-LIVECD-VIRTUAL-ISO-BOOT.md)** for either remote ISO path, this is useful for exploring a new system quickly. Other lab users may prefer a bootable USB stick to enable persistence, and for bringing artifacts for firmware updates.

Once you are booted into a LiveCD, proceed onto the next pre-requisite steps for bare-metal.

<a name="collect-config-payload"></a>
### Collect Config Payload

New configuration files are needed and can be easier to collect from a running Shasta-1.3 system.

See the [Service Guides](300-SERVICE-GUIDES.md) for information regarding the three files.

<a name="network-configuration-and-firmware"></a>
### Network Configuration and Firmware

To complete this step, the network configuration needs to be applied. For information on bare
configurations, firmware, and more, see [Management network install](401-MANAGEMENT-NETWORK-INSTALL.md).

<a name="upgrading-bios-and-firmware"></a>
### Upgrading BIOS and Firmware

BIOS and Firmware should be updated prior to install for various components such as NCNs.

For minimum NCN versions see [Node Firmware](252-FIRMWARE-NODE.md).

> Next: Starting an Installation

The system is now ready for [Starting an Installation](#starting-an-installation).

---

<a name="reinstalling-a-shasta-v14-system"></a>
## Reinstalling a Shasta v1.4 System

The following pre-requisites must be completed in order to successfully reinstall Shasta v1.4.

* [Scaling Down DHCP](#scaling-down-dhcp)
* [Power down the NCNs](#power-down-the-ncns)
  * [Degraded System Notice](#degraded-system-notice)
  * [Powering Off](#powering-off)

<a name="scaling-down-dhcp"></a>
### Scaling Down DHCP

Runtime DHCP services interfere with the LiveCD's bootstrap nature to lease to BMCs. To remove
edge-cases, disable the run-time KEA.

Scale the deployment from either the LiveCD or any Kubernetes node

```bash
linux:~ # kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
```

<a name="bmcs-back-to-dhcp"></a>
### Set the BMCs on the systems back to DHCP

This step uses the old statics.conf on the system in case CSI changes IPs:

```bash
for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
do
ipmitool -U root -I lanplus -H $h -P initial0 lan set 1 ipsrc dhcp
done

for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
do
ipmitool -U root -I lanplus -H $h -P initial0 lan print 1 | grep Source
done

for h in $( grep mgmt /etc/dnsmasq.d/statics.conf | grep -v m001 | awk -F ',' '{print $2}' )
do
ipmitool -U root -I lanplus -H $h -P initial0 mc reset cold
done
```

<a name="power-down-the-ncns"></a>
### Power down the NCNs

> UANs and CNs do not need to power off.

<a name="degraded-system-notice"></a>
#### Degraded System Notice

If the system is degraded, and the administrator wants to ensure a clean-slated install then a wipe
may be performed to rule out issues with disks and boot-order.

For each NCN, login and wipe it

```bash
wipefs --all --force /dev/sd[a-z]
wipefs --all --force /dev/disk/by-label/*
ipmitool power off
```

<a name="powering-off"></a>
#### Powering Off

The NCNs will auto-wipe on the next install. Optionally, they can be powered down to minimize network
activity.

Power each NCN off using `ipmitool` from m001 (or the booted LiveCD if reinstalling an incomplete
install).

- Shutdown from LiveCD
  ```bash
    export username=root
    export IPMI_PASSWORD=
    conman -q | grep mgmt | xargs -t -i  ipmitool -I lanplus -U $username -E -H {} power off
    ```
- Shutdown from m001
    ```bash
    export username=alice
    export IPMI_PASSWORD=bobby
    grep ncn /etc/hosts | grep mgmt | sort -u | xargs -t -i ipmitool -I lanplus -U $username -E -H {} power off
    done
    ```

With the nodes off, you can now continue.

> *`Next`*: Starting an Installation

The system is now ready for [Starting an Installation](#starting-an-installation).

---

<a name="starting-an-installation"></a>
# Starting an Installation

**After finishing the pre-requisites** an installation can be started one of two ways.

<a name="boot-the-livecd"></a>
## Boot the LiveCD

All installs may be done in full from a LiveCD of any supported medium.

- For preloading on a laptop or and inserting into a CRAY, click here for starting an installation
  with the (persistent bootable) [CSM USB LiveCD](003-CSM-USB-LIVECD.md).

*Experimental*
- For installing through a remote console, click here for starting an installation with the (
  non-persistent bootable) [CSM Remote LiveCD](004-CSM-REMOTE-LIVECD.md).

> **`NOTICE`** the remote ISO runs entirely in the systems volatile memory.

> For installs using the remote mounted LiveCD (no USB stick), pay attention to memory usage as
artifacts are downloaded and subsequently extracted. When RAM is limited to less than 128GB, memory
pressure may occur from increasing file-system usage.
> For instances where memory is scarce, an NFS/CIF or HTTP/S share can be mounted in-place of the USB's data partition at `/var/www/ephemeral`. Using the same mount point as the USB data partition will help ward off mistakes when following along.
