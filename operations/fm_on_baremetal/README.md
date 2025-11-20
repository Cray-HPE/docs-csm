# FM (Fabric Manager) on baremetal

- [Introduction](#introduction)
- [Terminology and components](#terminology-and-components)
- [Architecture](#architecture)
- [Enable and configure](#enable-and-configure)
- [Troubleshooting](#troubleshooting)

## Introduction

The Fabric Manager (FM) bare-metal enablement within the Cray System Management (CSM) framework introduces dedicated Fabric Manager Nodes (FMNs) that manage and monitor Slingshot fabric operations outside of a Kubernetes environment. While the overall bare-metal Fabric Manager solution is described in the Slingshot Fabric Manager HA documentation <reference>, this CSM detail design document focuses specifically on the CSM-level enhancements required to integrate and support FMNs.

CSM 1.7.1 includes bare-metal FM support, which provides the necessary base OS image, networking, and storage configurations for running the Slingshot Fabric Manager natively within the CSM environment.

**NOTE**:

- FM on baremetal is disabled by default.

## Terminology and components

## Architecture

![FM On Baremetal Solution Overview](../../img/fm_on_baremetal.png)

The FM HA solution is implemented in following stages. These stages are:

1. [Enable and configure](#enable-and-configure)
1. [Setup of FM HA](Setup_of_FM_HA.md)

## Enable and configure

How to enable and configure FM on baremetal depends on the context.
See the following links:

- [Enabling FM On BaremetalPost CSM Install](Enabling_FM_On_Baremetal_Post_CSM_Install.md)
- [Enabling FM On BaremetalPost CSM Upgrade](Enabling_FM_On_Baremetal_Post_CSM_Upgrade.md)

## Troubleshooting

For information on how to troubleshoot FM on baremetal, see [Troubleshooting](Troubleshooting.md).
