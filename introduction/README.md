# Introduction to CSM Installation

This document provides an introduction to the Cray System Management (CSM) installation documentation
for an HPE Cray EX system.

## Topics

- [CSM overview](#csm-overview)
- [Scenarios for Shasta v1.5](#scenarios-for-shasta-v15)
- [CSM product stream updates](#csm-product-stream-updates)
- [CSM operational activities](#csm-operational-activities)
- [Differences from previous release](#differences-from-previous-release)
- [Documentation conventions](#documentation-conventions)

## CSM overview

The CSM installation prepares and deploys a distributed system across a group of management
nodes organized into a Kubernetes cluster which uses Ceph for utility storage. These nodes
perform their function as Kubernetes master nodes, Kubernetes worker nodes, or utility storage
nodes with the Ceph storage.

System services on these nodes are provided as containerized micro-services packaged for deployment
via Helm charts. Kubernetes orchestrates these services and schedules them on Kubernetes worker
nodes with horizontal scaling. Horizontal scaling increases or decreases the number of services' instances as
demand for them varies, such as when booting many compute nodes or application nodes.

There is much more information available in the [CSM Overview](csm_overview.md) about the hardware,
software, network, and access to these services and components.

See [CSM Overview](csm_overview.md).

## Scenarios for Shasta v1.5

These scenarios for how to get CSM software onto a system are described in [Scenarios for Shasta v1.5](scenarios.md).

- Installation of CSM software
  - First time installation of CSM software
  - Reinstall of CSM software
- Upgrade from a previous version of CSM software

> ***NOTE*** A migration from Shasta v1.3.x software to Shasta v1.5 software is not supported
> as a direct action, but is a two step process of first migrating from Shasta v1.3.x to
> Shasta v1.4 and then following the upgrade procedure from v1.4 to v1.5.

See [Scenarios for Shasta v1.5](scenarios.md).

## CSM product stream updates

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with late-breaking documentation updates or hotfixes after the release.

See [CSM Product Stream Updates](../update_product_stream/README.md).

## CSM operational activities

Procedures which are used during either installation, upgrading, or general operation of the system reside here. They are referenced in the context
of the specific workflow. For example, updating firmware with FAS or running the CSM health checks.

See [CSM Operational Activities](../operations/README.md).

## Differences from previous release

Significant changes from the previous release of CSM are described.

- New features
- Deprecating features
- Deprecated features
- Other changes

See [Differences from Previous Release](differences.md).

## Documentation conventions

Several conventions have been used in the preparation of this documentation.

- File formats
- Typographic conventions
- Command prompt conventions, which indicate the context for user, host, directory, `chroot` environment, or container environment

See [Documentation Conventions](documentation_conventions.md)
