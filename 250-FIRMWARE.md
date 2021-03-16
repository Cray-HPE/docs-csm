# Firmware Checkout

This page will guide an administrator on 3 things:
1. Checking Firmware Status
1. Applying Firmware over the GUI
1. (optionally) Applying firmware via Redfish

Information below is sorted based on device type; complete each when directed to by the prerequisite page. On the other hand, if an administrator is using this guide ad-hoc then they must complete each of the listed guides in order.

- (**required**) [Management Network Firmware Guide](251-FIRMWARE-NETWORK.md)
- (**required**) [NCN Firmware Guide for Bootstrap](252-FIRMWARE-NCN.md)

##### Guides for Runtime

The following guide(s) can be done when the CRAY is operational (in runtime).

These are **not** required for an installation. 

- [NCN Firmware Installation Guide for FAS](010-FIRMWARE-UPDATE-WITH-FAS.md)
- [NCN Firmware Action Service (FAS) Guide](255-FIRMWARE-ACTION-SERVICE-FAS.md)
- [NCN Firmware Action Service FAS Recipes](256-FIRMWARE-ACTION-SERVICE-FAS-RECIPES.md)

> **WARNING:** Non-compute nodes (NCNs) should be locked with the HSM locking API to ensure they are not unintentionally updated by FAS. Research [009-NCN-LOCKING](009-NCN-LOCKING.md) for more information. Failure to lock the NCNs could result in an unintentional update of the NCNs if FAS is not used correctly; this will lead to system instability problems.
