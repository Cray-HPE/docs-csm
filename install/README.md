# Cray System Management Install

This page will guide an administrator through installing Cray System Management (CSM) on an
HPE Cray EX system. Fresh-installations on bare-metal or re-installations of CSM must follow
this guide in order.

## Bifurcated CAN notice

The Bifurcated CAN (BICAN) is a major feature introduced in CSM 1.2. The BICAN is designed to
separate administrative network traffic from user network traffic. More information can be found
on the [BICAN summary page](../operations/network/management_network/bican_technical_summary.md).
Review the BICAN summary before continuing with the CSM install. For detailed BICAN documentation,
see [BICAN technical details](../operations/network/management_network/bican_technical_details.md).

Detailed BICAN documentation can be found on the [BICAN technical details](../operations/network/management_network/bican_technical_details.md) pages.

Install Cray System Management by using one of the following options:

**Option 1** : [CSM Install](csm-install/README.md)

**Option 2 (Tech Preview)** : [CSM Install with Common Pre-installer](common-pre-install/README.md)
