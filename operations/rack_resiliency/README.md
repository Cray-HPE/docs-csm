# Rack Resiliency (RR)

- [Warning: RR is not for production use](#warning-rr-is-not-for-production-use)
- [Introduction](#introduction)
- [Terminology and components](#terminology-and-components)
    - [Rack Resiliency Service (RRS)](#rack-resiliency-service-rrs)
    - [Racks](#racks)
        - [Physical racks](#physical-racks)
        - [Ceph racks](#ceph-racks)
    - [Placement](#placement)
    - [Failure domains](#failure-domains)
    - [Zones](#zones)
    - [Critical services](#critical-services)
    - [ConfigMaps](#configmaps)
    - [Kyverno policy](#kyverno-policy)
    - [Resiliency Monitoring Service (RMS)](#resiliency-monitoring-service-rms)
    - [RRS CLI](#rrs-cli)
    - [RRS API](#rrs-api)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)

## Warning: RR is not for production use

In CSM 1.7.0, Rack Resiliency is **experimental** and **use-at-your-own-risk**. It is offered
as a technology preview for administrators who wish to try it in a non-production environment.
It has not undergone sufficient validation to be considered stable for production use.

## Introduction

HPE Cray Supercomputing EX systems are designed to maintain high availability (HA) for critical
services, even if management nodes fail. However, rack-level failures can cause service disruptions
if management nodes are concentrated within a single rack. This can result in the loss of HA quorum.
Additionally, incorrect physical placement or software configuration of storage nodes can cause
utility storage service disruptions due to rack-level failures.

To address these issues, CSM 1.7.0 includes the technology preview of Rack Resiliency, which provides management
rack level resiliency to maintain HA of critical management services due to a single rack failure.
This feature prevents system-wide outages, allowing for successful execution of user jobs or
scheduling new ones.

**NOTE**:

- Rack Resiliency is disabled by default.
- Rack Resiliency can be enabled only during fresh install of CSM 1.7 or an upgrade from CSM 1.6
  to CSM 1.7.
- Rack Resiliency cannot be disabled after it has been enabled during the install or upgrade.

## Terminology and components

### Rack Resiliency Service (RRS)

RRS is the implementation of Rack Resiliency in CSM.

For details on the Kubernetes deployment of RRS, see [`cray-rrs` Deployment](cray-rrs_Deployment.md).

### Racks

#### Physical racks

Racks are a standardized physical structure designed to house and organize computer servers and other
hardware like network switches. Each HPE Cray Supercomputing EX system rack houses NCNs and
non-NCNs, along with Slingshot switches. Racks are also referred to as cabinets.

#### Ceph racks

In the Rack Resiliency lexicon, the term "rack" also has a second meaning; a rack can refer to
a logical, hierarchical Ceph bucket in the
[CRUSH map](https://docs.ceph.com/en/latest/rados/operations/crush-map/). A Ceph rack groups together
hosts or nodes that are located in the same physical rack.

### Placement

Placement refers to the physical arrangement of nodes across racks.

### Failure domains

In the context of CSM, a failure domain is the minimum infrastructure that provides high availability
for CSM services.

### Zones

A [Zone](Zones.md) in the Rack Resiliency solution is a logical representation of a failure domain.
There are two varieties of zone in Rack Resiliency: [Kubernetes zones] and [Ceph Zones].

### Critical services

In the context of Rack Resiliency, [Critical Services](Critical_Services.md) are
those Kubernetes services that are necessary for the execution of user jobs.

### ConfigMaps

Rack Resiliency uses Kubernetes ConfigMaps to store information about critical services and zones.
They are also used to provide the configuration parameters for the
[Resiliency Monitoring Service](Resiliency_Monitoring_Service.md).

For details, see [ConfigMaps](ConfigMaps.md).

### Kyverno policy

Rack Resiliency uses a Kyverno policy to ensure that critical services survive the failure of nodes
or a single rack. This is accomplished by spreading out the replicas of the critical services across
multiple zones.

See [Kyverno Policy](Kyverno_Policy.md) for more information.

### Resiliency Monitoring Service (RMS)

The [Resiliency Monitoring Service (RMS)](Resiliency_Monitoring_Service.md) is a part of the
Rack Resiliency Service. The RMS provides the functionality to detect rack or node failures and monitor
critical services.

For more information, see [Resiliency Monitoring Service](Resiliency_Monitoring_Service.md).

### RRS CLI

The [Cray CLI](../../glossary.md#cray-cli-cray) has been updated to support the
Rack Resiliency Service. The RRS CLI has subcommands for the following:

- [Managing zones](Zones.md#managing-zones)
- [Managing Critical Services](Manage_Critical_Services.md)

### RRS API

The RRS RESTful API is used by the [RRS CLI](#rrs-cli) and also can be accessed using tools like `curl`.
See [Rack Resiliency Service v1](../../api/rrs.md) for more information.

## Architecture

![Rack Resiliency solution overview](../../img/rack-resiliency-1.png)

The Rack Resiliency solution is implemented in multiple stages. These stages are:

1. [Enabling Rack Resiliency](Enabling_Rack_Resiliency.md)
1. [Setup of Rack Resiliency](Setup_of_Rack_Resiliency.md)
1. [Resiliency Monitoring Service](Resiliency_Monitoring_Service.md)

## Troubleshooting

For information on how to troubleshoot RRS, see [Troubleshooting](Troubleshooting.md).
