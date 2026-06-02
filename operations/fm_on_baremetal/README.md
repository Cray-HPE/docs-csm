# FM (Fabric Manager) on baremetal

- [Introduction](#introduction)
- [Terminology and Components](#terminology-and-components)
- [Architecture](#architecture)
- [Configure FM on baremetal](#configure-fm-on-baremetal)
- [Slingshot Switch Firmware Update](#slingshot-switch-firmware-update)

## Introduction

The Fabric Manager (FM) bare-metal enablement within the Cray System Management (CSM) framework introduces dedicated Fabric Manager Nodes (FMNs) that manage and monitor Slingshot fabric operations outside of a Kubernetes environment. The overall bare-metal Fabric Manager solution is described in the Slingshot Fabric Manager HA documentation <reference>.

CSM 1.7.1 includes bare-metal FM support, which provides the necessary base OS image, networking, and storage configurations for running the Slingshot Fabric Manager natively within the CSM environment.

**NOTE**:

* `FMNs` are considered Management nodes.
* After Fabric Manager is migrated from a Kubernetes pod to bare-metal infrastructure, it cannot be reverted.
* The two `FMNs` must be part of two different management racks to support Rack Resiliency.
* This feature will not be supported on systems with Dell/ Mellanox based management networks.

## Terminology and Components

### SHS
[Slingshot Host Software](../../glossary.md#slingshot-host-software-shs)

### FM
[Fabric Manager](../../glossary.md#fabric-manager)

### FMN
[Fabric Manager Node](../../glossary.md#fabric-manager-node)

### SLS 

[System Layout Service](../../glossary.md#system-layout-service-sls)

### HSM 
[Hardware State Manager](../../glossary.md#hardware-state-manager-hsm)

### BSS
[Boot Script Service](../../glossary.md#boot-script-service-bss)

### CANU
[CSM Automatic Network Utility](../../glossary.md#csm-automatic-network-utility-canu)

### SAT
[System Admin Toolkit](../../glossary.md#system-admin-toolkit-sat)

### SMA
[System Monitoring Application](../../glossary.md#system-monitoring-application-sma)

## Architecture

In CSM versions < 1.7.0, the deployment of the Fabric Manager within CSM uses native Kubernetes capabilities—both during upgrades and in failure/HA scenarios. Kubernetes itself provides health checks and a scheduler that can rebalance workloads across nodes based on load, administrative policies, and other criteria. The Fabric Manager is deployed as a single pod in Kubernetes. A traditional HA model for Fabric Manager doesn’t map cleanly into Kubernetes, so instead, Kubernetes’ built-in mechanisms detect failures and spin up a replacement pod, minimizing downtime.

In theory, this model should satisfy HA requirements: if the pod fails (or needs to be moved during an upgrade), Kubernetes can detect the fault and recreate the Fabric Manager on another node, providing continuity.

In practice, however, this approach does not meet the contractual HA obligations. Because of Kubernetes "best‑effort" scheduling and the resource demands of the Fabric Manager, real service outages can exceed 5 minutes.

To address these issues, CSM 1.7.1 includes FM on baremetal support, which provides the necessary base OS image, networking, and storage configurations for running the Slingshot Fabric Manager natively within the CSM environment to achieve HA.

![FM On Baremetal](FM-HA-1.png)

## Configure FM on baremetal

To configure FM on baremetal please follow the [procedure](Configure_FM_On_Baremetal.md).

## Slingshot Switch Firmware Update

* For clusters using the FM pod: CSM will continue to handle switch firmware uploads and updates as [before](../../operations/iuf/workflows/slingshot_management_network_switch_updates.md#perform-slingshot-switch-and-management-network-switch-firmware-updates).
* For clusters with bare-metal FM: FMN will host the switch firmware, and FM will be responsible for managing switch updates. Refer section "3.2.6 (Optional) Update HPE Slingshot switch firmware" in _HPE Slingshot Installation Guide for CSM_ PDF.
