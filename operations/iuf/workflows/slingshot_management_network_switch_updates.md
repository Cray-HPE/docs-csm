# Perform HPE Slingshot Switch and Management Network Switch Firmware Updates

This section updates the HPE Slingshot switch and management network switch firmware updates.

- [1. Perform HPE Slingshot switch firmware updates](#1-perform-hpe-slingshot-switch-firmware-updates)
- [2. Perform management network switch firmware updates](#2-perform-management-network-switch-firmware-updates)

> **NOTE:** Switch firmware updates may cause temporary interrupts in network traffic during the upgrade procedure.

## 1. Perform HPE Slingshot switch firmware updates

**`NOTE`** This subsection is only required if a new version of the HPE Slingshot product is being installed by IUF.

Instructions to perform HPE Slingshot switch firmware updates are provided in the "Update switch firmware for CSM" section of the _HPE Slingshot Administration Guide (S-9007)_.

Once this step has completed:

- HPE Slingshot switch firmware has been updated

## 2. Perform management network switch firmware updates

**`NOTE`** This section is optional and can be skipped or deferred unless network configuration that requires updated firmware is being applied to the system.

Management network switch firmware is shipped in the HPC Firmware Pack (HFP) product tarball.

Refer to [Update Management Network Firmware](../../network/management_network/firmware/update_management_network_firmware.md) for instructions on performing the switch firmware update.

**`NOTE`** The firmware on spine, leaf, and CDU switches can be updated without disruption. Air-cooled compute nodes, their BMCs, and other air-cooled devices
such as HPE Slingshot switches will experience a loss of connectivity while the leaf-bmc switch the device is connected to restarts.

Once this step has been completed:

- Management network switch firmware has been updated
