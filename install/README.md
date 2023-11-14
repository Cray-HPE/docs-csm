# Cray System Management Install

This page will guide an administrator through installing Cray System Management (CSM) on an
HPE Cray EX system. Fresh-installations on bare-metal or re-installations of CSM must follow
this guide in order.

## Bifurcated CAN notice

Introduced in CSM 1.2, a major feature of CSM is the [Bifurcated CAN (BICAN)](../glossary.md#bifurcated-can-bican).
The BICAN is designed to separate administrative network traffic from user network traffic.
More information can be found on the [BICAN Technical Summary](../operations/network/management_network/bican_technical_summary.md).
Review the BICAN summary before continuing with the CSM install.
For detailed BICAN documentation, see [BICAN Technical Details](../operations/network/management_network/bican_technical_details.md).

Install Cray System Management by using one of the following options:

**Option 1** : [CSM Install](csm-install/README.md)

**Option 2 (Tech Preview)** : [CSM Install with Common Pre-installer](common-pre-install/README.md)
