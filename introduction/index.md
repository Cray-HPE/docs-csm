# Introduction to CSM Installation

This document provides an introduction to the Cray System Management (CSM) installation documentation
for an HPE Cray EX system.

### Topics:
   * [CSM Overview](#csm_overview)
   * [Scenarios for Shasta v1.5](#scenarios)
   * [CSM Product Stream Updates](#product-stream-updates)
   * [CSM Operational Activities](#operations)
   * [Differences from Previous Release](#differences)
   * [Documentation Conventions](#documentation_conventions)

## Details

<a name="csm_overview"></a>
## CSM Overview

   The CSM installation prepares and deploys a distributed system across a group of management
   nodes organized into a Kubernetes cluster which uses Ceph for utility storage. These nodes
   perform their function as Kubernetes master nodes, Kubernetes worker nodes, or utility storage
   nodes with the Ceph storage.

   System services on these nodes are provided as containerized micro-services packaged for deployment
   via Helm charts. Kubernetes orchestrates these services and schedules them on Kubernetes worker
   nodes with horizontal scaling. Horizontal scales increases or decreases the number of services instances
   demand for them varies, such as when booting many compute nodes or application nodes.

   There is much more information available in the [CSM Overview](csm_overview.md) about the hardware,
   software, network, and access to these services and components.

   See [CSM Overview](csm_overview.md)

<a name="scenarios"></a>
## Scenarios for Shasta v1.5

   These scenarios for how to get CSM software onto a system are described in [Scenarios for Shasta v1.5](scenarios.md).

   * Installation of CSM software
      * First time installation of CSM software
      * Reinstall of CSM software
   * Upgrade from a previous version of CSM software

   Note: A migration from Shasta v1.3.x software to Shasta v1.5 software is not supported as a direct action, but is a two step process of first migrating from Shasta v1.3.x to Shasta v1.4 and then following the Upgrade procedure from v1.4 to v1.5.

See [Scenarios for Shasta v1.5](scenarios.md)

<a name="product-stream-updates"></a>
## CSM Product Stream Updates

   The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with late-breaking documentation updates or hotfixes after the release.

   See [CSM Product Stream Updates](../update_product_stream/index.md)

<a name="operations"></a>
## CSM Operational Activities

   Procedures which are used during either installation or upgrading of software or in both, but which
   may also be used for general operation of the system reside here. They are referenced in the context
   of the installation workflow. For example, updating firmware with FAS or running the CSM health checks.

   See [CSM Operational Activities](../operations/index.md)

<a name="differences"></a>
## Differences from Previous Release

   Significant changes from the previous release of CSM are described.

   * New Features
   * Deprecating Features
   * Deprecated Features
   * Other Changes

See [Differences from Previous Release](differences.md)

<a name="documentation_conventions"></a>
## Documentation Conventions

   Several conventions have been used in the preparation of this documentation.

   * File Formats
   * Typographic Conventions
   * Command Prompt Conventions which indicate the context for user, host, directory, chroot environment, or container environment

See [Documentation Conventions](documentation_conventions.md)
