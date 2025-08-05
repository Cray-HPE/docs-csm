# Rack Resiliency (RR)

* [Introduction](#introduction)
* [Key Terminology](#key-terminology)
* [Objective of Rack Resiliency](#objective-of-rack-resiliency)
    * [Key Features](#key-features)
* [Architecture Overview](#architecture-overview)
    * [Management plane placement discovery and placement validation](management_plane_discovery_and_validation.md)
    * [Spreading of NCNs across Kubernetes zones, and spreading storage nodes across Ceph zones](spreading_NCNs_across_k8s_and_ceph_zones.md)
    * [Distribution of critical services across zones](distribution_of_critical_services_across_zones.md)
    * [Monitoring failures and ensuring critical services are available across zones](monitor_and_ensure_critical_service_availability.md)
* [Components of Rack Resiliency](#components-of-rack-resiliency)
    * [Critical Services](README.md#1-critical-services)
    * [ConfigMaps](README.md#2-configmaps)
    * [Kyverno Policy](README.md#3-kyverno-policy)
    * [Rack Resiliency Service (RRS)](README.md#4-rack-resiliency-service-rrs)
* [Rack Resiliency Management Tools](#rack-resiliency-management-tools)
    * [Interactive interface with Cray CLI](#interactive-interface-with-cray-cli)
    * [API Interface with  RESTful APIs](#api-interface-with--restful-apis)
* [Rack Resiliency Management Tasks](#rack-resiliency-management-tasks)
    * [Enable and Configure Rack Resiliency](README.md#1-enable-and-configure-rack-resiliency)
    * [Managing Critical Services](README.md#2-managing-critical-services)
    * [Managing `Kyverno` Policy](README.md#3-managing-kyverno-policy)
* [Troubleshooting](#troubleshooting)

# Introduction

HPE Cray Supercomputing EX systems are engineered to ensure services critical to the execution of user jobs, remain resilient, even if management nodes (Master, Worker, and Storage nodes) fail, provided that the minimum quorum of nodes required for high availability (HA) is maintained, user jobs will remain unaffected. Despite these methods of software resiliency, rack-level failures can cause service disruptions if management nodes running critical services are concentrated within a single rack. The loss of critical management services can occur when multiple nodes located in the same rack fail, resulting in the loss of the quorum necessary for HA. 

A similar problem emerges for utility storage on management storage nodes. Even though these are not orchestrated by Kubernetes, incorrect physical placement or software configuration, specifically around replication, may cause utility storage service disruptions in the event of rack-level failures.

The Rack Resiliency feature is introduced in CSM 1.7.0 to mitigate the issues mentioned above. It provides management rack level resiliency by providing methods and functionality required to maintain the HA of critical management services due to a single rack failure. This feature ensures that CSM can tolerate failures of racks and prevent a system-wide outage, where such outage encompasses the inability for completing current jobs or scheduling new ones. This feature doesn't address planned downtime of racks.

**NOTE**: 
- This feature is disabled by default. 
- This feature does not address routine maintenance scenario.

# Key Terminology

* Rack: A standardized structure designed to house and organize computer servers and other hardware like network switches. Each HPE Cray Supercomputing EX system rack houses `NCNs` and `Non-NCNs` along with slingshot switches. This is also referred to as cabinets.
* [Zone](Zones.md): A zone represents a logical failure domain. It is common for Kubernetes clusters to span multiple zones for increased availability.
* Failure Domain: Failure domains are zones which includes infrastructure that provides availability for CSM services.
* MPFD: Management Plane Failure Domain
* Placement: Arrangement of Management Nodes across racks. Note that zone awareness primitives in Kubernetes refer to this as "topology".
* Kubernetes topology zones: You can use topology spread constraints to control how pods are spread across cluster among failure-domains such as regions, zones, nodes,
  and other user-defined topology domains. This can help to achieve high availability as well as efficient resource utilization.
* Ceph is the utility storage platform that is used to enable pods to store persistent data. It is deployed to provide block, object, and file storage to the
  management services running on Kubernetes, as well as for telemetry data coming from the compute nodes.
* [Critical services](Critical_Services.md): Critical services are those services that are critical to execution of user jobs. These services are monitored by [Rack Resiliency Service](Rack_Resiliency_Service.md).

# Objective of Rack Resiliency

To enable CSM to tolerate failure of racks and prevent a system-wide outage, where such outage encompasses the inability for completing current jobs or scheduling new ones. The RR solution provides the ability to distribute and monitor critical services to tolerate single rack failures.

## Key Features

* Discovery of kubernetes management plane along with storage nodes
* Validation of placement of management plane
* Efficient zoning of kubernetes nodes along with ceph nodes to provide tolerance for single rack failure
* Identification and segregation of [critical services](Critical_Services.md) essential for user jobs
* Policy based distribution of critical services across [MPFD](#key-terminology)
* Continous monitoring of critical services and generation of alerts post failures of nodes or rack.

# Architecture Overview

![Rack Resiliency solution overview](../../img/rack-resiliency-1.png)

The Rack Resiliency solution is implemented in multiple stages. These stages are:

[Stage 1 - Enablement](Enabling_Rack_Resiliency.md)
[Stage 2 - Placement Discovery](Setup.md#stage-2---placement-discovery)
[Stage 3 - Placement Validation](Setup.md#stage-3---placement-validation)
[Stage 4 - Kubernetes Zoning](Setup.md#stage-4---kubernetes-zoning)
[Stage 5 - Ceph Zoning]((Setup.md#stage-4---ceph-zoning))
[Stage 6 - Apply Kyverno policy](#stage-5---apply-kyverno-policy)
[Stage 7 - Deploy Rack Resiliency Service](#deploying-helm-charts-for-rack-resiliency-service-rrs)
[Stage 8 - Continous Monitoring](Resiliency_Monitoring_Service.md)

# Components of Rack Resiliency

## 1. Critical Services

Rack Resiliency monitors specific CSM Services for continous availability. These services are called critical services. For further details refer to [Critical Servies](Critical_Services.md)

## 2. ConfigMaps

Rack Resiliency(RR) uses configmaps to store details about the critical services. They are also used to provide the configuration parameters for [resiliency monitoring service](Resiliency_Monitoring_Service.md).

Refer for more information on [ConfigMaps](ConfigMaps.md)

## 3. `Kyverno` policy

One of the key ways to ensure that CSM critical services survive the failure of nodes or a single rack is to spread the replicas of these services across multiple zones and racks. 

Refer [`Kyverno` cluster policy](distribution_of_critical_services_across_zones.md#kyverno-cluster-policy) for more info.

## 4. [Rack Resiliency Service](Rack_Resiliency_Service.md) (RRS)
 
RRS is designed as a singleton pod(`cray-rrs`) with two containers - cray-rrs-rms and cray-rrs-api along with two init containers named cray-rrs-check and cray-rrs-init

**Resiliency Monitoring Service (RMS)**

The Resiliency Monitoring Service (RMS) provides the functionality to detect rack or node failures and monitor critical services post the failure. 
  
Refer for more info on [RMS](Resiliency_Monitoring_Service.md)

**Rack Resiliency API Service**

The Rack Resiliency Service (RRS) provides APIs to access and manage zones data and critical services information within Kubernetes and Ceph clusters. 
It supports zone discovery, status checks, and critical service registration. RRS is used by the Cray `rrs` CLI to power high-availability, fault-tolerant operations.

Refer [API](../../api/rrs.md) for more info.

Refer for more information on [RRS](Rack_Resiliency_Service.md)

# Rack Resiliency Management Tools

## Interactive interface with Cray CLI
    * The CLI for interfacing with rack resiliency service is part of Cray CLI. A new module (RRS) is added to Cray CLI to support rack resiliency specific commands.
    * Refer [Craycli commands for zones](Zones.md#managing-zones) for more information on the commands related to zones.
    * Refer [Craycli commands for critical services](Managed_Critical_Services.md#critical-services-operations) for more information on the commands related to critical services.

## API Interface with  RESTful APIs
    * Refer for more info [RRS](../../api/rrs.md) for APIs
  
# Rack Resiliency Management Tasks

## 1. Getting started with Rack Resiliency

Rack Resiliency uses a 3 step procedure to be set up for monitoring critical services:

1. [Enabling Rack Resiliency and add zone prefixes](Enabling_Rack_resiliency.md#update-customization-yaml-file)
2. [Setup Rack Resiliency](Setup.md#running-ansible-playbooks)
3. [Deploy RRS (Rack Resiliency Service)](#deploying-helm-charts-for-rack-resiliency-service-rrs)

### Deploying helm charts for Rack Resiliency Service (RRS)

The RRS (Rack Resiliency Service) Helm chart includes both the RRS and the RMS (Resiliency Monitoring Service). The chart will be deployed automatically during the CSM install or upgrade process, provided that RR is enabled. Otherwise, the chart will not be deployed.

## 2. Managing critical services

During the execution of RRS there maybe a need to manage critical services, which may need administrator intervention. This can be done using the Cray CLI or the API. Refer [manage critical services](Managed_Critical_Services.md) for complete list of supported operations.

## 3. Managing `kyverno` policy 

While managing critical services the kyverno policy also needs to be managed. Refer [Manage `kyverno` policy](kyverno.md) for complete list of supported operations.

# Troubleshooting

There are scenarios which need administrator interference. For complete list of scenarios related to different components of Rack Resiliency refer to [Troubleshooting](Troubleshooting.md).
