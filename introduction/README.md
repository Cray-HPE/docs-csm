# Introduction to CSM Installation

This document provides an introduction to the Cray System Management (CSM) installation documentation
for an HPE Cray EX system.

## Topics

- [CSM overview](#csm-overview)
- [Installing or upgrading CSM](#installing-or-upgrading-csm)
- [CSM product stream updates](#csm-product-stream-updates)
- [CSM operational activities](#csm-operational-activities)
- [Deprecated Features](#deprecated-features)
- [Documentation Conventions](#documentation-conventions)
- [Viewing CSM Documentation](#viewing-csm-documentation)

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

## Installing or upgrading CSM

For information on installing or reinstalling CSM on a system, see [Install CSM](../install/README.md).

For information on upgrading the CSM software on a system, see [Upgrade CSM](../upgrade/README.md).

## CSM product stream updates

The software included in the CSM product stream is released in more than one way. The initial product release may be augmented with late-breaking documentation updates or hotfixes after the release.

See [CSM Product Stream Updates](../update_product_stream/README.md).

## CSM operational activities

Procedures which are used during either installation, upgrading, or general operation of the system reside here. They are referenced in the context
of the specific workflow. For example, updating firmware with FAS or running the CSM health checks.

See [CSM Operational Activities](../operations/README.md).

## Deprecated features

For information on deprecated features in CSM releases, see [Deprecated Features](deprecated_features/README.md).

## Documentation conventions

The CSM documentation follows conventions to ensure consistency across documentation and provide a
better experience for readers. These conventions must be followed when writing or updating documentation.

For more information, see [Documentation Conventions](documentation_conventions.md).

## Viewing CSM documentation

The CSM documentation can be viewed in multiple ways, both online and offline. For
more details and tips, see [Viewing CSM documentation](viewing_csm_documentation.md).
