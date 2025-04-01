# Perform Slingshot switch and management network switch firmware updates

This section updates the Slingshot switch and management network switch firmware updates.

- [1. Perform Slingshot switch firmware updates](#1-perform-slingshot-switch-firmware-updates)
- [2. Perform management network switch firmware updates](#2-perform-management-network-switch-firmware-updates)

> **NOTE:** Switch firmware updates may cause temporary interrupts in network traffic during the upgrade procedure.

## 1. Perform Slingshot switch firmware updates

**`NOTE`** This subsection is optional and can be skipped if upgrading only CSM through IUF.

Instructions to perform Slingshot switch firmware updates are provided in the "Upgrade HPE Slingshot switch firmware in a CSM environment" section of the _HPE Slingshot Installation Guide for CSM_.

Once this step has completed:

- Slingshot switch firmware has been updated

## 2. Perform management network switch firmware updates

**`NOTE`** This section is optional and can be skipped or deferred unless network configuration that requires updated firmware is being applied to the system.

Management network switch firmware is shipped in the HPC Firmware Pack (HFP) product tarball.

Refer to [Update Management Network Firmware](../../network/management_network/firmware/update_management_network_firmware.md) for instructions on performing the switch firmware update.

**`NOTE`** The firmware on spine, leaf, and CDU switches can be updated without disruption. Air-cooled compute nodes, their BMCs, and other air-cooled devices
such as Slingshot switches will experience a loss of connectivity while the leaf-bmc switch the device is connected to restarts.

Once this step has been completed:

- Management network switch firmware has been updated