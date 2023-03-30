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

## High-level overview of CSM install

In the [Pre-installation](#pre-installation) section of the install, information about the HPE Cray
EX system and the site is used to prepare the configuration payload. An initial node called the PIT
node is then set up to bootstrap the installation process. It is called the PIT node because the
Pre-Install Toolkit is installed there. The management network switches are also configured in this
section.

In the [Installation](#installation) section of the install, the other management nodes are deployed
with an operating system and the software required to create a Kubernetes cluster utilizing Ceph
storage. The CSM services are then deployed in the Kubernetes cluster to provide essential software
infrastructure including the API gateway and many micro-services with REST APIs for managing the
system. Administrative access is then configured, and the health of the system is validated before
proceeding with operational tasks like checking and updating firmware on system components and
preparing compute nodes.

The [Post-installation](#post-installation) section covers tasks which are performed after the
main install procedure is completed.

The final section, [Installation of additional HPE Cray EX software products](#installation-of-additional-hpe-cray-ex-software-products)
describes how to install additional HPE Cray EX software products using the Install and Upgrade
Framework (IUF).

Detailed BICAN documentation can be found on the [BICAN technical details](../operations/network/management_network/bican_technical_details.md) pages.

Install Cray System Management by using one of the following options:

**Option 1** : [CSM Install](csm-install/README.md)

**Option 2 (Tech Preview)** : [CSM Install with Common Pre-installer](common-pre-install/README.md)